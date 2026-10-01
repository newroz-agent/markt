-- Step B: one private/business listing submission path and one admin queue.
-- Existing product/seller enums, RLS, notification outbox, and Realtime publication
-- are extended rather than duplicated.

begin;

alter table public.products
  add column if not exists moderation_reason text,
  add column if not exists moderated_at timestamptz,
  add column if not exists moderated_by uuid references auth.users (id) on delete set null;

alter table public.products
  drop constraint if exists products_moderation_reason_length,
  add constraint products_moderation_reason_length
    check (moderation_reason is null or char_length(moderation_reason) <= 2000),
  drop constraint if exists products_moderation_reason_status,
  add constraint products_moderation_reason_status
    check (status = 'rejected' or moderation_reason is null);

create index if not exists products_moderation_queue_idx
  on public.products (created_at, id)
  where status = 'pending_review';
create index if not exists products_moderated_today_idx
  on public.products (moderated_at, status)
  where moderated_at is not null;

-- The later unified trigger forces both seller kinds to pending. Align the
-- insert policy with that final trigger result (the older policy expected
-- private sellers to be approved and therefore rejected their post-trigger row).
drop policy if exists sellers_insert_own_application on public.sellers;
create policy sellers_insert_own_application
  on public.sellers for insert to authenticated
  with check (user_id = auth.uid() and status = 'pending');

create or replace function public.is_marketplace_german_city(candidate text)
returns boolean
language sql
immutable
parallel safe
set search_path = ''
as $$
  select pg_catalog.btrim(coalesce(candidate, '')) = any (array[
    'Berlin', 'Hamburg', 'München', 'Köln', 'Frankfurt am Main',
    'Stuttgart', 'Düsseldorf', 'Leipzig', 'Dortmund', 'Essen', 'Bremen',
    'Dresden', 'Hannover', 'Nürnberg', 'Bonn', 'Halle (Saale)',
    'Magdeburg', 'Karlsruhe', 'Mannheim', 'Augsburg'
  ]::text[]);
$$;

create or replace function public.prepare_product_write()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is not null and not public.is_admin() then
    if tg_op = 'INSERT' then
      new.status = 'pending_review';
      new.published_at = null;
      new.moderation_reason = null;
      new.moderated_at = null;
      new.moderated_by = null;
    elsif new.status is distinct from old.status
      or new.moderation_reason is distinct from old.moderation_reason
      or new.moderated_at is distinct from old.moderated_at
      or new.moderated_by is distinct from old.moderated_by then
      raise exception 'Product moderation fields are reserved for administrators'
        using errcode = '42501';
    end if;
  end if;

  if new.status = 'active' then
    new.published_at = coalesce(new.published_at, now());
    new.moderation_reason = null;

    update public.sellers as seller
    set status = 'approved',
        approved_at = coalesce(seller.approved_at, now()),
        rejection_reason = null
    where seller.id = new.seller_id
      and seller.status in ('pending', 'rejected');
  else
    new.published_at = null;
    if new.status <> 'rejected' then
      new.moderation_reason = null;
    end if;
  end if;

  return new;
end;
$$;

