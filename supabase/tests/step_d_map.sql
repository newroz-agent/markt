-- Step D acceptance against an effective local schema. All fixtures roll back.
begin;

create function pg_temp.expect_error(command text, expected_state text)
returns void language plpgsql as $$
begin
  begin
    execute command;
  exception when others then
    assert sqlstate = expected_state,
      format('Expected SQLSTATE %s, got %s (%s)', expected_state, sqlstate, sqlerrm);
    return;
  end;
  raise exception 'Expected command to fail: %', command;
end;
$$;

do $$
begin
  assert to_regclass('public.listings') is null,
    'Step D must not create a competing listings table';
  assert not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'products'
      and column_name in ('city_lat', 'city_lng')
  ), 'Step D must reuse products.latitude/longitude';
  assert (select count(*) = 20 from public.german_cities),
    'Canonical Flutter city list is seeded exactly once';
  assert public.is_marketplace_german_city('Berlin');
  assert not public.is_marketplace_german_city('Potsdam');
  assert not exists (
    select 1 from public.products
    where country_code = 'DE' and city is not null
      and (latitude is null or longitude is null)
  ), 'Existing German listings are backfilled';
  assert not exists (
    select 1 from public.products
    where (latitude is null) <> (longitude is null)
  ), 'Partial map points are impossible';
  assert not exists (
    select 1
    from public.products as product
    join public.german_cities as city on city.name = product.city
    where product.country_code = 'DE'
      and public.marketplace_distance_km(
        city.latitude, city.longitude, product.latitude, product.longitude
      ) not between 0.29 and 0.51
  ), 'Every persisted listing point stays in the 300–500 m privacy envelope';
end;
$$;

insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
values (
  'd1000000-0000-0000-0000-000000000001',
  'step-d-owner@example.invalid',
  '{"display_name":"Step D Owner"}',
  '{}'
);

insert into public.sellers (
  id, user_id, kind, status, shop_name, slug, city, country_code
) values
  (
    'd2000000-0000-0000-0000-000000000001',
    'd1000000-0000-0000-0000-000000000001',
    'private', 'approved', 'Private Map Seller', 'step-d-private-map',
    'Berlin', 'DE'
  ),
  (
    'd2000000-0000-0000-0000-000000000002',
    null,
    'business', 'approved', 'Precise Map Store', 'step-d-precise-map',
    'Berlin', 'DE'
  );

insert into public.seller_documents (
  seller_id, kind, storage_path, mime_type, status
) values
  (
    'd2000000-0000-0000-0000-000000000002',
    'identity', 'step-d/identity.pdf', 'application/pdf', 'approved'
  ),
  (
    'd2000000-0000-0000-0000-000000000002',
    'business_registration', 'step-d/business.pdf', 'application/pdf', 'approved'
  );

update public.sellers
set precise_location_opt_in = true,
    latitude = 52.516275,
    longitude = 13.377704,
    address_line = '  Platz der Republik 1  '
where id = 'd2000000-0000-0000-0000-000000000002';

insert into public.products (
  id, seller_id, category_id, title, slug, description,
  condition, status, price_cents, city, country_code, quantity
) values
  (
    'd3000000-0000-0000-0000-000000000001',
    'd2000000-0000-0000-0000-000000000001',
    (select id from public.categories where is_active order by id limit 1),
    'Step D private one', 'step-d-private-one',
    'Private Berlin map privacy fixture one.',
    'used', 'active', 2500, 'Berlin', 'DE', 1
  ),
  (
    'd3000000-0000-0000-0000-000000000002',
    'd2000000-0000-0000-0000-000000000001',
    (select id from public.categories where is_active order by id limit 1),
    'Step D private two', 'step-d-private-two',
    'Private Berlin map privacy fixture two.',
    'new', 'active', 7500, 'Berlin', 'DE', 1
  ),
  (
    'd3000000-0000-0000-0000-000000000003',
    'd2000000-0000-0000-0000-000000000002',
    (select id from public.categories where is_active order by id limit 1),
    'Step D precise store', 'step-d-precise-store',
    'Verified store map fixture with a public point.',
    'new', 'active', 12500, 'Berlin', 'DE', 1
  ),
  (
    'd3000000-0000-0000-0000-000000000004',
    'd2000000-0000-0000-0000-000000000001',
    (select id from public.categories where is_active order by id limit 1),
    'Step D Leipzig distance', 'step-d-leipzig-distance',
    'Private Leipzig radius boundary fixture.',
    'used', 'active', 3500, 'Leipzig', 'DE', 1
  );

do $$
declare
  berlin_lat numeric;
  berlin_lng numeric;
  first_lat numeric;
  first_lng numeric;
  second_lat numeric;
  second_lng numeric;
  first_distance double precision;
begin
  select latitude, longitude into berlin_lat, berlin_lng
  from public.german_cities where name = 'Berlin';
  select latitude, longitude into first_lat, first_lng
  from public.products where id = 'd3000000-0000-0000-0000-000000000001';
  select latitude, longitude into second_lat, second_lng
  from public.products where id = 'd3000000-0000-0000-0000-000000000002';
  first_distance := public.marketplace_distance_km(
    berlin_lat, berlin_lng, first_lat, first_lng
  );
  assert first_distance between 0.29 and 0.51,
    'Private point is approximately 300–500 m from the city centroid';
  assert (first_lat, first_lng) is distinct from (berlin_lat, berlin_lng),
    'Private point is never the exact city centroid';
  assert (first_lat, first_lng) is distinct from (second_lat, second_lng),
    'Same-city private listings do not stack on one point';
