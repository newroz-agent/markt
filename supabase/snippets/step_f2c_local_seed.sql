-- Step F2c local-only seed for integration_test/step_f_live_test.dart.
-- Requires the effective schema through 20260928000100 Step F2a.
--
-- This seed is deterministic and idempotent. It owns only the UUIDs, emails,
-- slugs, listings and chat contexts declared below. It refuses collisions or
-- unexpected extra seller identities rather than deleting ambient data.
-- Never run against a linked or remote project.
--
-- Accounts (password for all: ZerinStepF!2026):
--   step-f2c-dual@example.invalid       private + verified business
--   step-f2c-buyer@example.invalid      chat counterpart
--   step-f2c-other@example.invalid      owner of buyer-side chat seller
begin;

create function pg_temp.seed_user(
  p_user_id uuid,
  p_user_email text,
  p_display_name text,
  p_username text
) returns void language plpgsql as $$
begin
  if exists (
    select 1 from auth.users as app_user
    where app_user.id = p_user_id
      and app_user.email is distinct from p_user_email
  ) then
    raise exception 'F2c user UUID collision for %', p_user_id;
  end if;

  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at
  ) values (
    '00000000-0000-0000-0000-000000000000', p_user_id,
    'authenticated', 'authenticated', p_user_email,
    extensions.crypt('ZerinStepF!2026', extensions.gen_salt('bf')), now(),
    '', '', '', '',
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('display_name', p_display_name), now(), now()
  ) on conflict (id) do update set
    encrypted_password = excluded.encrypted_password,
    email_confirmed_at = coalesce(auth.users.email_confirmed_at, now()),
    raw_app_meta_data = excluded.raw_app_meta_data,
    raw_user_meta_data = excluded.raw_user_meta_data;

  insert into auth.identities (
    provider_id, user_id, identity_data, provider, created_at, updated_at
  ) values (
    p_user_id::text, p_user_id,
    jsonb_build_object(
      'sub', p_user_id::text,
      'email', p_user_email,
      'email_verified', true
    ),
    'email', now(), now()
  ) on conflict (provider_id, provider) do nothing;

  update public.profiles as profile
  set display_name = p_display_name,
      username = p_username,
      city = 'Berlin',
      bio = 'Lokales Step-F-Testprofil',
      updated_at = now()
  where profile.id = p_user_id;
end;
$$;

-- Fail closed if deterministic fixture ownership has drifted.
do $$
begin
  if exists (
    select 1 from public.sellers
    where user_id = 'f2c10000-0000-4000-8000-000000000001'
      and id not in (
        'f2c20000-0000-4000-8000-000000000001',
        'f2c20000-0000-4000-8000-000000000002'
      )
  ) then
    raise exception 'F2c dual user owns an unexpected seller identity';
  end if;
  if exists (
    select 1 from public.sellers
    where user_id = 'f2c10000-0000-4000-8000-000000000003'
      and id <> 'f2c20000-0000-4000-8000-000000000003'
  ) then
    raise exception 'F2c counterpart user owns an unexpected seller identity';
  end if;
  if exists (
    select 1 from public.products
    where id in (
      'f2c30000-0000-4000-8000-000000000001',
      'f2c30000-0000-4000-8000-000000000002'
    ) and seller_id not in (
      'f2c20000-0000-4000-8000-000000000001',
      'f2c20000-0000-4000-8000-000000000002'
    )
  ) then
    raise exception 'F2c listing UUID collision';
  end if;
  if exists (
    select 1 from public.chats
    where id in (
      'f2c40000-0000-4000-8000-000000000001',
      'f2c40000-0000-4000-8000-000000000002',
      'f2c40000-0000-4000-8000-000000000003'
    ) and (buyer_id, seller_id) not in (
      ('f2c10000-0000-4000-8000-000000000002'::uuid,
       'f2c20000-0000-4000-8000-000000000001'::uuid),
      ('f2c10000-0000-4000-8000-000000000002'::uuid,
       'f2c20000-0000-4000-8000-000000000002'::uuid),
      ('f2c10000-0000-4000-8000-000000000001'::uuid,
       'f2c20000-0000-4000-8000-000000000003'::uuid)
    )
  ) then
    raise exception 'F2c chat UUID collision';
  end if;
end;
$$;

select pg_temp.seed_user(
  'f2c10000-0000-4000-8000-000000000001',
  'step-f2c-dual@example.invalid',
  'Rojin Demir',
  'rojin_f2c'
);
select pg_temp.seed_user(
  'f2c10000-0000-4000-8000-000000000002',
  'step-f2c-buyer@example.invalid',
  'Dilan Kaya',
  'dilan_f2c'
);
select pg_temp.seed_user(
  'f2c10000-0000-4000-8000-000000000003',
  'step-f2c-other@example.invalid',
  'Mina Aydin',
  'mina_f2c'
);

