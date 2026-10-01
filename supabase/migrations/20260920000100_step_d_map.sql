-- Step D: privacy-safe map discovery over the existing products/sellers model.
-- Precondition audit (2026-09-20): no public.listings or public.german_cities;
-- products.latitude/longitude exist but are empty; Step C seller precise fields exist.

begin;

-- Fail closed if the effective schema no longer matches the audited Step C shape.
do $audit$
begin
  if to_regclass('public.products') is null
    or to_regclass('public.sellers') is null
    or to_regclass('public.profiles') is null then
    raise exception 'Step D requires the existing products, sellers, and profiles tables';
  end if;
  if to_regclass('public.listings') is not null then
    raise exception 'Step D uses public.products; a competing public.listings table exists';
  end if;
  if to_regclass('public.german_cities') is not null then
    raise exception 'public.german_cities already exists; review before applying Step D';
  end if;
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'products'
      and column_name = 'latitude' and data_type = 'numeric'
  ) or not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'products'
      and column_name = 'longitude' and data_type = 'numeric'
  ) then
    raise exception 'Step D requires existing products.latitude/longitude numeric columns';
  end if;
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name in ('products', 'listings')
      and column_name in ('city_lat', 'city_lng')
  ) then
    raise exception 'Competing city_lat/city_lng columns exist; review before Step D';
  end if;
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'sellers'
      and column_name = 'latitude'
  ) or not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'sellers'
      and column_name = 'longitude'
  ) or not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'sellers'
      and column_name = 'address_line'
  ) or not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'sellers'
      and column_name = 'precise_location_opt_in'
  ) then
    raise exception 'Step D requires the Step C verified-store location fields';
  end if;
  if to_regprocedure(
    'public.marketplace_distance_km(numeric,numeric,numeric,numeric)'
  ) is null or to_regprocedure(
    'public.submit_listing(uuid,uuid,uuid,text,text,product_condition,bigint,text,text[],jsonb)'
  ) is null then
    raise exception 'Step D requires the existing distance and listing submission RPCs';
  end if;
  if exists (
    select 1 from public.products
    where (latitude is null) <> (longitude is null)
  ) then
    raise exception 'Partial product coordinate pairs must be reconciled before Step D';
  end if;
end;
$audit$;

-- This is the server-owned coordinate source for the existing canonical Flutter list.
-- Coordinates are reviewed WGS84 city-centre points; clients may read but never write it.
create table public.german_cities (
  name text primary key,
  latitude numeric(9, 6) not null check (latitude between -90 and 90),
  longitude numeric(9, 6) not null check (longitude between -180 and 180)
);

comment on table public.german_cities is
  'Canonical marketplace cities and reviewed WGS84 centroids. Seed mirrors germanMarketplaceCities; server-owned and never device-geocoded.';
comment on column public.german_cities.latitude is
  'Public city centroid used only to derive privacy-safe listing points and manual map centers.';
comment on column public.german_cities.longitude is
  'Public city centroid used only to derive privacy-safe listing points and manual map centers.';

insert into public.german_cities (name, latitude, longitude) values
  ('Berlin', 52.520008, 13.404954),
  ('Hamburg', 53.551086, 9.993682),
  ('München', 48.135125, 11.581981),
  ('Köln', 50.937531, 6.960279),
  ('Frankfurt am Main', 50.110924, 8.682127),
  ('Stuttgart', 48.775846, 9.182932),
  ('Düsseldorf', 51.227741, 6.773456),
  ('Leipzig', 51.339695, 12.373075),
  ('Dortmund', 51.513587, 7.465298),
  ('Essen', 51.455643, 7.011555),
  ('Bremen', 53.079296, 8.801694),
  ('Dresden', 51.050409, 13.737262),
  ('Hannover', 52.375892, 9.732010),
  ('Nürnberg', 49.452103, 11.076665),
  ('Bonn', 50.737430, 7.098207),
  ('Halle (Saale)', 51.496981, 11.968803),
  ('Magdeburg', 52.120533, 11.627624),
  ('Karlsruhe', 49.006890, 8.403653),
  ('Mannheim', 49.487459, 8.466039),
  ('Augsburg', 48.370544, 10.897790);

