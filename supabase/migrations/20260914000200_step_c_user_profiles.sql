-- Step C: public-safe user profiles, opaque avatars, and verified business location fields.
-- Extends public.profiles and the linked seller identity; no second user table or Map UI.

begin;


-- Reassert the intended final Phase3 dependency from 20260907000800. This is
-- idempotent on canonical databases and repairs effective schemas whose stale
-- local ledger left the older legal-address implementation in place.
create or replace function public.phase3_in_germany(public.sellers)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.sellers as seller
    where seller.id = $1.id
      and seller.status = 'approved'
      and seller.country_code = 'DE'
  );
$$;
revoke all on function public.phase3_in_germany(public.sellers)
  from public, anon, authenticated;
grant execute on function public.phase3_in_germany(public.sellers)
  to anon, authenticated;
alter table public.profiles
  add column if not exists username text,
  add column if not exists city text,
  add column if not exists bio text,
  add column if not exists avatar_key uuid;

update public.profiles
set avatar_key = extensions.gen_random_uuid()
where avatar_key is null;

alter table public.profiles
  alter column avatar_key set default extensions.gen_random_uuid(),
  alter column avatar_key set not null;

alter table public.profiles
  drop constraint if exists profiles_username_format,
  add constraint profiles_username_format check (
    username is null
    or (
      char_length(username) between 3 and 30
      and username = lower(username)
      and username ~ '^[a-z0-9][a-z0-9_]{2,29}$'
    )
  ),
  drop constraint if exists profiles_city_supported,
  add constraint profiles_city_supported check (
    city is null or public.is_marketplace_german_city(city)
  ),
  drop constraint if exists profiles_bio_length,
  add constraint profiles_bio_length check (
    bio is null or char_length(bio) <= 500
  );

create unique index if not exists profiles_username_lower_key
  on public.profiles (lower(username))
  where username is not null;
create unique index if not exists profiles_avatar_key_key
  on public.profiles (avatar_key);

create or replace function public.profile_username_key(value text)
returns text
language sql
immutable
parallel safe
set search_path = ''
as $$
  select pg_catalog.btrim(
    regexp_replace(
      lower(translate(coalesce(value, ''), 'ÄÖÜäöüß', 'AOUaous')),
      '[^a-z0-9]+',
      '_',
      'g'
    ),
    '_'
  );
$$;

create or replace function public.profile_username_error(
  candidate text,
  target_profile_id uuid default null
)
returns text
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  normalized text := lower(pg_catalog.btrim(coalesce(candidate, '')));
begin
  if char_length(normalized) not between 3 and 30
    or normalized !~ '^[a-z0-9][a-z0-9_]{2,29}$' then
    return 'invalid';
  end if;

  if normalized = any (array[
    'admin', 'administrator', 'api', 'app', 'auth', 'account', 'edit',
    'help', 'legal', 'map', 'moderator', 'moderation', 'null', 'official',
    'profile', 'profiles', 'root', 'security', 'seller', 'sellers', 'shop',
    'staff', 'store', 'support', 'system', 'undefined', 'www', 'zerin'
  ]::text[])
    or normalized ~ '(^|_)(admin|administrator|moderator|moderation|official|security|staff|support|system|zerin)(_|$)' then
    return 'reserved';
  end if;

  if exists (
    select 1
    from public.sellers as seller
    where seller.kind = 'business'
      and seller.status = 'approved'
      and public.is_verified_seller(seller.id)
      and normalized in (
        public.profile_username_key(seller.shop_name),
        replace(lower(seller.slug), '-', '_')
      )
  ) then
    return 'reserved';
  end if;

  if exists (
    select 1
    from auth.users as account
    join public.profiles as profile on profile.id = account.id
    where account.raw_app_meta_data ->> 'role' = 'admin'
      and account.id is distinct from target_profile_id
      and public.profile_username_key(profile.display_name) = normalized
  ) then
    return 'reserved';
  end if;

  if exists (
    select 1
    from public.profiles as profile
    where lower(profile.username) = normalized
      and profile.id is distinct from target_profile_id
  ) then
    return 'taken';
  end if;

  return null;
end;
$$;

