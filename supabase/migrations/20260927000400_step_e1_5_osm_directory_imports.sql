-- Step E1.5: unclaimed OpenStreetMap places, admin-only outreach, suppression list,
-- idempotent import contract, and public search/detail that expose source + claim state.
-- Owner-side E1 contracts are unchanged except that fast_food behaves like restaurant/cafe.
begin;

-- fast_food parity with restaurant/cafe for owner profiles, menus and reviews.
alter table public.business_directory_profiles drop constraint directory_type_fields;
alter table public.business_directory_profiles add constraint directory_type_fields check (
  (
    type in ('restaurant', 'cafe', 'fast_food')
    and specialty is null and insurance is null
    and cardinality(cuisines) >= 1 and price_level is not null
  ) or (
    type = 'doctor'
    and specialty is not null and insurance is not null
    and cardinality(cuisines) = 0 and price_level is null
    and not has_halal and not has_vegetarian_options and not has_vegan_options
  )
);

create or replace function public.validate_directory_menu_write()
returns trigger language plpgsql set search_path = '' as $$
begin
  if not exists (
    select 1 from public.business_directory_profiles profile
    where profile.seller_id = new.seller_id and profile.type in ('restaurant', 'cafe', 'fast_food')
  ) then
    raise exception 'Menus are only available to restaurants, cafes and fast food' using errcode = '23514';
  end if;
  return new;
end;
$$;

