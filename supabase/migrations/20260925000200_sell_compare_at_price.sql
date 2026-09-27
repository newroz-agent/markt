-- Sell flow "Originalpreis / Streichpreis": sellers can flag a deal at submit.
-- Additive only. products.compare_at_price_cents already exists (nullable
-- bigint, reused by the Home Angebote section); no column is added here.
--
-- Audit basis (live schema 2026-09-25):
-- - submit_listing has 10 params (p_specifications already defaulted) and
--   inserts compare_at_price_cents never. Zero existing rows violate
--   NULL-or-greater (verified before the CHECK below).
-- - No edit/update RPC exists; the edit path is a direct owner UPDATE via
--   products_update_own (owns_seller OR admin), and prepare_product_write
--   does not restrict compare_at_price_cents. The CHECK constraint below
--   therefore validates BOTH the RPC path and the direct-UPDATE edit path.
-- - record_product_price_change already tracks compare_at_price_cents in
--   product_price_history, so deal submits flow into existing history.
--
-- The old 10-arg signature is dropped and replaced by the 11-arg version
-- with p_compare_at_price_cents defaulting to null, so existing positional
-- callers (Step B acceptance test) keep working unchanged.
begin;

-- 1) Table-level invariant: compare_at is NULL or strictly greater than price.
alter table public.products
  drop constraint if exists products_compare_at_price_check;
alter table public.products
  add constraint products_compare_at_price_check check (
    compare_at_price_cents is null
    or compare_at_price_cents > price_cents
  );

-- 2) Replace submit_listing with the extended signature. All existing
-- parameters keep their positions, types, defaults, and validation.
drop function if exists public.submit_listing(
  uuid, uuid, uuid, text, text, public.product_condition, bigint, text,
  text[], jsonb
);

create function public.submit_listing(
  p_product_id uuid,
  p_seller_id uuid,
  p_category_id uuid,
  p_title text,
  p_description text,
  p_condition public.product_condition,
  p_price_cents bigint,
  p_city text,
  p_image_paths text[],
  p_specifications jsonb default '{}'::jsonb,
  p_compare_at_price_cents bigint default null
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
  if p_compare_at_price_cents is not null
    and p_compare_at_price_cents <= p_price_cents then
    raise exception 'Compare-at price must be greater than the price'
      using errcode = '22023';
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
    compare_at_price_cents,
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
    p_compare_at_price_cents,
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

revoke all on function public.submit_listing(
  uuid, uuid, uuid, text, text, public.product_condition, bigint, text,
  text[], jsonb, bigint
) from public;
grant execute on function public.submit_listing(
  uuid, uuid, uuid, text, text, public.product_condition, bigint, text,
  text[], jsonb, bigint
) to authenticated;

commit;