-- Reserve a server-generated product UUID and create the caller's single seller
-- identity when needed. No product exists until submit_listing validates uploads.
create or replace function public.prepare_listing_submission(
  p_seller_kind public.seller_kind,
  p_seller_name text,
  p_city text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  seller_row public.sellers%rowtype;
  new_seller_id uuid;
  reserved_product_id uuid := extensions.gen_random_uuid();
  normalized_name text := nullif(pg_catalog.btrim(p_seller_name), '');
  normalized_city text := pg_catalog.btrim(coalesce(p_city, ''));
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if not public.is_marketplace_german_city(normalized_city) then
    raise exception 'Choose a supported German city' using errcode = '22023';
  end if;

  select seller.* into seller_row
  from public.sellers as seller
  where seller.user_id = auth.uid()
  for update;

  if not found then
    if normalized_name is null then
      select nullif(pg_catalog.btrim(profile.display_name), '')
        into normalized_name
      from public.profiles as profile
      where profile.id = auth.uid();
    end if;
    normalized_name := coalesce(normalized_name, 'Zêrîn Nutzer');
    if char_length(normalized_name) < 2 or char_length(normalized_name) > 100 then
      raise exception 'Seller name must contain 2 to 100 characters'
        using errcode = '22023';
    end if;

    new_seller_id := extensions.gen_random_uuid();
    insert into public.sellers (
      id, user_id, kind, status, shop_name, slug, city, country_code
    ) values (
      new_seller_id,
      auth.uid(),
      p_seller_kind,
      'pending',
      normalized_name,
      'seller-' || replace(left(new_seller_id::text, 18), '-', ''),
      normalized_city,
      'DE'
    )
    returning * into seller_row;
  end if;

  return jsonb_build_object(
    'seller_id', seller_row.id,
    'seller_kind', seller_row.kind,
    'seller_name', seller_row.shop_name,
    'product_id', reserved_product_id
  );
end;
$$;

-- Storage uploads precede the atomic product/image-row insert. The caller may
-- manage only exact <owned-seller>/<reserved-product>/<file>.webp paths.
create or replace function public.can_manage_product_image_upload_path(
  target_storage_path text
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null
    and array_length(storage.foldername(target_storage_path), 1) = 2
    and lower(target_storage_path) ~ '\.webp$'
    and (storage.foldername(target_storage_path))[2]
      ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    and exists (
      select 1
      from public.sellers as seller
      where seller.id::text = (storage.foldername(target_storage_path))[1]
        and seller.user_id = auth.uid()
    );
$$;

create or replace function public.submit_listing(
  p_product_id uuid,
  p_seller_id uuid,
  p_category_id uuid,
  p_title text,
  p_description text,
  p_condition public.product_condition,
  p_price_cents bigint,
  p_city text,
  p_image_paths text[],
  p_specifications jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  normalized_title text := pg_catalog.btrim(coalesce(p_title, ''));
  normalized_description text := pg_catalog.btrim(coalesce(p_description, ''));
  normalized_city text := pg_catalog.btrim(coalesce(p_city, ''));
  image_count integer := coalesce(cardinality(p_image_paths), 0);
  inserted_product public.products%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if not exists (
    select 1 from public.sellers as seller
    where seller.id = p_seller_id and seller.user_id = auth.uid()
  ) then
    raise exception 'Seller identity is not owned by caller' using errcode = '42501';
  end if;
  if not exists (
    select 1 from public.categories as category
    where category.id = p_category_id and category.is_active
  ) then
    raise exception 'Choose an active category' using errcode = '22023';
  end if;
  if not public.is_marketplace_german_city(normalized_city) then
    raise exception 'Choose a supported German city' using errcode = '22023';
  end if;
  if char_length(normalized_title) < 3 or char_length(normalized_title) > 180 then
    raise exception 'Title must contain 3 to 180 characters' using errcode = '22023';
  end if;
  if char_length(normalized_description) < 10
    or char_length(normalized_description) > 10000 then
    raise exception 'Description must contain 10 to 10000 characters'
      using errcode = '22023';
  end if;
  if p_price_cents is null or p_price_cents <= 0 then
    raise exception 'Price must be greater than zero' using errcode = '22023';
  end if;
  if jsonb_typeof(coalesce(p_specifications, '{}'::jsonb)) <> 'object' then
    raise exception 'Specifications must be an object' using errcode = '22023';
  end if;
  if image_count < 1 or image_count > 10 then
    raise exception 'A listing requires between 1 and 10 photos'
      using errcode = '22023';
  end if;
  if (select count(distinct path) from unnest(p_image_paths) as path) <> image_count then
    raise exception 'Listing photo paths must be unique' using errcode = '22023';
  end if;
  if exists (
    select 1
    from unnest(p_image_paths) as path
    where split_part(path, '/', 1) <> p_seller_id::text
      or split_part(path, '/', 2) <> p_product_id::text
      or array_length(storage.foldername(path), 1) <> 2
      or lower(path) !~ '\.webp$'
  ) then
    raise exception 'Listing photo path does not match the reserved listing'
      using errcode = '42501';
  end if;
  if (
    select count(*)
    from storage.objects as object
    where object.bucket_id = 'product-images'
      and object.name = any(p_image_paths)
  ) <> image_count then
    raise exception 'Every listing photo must be uploaded before submission'
      using errcode = '22023';
  end if;

  insert into public.products (
    id,
    seller_id,
    category_id,
    title,
    slug,
    description,
    condition,
    status,
    price_cents,
    specifications,
    city,
    country_code,
    quantity
  ) values (
    p_product_id,
    p_seller_id,
    p_category_id,
    normalized_title,
    'listing-' || replace(left(p_product_id::text, 18), '-', ''),
    normalized_description,
    p_condition,
    'draft',
    p_price_cents,
    coalesce(p_specifications, '{}'::jsonb),
    normalized_city,
    'DE',
    1
  )
  returning * into inserted_product;

  insert into public.product_images (product_id, storage_path, sort_order)
  select p_product_id, image.path, image.ordinality - 1
  from unnest(p_image_paths) with ordinality as image(path, ordinality);

  return jsonb_build_object(
    'id', inserted_product.id,
    'seller_id', inserted_product.seller_id,
    'status', inserted_product.status,
    'title', inserted_product.title,
    'created_at', inserted_product.created_at
  );
end;
$$;

create or replace function public.get_moderation_dashboard(
  p_limit integer default 50
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  bounded_limit integer := least(greatest(coalesce(p_limit, 50), 1), 100);
begin
  if auth.uid() is null or not public.is_admin() then
    raise exception 'Administrator role required' using errcode = '42501';
  end if;

  return jsonb_build_object(
    'counts', jsonb_build_object(
      'pending', (select count(*) from public.products where status = 'pending_review'),
      'approved_today', (
        select count(*) from public.products
        where status = 'active' and moderated_at >= date_trunc('day', now())
      ),
      'rejected_today', (
        select count(*) from public.products
        where status = 'rejected' and moderated_at >= date_trunc('day', now())
      )
    ),
    'items', coalesce((
      select jsonb_agg(item.payload order by item.created_at, item.id)
      from (
        select
          product.id,
          product.created_at,
          jsonb_build_object(
            'id', product.id,
            'title', product.title,
            'description', product.description,
            'condition', product.condition,
            'price_cents', product.price_cents,
            'currency', product.currency,
            'city', product.city,
            'specifications', product.specifications,
            'created_at', product.created_at,
            'seller', jsonb_build_object(
              'id', seller.id,
              'name', seller.shop_name,
              'kind', seller.kind
            ),
            'category', jsonb_build_object(
              'id', category.id,
              'name_de', category.name_de,
              'name_en', category.name_en,
              'name_ar', category.name_ar,
              'name_tr', category.name_tr,
              'name_ku', category.name_ku
            ),
            'images', coalesce((
              select jsonb_agg(jsonb_build_object(
                'storage_path', image.storage_path,
                'sort_order', image.sort_order
              ) order by image.sort_order, image.id)
              from public.product_images as image
              where image.product_id = product.id
            ), '[]'::jsonb)
          ) as payload
        from public.products as product
        join public.sellers as seller on seller.id = product.seller_id
        join public.categories as category on category.id = product.category_id
        where product.status = 'pending_review'
        order by product.created_at, product.id
        limit bounded_limit
      ) as item
    ), '[]'::jsonb)
  );
end;
$$;

create or replace function public.moderate_listing(
  p_product_id uuid,
  p_decision text,
  p_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  normalized_decision text := lower(pg_catalog.btrim(coalesce(p_decision, '')));
  normalized_reason text := nullif(pg_catalog.btrim(p_reason), '');
  product_row public.products%rowtype;
  seller_user_id uuid;
  notification_id uuid;
begin
  if auth.uid() is null or not public.is_admin() then
    raise exception 'Administrator role required' using errcode = '42501';
  end if;
  if normalized_decision not in ('approve', 'reject') then
    raise exception 'Decision must be approve or reject' using errcode = '22023';
  end if;
  if normalized_reason is not null and char_length(normalized_reason) > 2000 then
    raise exception 'Moderation reason cannot exceed 2000 characters'
      using errcode = '22023';
  end if;

  select product.* into product_row
  from public.products as product
  where product.id = p_product_id
  for update;
  if not found then
    raise exception 'Listing not found' using errcode = 'P0002';
  end if;
  if product_row.status <> 'pending_review' then
    raise exception 'Only pending listings can be moderated' using errcode = '22023';
  end if;

  select seller.user_id into seller_user_id
  from public.sellers as seller
  where seller.id = product_row.seller_id;

  update public.products
  set
    status = case normalized_decision
      when 'approve' then 'active'::public.product_status
      else 'rejected'::public.product_status
    end,
    moderation_reason = case when normalized_decision = 'reject'
      then normalized_reason else null end,
    moderated_at = now(),
    moderated_by = auth.uid()
  where id = p_product_id
  returning * into product_row;

  if seller_user_id is not null then
    notification_id := public.create_user_notification(
      seller_user_id,
      'system',
      case normalized_decision
        when 'approve' then 'notifications.listing.approved.title'
        else 'notifications.listing.rejected.title'
      end,
      case normalized_decision
        when 'approve' then 'notifications.listing.approved.body'
        else 'notifications.listing.rejected.body'
      end,
      jsonb_strip_nulls(jsonb_build_object(
        'productId', product_row.id,
        'status', product_row.status,
        'reason', product_row.moderation_reason
      ))
    );
  end if;

  return jsonb_build_object(
    'id', product_row.id,
    'status', product_row.status,
    'moderation_reason', product_row.moderation_reason,
    'moderated_at', product_row.moderated_at,
    'notification_id', notification_id
  );
end;
$$;

-- Replace the impossible >=3 folder check: storage.foldername for the documented
-- seller/product/file.webp name is exactly {seller, product}.
drop policy if exists product_images_storage_insert on storage.objects;
create policy product_images_storage_insert
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'product-images'
    and (public.can_manage_product_image_upload_path(name) or public.is_admin())
  );

drop policy if exists product_images_storage_update on storage.objects;
create policy product_images_storage_update
  on storage.objects for update to authenticated
  using (
    bucket_id = 'product-images'
    and (public.can_manage_product_image_upload_path(name) or public.is_admin())
  )
  with check (
    bucket_id = 'product-images'
    and (public.can_manage_product_image_upload_path(name) or public.is_admin())
  );

drop policy if exists product_images_storage_delete on storage.objects;
create policy product_images_storage_delete
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'product-images'
    and (public.can_manage_product_image_upload_path(name) or public.is_admin())
  );

-- Product/image row creation must use submit_listing so required uploaded photos
-- cannot be bypassed with direct PostgREST inserts.
revoke insert on table public.products from authenticated;
revoke insert on table public.product_images from authenticated;

revoke all on function public.is_marketplace_german_city(text) from public;
revoke all on function public.prepare_listing_submission(
  public.seller_kind, text, text
) from public;
revoke all on function public.can_manage_product_image_upload_path(text) from public;
revoke all on function public.submit_listing(
  uuid, uuid, uuid, text, text, public.product_condition, bigint, text, text[], jsonb
) from public;
revoke all on function public.get_moderation_dashboard(integer) from public;
revoke all on function public.moderate_listing(uuid, text, text) from public;

grant execute on function public.is_marketplace_german_city(text)
  to anon, authenticated;
grant execute on function public.prepare_listing_submission(
  public.seller_kind, text, text
) to authenticated;
grant execute on function public.can_manage_product_image_upload_path(text)
  to authenticated;
grant execute on function public.submit_listing(
  uuid, uuid, uuid, text, text, public.product_condition, bigint, text, text[], jsonb
) to authenticated;
grant execute on function public.get_moderation_dashboard(integer) to authenticated;
grant execute on function public.moderate_listing(uuid, text, text) to authenticated;

-- Approval should refresh public discovery and owner/admin status screens without
-- polling. Existing product RLS remains the visibility authority for Realtime.
do $$
begin
  if exists (
    select 1 from pg_catalog.pg_publication where pubname = 'supabase_realtime'
  ) and not exists (
    select 1 from pg_catalog.pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'products'
  ) then
    alter publication supabase_realtime add table public.products;
  end if;
end;
$$;

alter table public.products replica identity full;

notify pgrst, 'reload schema';

commit;