alter table public.german_cities enable row level security;
create policy german_cities_public_read
  on public.german_cities for select to anon, authenticated
  using (true);
revoke all on table public.german_cities from public, anon, authenticated;
grant select (name, latitude, longitude) on table public.german_cities
  to anon, authenticated;

-- Preserve the Step B API while replacing its duplicated hard-coded allowlist.
create or replace function public.is_marketplace_german_city(candidate text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.german_cities as city
    where city.name = pg_catalog.btrim(coalesce(candidate, ''))
  );
$$;
revoke all on function public.is_marketplace_german_city(text)
  from public, anon, authenticated;
grant execute on function public.is_marketplace_german_city(text)
  to anon, authenticated;

-- Every city-bearing marketplace row now references the one canonical source.
alter table public.products
  add constraint products_city_reference
  foreign key (city) references public.german_cities(name) not valid;
alter table public.sellers
  add constraint sellers_city_reference
  foreign key (city) references public.german_cities(name) not valid;
alter table public.profiles
  add constraint profiles_city_reference
  foreign key (city) references public.german_cities(name) not valid;
alter table public.products validate constraint products_city_reference;
alter table public.sellers validate constraint sellers_city_reference;
alter table public.profiles validate constraint profiles_city_reference;

-- Stable 300–500 m privacy jitter around a canonical city centroid. The point is
-- deterministic per product so it never moves between reads, yet same-city listings
-- do not stack and no device/legal/store address is involved.
create function public.safe_listing_city_point(
  target_product_id uuid,
  target_city text
)
returns table (safe_latitude numeric, safe_longitude numeric)
language sql
stable
security definer
set search_path = ''
as $$
  with source as (
    select
      city.latitude::double precision as latitude,
      city.longitude::double precision as longitude
    from public.german_cities as city
    where city.name = pg_catalog.btrim(coalesce(target_city, ''))
  ), entropy as (
    select
      (
        ((
          'x' || substr(md5(target_product_id::text || ':distance'), 1, 8)
        )::bit(32)::bigint % 201) + 300
      )::double precision as distance_metres,
      (
        ((
          'x' || substr(md5(target_product_id::text || ':bearing'), 1, 8)
        )::bit(32)::bigint % 360000) / 1000.0
      )::double precision as bearing_degrees
  )
  select
    round((
      source.latitude
      + (entropy.distance_metres / 1000.0 / 111.32)
        * pg_catalog.cos(pg_catalog.radians(entropy.bearing_degrees))
    )::numeric, 6) as safe_latitude,
    round((
      source.longitude
      + (entropy.distance_metres / 1000.0)
        / (111.32 * greatest(
          0.2,
          abs(pg_catalog.cos(pg_catalog.radians(source.latitude)))
        ))
        * pg_catalog.sin(pg_catalog.radians(entropy.bearing_degrees))
    )::numeric, 6) as safe_longitude
  from source
  cross join entropy
  where target_product_id is not null;
$$;
revoke all on function public.safe_listing_city_point(uuid, text)
  from public, anon, authenticated;

-- Product coordinates are server-derived map points. Any direct coordinate write is
-- overwritten from city + product ID; changing city safely re-derives the point.
create function public.derive_product_map_point()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.city := nullif(pg_catalog.btrim(new.city), '');
  if new.city is null then
    new.latitude := null;
    new.longitude := null;
    return new;
  end if;

  select point.safe_latitude, point.safe_longitude
    into new.latitude, new.longitude
  from public.safe_listing_city_point(new.id, new.city) as point;

  if new.latitude is null or new.longitude is null then
    raise exception 'Choose a supported German city' using errcode = '22023';
  end if;
  return new;
end;
$$;
revoke all on function public.derive_product_map_point()
  from public, anon, authenticated;

