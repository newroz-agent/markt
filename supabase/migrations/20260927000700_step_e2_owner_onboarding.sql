-- Step E2: owner onboarding for the business directory.
-- A seller declares a directory type first, then uploads exactly the documents that
-- type needs (identity + business_registration, or identity + medical registration for
-- doctors) through the existing seller-documents bucket and admin verification queue.
begin;

-- Declared directory type of a business seller, set before any profile exists. Once a
-- profile exists, its type is the source of truth and is mirrored here.
alter table public.sellers add column directory_type public.directory_business_type;
alter table public.sellers add constraint sellers_directory_type_business
  check (directory_type is null or kind = 'business');

update public.sellers seller set directory_type = profile.type
from public.business_directory_profiles profile
where profile.seller_id = seller.id and seller.directory_type is distinct from profile.type;

create function public.sync_seller_directory_type()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  update public.sellers set directory_type = new.type
  where id = new.seller_id and directory_type is distinct from new.type;
  return null;
end;
$$;
create trigger sync_seller_directory_type
  after insert or update of type on public.business_directory_profiles
  for each row execute function public.sync_seller_directory_type();

create function public.guard_seller_directory_type()
returns trigger language plpgsql set search_path = '' as $$
begin
  if exists (
    select 1 from public.business_directory_profiles profile
    where profile.seller_id = new.id and profile.type is distinct from new.directory_type
  ) then
    raise exception 'Change the directory type in the directory profile' using errcode = '22023';
  end if;
  return new;
end;
$$;
create trigger guard_seller_directory_type
  before update of directory_type on public.sellers
  for each row when (new.directory_type is distinct from old.directory_type)
  execute function public.guard_seller_directory_type();

create function public.directory_required_document_kinds(p_type public.directory_business_type)
returns public.seller_document_kind[] language sql immutable set search_path = '' as $$
  select case
    when p_type is null then '{}'::public.seller_document_kind[]
    when p_type = 'doctor' then
      array['identity', 'medical_professional_registration']::public.seller_document_kind[]
    else array['identity', 'business_registration']::public.seller_document_kind[]
  end;
$$;

-- Directory sellers never get a listing approved, which is how marketplace sellers leave
-- `pending`. Approving the last required document of a pending directory seller approves
-- the seller. Marketplace-only sellers (no directory_type) keep their existing path.
create function public.approve_directory_seller_if_complete()
returns trigger language plpgsql security definer set search_path = '' as $$
declare seller_row public.sellers%rowtype;
begin
  select * into seller_row from public.sellers where id = new.seller_id for update;
  if not found or seller_row.kind <> 'business' or seller_row.status <> 'pending'
    or seller_row.directory_type is null then
    return null;
  end if;
  if not exists (
    select 1 from unnest(public.directory_required_document_kinds(seller_row.directory_type)) required(kind)
    where not exists (
      select 1 from public.seller_documents document
      where document.seller_id = seller_row.id and document.kind = required.kind
        and document.status = 'approved'
    )
  ) then
    update public.sellers set status = 'approved' where id = seller_row.id;
  end if;
  return null;
end;
$$;
create trigger approve_directory_seller_if_complete
  after update of status on public.seller_documents
  for each row when (new.status = 'approved' and old.status is distinct from 'approved')
  execute function public.approve_directory_seller_if_complete();

-- Harden owner inserts: a document row may only point into the owner's own folder, and
-- each kind has at most one pending document (replace = withdraw, then upload again).
create or replace function public.protect_seller_document_write()
returns trigger language plpgsql set search_path = '' as $$
begin
  if auth.uid() is null or public.is_admin() then
    return new;
  end if;

  if tg_op = 'INSERT' then
    if split_part(new.storage_path, '/', 1) is distinct from new.seller_id::text then
      raise exception 'Seller documents must be stored in the seller''s own folder'
        using errcode = '42501';
    end if;
    new.uploaded_by = auth.uid();
    new.status = 'pending';
    new.reviewed_by = null;
    new.reviewed_at = null;
    new.admin_note = null;
  elsif new.seller_id is distinct from old.seller_id
    or new.uploaded_by is distinct from old.uploaded_by
    or new.kind is distinct from old.kind
    or new.storage_path is distinct from old.storage_path
    or new.mime_type is distinct from old.mime_type
    or new.status is distinct from old.status
    or new.reviewed_by is distinct from old.reviewed_by
    or new.reviewed_at is distinct from old.reviewed_at
    or new.admin_note is distinct from old.admin_note then
    raise exception 'Seller document moderation fields are server-managed';
  end if;

  return new;
end;
$$;

create unique index seller_documents_one_pending_per_kind
  on public.seller_documents(seller_id, kind) where status = 'pending';