create or replace function public.prepare_profile_identity_write()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  validation_error text;
begin
  new.display_name := pg_catalog.btrim(new.display_name);
  new.username := nullif(lower(pg_catalog.btrim(new.username)), '');
  new.city := nullif(pg_catalog.btrim(new.city), '');
  new.bio := nullif(pg_catalog.btrim(new.bio), '');

  if new.username is not null then
    validation_error := public.profile_username_error(new.username, new.id);
    if validation_error = 'taken' then
      raise exception 'Username is already taken'
        using errcode = '23505', constraint = 'profiles_username_lower_key';
    elsif validation_error = 'reserved' then
      raise exception 'Username is reserved' using errcode = '22023';
    elsif validation_error is not null then
      raise exception 'Username format is invalid' using errcode = '22023';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists prepare_profile_identity_write on public.profiles;
create trigger prepare_profile_identity_write
  before insert or update of display_name, username, city, bio
  on public.profiles
  for each row execute function public.prepare_profile_identity_write();

-- Profiles remain mixed private rows. Public callers only execute the safe RPCs below.
create or replace function public.get_my_profile()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  profile_row public.profiles%rowtype;
  seller_row public.sellers%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select profile.* into profile_row
  from public.profiles as profile
  where profile.id = auth.uid();
  if not found then
    raise exception 'Profile not found' using errcode = 'P0002';
  end if;

  select seller.* into seller_row
  from public.sellers as seller
  where seller.user_id = profile_row.id
  limit 1;

  return jsonb_build_object(
    'display_name', profile_row.display_name,
    'username', profile_row.username,
    'city', profile_row.city,
    'bio', profile_row.bio,
    'avatar_object', profile_row.avatar_path,
    'listing_count', case when seller_row.id is null then 0 else (
      select count(*)
      from public.products as product
      where product.seller_id = seller_row.id
        and product.status = 'active'
        and product.quantity > 0
    ) end,
    'seller', case when seller_row.id is null then null else jsonb_build_object(
      'id', seller_row.id,
      'kind', seller_row.kind,
      'status', seller_row.status,
      'store_name', case when seller_row.kind = 'business'
        then seller_row.shop_name else null end,
      'verified', public.is_verified_seller(seller_row.id)
    ) end
  );
end;
$$;

create or replace function public.get_public_profile(p_username text)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  profile_row public.profiles%rowtype;
  seller_row public.sellers%rowtype;
  safe_avatar text;
begin
  select profile.* into profile_row
  from public.profiles as profile
  where lower(profile.username) = lower(pg_catalog.btrim(coalesce(p_username, '')))
    and profile.username is not null;
  if not found then
    return null;
  end if;

  select seller.* into seller_row
  from public.sellers as seller
  where seller.user_id = profile_row.id
    and seller.status = 'approved'
    and seller.country_code = 'DE'
    and public.phase3_in_germany(seller)
  limit 1;

  if profile_row.avatar_path ~ (
    '^' || profile_row.avatar_key::text
    || '/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.webp$'
  ) then
    safe_avatar := profile_row.avatar_path;
  end if;

  return jsonb_build_object(
    'display_name', profile_row.display_name,
    'username', profile_row.username,
    'city', profile_row.city,
    'bio', profile_row.bio,
    'avatar_object', safe_avatar,
    'is_self', auth.uid() is not null and profile_row.id = auth.uid(),
    'listing_count', case when seller_row.id is null then 0 else (
      select count(*)
      from public.products as product
      where product.seller_id = seller_row.id
        and product.status = 'active'
        and product.quantity > 0
        and product.country_code = 'DE'
    ) end,
    'seller', case when seller_row.id is null then null else jsonb_build_object(
      'id', seller_row.id,
      'kind', seller_row.kind,
      'store_name', case when seller_row.kind = 'business'
        then seller_row.shop_name else null end,
      'verified', public.is_verified_seller(seller_row.id)
    ) end
  );
end;
$$;

-- Batch overlay used by public listing/detail/chat repositories. Only approved private
-- sellers receive person identity fields; business store identity remains distinct.
create or replace function public.get_public_profile_summaries(
  p_seller_ids uuid[]
)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'seller_id', seller.id,
    'display_name', profile.display_name,
    'username', profile.username,
    'city', profile.city,
    'avatar_object', case when profile.avatar_path ~ (
      '^' || profile.avatar_key::text
      || '/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.webp$'
    ) then profile.avatar_path else null end
  ) order by seller.id), '[]'::jsonb)
  from public.sellers as seller
  join public.profiles as profile on profile.id = seller.user_id
  where seller.id = any(coalesce(p_seller_ids, '{}'::uuid[]))
    and seller.kind = 'private'
    and seller.status = 'approved'
    and seller.country_code = 'DE'
    and public.phase3_in_germany(seller);