insert into public.sellers (
  id, user_id, kind, status, shop_name, slug, city, country_code,
  directory_type, approved_at
) values
  (
    'f2c20000-0000-4000-8000-000000000001',
    'f2c10000-0000-4000-8000-000000000001',
    'private', 'approved', 'Rojin Demir', 'f2c-rojin-private',
    'Berlin', 'DE', null, now()
  ),
  (
    'f2c20000-0000-4000-8000-000000000002',
    'f2c10000-0000-4000-8000-000000000001',
    'business', 'approved', 'Rojin Atelier', 'f2c-rojin-atelier',
    'Berlin', 'DE', 'restaurant', now()
  ),
  (
    'f2c20000-0000-4000-8000-000000000003',
    'f2c10000-0000-4000-8000-000000000003',
    'business', 'approved', 'Mina Market', 'f2c-mina-market',
    'Berlin', 'DE', null, now()
  )
on conflict (id) do update set
  status = excluded.status,
  shop_name = excluded.shop_name,
  city = excluded.city,
  country_code = excluded.country_code,
  directory_type = excluded.directory_type,
  approved_at = coalesce(public.sellers.approved_at, now());

insert into public.seller_documents (
  id, seller_id, kind, storage_path, mime_type, status, reviewed_at
) values
  (
    'f2c60000-0000-4000-8000-000000000001',
    'f2c20000-0000-4000-8000-000000000002',
    'identity',
    'f2c20000-0000-4000-8000-000000000002/identity/seed.pdf',
    'application/pdf', 'approved', now()
  ),
  (
    'f2c60000-0000-4000-8000-000000000002',
    'f2c20000-0000-4000-8000-000000000002',
    'business_registration',
    'f2c20000-0000-4000-8000-000000000002/business_registration/seed.pdf',
    'application/pdf', 'approved', now()
  )
on conflict (id) do update set
  status = 'approved', reviewed_at = now();

insert into public.products (
  id, seller_id, category_id, title, slug, description, condition, status,
  price_cents, city, country_code, quantity, created_at
) values
  (
    'f2c30000-0000-4000-8000-000000000001',
    'f2c20000-0000-4000-8000-000000000001',
    (select id from public.categories where slug = 'elektronik'),
    'Private Vintage Kamera', 'f2c-private-vintage-kamera',
    'Private Step-F-Testanzeige für die Identitätsabschnitte.',
    'used', 'pending_review', 12900, 'Berlin', 'DE', 1,
    '2026-09-30 10:00:00+00'
  ),
  (
    'f2c30000-0000-4000-8000-000000000002',
    'f2c20000-0000-4000-8000-000000000002',
    (select id from public.categories where slug = 'elektronik'),
    'Geschäftliche Keramikserie', 'f2c-business-keramikserie',
    'Geschäftliche Step-F-Testanzeige für die Identitätsabschnitte.',
    'new', 'pending_review', 24900, 'Berlin', 'DE', 1,
    '2026-09-30 11:00:00+00'
  )
on conflict (id) do update set
  seller_id = excluded.seller_id,
  category_id = excluded.category_id,
  title = excluded.title,
  description = excluded.description,
  condition = excluded.condition,
  status = excluded.status,
  price_cents = excluded.price_cents,
  city = excluded.city,
  country_code = excluded.country_code,
  quantity = excluded.quantity,
  created_at = excluded.created_at;

-- Reset only the seed-owned chat contexts and their generated notifications.
delete from public.notifications
where data ->> 'chatId' in (
  'f2c40000-0000-4000-8000-000000000001',
  'f2c40000-0000-4000-8000-000000000002',
  'f2c40000-0000-4000-8000-000000000003'
);
delete from public.chats
where id in (
  'f2c40000-0000-4000-8000-000000000001',
  'f2c40000-0000-4000-8000-000000000002',
  'f2c40000-0000-4000-8000-000000000003'
);

-- Refuse a conflicting open context that is not owned by this seed.
do $$
begin
  if exists (
    select 1 from public.chats
    where closed_at is null and product_id is null
      and (
        (buyer_id = 'f2c10000-0000-4000-8000-000000000002'
         and seller_id in (
           'f2c20000-0000-4000-8000-000000000001',
           'f2c20000-0000-4000-8000-000000000002'
         ))
        or (buyer_id = 'f2c10000-0000-4000-8000-000000000001'
            and seller_id = 'f2c20000-0000-4000-8000-000000000003')
      )
  ) then
    raise exception 'F2c chat context collision outside deterministic IDs';
  end if;