end;
$$;

-- An owner cannot inject a GPS/address-derived coordinate; the trigger restores the
-- same server-owned point and leaves unrelated rows untouched.
set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"d1000000-0000-0000-0000-000000000001","role":"authenticated"}',
  true
);

do $$
declare
  before_lat numeric;
  before_lng numeric;
  after_lat numeric;
  after_lng numeric;
begin
  select latitude, longitude into before_lat, before_lng
  from public.products
  where id = 'd3000000-0000-0000-0000-000000000001';

  update public.products
  set latitude = 48.000000, longitude = 11.000000
  where id = 'd3000000-0000-0000-0000-000000000001';

  select latitude, longitude into after_lat, after_lng
  from public.products
  where id = 'd3000000-0000-0000-0000-000000000001';
  assert (after_lat, after_lng) = (before_lat, before_lng),
    'Direct coordinate injection is overwritten by server derivation';
end;
$$;

reset role;
select set_config('request.jwt.claims', '{}', true);

select pg_temp.expect_error(
  $q$select * from public.listings_within_radius(91, 13, 5)$q$,
  '22023'
);
select pg_temp.expect_error(
  $q$select * from public.listings_within_radius(52, 181, 5)$q$,
  '22023'
);
select pg_temp.expect_error(
  $q$select * from public.listings_within_radius(52, 13, 0)$q$,
  '22023'
);
select pg_temp.expect_error(
  $q$select * from public.listings_within_radius(52, 13, 501)$q$,
  '22023'
);
select pg_temp.expect_error(
  $q$select * from public.listings_within_radius(
    52, 13, 5, p_min_price_cents => 5000, p_max_price_cents => 1000
  )$q$,
  '22023'
);

do $$
declare
  private_row record;
  precise_row record;
  before_lat numeric;
  before_lng numeric;
  after_lat numeric;
  after_lng numeric;
begin
  select latitude, longitude into before_lat, before_lng
  from public.products where id = 'd3000000-0000-0000-0000-000000000001';

  select * into private_row
  from public.listings_within_radius(
    52.520008, 13.404954, 5,
    p_condition => 'used',
    p_seller_kind => 'private',
    p_max_price_cents => 3000
  )
  where product_id = 'd3000000-0000-0000-0000-000000000001';
  assert private_row.product_id is not null,
    'Radius composes with condition, seller-kind, and price filters';
  assert not private_row.is_precise_business;
  assert private_row.public_address is null,
    'Private listing never projects an exact address';
  assert (private_row.marker_latitude, private_row.marker_longitude)
    = (before_lat, before_lng),
    'Private marker is exactly the stored server-derived safe point';

  assert not exists (
    select 1 from public.listings_within_radius(52.520008, 13.404954, 100)
    where product_id = 'd3000000-0000-0000-0000-000000000004'
  ), 'Leipzig fixture is outside 100 km of Berlin';
  assert exists (
    select 1 from public.listings_within_radius(52.520008, 13.404954, 200)
    where product_id = 'd3000000-0000-0000-0000-000000000004'
  ), 'Larger server radius includes the Leipzig fixture';
  assert exists (
    select 1 from public.listings_within_radius(52.520008, 13.404954, null)
    where product_id = 'd3000000-0000-0000-0000-000000000004'
  ), 'Alle radius keeps otherwise eligible German listings';

  select * into precise_row
  from public.listings_within_radius(52.520008, 13.404954, 5)
  where product_id = 'd3000000-0000-0000-0000-000000000003';
  assert precise_row.is_precise_business;
  assert precise_row.marker_latitude = 52.516275
    and precise_row.marker_longitude = 13.377704,
    'Verified opted-in store uses its precise public point';
  assert precise_row.public_address = 'Platz der Republik 1',
    'Only a verified opted-in store projects its public address';

  -- Viewer center is query input only and never mutates the listing point.
  perform * from public.listings_within_radius(48.135125, 11.581981, 100);
  select latitude, longitude into after_lat, after_lng
  from public.products where id = 'd3000000-0000-0000-0000-000000000001';
  assert (after_lat, after_lng) = (before_lat, before_lng),
    'Viewer GPS/map center is never persisted to a listing';
end;
$$;

-- Revoking verification clears the precise store point and the map fails closed to
-- the product's safe city-jittered fallback with no directions address.
update public.seller_documents
set status = 'rejected'
where seller_id = 'd2000000-0000-0000-0000-000000000002'
  and kind = 'identity';

do $$
declare
  fallback record;
  product_lat numeric;
  product_lng numeric;
begin
  assert (
    select not precise_location_opt_in
      and latitude is null and longitude is null and address_line is null
    from public.sellers
    where id = 'd2000000-0000-0000-0000-000000000002'
  ), 'Verification revocation clears every precise store field';

  select latitude, longitude into product_lat, product_lng
  from public.products where id = 'd3000000-0000-0000-0000-000000000003';
  select * into fallback
  from public.listings_within_radius(52.520008, 13.404954, 5)
  where product_id = 'd3000000-0000-0000-0000-000000000003';
  assert not fallback.is_precise_business;
  assert fallback.public_address is null;
  assert (fallback.marker_latitude, fallback.marker_longitude)
    = (product_lat, product_lng),
    'Revoked store falls back to the safe listing point';
end;
$$;

rollback;