create or replace function public.owner_replace_directory_menu(p_sections jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare target_seller uuid; section jsonb; item jsonb; section_id uuid; result jsonb;
begin
  select profile.seller_id into target_seller from public.business_directory_profiles profile
    join public.sellers seller on seller.id=profile.seller_id
    where seller.user_id=auth.uid() and profile.type in ('restaurant','cafe','fast_food');
  if target_seller is null then raise exception 'Restaurant, cafe or fast food profile required' using errcode='23514'; end if;
  if jsonb_typeof(coalesce(p_sections,'[]')) <> 'array' or jsonb_array_length(coalesce(p_sections,'[]')) > 50 then
    raise exception 'Menu must be an array of at most 50 sections' using errcode='22023'; end if;
  delete from public.business_directory_menu_sections where seller_id=target_seller;
  for section in select value from jsonb_array_elements(coalesce(p_sections,'[]')) loop
    insert into public.business_directory_menu_sections(seller_id,name,sort_order)
      values(target_seller,btrim(section->>'name'),coalesce((section->>'sort_order')::integer,0)) returning id into section_id;
    if jsonb_typeof(coalesce(section->'items','[]')) <> 'array' or jsonb_array_length(coalesce(section->'items','[]')) > 200 then
      raise exception 'Menu section items must be an array of at most 200 items' using errcode='22023'; end if;
    for item in select value from jsonb_array_elements(coalesce(section->'items','[]')) loop
      insert into public.business_directory_menu_items(
        section_id,seller_id,name,description,price_cents,is_available,is_halal,is_vegetarian,is_vegan,sort_order
      ) values(section_id,target_seller,btrim(item->>'name'),nullif(btrim(item->>'description'),''),(item->>'price_cents')::bigint,
        coalesce((item->>'is_available')::boolean,true),coalesce((item->>'is_halal')::boolean,false),
        coalesce((item->>'is_vegetarian')::boolean,false),coalesce((item->>'is_vegan')::boolean,false),
        coalesce((item->>'sort_order')::integer,0));
    end loop;
  end loop;
  select coalesce(jsonb_agg(jsonb_build_object('id',s.id,'name',s.name,'sort_order',s.sort_order,
    'items',(select coalesce(jsonb_agg(to_jsonb(i) order by i.sort_order,i.id),'[]') from public.business_directory_menu_items i where i.section_id=s.id)) order by s.sort_order,s.id),'[]')
    into result from public.business_directory_menu_sections s where s.seller_id=target_seller;
  return result;
end; $$;

create or replace function public.validate_directory_review_write()
returns trigger language plpgsql set search_path = '' as $$
begin
  if new.context = 'directory' then
    -- Imported OSM places have no seller row, so they can never satisfy this check.
    if not exists (
      select 1 from public.business_directory_profiles profile
      where profile.seller_id = new.seller_id and profile.type in ('restaurant', 'cafe', 'fast_food')
        and profile.is_published and public.is_verified_seller(profile.seller_id)
    ) then raise exception 'Directory reviews are only available for verified food businesses' using errcode='23514'; end if;
    if exists (
      select 1 from public.sellers seller
      where seller.id = new.seller_id and seller.user_id = new.reviewer_id
    ) then raise exception 'Owners cannot review their own business' using errcode='23514'; end if;
  end if;
  return new;
end;
$$;

drop policy reviews_select_visible on public.reviews;
create policy reviews_select_visible on public.reviews for select to anon, authenticated using (
  reviewer_id = auth.uid() or public.is_admin() or (
    status='published' and (
      context='purchase' or exists (
        select 1 from public.business_directory_profiles profile
        where profile.seller_id=reviews.seller_id and profile.is_published
          and profile.type in ('restaurant','cafe','fast_food') and public.is_verified_seller(profile.seller_id)
      )
    )
  )
);

-- Imported places. Public access only through the search/detail RPCs below.
create type public.directory_outreach_status as enum (
  'not_contacted', 'contacted', 'claimed', 'declined', 'removal_requested'
);

create table public.directory_imported_places (
  id uuid primary key default gen_random_uuid(),
  source text not null default 'osm' check (source = 'osm'),
  osm_type text not null check (osm_type in ('node', 'way', 'relation')),
  osm_id bigint not null check (osm_id > 0),
  name text not null check (char_length(btrim(name)) between 1 and 200),
  type public.directory_business_type not null check (type in ('restaurant', 'cafe', 'fast_food')),
  cuisines public.directory_cuisine[] not null check (cardinality(cuisines) between 1 and 16),
  osm_cuisine text not null check (char_length(osm_cuisine) between 1 and 255),
  latitude numeric not null check (latitude between -90 and 90),
  longitude numeric not null check (longitude between -180 and 180),
  addr_street text check (addr_street is null or char_length(addr_street) between 1 and 200),
  addr_housenumber text check (addr_housenumber is null or char_length(addr_housenumber) between 1 and 40),
  addr_postcode text check (addr_postcode is null or char_length(addr_postcode) between 1 and 20),
  addr_city text check (addr_city is null or char_length(addr_city) between 1 and 100),
  phone text check (phone is null or char_length(phone) between 3 and 60),
  website text check (website is null or (char_length(website) <= 500 and website ~ '^https?://[^[:space:]]+$')),
  has_halal boolean,
  has_vegetarian boolean,
  has_vegan boolean,
  source_snapshot date not null,
  claimed_seller_id uuid unique references public.sellers(id) on delete set null,
  claimed_at timestamptz,
  is_hidden boolean not null default false,
  imported_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (osm_type, osm_id),
  -- claimed_at may outlive the link: deleting the claiming seller sets the id to null
  -- (the place becomes unclaimed again) and must not be blocked by this check.
  constraint directory_imported_places_claim_shape
    check (claimed_seller_id is null or claimed_at is not null)
);

create index directory_imported_places_public_idx
  on public.directory_imported_places(type, name) where claimed_seller_id is null and not is_hidden;

create table public.directory_imported_place_hours (
  id uuid primary key default gen_random_uuid(),
  place_id uuid not null references public.directory_imported_places(id) on delete cascade,
  weekday smallint not null check (weekday between 0 and 6),
  opens_at time not null,
  closes_at time not null,
  unique (place_id, weekday, opens_at, closes_at),
  check (opens_at <> closes_at)
);

create index directory_imported_place_hours_lookup_idx
  on public.directory_imported_place_hours(place_id, weekday, opens_at);

-- Internal outreach data: admin RPCs only, never any public projection.
create table public.directory_outreach_contacts (
  id uuid primary key default gen_random_uuid(),
  place_id uuid not null unique references public.directory_imported_places(id) on delete cascade,
  email text check (
    email is null or (char_length(email) <= 254 and email ~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$')
  ),
  source text not null default 'osm' check (source = 'osm'),
  collected_at timestamptz not null default now(),
  status public.directory_outreach_status not null default 'not_contacted',
  contacted_at timestamptz,
  admin_notes text check (admin_notes is null or char_length(admin_notes) <= 2000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.directory_import_suppressions (
  osm_type text not null check (osm_type in ('node', 'way', 'relation')),
  osm_id bigint not null check (osm_id > 0),
  reason public.directory_outreach_status not null check (reason in ('declined', 'removal_requested')),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  primary key (osm_type, osm_id)
);

create trigger set_updated_at before update on public.directory_imported_places
  for each row execute function public.set_updated_at();
create trigger set_updated_at before update on public.directory_outreach_contacts
  for each row execute function public.set_updated_at();

alter table public.directory_imported_places enable row level security;
alter table public.directory_imported_place_hours enable row level security;
alter table public.directory_outreach_contacts enable row level security;
alter table public.directory_import_suppressions enable row level security;
revoke all on public.directory_imported_places, public.directory_imported_place_hours,
  public.directory_outreach_contacts, public.directory_import_suppressions from public, anon, authenticated;

create function public.directory_imported_place_is_open(
  target_place_id uuid,
  at_time timestamptz default now()
) returns boolean language sql stable security definer set search_path = '' as $$
  with local_clock as (
    select at_time at time zone 'Europe/Berlin' as value
  ), parts as (
    select value::time as local_time, (extract(isodow from value)::integer % 7) as weekday
    from local_clock
  )
  select exists (
    select 1
    from public.directory_imported_place_hours hours cross join parts
    where hours.place_id = target_place_id and (
      (hours.opens_at < hours.closes_at and hours.weekday = parts.weekday
        and parts.local_time >= hours.opens_at and parts.local_time < hours.closes_at)
      or (hours.opens_at > hours.closes_at and hours.weekday = parts.weekday
        and parts.local_time >= hours.opens_at)
      or (hours.opens_at > hours.closes_at and hours.weekday = ((parts.weekday + 6) % 7)
        and parts.local_time < hours.closes_at)
    )
  );
$$;

create function public.directory_imported_place_address(place public.directory_imported_places)
returns text language sql immutable set search_path = '' as $$
  select nullif(concat_ws(', ',
    nullif(concat_ws(' ', place.addr_street, place.addr_housenumber), ''),
    nullif(concat_ws(' ', place.addr_postcode, place.addr_city), '')
  ), '');
$$;

-- Import contract. Called only by the local import tool (postgres/service_role).
-- Suppressed ids are skipped, claimed rows are never touched, nothing is deleted.
create function public.import_osm_directory_places(p_places jsonb, p_snapshot_date date)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  place record;
  existing public.directory_imported_places%rowtype;
  new_place_id uuid;
  new_hours jsonb;
  old_hours jsonb;
  inserted integer := 0;
  updated integer := 0;
  unchanged integer := 0;
  skipped_claimed integer := 0;
  skipped_suppressed integer := 0;
  emails_updated integer := 0;
  vanished jsonb;
begin
  if jsonb_typeof(p_places) is distinct from 'array' then
    raise exception 'Places must be a JSON array' using errcode = '22023';
  end if;
  if p_snapshot_date is null then
    raise exception 'Snapshot date required' using errcode = '22023';
  end if;
  perform pg_advisory_xact_lock(hashtext('import_osm_directory_places'));

  for place in
    select * from jsonb_to_recordset(p_places) as x(
      osm_type text, osm_id bigint, name text, type public.directory_business_type,
      cuisines public.directory_cuisine[], osm_cuisine text, latitude numeric, longitude numeric,
      addr_street text, addr_housenumber text, addr_postcode text, addr_city text,
      phone text, website text, email text,
      has_halal boolean, has_vegetarian boolean, has_vegan boolean, hours jsonb
    )
  loop
    if exists (
      select 1 from public.directory_import_suppressions suppression
      where suppression.osm_type = place.osm_type and suppression.osm_id = place.osm_id
    ) then
      skipped_suppressed := skipped_suppressed + 1;
      continue;
    end if;

    select coalesce(jsonb_agg(jsonb_build_object(
      'weekday', (slot->>'weekday')::smallint,
      'opens_at', (slot->>'opens_at')::time,
      'closes_at', (slot->>'closes_at')::time
    ) order by (slot->>'weekday')::smallint, (slot->>'opens_at')::time, (slot->>'closes_at')::time), '[]')
    into new_hours from jsonb_array_elements(coalesce(place.hours, '[]')) slot;

    select * into existing from public.directory_imported_places imported
    where imported.osm_type = place.osm_type and imported.osm_id = place.osm_id
    for update;

    if not found then
      insert into public.directory_imported_places(
        osm_type, osm_id, name, type, cuisines, osm_cuisine, latitude, longitude,
        addr_street, addr_housenumber, addr_postcode, addr_city, phone, website,
        has_halal, has_vegetarian, has_vegan, source_snapshot
      ) values (
        place.osm_type, place.osm_id, place.name, place.type, place.cuisines, place.osm_cuisine,
        place.latitude, place.longitude, place.addr_street, place.addr_housenumber,
        place.addr_postcode, place.addr_city, place.phone, place.website,
        place.has_halal, place.has_vegetarian, place.has_vegan, p_snapshot_date
      ) returning id into new_place_id;
      insert into public.directory_imported_place_hours(place_id, weekday, opens_at, closes_at)
      select new_place_id, (slot->>'weekday')::smallint, (slot->>'opens_at')::time, (slot->>'closes_at')::time
      from jsonb_array_elements(new_hours) slot;
      insert into public.directory_outreach_contacts(place_id, email) values (new_place_id, place.email);
      inserted := inserted + 1;
      continue;
    end if;

    if existing.claimed_seller_id is not null then
      skipped_claimed := skipped_claimed + 1;
      continue;
    end if;

    select coalesce(jsonb_agg(jsonb_build_object(
      'weekday', hours.weekday, 'opens_at', hours.opens_at, 'closes_at', hours.closes_at
    ) order by hours.weekday, hours.opens_at, hours.closes_at), '[]')
    into old_hours from public.directory_imported_place_hours hours where hours.place_id = existing.id;

    if (
      existing.name, existing.type, existing.cuisines, existing.osm_cuisine,
      existing.latitude, existing.longitude, existing.addr_street, existing.addr_housenumber,
      existing.addr_postcode, existing.addr_city, existing.phone, existing.website,
      existing.has_halal, existing.has_vegetarian, existing.has_vegan
    ) is distinct from (
      place.name, place.type, place.cuisines, place.osm_cuisine,
      place.latitude, place.longitude, place.addr_street, place.addr_housenumber,
      place.addr_postcode, place.addr_city, place.phone, place.website,
      place.has_halal, place.has_vegetarian, place.has_vegan
    ) or old_hours <> new_hours then
      update public.directory_imported_places set
        name = place.name, type = place.type, cuisines = place.cuisines, osm_cuisine = place.osm_cuisine,
        latitude = place.latitude, longitude = place.longitude, addr_street = place.addr_street,
        addr_housenumber = place.addr_housenumber, addr_postcode = place.addr_postcode,
        addr_city = place.addr_city, phone = place.phone, website = place.website,
        has_halal = place.has_halal, has_vegetarian = place.has_vegetarian, has_vegan = place.has_vegan,
        source_snapshot = p_snapshot_date
      where id = existing.id;
      if old_hours <> new_hours then
        delete from public.directory_imported_place_hours where directory_imported_place_hours.place_id = existing.id;
        insert into public.directory_imported_place_hours(place_id, weekday, opens_at, closes_at)
        select existing.id, (slot->>'weekday')::smallint, (slot->>'opens_at')::time, (slot->>'closes_at')::time
        from jsonb_array_elements(new_hours) slot;
      end if;
      updated := updated + 1;
    else
      unchanged := unchanged + 1;
    end if;

    -- Only refresh the OSM email while nobody has acted on the contact yet.
    update public.directory_outreach_contacts contact
      set email = place.email, collected_at = now()
    where contact.place_id = existing.id and contact.status = 'not_contacted'
      and contact.email is distinct from place.email;
    if found then emails_updated := emails_updated + 1; end if;
  end loop;

  select coalesce(jsonb_agg(jsonb_build_object(
    'osm_type', imported.osm_type, 'osm_id', imported.osm_id, 'name', imported.name
  ) order by imported.osm_type, imported.osm_id), '[]')
  into vanished
  from public.directory_imported_places imported
  where imported.claimed_seller_id is null and not imported.is_hidden
    and not exists (
      select 1 from jsonb_to_recordset(p_places) as x(osm_type text, osm_id bigint)
      where x.osm_type = imported.osm_type and x.osm_id = imported.osm_id
    );

  return jsonb_build_object(
    'received', jsonb_array_length(p_places), 'inserted', inserted, 'updated', updated,
    'unchanged', unchanged, 'skipped_claimed', skipped_claimed,
    'skipped_suppressed', skipped_suppressed, 'emails_updated', emails_updated,
    'vanished', vanished
  );
end;
$$;

-- Admin outreach workflow. Declined/removal hides the place and suppresses re-imports.
create function public.admin_set_directory_outreach_status(
  p_place_id uuid,
  p_status public.directory_outreach_status,
  p_admin_notes text default null,
  p_claimed_seller_id uuid default null
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  target public.directory_imported_places%rowtype;
  contact public.directory_outreach_contacts%rowtype;
begin
  if not public.is_admin() then
    raise exception 'Admin role required' using errcode = '42501';
  end if;
  select * into target from public.directory_imported_places where id = p_place_id for update;
  if not found then raise exception 'Imported place not found' using errcode = 'P0002'; end if;
  select * into contact from public.directory_outreach_contacts where place_id = p_place_id for update;
  if contact.status in ('declined', 'removal_requested') then
    raise exception 'Suppressed places cannot change outreach status' using errcode = '22023';
  end if;
  if p_status = 'claimed' then
    if p_claimed_seller_id is null or not exists (
      select 1 from public.sellers seller where seller.id = p_claimed_seller_id and seller.kind = 'business'
    ) then
      raise exception 'Claiming requires a business seller' using errcode = '22023';
    end if;
    update public.directory_imported_places
      set claimed_seller_id = p_claimed_seller_id, claimed_at = now()
    where id = p_place_id;
  elsif p_claimed_seller_id is not null then
    raise exception 'A seller can only be linked when claiming' using errcode = '22023';
  elsif target.claimed_seller_id is not null then
    raise exception 'Claimed places cannot change outreach status' using errcode = '22023';
  end if;
  if p_status in ('declined', 'removal_requested') then
    update public.directory_imported_places set is_hidden = true where id = p_place_id;
    insert into public.directory_import_suppressions(osm_type, osm_id, reason, created_by)
    values (target.osm_type, target.osm_id, p_status, auth.uid())
    on conflict (osm_type, osm_id) do update set reason = excluded.reason;
  end if;
  update public.directory_outreach_contacts set
    status = p_status,
    contacted_at = case when p_status = 'contacted' then now() else contacted_at end,
    admin_notes = coalesce(nullif(btrim(p_admin_notes), ''), admin_notes)
  where place_id = p_place_id
  returning * into contact;
  return jsonb_build_object(
    'place_id', p_place_id, 'status', contact.status, 'contacted_at', contact.contacted_at,
    'is_hidden', p_status in ('declined', 'removal_requested')
  );
end;
$$;

create function public.directory_csv_field(value text)
returns text language sql immutable set search_path = '' as $$
  -- Quote every field and neutralise spreadsheet formula prefixes.
  select '"' || replace(
    case when coalesce(value, '') ~ '^(=|@|[+-][^0-9 ])' then '''' || value else coalesce(value, '') end,
    '"', '""'
  ) || '"';
$$;

create function public.admin_export_directory_outreach_csv(
  p_status public.directory_outreach_status default null
) returns text language plpgsql stable security definer set search_path = '' as $$
declare result text;
begin
  if not public.is_admin() then
    raise exception 'Admin role required' using errcode = '42501';
  end if;
  select 'name,cuisine,address,email,website,phone,status' || E'\n' || coalesce(string_agg(
    concat_ws(',',
      public.directory_csv_field(place.name),
      public.directory_csv_field(array_to_string(place.cuisines::text[], ';')),
      public.directory_csv_field(public.directory_imported_place_address(place)),
      public.directory_csv_field(contact.email),
      public.directory_csv_field(place.website),
      public.directory_csv_field(place.phone),
      public.directory_csv_field(contact.status::text)
    ), E'\n' order by place.name, place.id
  ), '') into result
  from public.directory_imported_places place
  join public.directory_outreach_contacts contact on contact.place_id = place.id
  where p_status is null or contact.status = p_status;
  return result;
end;
$$;

-- Public search: verified owner profiles plus unclaimed, visible OSM places.
create or replace function public.search_business_directory(
  p_type public.directory_business_type default null, p_center_lat numeric default null,
  p_center_lng numeric default null, p_radius_km numeric default null,
  p_cuisine public.directory_cuisine default null, p_price_level smallint default null,
  p_min_rating numeric default null, p_open_now boolean default null,
  p_language public.directory_spoken_language default null,
  p_limit integer default 20, p_offset integer default 0
) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare result jsonb; bounded_limit integer:=least(greatest(coalesce(p_limit,20),1),100); bounded_offset integer:=greatest(coalesce(p_offset,0),0);
begin
  if (p_center_lat is null) <> (p_center_lng is null) or (p_radius_km is not null and p_center_lat is null)
    or p_center_lat not between -90 and 90 or p_center_lng not between -180 and 180
    or (p_radius_km is not null and p_radius_km not between 0.1 and 500)
    then raise exception 'Valid center and radius required' using errcode='22023'; end if;
  if p_type='doctor' and p_min_rating is not null then raise exception 'Doctors cannot be filtered by rating' using errcode='22023'; end if;
  if p_min_rating is not null and p_min_rating not between 1 and 5 then raise exception 'Minimum rating must be 1-5' using errcode='22023'; end if;
  with owner_candidates as (
    select profile.seller_id,null::uuid place_id,'owner'::text source,true is_claimed,
      seller.shop_name,seller.city,profile.type,profile.description,profile.phone,profile.website,
      profile.cover_image_path,profile.languages,profile.cuisines,profile.price_level,profile.has_halal,
      profile.has_vegetarian_options,profile.has_vegan_options,profile.specialty,profile.insurance,
      case when profile.type='doctor' then null else seller.rating_average end rating_average,
      case when profile.type='doctor' then null else seller.rating_count end rating_count,
      profile.type <> 'doctor' reviews_enabled,
      public.directory_is_open(profile.seller_id,now()) is_open_now,
      exists(select 1 from public.business_directory_hours h where h.seller_id=profile.seller_id) has_hours,
      case when p_center_lat is null or not seller.precise_location_opt_in then null
        else public.marketplace_distance_km(p_center_lat,p_center_lng,seller.latitude,seller.longitude) end distance_km,
      case when seller.precise_location_opt_in then seller.latitude end latitude,
      case when seller.precise_location_opt_in then seller.longitude end longitude,
      case when seller.precise_location_opt_in then seller.address_line end address
    from public.business_directory_profiles profile join public.sellers seller on seller.id=profile.seller_id
    where profile.is_published and public.is_verified_seller(profile.seller_id)
      and (p_type is null or profile.type=p_type) and (p_cuisine is null or p_cuisine=any(profile.cuisines))
      and (p_price_level is null or profile.price_level=p_price_level)
      and (p_min_rating is null or (profile.type <> 'doctor' and seller.rating_average >= p_min_rating))
      and (p_open_now is null or public.directory_is_open(profile.seller_id,now())=p_open_now)
      and (p_language is null or p_language=any(profile.languages))
  ), imported_candidates as (
    -- OSM carries no rating, price level or spoken languages, so those filters exclude imports.
    select null::uuid seller_id,place.id place_id,place.source,false is_claimed,
      place.name shop_name,place.addr_city city,place.type,null::text description,place.phone,place.website,
      null::text cover_image_path,'{}'::public.directory_spoken_language[] languages,place.cuisines,
      null::smallint price_level,place.has_halal,place.has_vegetarian has_vegetarian_options,
      place.has_vegan has_vegan_options,null::public.directory_doctor_specialty specialty,
      null::public.directory_insurance insurance,null::numeric rating_average,null::integer rating_count,
      false reviews_enabled,
      public.directory_imported_place_is_open(place.id,now()) is_open_now,
      exists(select 1 from public.directory_imported_place_hours h where h.place_id=place.id) has_hours,
      case when p_center_lat is null then null
        else public.marketplace_distance_km(p_center_lat,p_center_lng,place.latitude,place.longitude) end distance_km,
      place.latitude,place.longitude,public.directory_imported_place_address(place) address
    from public.directory_imported_places place
    where place.claimed_seller_id is null and not place.is_hidden
      and (p_type is null or place.type=p_type) and (p_cuisine is null or p_cuisine=any(place.cuisines))
      and p_price_level is null and p_min_rating is null and p_language is null
      and (p_open_now is null or public.directory_imported_place_is_open(place.id,now())=p_open_now)
  ), candidates as (
    select * from owner_candidates union all select * from imported_candidates
  ), filtered as (select * from candidates where p_radius_km is null or distance_km <= p_radius_km),
  paged as (select *,count(*) over() total_count from filtered
    order by distance_km nulls last,shop_name,coalesce(seller_id,place_id) limit bounded_limit offset bounded_offset)
  select jsonb_build_object('items',coalesce(jsonb_agg(to_jsonb(paged)),'[]'),'total_count',coalesce(max(total_count),0)) into result from paged;
  return result;
end; $$;

create or replace function public.get_business_directory_detail(p_seller_id uuid)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare result jsonb;
begin
  select jsonb_build_object(
    'seller_id',profile.seller_id,'place_id',null,'source','owner','is_claimed',true,
    'reviews_enabled',profile.type <> 'doctor',
    'name',seller.shop_name,'city',seller.city,'type',profile.type,
    'description',profile.description,'phone',profile.phone,'website',profile.website,'cover_image_path',profile.cover_image_path,
    'languages',profile.languages,'cuisines',profile.cuisines,'price_level',profile.price_level,
    'has_halal',profile.has_halal,'has_vegetarian_options',profile.has_vegetarian_options,'has_vegan_options',profile.has_vegan_options,
    'specialty',profile.specialty,'insurance',profile.insurance,'open_now',public.directory_is_open(profile.seller_id,now()),
    'rating_average',case when profile.type='doctor' then null else seller.rating_average end,
    'rating_count',case when profile.type='doctor' then null else seller.rating_count end,
    'latitude',case when seller.precise_location_opt_in then seller.latitude end,
    'longitude',case when seller.precise_location_opt_in then seller.longitude end,
    'address',case when seller.precise_location_opt_in then seller.address_line end,
    'hours',(select coalesce(jsonb_agg(to_jsonb(h) order by h.weekday,h.sort_order,h.opens_at),'[]') from public.business_directory_hours h where h.seller_id=profile.seller_id),
    'menu',case when profile.type='doctor' then '[]'::jsonb else (select coalesce(jsonb_agg(jsonb_build_object('id',s.id,'name',s.name,'sort_order',s.sort_order,
      'items',(select coalesce(jsonb_agg(to_jsonb(i) order by i.sort_order,i.id),'[]') from public.business_directory_menu_items i where i.section_id=s.id)) order by s.sort_order,s.id),'[]') from public.business_directory_menu_sections s where s.seller_id=profile.seller_id) end
  ) into result
  from public.business_directory_profiles profile join public.sellers seller on seller.id=profile.seller_id
  where profile.seller_id=p_seller_id and profile.is_published and public.is_verified_seller(profile.seller_id);
  return result;
end; $$;

-- Public detail for an unclaimed OSM place. Never includes outreach data.
create function public.get_directory_imported_place_detail(p_place_id uuid)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare result jsonb;
begin
  select jsonb_build_object(
    'seller_id',null,'place_id',place.id,'source',place.source,'is_claimed',false,'reviews_enabled',false,
    'name',place.name,'city',place.addr_city,'type',place.type,'description',null,
    'phone',place.phone,'website',place.website,'cover_image_path',null,
    'languages','[]'::jsonb,'cuisines',place.cuisines,'price_level',null,
    'has_halal',place.has_halal,'has_vegetarian_options',place.has_vegetarian,'has_vegan_options',place.has_vegan,
    'specialty',null,'insurance',null,'open_now',public.directory_imported_place_is_open(place.id,now()),
    'rating_average',null,'rating_count',null,
    'latitude',place.latitude,'longitude',place.longitude,
    'address',public.directory_imported_place_address(place),
    'hours',(select coalesce(jsonb_agg(jsonb_build_object('weekday',h.weekday,'opens_at',h.opens_at,'closes_at',h.closes_at)
      order by h.weekday,h.opens_at),'[]') from public.directory_imported_place_hours h where h.place_id=place.id),
    'menu','[]'::jsonb
  ) into result
  from public.directory_imported_places place
  where place.id=p_place_id and place.claimed_seller_id is null and not place.is_hidden;
  return result;
end; $$;

revoke all on function public.directory_imported_place_is_open(uuid,timestamptz) from public,anon,authenticated;
revoke all on function public.directory_imported_place_address(public.directory_imported_places) from public,anon,authenticated;
revoke all on function public.import_osm_directory_places(jsonb,date) from public,anon,authenticated;
grant execute on function public.import_osm_directory_places(jsonb,date) to service_role;
revoke all on function public.admin_set_directory_outreach_status(uuid,public.directory_outreach_status,text,uuid) from public,anon;
grant execute on function public.admin_set_directory_outreach_status(uuid,public.directory_outreach_status,text,uuid) to authenticated;
revoke all on function public.directory_csv_field(text) from public,anon,authenticated;
revoke all on function public.admin_export_directory_outreach_csv(public.directory_outreach_status) from public,anon;
grant execute on function public.admin_export_directory_outreach_csv(public.directory_outreach_status) to authenticated;
revoke all on function public.get_directory_imported_place_detail(uuid) from public;
grant execute on function public.get_directory_imported_place_detail(uuid) to anon,authenticated;

notify pgrst,'reload schema';
commit;
