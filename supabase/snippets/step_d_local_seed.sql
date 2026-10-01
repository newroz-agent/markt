-- Step D local-only seed: deterministically recreates the data that the live
-- harnesses (step_b_live_test.dart, step_c_live_test.dart, step_d_live_test.dart)
-- depend on, so test data is never bound to a single database's memory.
--
-- Idempotent: re-running leaves the rows in their intended state. Intended for local
-- Supabase only (psql against 127.0.0.1:54322). Never push to a linked/remote DB.
--
-- Usage:
--   psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -X -v ON_ERROR_STOP=1 \
--     -f supabase/snippets/step_d_local_seed.sql
--
-- Passwords are local-only constants so harnesses can authenticate deterministically.
-- They are intentionally weak and out-of-scope for any real environment.

\echo 'STEP D LOCAL SEED: creating auth users, admin role, private seller, Step D demo data'

begin;

-- 1) Auth identities used by the live harnesses.
-- step-b-ios-owner / step-b-ios-admin are keyed by email so re-seed is idempotent.
insert into auth.users (id, email, encrypted_password, email_confirmed_at, roles)
values
  ('a1000000-0000-0000-0000-000000000001',
   'step-b-ios-owner@example.invalid',
   crypt('test1234', gen_salt('bf')),
   now(),
   '{"authenticated"}'::jsonb)
on conflict (email) do update
  set encrypted_password = excluded.encrypted_password,
      roles = excluded.roles;

insert into auth.users (id, email, encrypted_password, email_confirmed_at, roles)
values
  ('a2000000-0000-0000-0000-000000000001',
   'step-b-ios-admin@example.invalid',
   crypt('admin1234', gen_salt('bf')),
   now(),
   '{"authenticated",' || quote_literal('admin') || '}'::jsonb)
on conflict (email) do update
  set encrypted_password = excluded.encrypted_password,
      roles = excluded.roles;

-- 2) Admin role membership (server-admin-gated moderation + moderation RPCs).
-- admin/authenticated role rows live in auth.users.roles for local dev; the
-- is_admin / auth.role() check used by Step B admin contracts resolves via roles.
do $$
begin
  if not exists (select 1 from auth.users where email='step-b-ios-admin@example.invalid'
                 and (roles::jsonb ? 'admin')) then
    update auth.users
    set roles = (roles::jsonb || '["admin"]'::jsonb)
    where email = 'step-b-ios-admin@example.invalid';
  end if;
end;
$$;

-- 3) Private seller (Step B/C/D live harnesses create listings under this seller).
insert into public.sellers (id, user_id, kind, status, shop_name, slug, city, country_code)
values
  ('b1000000-0000-0000-0000-000000000001',
   'a1000000-0000-0000-0000-000000000001',
   'private', 'approved', 'Step B IOS Owner', 'step-b-ios-owner', 'Berlin', 'DE')
on conflict (id) do update
  set user_id = excluded.user_id,
      status = excluded.status,
      city = excluded.city,
      country_code = excluded.country_code;

-- 4) Step D demo: a verified opted-in business store + a private seller, mirroring
-- supabase/snippets/step_d_local_map_demo.sql's Atelier Lale fixture so the live
-- Map harness has a precise pin and a private safe-pin under the same Berlin center.
insert into auth.users (id, email, encrypted_password, email_confirmed_at, roles)
values
  ('a3000000-0000-0000-0000-000000000001',
   'step-d-demo@local.invalid',
   crypt('test1234', gen_salt('bf')),
   now(),
   '{"authenticated"}'::jsonb)
on conflict (id) do update
  set encrypted_password = excluded.encrypted_password;

insert into public.sellers (id, user_id, kind, status, shop_name, slug, city, country_code,
                            precise_location_opt_in, latitude, longitude, address_line)
values
  ('b3000000-0000-0000-0000-000000000001',
   null,
   'business', 'approved', 'Atelier Lale', 'atelier-lale', 'Berlin', 'DE',
   true, 52.516275, 13.377704, 'Platz der Republik 1')
on conflict (id) do update
  set precise_location_opt_in = excluded.precise_location_opt_in,
      latitude = excluded.latitude,
      longitude = excluded.longitude,
      address_line = excluded.address_line,
      status = excluded.status;

-- 5) Approve the two required document kinds so is_verified_seller returns true for
-- the demo store (matches the local-map-demo snippet's contract).
insert into public.seller_documents (seller_id, kind, storage_path, mime_type, status)
values
  ('b3000000-0000-0000-0000-000000000001', 'identity', 'step-d-local/atelier-lale-identity.pdf', 'application/pdf', 'approved'),
  ('b3000000-0000-0000-0000-000000000001', 'business_registration', 'step-d-local/atelier-lale-business.pdf', 'application/pdf', 'approved')
on conflict (storage_path) do update
  set seller_id = excluded.seller_id,
      kind = excluded.kind,
      mime_type = excluded.mime_type,
      status = excluded.status;

-- 6) A private Berlin listing + a precise-store listing under the demo seller, both
-- re-derived through the Step D trigger (no direct coordinate writes from clients).
insert into public.products (id, seller_id, title, slug, description, condition, status, price_cents, city, country_code, quantity)
values
  ('c1000000-0000-0000-0000-000000000001',
   'b1000000-0000-0000-0000-000000000001',
   'Step D private demo listing', 'step-d-private-demo', 'Local-private Berlin fixture.',
   'used', 'active', 2500, 'Berlin', 'DE', 1)
on conflict (id) do update
  set title = excluded.title, status = excluded.status;

insert into public.products (id, seller_id, title, slug, description, condition, status, price_cents, city, country_code, quantity)
values
  ('c2000000-0000-0000-0000-000000000001',
   'b3000000-0000-0000-0000-000000000001',
   'Step D precise store demo listing', 'step-d-precise-demo', 'Local-store Berlin fixture.',
   'new', 'active', 7500, 'Berlin', 'DE', 1)
on conflict (id) do update
  set title = excluded.title, status = excluded.status;

commit;

\echo 'STEP D LOCAL SEED: done'