-- Everything the owner screens need in one call, for the signed-in user only.
create function public.get_my_directory_onboarding()
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare seller_row public.sellers%rowtype; result jsonb;
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode = '42501'; end if;
  select * into seller_row from public.sellers where user_id = auth.uid();
  if not found then
    return jsonb_build_object('seller', null, 'is_verified', false,
      'required_document_kinds', '[]'::jsonb, 'documents', '[]'::jsonb,
      'profile', null, 'hours', '[]'::jsonb, 'menu', '[]'::jsonb);
  end if;
  select jsonb_build_object(
    'seller', jsonb_build_object('id', seller_row.id, 'kind', seller_row.kind, 'status', seller_row.status,
      'shop_name', seller_row.shop_name, 'city', seller_row.city, 'directory_type', seller_row.directory_type),
    'is_verified', public.is_verified_seller(seller_row.id),
    'required_document_kinds', to_jsonb(public.directory_required_document_kinds(seller_row.directory_type)),
    'documents', (select coalesce(jsonb_agg(jsonb_build_object(
        'id', document.id, 'kind', document.kind, 'status', document.status,
        'admin_note', document.admin_note, 'mime_type', document.mime_type,
        'storage_path', document.storage_path, 'created_at', document.created_at,
        'reviewed_at', document.reviewed_at) order by document.created_at desc), '[]'::jsonb)
      from public.seller_documents document where document.seller_id = seller_row.id),
    'profile', (select jsonb_build_object('type', profile.type, 'description', profile.description,
        'phone', profile.phone, 'website', profile.website, 'cover_image_path', profile.cover_image_path,
        'languages', profile.languages, 'cuisines', profile.cuisines, 'price_level', profile.price_level,
        'has_halal', profile.has_halal, 'has_vegetarian_options', profile.has_vegetarian_options,
        'has_vegan_options', profile.has_vegan_options, 'specialty', profile.specialty,
        'insurance', profile.insurance, 'is_published', profile.is_published)
      from public.business_directory_profiles profile where profile.seller_id = seller_row.id),
    'hours', (select coalesce(jsonb_agg(jsonb_build_object('weekday', hours.weekday,
        'opens_at', to_char(hours.opens_at, 'HH24:MI'), 'closes_at', to_char(hours.closes_at, 'HH24:MI'))
        order by hours.weekday, hours.sort_order, hours.opens_at), '[]'::jsonb)
      from public.business_directory_hours hours where hours.seller_id = seller_row.id),
    'menu', (select coalesce(jsonb_agg(jsonb_build_object('id', section.id, 'name', section.name,
        'sort_order', section.sort_order,
        'items', (select coalesce(jsonb_agg(jsonb_build_object('id', item.id, 'name', item.name,
            'description', item.description, 'price_cents', item.price_cents,
            'is_available', item.is_available, 'is_halal', item.is_halal,
            'is_vegetarian', item.is_vegetarian, 'is_vegan', item.is_vegan, 'sort_order', item.sort_order)
            order by item.sort_order, item.id), '[]'::jsonb)
          from public.business_directory_menu_items item where item.section_id = section.id))
        order by section.sort_order, section.id), '[]'::jsonb)
      from public.business_directory_menu_sections section where section.seller_id = seller_row.id)
  ) into result;
  return result;
end;
$$;

-- Start (or change the type of) a directory business. Creates a pending business seller
-- for users without one; private sellers cannot join the directory.
create function public.owner_start_directory(
  p_directory_type public.directory_business_type,
  p_shop_name text default null,
  p_city text default null
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  seller_row public.sellers%rowtype;
  new_seller_id uuid;
  normalized_name text := nullif(btrim(p_shop_name), '');
  normalized_city text := nullif(btrim(p_city), '');
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode = '42501'; end if;
  if p_directory_type is null then raise exception 'Directory type required' using errcode = '22023'; end if;
  select * into seller_row from public.sellers where user_id = auth.uid() for update;
  if not found then
    if normalized_name is null or char_length(normalized_name) not between 2 and 100 then
      raise exception 'Business name must contain 2 to 100 characters' using errcode = '22023';
    end if;
    if normalized_city is null or not public.is_marketplace_german_city(normalized_city) then
      raise exception 'Choose a supported German city' using errcode = '22023';
    end if;
    new_seller_id := gen_random_uuid();
    insert into public.sellers(id, user_id, kind, status, shop_name, slug, city, country_code, directory_type)
    values (new_seller_id, auth.uid(), 'business', 'pending', normalized_name,
      'seller-' || replace(left(new_seller_id::text, 18), '-', ''), normalized_city, 'DE', p_directory_type);
  elsif seller_row.kind <> 'business' then
    raise exception 'Private seller accounts cannot join the business directory' using errcode = '42501';
  else
    update public.sellers set directory_type = p_directory_type where id = seller_row.id;
  end if;
  return public.get_my_directory_onboarding();
end;
$$;

revoke all on function public.sync_seller_directory_type() from public, anon, authenticated;
revoke all on function public.approve_directory_seller_if_complete() from public, anon, authenticated;
revoke all on function public.directory_required_document_kinds(public.directory_business_type) from public, anon;
grant execute on function public.directory_required_document_kinds(public.directory_business_type) to authenticated;
revoke all on function public.get_my_directory_onboarding() from public, anon;
grant execute on function public.get_my_directory_onboarding() to authenticated;
revoke all on function public.owner_start_directory(public.directory_business_type, text, text) from public, anon;
grant execute on function public.owner_start_directory(public.directory_business_type, text, text) to authenticated;

notify pgrst, 'reload schema';
commit;
