-- Step E2 local-only seed for the owner-side live harness
-- (integration_test/step_e2_live_test.dart). Requires migrations up to
-- 20260927000700_step_e2_owner_onboarding.sql.
--
-- Idempotent: re-running restores the intended state. The live harness removes its
-- own uploads (row and file) in tearDownAll; if a run was killed before that, the seed
-- refuses to continue while an uploaded doctor document still has a stored file, so a
-- re-seed never orphans files. Local Supabase only (Docker Desktop, 127.0.0.1:54322).
-- Never run against a linked/remote project.
--
--   docker exec -i supabase_db_flutterapp psql -U postgres -d postgres -X \
--     -v ON_ERROR_STOP=1 < supabase/snippets/step_e2_local_seed.sql
--
-- The password is a local-only constant so the harness can sign in
-- deterministically. It is out of scope for any real environment.
--   step-e2-ios-new@example.invalid         no seller yet (start card)
--   step-e2-ios-doctor@example.invalid      doctor, identity approved, medical rejected
--   step-e2-ios-restaurant@example.invalid  verified restaurant with profile/hours/menu
--   password for all three: ZerinStepE2!2026

begin;

create function pg_temp.seed_user(user_id uuid, user_email text, display_name text)
returns void language sql as $$
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at
  ) values (
    '00000000-0000-0000-0000-000000000000', user_id, 'authenticated', 'authenticated',
    user_email, extensions.crypt('ZerinStepE2!2026', extensions.gen_salt('bf')), now(),
    '', '', '', '',
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('display_name', display_name), now(), now()
  )
  on conflict (id) do update set
    encrypted_password = excluded.encrypted_password,
    email_confirmed_at = coalesce(auth.users.email_confirmed_at, now()),
    raw_app_meta_data = excluded.raw_app_meta_data;
  insert into auth.identities (provider_id, user_id, identity_data, provider, created_at, updated_at)
  values (user_id::text, user_id,
    jsonb_build_object('sub', user_id::text, 'email', user_email, 'email_verified', true),
    'email', now(), now())
  on conflict (provider_id, provider) do nothing;
$$;

select pg_temp.seed_user('e2e20000-0000-4000-8000-000000000001', 'step-e2-ios-new@example.invalid', 'Neue Inhaberin');
select pg_temp.seed_user('e2e20000-0000-4000-8000-000000000002', 'step-e2-ios-doctor@example.invalid', 'Dr. Ava Rahimi');
select pg_temp.seed_user('e2e20000-0000-4000-8000-000000000003', 'step-e2-ios-restaurant@example.invalid', 'Zagros Grill');

-- The new user starts without any seller identity.
delete from public.sellers where user_id = 'e2e20000-0000-4000-8000-000000000001';

-- Doctor: pending business seller, identity approved, medical proof rejected with a note.
insert into public.sellers (id, user_id, kind, status, shop_name, slug, city, country_code, directory_type)
values ('e2e30000-0000-4000-8000-000000000002', 'e2e20000-0000-4000-8000-000000000002',
  'business', 'pending', 'Praxis Dr. Ava Rahimi', 'praxis-dr-ava-rahimi', 'Berlin', 'DE', 'doctor')
on conflict (id) do update set status = 'pending', directory_type = 'doctor',
  shop_name = excluded.shop_name, city = excluded.city;
do $$
begin
  if exists (
    select 1 from public.seller_documents document
    join storage.objects object
      on object.bucket_id = 'seller-documents' and object.name = document.storage_path
    where document.seller_id = 'e2e30000-0000-4000-8000-000000000002'
      and document.id not in ('e2e40000-0000-4000-8000-000000000021', 'e2e40000-0000-4000-8000-000000000022')
  ) then
    raise exception 'The E2 doctor still has uploaded documents with stored files; remove them (row and file) before re-seeding';
  end if;
end;
$$;
delete from public.seller_documents
where seller_id = 'e2e30000-0000-4000-8000-000000000002'
  and id not in ('e2e40000-0000-4000-8000-000000000021', 'e2e40000-0000-4000-8000-000000000022');
insert into public.seller_documents (id, seller_id, kind, storage_path, mime_type, status, admin_note, reviewed_at, created_at)
values
  ('e2e40000-0000-4000-8000-000000000021', 'e2e30000-0000-4000-8000-000000000002', 'identity',
   'e2e30000-0000-4000-8000-000000000002/identity/seed-identity.jpg', 'image/jpeg',
   'approved', null, now() - interval '1 day', now() - interval '2 days'),
  ('e2e40000-0000-4000-8000-000000000022', 'e2e30000-0000-4000-8000-000000000002',
   'medical_professional_registration',
   'e2e30000-0000-4000-8000-000000000002/medical_professional_registration/seed-medical.jpg',
   'image/jpeg', 'rejected',
   'Die Approbationsurkunde ist abgeschnitten. Bitte das ganze Dokument als PDF oder Foto hochladen.',
   now() - interval '1 day', now() - interval '2 days')