$$;

create or replace function public.check_profile_username(p_username text)
returns text
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  result text;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  result := public.profile_username_error(p_username, auth.uid());
  return coalesce(result, 'available');
end;
$$;

create or replace function public.update_my_profile(
  p_display_name text,
  p_username text,
  p_city text,
  p_bio text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  normalized_name text := pg_catalog.btrim(coalesce(p_display_name, ''));
  normalized_username text := lower(pg_catalog.btrim(coalesce(p_username, '')));
  normalized_city text := pg_catalog.btrim(coalesce(p_city, ''));
  normalized_bio text := nullif(pg_catalog.btrim(p_bio), '');
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if char_length(normalized_name) not between 1 and 80 then
    raise exception 'Display name must contain 1 to 80 characters'
      using errcode = '22023';
  end if;
  if normalized_username = '' then
    raise exception 'Username format is invalid' using errcode = '22023';
  end if;
  if not public.is_marketplace_german_city(normalized_city) then
    raise exception 'Choose a supported German city' using errcode = '22023';
  end if;
  if normalized_bio is not null and char_length(normalized_bio) > 500 then
    raise exception 'Bio must contain at most 500 characters'
      using errcode = '22023';
  end if;

  update public.profiles as profile
  set display_name = normalized_name,
      username = normalized_username,
      city = normalized_city,
      bio = normalized_bio
  where profile.id = auth.uid();
  if not found then
    raise exception 'Profile not found' using errcode = 'P0002';
  end if;

  return public.get_my_profile();
exception
  when unique_violation then
    raise exception 'Username is already taken'
      using errcode = '23505', constraint = 'profiles_username_lower_key';
end;
$$;

-- Opaque avatar paths are <profile.avatar_key>/<server-generated UUID>.webp.
create or replace function public.can_manage_profile_avatar_path(
  target_storage_path text
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null
    and array_length(storage.foldername(target_storage_path), 1) = 1
    and lower(target_storage_path) ~ (
      '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/'
      || '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.webp$'
    )
    and exists (
      select 1
      from public.profiles as profile
      where profile.id = auth.uid()
        and profile.avatar_key::text = (storage.foldername(target_storage_path))[1]
    );
$$;

create or replace function public.prepare_profile_avatar_upload()
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  opaque_key uuid;
  object_path text;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  select profile.avatar_key into opaque_key
  from public.profiles as profile
  where profile.id = auth.uid();
  if not found then
    raise exception 'Profile not found' using errcode = 'P0002';
  end if;
  object_path := opaque_key::text || '/' || extensions.gen_random_uuid()::text || '.webp';
  return jsonb_build_object('avatar_object', object_path);
end;
$$;

create or replace function public.commit_profile_avatar(p_avatar_object text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  previous_path text;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if not public.can_manage_profile_avatar_path(p_avatar_object)
    or not exists (
      select 1 from storage.objects as object
      where object.bucket_id = 'avatars' and object.name = p_avatar_object
    ) then
    raise exception 'Avatar upload is unavailable' using errcode = '22023';
  end if;

  select profile.avatar_path into previous_path
  from public.profiles as profile
  where profile.id = auth.uid()
  for update;
  if not found then
    raise exception 'Profile not found' using errcode = 'P0002';
  end if;

  update public.profiles as profile
  set avatar_path = p_avatar_object
  where profile.id = auth.uid();

  return jsonb_build_object(
    'avatar_object', p_avatar_object,
    'previous_avatar_object', previous_path
  );
end;
$$;

create or replace function public.clear_my_profile_avatar()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  previous_path text;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  select profile.avatar_path into previous_path
  from public.profiles as profile
  where profile.id = auth.uid()
  for update;
  if not found then
    raise exception 'Profile not found' using errcode = 'P0002';
  end if;
  update public.profiles as profile
  set avatar_path = null
  where profile.id = auth.uid();
  return jsonb_build_object('previous_avatar_object', previous_path);
end;
$$;

-- Prevent arbitrary avatar_path assignment while preserving existing privacy/settings writes.
revoke update on table public.profiles from authenticated;
grant update (
  display_name, username, city, bio, phone, language, theme,
  notification_preferences, analytics_consent
) on table public.profiles to authenticated;

-- Existing public WebP bucket, now with opaque profile-key ownership for new objects.
drop policy if exists avatars_storage_insert on storage.objects;
create policy avatars_storage_insert
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'avatars'
    and (public.can_manage_profile_avatar_path(name) or public.is_admin())
  );

drop policy if exists avatars_storage_update on storage.objects;
create policy avatars_storage_update
  on storage.objects for update to authenticated
  using (
    bucket_id = 'avatars'
    and (
      public.can_manage_profile_avatar_path(name)
      or (storage.foldername(name))[1] = auth.uid()::text
      or public.is_admin()
    )
  )
  with check (
    bucket_id = 'avatars'
    and (public.can_manage_profile_avatar_path(name) or public.is_admin())
  );

drop policy if exists avatars_storage_delete on storage.objects;
create policy avatars_storage_delete
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'avatars'
    and (
      public.can_manage_profile_avatar_path(name)
      or (storage.foldername(name))[1] = auth.uid()::text
      or public.is_admin()
    )
  );

-- Step D data only: precise fields stay null unless a currently verified business opts in.
alter table public.sellers
  add column if not exists latitude numeric(9, 6),
  add column if not exists longitude numeric(9, 6),
  add column if not exists address_line text,
  add column if not exists precise_location_opt_in boolean not null default false;

alter table public.sellers
  drop constraint if exists sellers_precise_latitude_range,
  add constraint sellers_precise_latitude_range check (
    latitude is null or latitude between -90 and 90
  ),
  drop constraint if exists sellers_precise_longitude_range,
  add constraint sellers_precise_longitude_range check (
    longitude is null or longitude between -180 and 180
  ),
  drop constraint if exists sellers_precise_coordinate_pair,
  add constraint sellers_precise_coordinate_pair check (
    (latitude is null) = (longitude is null)
  ),
  drop constraint if exists sellers_address_line_length,
  add constraint sellers_address_line_length check (
    address_line is null or char_length(address_line) between 1 and 240
  ),
  drop constraint if exists sellers_precise_location_shape,
  add constraint sellers_precise_location_shape check (
    (
      not precise_location_opt_in
      and latitude is null and longitude is null and address_line is null
    )
    or (
      precise_location_opt_in
      and kind = 'business'
      and status = 'approved'
      and latitude is not null and longitude is not null
    )
  );

create or replace function public.protect_seller_precise_location()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.address_line := nullif(pg_catalog.btrim(new.address_line), '');

  if not new.precise_location_opt_in then
    new.latitude := null;
    new.longitude := null;
    new.address_line := null;
    return new;
  end if;

  if new.kind <> 'business'
    or new.status <> 'approved'
    or new.latitude is null
    or new.longitude is null
    or not public.is_verified_seller(new.id) then
    raise exception 'Precise location requires an opted-in verified business'
      using errcode = '42501';
  end if;

  return new;
end;
$$;

drop trigger if exists protect_seller_precise_location on public.sellers;
create trigger protect_seller_precise_location
  before insert or update of kind, status, latitude, longitude,
    address_line, precise_location_opt_in
  on public.sellers
  for each row execute function public.protect_seller_precise_location();

create or replace function public.clear_unverified_seller_location()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_seller_id uuid := coalesce(new.seller_id, old.seller_id);
begin
  if not public.is_verified_seller(target_seller_id) then
    update public.sellers as seller
    set precise_location_opt_in = false,
        latitude = null,
        longitude = null,
        address_line = null
    where seller.id = target_seller_id
      and (
        seller.precise_location_opt_in
        or seller.latitude is not null
        or seller.longitude is not null
        or seller.address_line is not null
      );
  end if;
  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

drop trigger if exists clear_unverified_seller_location on public.seller_documents;
create trigger clear_unverified_seller_location
  after insert or update or delete on public.seller_documents
  for each row execute function public.clear_unverified_seller_location();

-- Chat remains the existing seller-based model. Private seller display identity now
-- comes from profiles, and only opaque avatar delivery data reaches participants.
create or replace function public.get_chat_inbox(p_chat_id uuid default null)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  with caller as materialized (
    select auth.uid() as id
  ), participant_chats as materialized (
    select chat.*
    from public.chats as chat
    where chat.buyer_id = (select id from caller)
      and (p_chat_id is null or chat.id = p_chat_id)
    union all
    select chat.*
    from public.chats as chat
    join public.sellers as seller on seller.id = chat.seller_id
    where seller.user_id = (select id from caller)
      and chat.buyer_id is distinct from (select id from caller)
      and (p_chat_id is null or chat.id = p_chat_id)
  )
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'id', chat.id,
      'buyer_id', chat.buyer_id,
      'seller_id', chat.seller_id,
      'seller_user_id', seller.user_id,
      'shop_name', case when seller.kind = 'private'
        then coalesce(seller_profile.display_name, seller.shop_name)
        else seller.shop_name end,
      'shop_slug', seller.slug,
      'shop_profile_username', case when seller.kind = 'private'
        then seller_profile.username else null end,
      'shop_avatar_url', case when seller.kind = 'private'
        and seller_profile.avatar_path ~ (
          '^' || seller_profile.avatar_key::text
          || '/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.webp$'
        ) then seller_profile.avatar_path
        else seller.avatar_url end,
      'buyer_name', buyer.display_name,
      'buyer_avatar_url', case when buyer.avatar_path ~ (
        '^' || buyer.avatar_key::text
        || '/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.webp$'
      ) then buyer.avatar_path else null end,
      'last_message_at', chat.last_message_at,
      'last_message_preview', chat.last_message_preview,
      'created_at', chat.created_at,
      'unread_count', (
        select count(*) from public.messages as unread
        where unread.chat_id = chat.id and unread.read_at is null
          and unread.kind <> 'system'
          and unread.sender_id is distinct from (select id from caller)
      ),
      'product', case when product.id is not null then jsonb_build_object(
        'id', product.id,
        'title', product.title,
        'price_cents', product.price_cents,
        'currency', product.currency,
        'image_url', image.image_url
      ) else null end
    ) order by chat.last_message_at desc nulls last, chat.created_at desc, chat.id
  ), '[]'::jsonb)
  from participant_chats as chat
  join public.sellers as seller on seller.id = chat.seller_id
  left join public.profiles as seller_profile on seller_profile.id = seller.user_id
  left join public.profiles as buyer on buyer.id = chat.buyer_id
  left join lateral (
    select message.product_id
    from public.messages as message
    where message.chat_id = chat.id and message.kind = 'product'
    order by message.created_at, message.id
    limit 1
  ) as pinned on true
  left join public.products as product on product.id = pinned.product_id
  left join lateral (
    select product_image.image_url
    from public.product_images as product_image
    where product_image.product_id = product.id
    order by product_image.sort_order, product_image.created_at, product_image.id
    limit 1
  ) as image on true;
