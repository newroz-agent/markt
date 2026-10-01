-- LOCAL DEV ONLY: opt-in Step D real-simulator evidence fixture.
-- Reuses the deterministic migration catalog; never run against a linked/remote DB.
-- psql postgresql://postgres:postgres@127.0.0.1:54322/postgres -X \
--   -v ON_ERROR_STOP=1 -v step_d_local_demo=true \
--   -f supabase/snippets/step_d_local_map_demo.sql
\if :{?step_d_local_demo}
\else
  \quit 3
\endif
\if :step_d_local_demo
\else
  \quit 3
\endif

begin;

-- Atelier Lale is a fixed unowned local demo business. Give only this fixture
-- the two approved document kinds required by is_verified_seller.
insert into public.seller_documents (
  id, seller_id, kind, storage_path, mime_type, status
) values
  (
    'd4000000-0000-4000-8000-000000000001',
    'b0000000-0000-4000-8000-000000000002',
    'identity', 'step-d-local/atelier-lale-identity.pdf',
    'application/pdf', 'approved'
  ),
  (
    'd4000000-0000-4000-8000-000000000002',
    'b0000000-0000-4000-8000-000000000002',
    'business_registration', 'step-d-local/atelier-lale-business.pdf',
    'application/pdf', 'approved'
  )
on conflict (storage_path) do update
set seller_id = excluded.seller_id,
    kind = excluded.kind,
    mime_type = excluded.mime_type,
    status = excluded.status;

-- Public demo storefront point. It is unrelated to seller_private_details and
-- exists only so the real simulator can exercise precise verified-store pins.
update public.sellers
set precise_location_opt_in = true,
    latitude = 52.516275,
    longitude = 13.377704,
    address_line = 'Unter den Linden 77, Berlin'
where id = 'b0000000-0000-4000-8000-000000000002'
  and slug = 'atelier-lale'
  and user_id is null
  and kind = 'business'
  and status = 'approved'
  and country_code = 'DE';

-- Re-run server derivation for the fixed catalog without accepting coordinates.
update public.products
set latitude = latitude
where specifications @> '{"demo":true}'::jsonb
  and country_code = 'DE';

do $$
begin
  assert public.is_verified_seller(
    'b0000000-0000-4000-8000-000000000002'
  ), 'Atelier Lale local fixture must be verified';
  assert (
    select precise_location_opt_in
      and latitude = 52.516275
      and longitude = 13.377704
      and address_line = 'Unter den Linden 77, Berlin'
    from public.sellers
    where id = 'b0000000-0000-4000-8000-000000000002'
  ), 'Atelier Lale must expose only its reviewed public demo point';
  assert not exists (
    select 1
    from public.products as product
    join public.german_cities as city on city.name = product.city
    where product.country_code = 'DE'
      and (
        product.latitude is null
        or product.longitude is null
        or public.marketplace_distance_km(
          city.latitude, city.longitude, product.latitude, product.longitude
        ) not between 0.29 and 0.51
      )
  ), 'Every German product keeps a server-derived 300–500 m safe point';
  assert exists (
    select 1 from public.listings_within_radius(52.520008, 13.404954, 30)
    where is_precise_business
      and marker_latitude = 52.516275
      and marker_longitude = 13.377704
      and public_address = 'Unter den Linden 77, Berlin'
  ), 'Map RPC must project the precise verified-store point';
  assert exists (
    select 1 from public.listings_within_radius(52.520008, 13.404954, 30)
    where seller_kind = 'private'
      and not is_precise_business
      and public_address is null
  ), 'Map RPC must retain a private address-free safe pin';
end;
$$;

commit;