on conflict (id) do update set status = excluded.status, admin_note = excluded.admin_note;

-- Restaurant: approved and verified via documents, draft profile with hours and menu.
insert into public.sellers (id, user_id, kind, status, shop_name, slug, city, country_code, directory_type)
values ('e2e30000-0000-4000-8000-000000000003', 'e2e20000-0000-4000-8000-000000000003',
  'business', 'approved', 'Zagros Grill', 'zagros-grill', 'Berlin', 'DE', 'restaurant')
on conflict (id) do update set status = 'approved', directory_type = 'restaurant',
  shop_name = excluded.shop_name, city = excluded.city;
insert into public.seller_documents (id, seller_id, kind, storage_path, mime_type, status, reviewed_at)
values
  ('e2e40000-0000-4000-8000-000000000031', 'e2e30000-0000-4000-8000-000000000003', 'identity',
   'e2e30000-0000-4000-8000-000000000003/identity/seed-identity.jpg', 'image/jpeg', 'approved', now()),
  ('e2e40000-0000-4000-8000-000000000032', 'e2e30000-0000-4000-8000-000000000003', 'business_registration',
   'e2e30000-0000-4000-8000-000000000003/business_registration/seed-business.pdf', 'application/pdf',
   'approved', now())
on conflict (id) do update set status = 'approved';

insert into public.business_directory_profiles (
  seller_id, type, description, phone, website, languages, cuisines, price_level,
  has_halal, has_vegetarian_options, has_vegan_options, is_published
) values (
  'e2e30000-0000-4000-8000-000000000003', 'restaurant',
  'Kurdische Grillküche aus Duhok: Kebab vom Holzkohlegrill, hausgemachte Dolma und frisches Brot aus dem Tandur.',
  '030 61234567', 'https://zagros-grill.example',
  array['german', 'kurdish', 'arabic']::public.directory_spoken_language[],
  array['kurdish', 'middle_eastern', 'kebab']::public.directory_cuisine[], 2,
  true, true, false, false
)
on conflict (seller_id) do update set
  type = excluded.type, description = excluded.description, phone = excluded.phone,
  website = excluded.website, languages = excluded.languages, cuisines = excluded.cuisines,
  price_level = excluded.price_level, has_halal = excluded.has_halal,
  has_vegetarian_options = excluded.has_vegetarian_options,
  has_vegan_options = excluded.has_vegan_options, is_published = false;

delete from public.business_directory_hours where seller_id = 'e2e30000-0000-4000-8000-000000000003';
insert into public.business_directory_hours (seller_id, weekday, opens_at, closes_at, sort_order)
select 'e2e30000-0000-4000-8000-000000000003', weekday, opens_at::time, closes_at::time, 0
from (values
  (1, '11:30', '22:00'), (2, '11:30', '22:00'), (3, '11:30', '22:00'), (4, '11:30', '22:00'),
  (5, '11:30', '23:30'), (6, '12:00', '02:00'), (0, '12:00', '21:00')
) hours(weekday, opens_at, closes_at);

delete from public.business_directory_menu_sections where seller_id = 'e2e30000-0000-4000-8000-000000000003';
with sections as (
  insert into public.business_directory_menu_sections (seller_id, name, sort_order)
  values ('e2e30000-0000-4000-8000-000000000003', 'Vorspeisen', 0),
         ('e2e30000-0000-4000-8000-000000000003', 'Vom Grill', 1),
         ('e2e30000-0000-4000-8000-000000000003', 'Getränke', 2)
  returning id, name
)
insert into public.business_directory_menu_items (
  section_id, seller_id, name, description, price_cents, is_available, is_halal, is_vegetarian, is_vegan, sort_order
)
select sections.id, 'e2e30000-0000-4000-8000-000000000003', item.name, item.description, item.price_cents,
  item.is_available, item.is_halal, item.is_vegetarian, item.is_vegan, item.sort_order
from sections join (values
  ('Vorspeisen', 'Hummus', 'Mit Olivenöl und Paprika', 650, true, true, true, true, 0),
  ('Vorspeisen', 'Linsensuppe', null, 590, true, true, true, false, 1),
  ('Vom Grill', 'Kebab Duhok', 'Hackfleischspieß mit Sumach-Zwiebeln', 1450, true, true, false, false, 0),
  ('Vom Grill', 'Hähnchen-Tikka', null, 1590, true, true, false, false, 1),
  ('Vom Grill', 'Dolma', 'Gefüllte Weinblätter und Gemüse', 1290, false, true, true, false, 2),
  ('Getränke', 'Ayran', null, 290, true, true, true, false, 0),
  ('Getränke', 'Schwarzer Tee', null, 220, true, true, true, true, 1)
) item(section_name, name, description, price_cents, is_available, is_halal, is_vegetarian, is_vegan, sort_order)
  on item.section_name = sections.name;

commit;

\echo 'STEP E2 LOCAL SEED: done'