$$;

revoke all on function public.profile_username_key(text) from public, anon, authenticated;
revoke all on function public.profile_username_error(text, uuid) from public, anon, authenticated;
revoke all on function public.prepare_profile_identity_write() from public, anon, authenticated;
revoke all on function public.get_my_profile() from public, anon, authenticated;
revoke all on function public.get_public_profile(text) from public, anon, authenticated;
revoke all on function public.get_public_profile_summaries(uuid[]) from public, anon, authenticated;
revoke all on function public.check_profile_username(text) from public, anon, authenticated;
revoke all on function public.update_my_profile(text, text, text, text) from public, anon, authenticated;
revoke all on function public.can_manage_profile_avatar_path(text) from public, anon, authenticated;
revoke all on function public.prepare_profile_avatar_upload() from public, anon, authenticated;
revoke all on function public.commit_profile_avatar(text) from public, anon, authenticated;
revoke all on function public.clear_my_profile_avatar() from public, anon, authenticated;
revoke all on function public.protect_seller_precise_location() from public, anon, authenticated;
revoke all on function public.clear_unverified_seller_location() from public, anon, authenticated;
revoke all on function public.get_chat_inbox(uuid) from public, anon, authenticated;

grant execute on function public.get_public_profile(text) to anon, authenticated;
grant execute on function public.get_public_profile_summaries(uuid[]) to anon, authenticated;
grant execute on function public.get_my_profile() to authenticated;
grant execute on function public.check_profile_username(text) to authenticated;
grant execute on function public.update_my_profile(text, text, text, text) to authenticated;
grant execute on function public.can_manage_profile_avatar_path(text) to authenticated;
grant execute on function public.prepare_profile_avatar_upload() to authenticated;
grant execute on function public.commit_profile_avatar(text) to authenticated;
grant execute on function public.clear_my_profile_avatar() to authenticated;
grant execute on function public.get_chat_inbox(uuid) to authenticated;

notify pgrst, 'reload schema';
commit;