drop trigger if exists derive_product_map_point on public.products;
create trigger derive_product_map_point
  before insert or update of city, seller_id, latitude, longitude
  on public.products
  for each row execute function public.derive_product_map_point();

-- Trigger the same server derivation for every existing canonical German listing.
update public.products
set latitude = latitude
where city is not null and country_code = 'DE';

alter table public.products
  add constraint products_map_coordinate_pair check (
    (latitude is null) = (longitude is null)
  ),
  add constraint products_german_city_map_point check (
    country_code is distinct from 'DE'
    or city is null
    or (latitude is not null and longitude is not null)
  );

comment on column public.products.latitude is
  'Server-derived privacy-safe listing marker latitude. Never accepts device GPS or private seller address data.';
comment on column public.products.longitude is
  'Server-derived privacy-safe listing marker longitude. Never accepts device GPS or private seller address data.';

-- Public Map projection. Radius and all discovery filters execute server-side. A
-- currently verified, opted-in business uses its public precise point; every other
-- listing uses only its stable city-jittered product point.
create function public.listings_within_radius(
  center_lat numeric,
  center_lng numeric,
  radius_km numeric default 30,
  p_query text default null,
  p_category_id uuid default null,
  p_condition public.product_condition default null,
  p_seller_kind public.seller_kind default null,
  p_min_price_cents bigint default null,
  p_max_price_cents bigint default null,
  p_sort text default 'distance',
  p_limit integer default 100,
  p_offset integer default 0
)
returns table (
  product_id uuid,
  title text,
  price_cents bigint,
  currency text,
  product_condition public.product_condition,
  city text,
  seller_id uuid,
  seller_name text,
  seller_kind public.seller_kind,
  category_id uuid,
  primary_image_path text,
  primary_image_url text,
  marker_latitude numeric,
  marker_longitude numeric,
  distance_km double precision,
  is_precise_business boolean,
  public_address text,
  total_count bigint
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  normalized_query text := nullif(pg_catalog.btrim(p_query), '');
  normalized_sort text := coalesce(nullif(pg_catalog.btrim(p_sort), ''), 'distance');
  bounded_limit integer := least(greatest(coalesce(p_limit, 100), 1), 100);
  bounded_offset integer := greatest(coalesce(p_offset, 0), 0);
begin
  if center_lat is null or center_lng is null
    or center_lat < -90 or center_lat > 90
    or center_lng < -180 or center_lng > 180 then
    raise exception 'A valid map center is required' using errcode = '22023';
  end if;
  if radius_km is not null and (radius_km <= 0 or radius_km > 500) then
    raise exception 'Radius must be greater than zero and at most 500 kilometres'
      using errcode = '22023';
  end if;
  if p_min_price_cents is not null and p_min_price_cents < 0 then
    raise exception 'Minimum price cannot be negative' using errcode = '22023';
  end if;
  if p_max_price_cents is not null and p_max_price_cents < 0 then
    raise exception 'Maximum price cannot be negative' using errcode = '22023';
  end if;
  if p_min_price_cents is not null and p_max_price_cents is not null
    and p_min_price_cents > p_max_price_cents then
    raise exception 'Minimum price cannot exceed maximum price'
      using errcode = '22023';
  end if;
  if normalized_sort not in ('distance', 'newest', 'price_asc', 'price_desc') then
    raise exception 'Unsupported map sort: %', normalized_sort
      using errcode = '22023';
  end if;

  return query
  with search_input as (
    select case
      when normalized_query is null then null::pg_catalog.tsquery
      else pg_catalog.websearch_to_tsquery(
        'pg_catalog.german'::pg_catalog.regconfig,
        normalized_query
      )
    end as query
  ), public_candidates as (
    select
      product.id as product_id,
      product.title,
      product.price_cents,
      product.currency,
      product.condition as product_condition,
      product.city,
      product.published_at,
      seller.id as seller_id,
      seller.shop_name as seller_name,
      seller.kind as seller_kind,
      product.category_id,
      image.storage_path as primary_image_path,
      image.image_url as primary_image_url,
      precise.is_precise_business,
      case when precise.is_precise_business
        then seller.latitude else product.latitude end as marker_latitude,
      case when precise.is_precise_business
        then seller.longitude else product.longitude end as marker_longitude,
      case when precise.is_precise_business
        then seller.address_line else null end as public_address
    from public.products as product
    join public.sellers as seller on seller.id = product.seller_id
    join public.categories as category on category.id = product.category_id
    cross join search_input
    cross join lateral (
      select (
        seller.kind = 'business'
        and seller.status = 'approved'
        and seller.country_code = 'DE'
        and seller.precise_location_opt_in
        and seller.latitude is not null
        and seller.longitude is not null
        and public.is_verified_seller(seller.id)
      ) as is_precise_business
    ) as precise
    left join lateral (
      select product_image.storage_path, product_image.image_url
      from public.product_images as product_image
      where product_image.product_id = product.id
      order by product_image.sort_order, product_image.created_at, product_image.id
      limit 1
    ) as image on true
    where product.status = 'active'
      and product.quantity > 0
      and product.country_code = 'DE'
      and seller.status = 'approved'
      and seller.country_code = 'DE'
      and public.phase3_in_germany(seller)
      and category.is_active
      and product.latitude is not null
      and product.longitude is not null
      and (
        search_input.query is null
        or product.search_vector @@ search_input.query
      )
      and (
        p_category_id is null
        or product.category_id = p_category_id
        or category.parent_id = p_category_id
      )
      and (p_condition is null or product.condition = p_condition)
      and (p_seller_kind is null or seller.kind = p_seller_kind)
      and (p_min_price_cents is null or product.price_cents >= p_min_price_cents)
      and (p_max_price_cents is null or product.price_cents <= p_max_price_cents)
  ), measured as (
    select
      candidate.*,
      public.marketplace_distance_km(
        center_lat,
        center_lng,
        candidate.marker_latitude,
        candidate.marker_longitude
      ) as distance_km
    from public_candidates as candidate
    where candidate.marker_latitude is not null
      and candidate.marker_longitude is not null
  ), filtered as (
    select measured.*
    from measured
    where radius_km is null
      or measured.distance_km <= radius_km::double precision
  ), counted as (
    select filtered.*, count(*) over () as total_count
    from filtered
  )
  select
    counted.product_id,
    counted.title,
    counted.price_cents,
    counted.currency,
    counted.product_condition,
    counted.city,
    counted.seller_id,
    counted.seller_name,
    counted.seller_kind,
    counted.category_id,
    counted.primary_image_path,
    counted.primary_image_url,
    counted.marker_latitude,
    counted.marker_longitude,
    counted.distance_km,
    counted.is_precise_business,
    counted.public_address,
    counted.total_count
  from counted
  order by
    case when normalized_sort = 'distance' then counted.distance_km end asc nulls last,
    case when normalized_sort = 'newest' then counted.published_at end desc,
    case when normalized_sort = 'price_asc' then counted.price_cents end asc,
    case when normalized_sort = 'price_desc' then counted.price_cents end desc,
    counted.published_at desc,
    counted.product_id
  limit bounded_limit
  offset bounded_offset;
end;
$$;

revoke all on function public.listings_within_radius(
  numeric, numeric, numeric, text, uuid, public.product_condition,
  public.seller_kind, bigint, bigint, text, integer, integer
) from public, anon, authenticated;
grant execute on function public.listings_within_radius(
  numeric, numeric, numeric, text, uuid, public.product_condition,
  public.seller_kind, bigint, bigint, text, integer, integer
) to anon, authenticated;

comment on function public.listings_within_radius(
  numeric, numeric, numeric, text, uuid, public.product_condition,
  public.seller_kind, bigint, bigint, text, integer, integer
) is
  'Public Germany-only Map projection with server-side radius/filters and privacy-safe effective marker points.';

notify pgrst, 'reload schema';
commit;