end;
$$;

insert into public.chats (id, buyer_id, seller_id, created_at) values
  (
    'f2c40000-0000-4000-8000-000000000001',
    'f2c10000-0000-4000-8000-000000000002',
    'f2c20000-0000-4000-8000-000000000001',
    '2026-09-30 12:00:00+00'
  ),
  (
    'f2c40000-0000-4000-8000-000000000002',
    'f2c10000-0000-4000-8000-000000000002',
    'f2c20000-0000-4000-8000-000000000002',
    '2026-09-30 12:10:00+00'
  ),
  (
    'f2c40000-0000-4000-8000-000000000003',
    'f2c10000-0000-4000-8000-000000000001',
    'f2c20000-0000-4000-8000-000000000003',
    '2026-09-30 12:20:00+00'
  );

insert into public.messages (
  id, chat_id, sender_id, kind, body, created_at
) values
  (
    'f2c50000-0000-4000-8000-000000000001',
    'f2c40000-0000-4000-8000-000000000001',
    'f2c10000-0000-4000-8000-000000000002',
    'text', 'Frage zum privaten Angebot', '2026-09-30 13:00:00+00'
  ),
  (
    'f2c50000-0000-4000-8000-000000000002',
    'f2c40000-0000-4000-8000-000000000002',
    'f2c10000-0000-4000-8000-000000000002',
    'text', 'Frage an das Geschäft', '2026-09-30 13:10:00+00'
  ),
  (
    'f2c50000-0000-4000-8000-000000000003',
    'f2c40000-0000-4000-8000-000000000003',
    'f2c10000-0000-4000-8000-000000000003',
    'text', 'Antwort von Mina Market', '2026-09-30 13:20:00+00'
  );

-- Assert the exact catalog, listing identity and three-context inbox matrix.
do $$
declare
  catalog jsonb;
  inbox jsonb;
begin
  perform set_config(
    'request.jwt.claims',
    '{"sub":"f2c10000-0000-4000-8000-000000000001","role":"authenticated"}',
    true
  );

  catalog := public.get_my_identity_catalog();
  assert jsonb_array_length(catalog -> 'identities') = 2;
  assert catalog -> 'identities' -> 0 ->> 'seller_id' =
    'f2c20000-0000-4000-8000-000000000001';
  assert catalog -> 'identities' -> 1 ->> 'seller_id' =
    'f2c20000-0000-4000-8000-000000000002';

  assert (select count(*) = 1 from public.products
    where id = 'f2c30000-0000-4000-8000-000000000001'
      and seller_id = 'f2c20000-0000-4000-8000-000000000001');
  assert (select count(*) = 1 from public.products
    where id = 'f2c30000-0000-4000-8000-000000000002'
      and seller_id = 'f2c20000-0000-4000-8000-000000000002');

  inbox := public.get_chat_inbox();
  assert jsonb_array_length(inbox) >= 3;
  assert exists (
    select 1 from jsonb_array_elements(inbox) item
    where item ->> 'id' = 'f2c40000-0000-4000-8000-000000000001'
      and item ->> 'viewer_role' = 'seller'
      and item ->> 'viewer_identity_type' = 'person'
      and item ->> 'viewer_seller_id' =
        'f2c20000-0000-4000-8000-000000000001'
      and item ->> 'viewer_identity_name' = 'Rojin Demir'
  );
  assert exists (
    select 1 from jsonb_array_elements(inbox) item
    where item ->> 'id' = 'f2c40000-0000-4000-8000-000000000002'
      and item ->> 'viewer_role' = 'seller'
      and item ->> 'viewer_identity_type' = 'business'
      and item ->> 'viewer_seller_id' =
        'f2c20000-0000-4000-8000-000000000002'
      and item ->> 'viewer_identity_name' = 'Rojin Atelier'
  );
  assert exists (
    select 1 from jsonb_array_elements(inbox) item
    where item ->> 'id' = 'f2c40000-0000-4000-8000-000000000003'
      and item ->> 'viewer_role' = 'buyer'
      and item ->> 'viewer_identity_type' = 'person'
      and item -> 'viewer_seller_id' = 'null'::jsonb
      and item ->> 'viewer_identity_name' = 'Rojin Demir'
  );
  assert public.get_unread_chat_count() = 3;

  perform set_config('request.jwt.claims', '{}', true);
end;
$$;

commit;

\echo 'STEP F2C LOCAL SEED: done'
