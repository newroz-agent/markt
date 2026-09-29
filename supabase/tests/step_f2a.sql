-- Step F2a database-only acceptance: one login may own one private and one
-- business seller identity. Every fixture is deterministic and every write rolls back.
begin;

create function pg_temp.expect_error(command text, expected_state text)
returns void language plpgsql as $$
begin
  begin
    execute command;
  exception when others then
    assert sqlstate = expected_state,
      format('Expected SQLSTATE %s, got %s (%s): %s',
        expected_state, sqlstate, sqlerrm, command);
    return;
  end;
  raise exception 'Expected command to fail: %', command;
end;
$$;

create function pg_temp.act_as(user_id uuid, admin boolean default false)
returns void language sql as $$
  select set_config(
    'request.jwt.claims',
    jsonb_build_object(
      'sub', user_id,
      'role', 'authenticated',
      'app_metadata', case when admin
        then '{"role":"admin"}'::jsonb else '{}'::jsonb end
    )::text,
    true
  );
$$;

create function pg_temp.clear_auth()
returns void language sql as $$
  select set_config('request.jwt.claims', '{}', true);
$$;

create table pg_temp.f2a_context (
  key text primary key,
  value text not null
);
grant select, insert, update, delete on pg_temp.f2a_context to authenticated;
grant select on pg_temp.f2a_context to anon;

-- Fixture accounts. The auth trigger creates the person profile for every account.
insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data) values
  ('f2a00000-0000-0000-0000-000000000001', 'f2a-person-only@example.invalid',
    '{"display_name":"F2a Person Only"}', '{}'),
  ('f2a00000-0000-0000-0000-000000000002', 'f2a-business-first@example.invalid',
    '{"display_name":"F2a Business First"}', '{}'),
  ('f2a00000-0000-0000-0000-000000000003', 'f2a-private-first@example.invalid',
    '{"display_name":"F2a Private First"}', '{}'),
  ('f2a00000-0000-0000-0000-000000000004', 'f2a-other-owner@example.invalid',
    '{"display_name":"F2a Other Owner"}', '{}'),
  ('f2a00000-0000-0000-0000-000000000005', 'f2a-buyer@example.invalid',
    '{"display_name":"F2a Buyer"}', '{}'),
  ('f2a00000-0000-0000-0000-000000000006', 'f2a-admin@example.invalid',
    '{"display_name":"F2a Admin"}', '{"role":"admin"}'),
  ('f2a00000-0000-0000-0000-000000000007', 'f2a-legacy@example.invalid',
    '{"display_name":"F2a Legacy"}', '{}');

update public.profiles set
  username = case id
    when 'f2a00000-0000-0000-0000-000000000001' then 'f2a_person_only'
    when 'f2a00000-0000-0000-0000-000000000002' then 'f2a_business_first'
    when 'f2a00000-0000-0000-0000-000000000003' then 'f2a_private_first'
    when 'f2a00000-0000-0000-0000-000000000004' then 'f2a_other_owner'
    when 'f2a00000-0000-0000-0000-000000000005' then 'f2a_buyer'
    when 'f2a00000-0000-0000-0000-000000000006' then 'f2a_operator'
    else 'f2a_legacy'
  end,
  city = 'Berlin',
  phone = case when id = 'f2a00000-0000-0000-0000-000000000001'
    then '+49-secret-person-only' else phone end
where id::text like 'f2a00000-0000-0000-0000-00000000000%';

insert into public.categories (
  id, slug, name_de, name_en, name_ar, name_tr, name_ku,
  icon_key, image_url, is_active
) values (
  'f2d00000-0000-0000-0000-000000000001',
  'f2a-category', 'F2a', 'F2a', 'F2a', 'F2a', 'F2a',
  'test', 'https://example.invalid/f2a.webp', true
);

-- A separate owner/business is used for cross-owner and buyer-side checks.
insert into public.sellers (
  id, user_id, kind, status, shop_name, slug, city, country_code, approved_at,
  directory_type
) values (
  'f2b00000-0000-0000-0000-000000000004',
  'f2a00000-0000-0000-0000-000000000004',
  'business', 'approved', 'F2a Other Business', 'f2a-other-business',
  'Berlin', 'DE', now(), 'cafe'
);

-- Schema, ACL, and rollout invariants.
do $$
begin
  assert not exists (
    select 1 from pg_constraint
    where conrelid = 'public.sellers'::regclass
      and conname = 'sellers_user_id_key'
  ), 'global seller/user uniqueness was removed';
  assert exists (
    select 1 from pg_constraint
    where conrelid = 'public.sellers'::regclass
      and conname = 'sellers_user_kind_key'
      and pg_get_constraintdef(oid) = 'UNIQUE (user_id, kind)'
  ), 'one seller per kind is enforced';
  assert not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'sellers'
      and policyname = 'sellers_insert_own_application'
  ), 'direct seller insert policy was removed';
  assert not has_table_privilege('authenticated', 'public.sellers', 'insert'),
    'authenticated clients cannot insert sellers directly';

  assert has_function_privilege('authenticated',
    'public.get_my_identity_catalog()', 'execute');
  assert not has_function_privilege('anon',
    'public.get_my_identity_catalog()', 'execute');
  assert has_function_privilege('authenticated',
    'public.prepare_listing_submission(uuid,public.seller_kind,text,text)', 'execute');
  assert not has_function_privilege('anon',
    'public.prepare_listing_submission(uuid,public.seller_kind,text,text)', 'execute');
  assert has_function_privilege('authenticated',
    'public.get_my_directory_onboarding(uuid)', 'execute');
  assert has_function_privilege('authenticated',
    'public.owner_start_directory(uuid,public.directory_business_type,text,text)', 'execute');
  assert not has_function_privilege('authenticated',
    'public.notify_chat_message()', 'execute');
  assert not has_function_privilege('authenticated',
    'public.notify_order_change()', 'execute');
  assert not has_function_privilege('authenticated',
    'public.record_product_price_change()', 'execute');
  assert to_regprocedure(
    'public.submit_listing(uuid,uuid,uuid,text,text,public.product_condition,bigint,text,text[],jsonb)'
  ) is null, 'obsolete ten-input submit overload stays absent';
end;
$$;

set local role authenticated;
select pg_temp.act_as('f2a00000-0000-0000-0000-000000000001');

-- A person exists before any seller row. The catalog is safe and stable.
do $$
declare
  catalog jsonb := public.get_my_identity_catalog();
  own_profile jsonb := public.get_my_profile();
begin
  assert exists (
    select 1 from public.profiles
    where id = 'f2a00000-0000-0000-0000-000000000001'
  ), 'auth signup created the person profile';
  assert not exists (
    select 1 from public.sellers
    where user_id = 'f2a00000-0000-0000-0000-000000000001'
  ), 'person identity does not eagerly create a seller';
  assert jsonb_array_length(catalog -> 'identities') = 1;
  assert catalog -> 'identities' -> 0 ->> 'identity_type' = 'person';
  assert catalog -> 'identities' -> 0 -> 'seller_id' = 'null'::jsonb;
  assert catalog -> 'identities' -> 0 ->> 'kind' = 'private';
  assert catalog::text not like '%f2a-person-only@example.invalid%';
  assert catalog::text not like '%f2a00000-0000-0000-0000-000000000001%';
  assert catalog::text not like '%+49-secret-person-only%';
  assert own_profile -> 'seller' = 'null'::jsonb
    and (own_profile ->> 'listing_count')::integer = 0;
end;
$$;

select pg_temp.expect_error($sql$
  insert into public.sellers (
    id, user_id, kind, status, shop_name, slug, city, country_code
  ) values (
    'f2b00000-0000-0000-0000-000000000001',
    'f2a00000-0000-0000-0000-000000000001',
    'private', 'pending', 'Forbidden Direct Seller', 'f2a-forbidden-direct',
    'Berlin', 'DE'
  )
$sql$, '42501');

-- Business-first: the explicit directory creator accepts JSON null only for an
-- account with no seller, then listing preparation lazily adds the private identity.
select pg_temp.act_as('f2a00000-0000-0000-0000-000000000002');
do $$
declare
  onboarding jsonb;
  prepared jsonb;
  catalog jsonb;
  business_id uuid;
  private_id uuid;
begin
  onboarding := public.owner_start_directory(
    null::uuid, 'restaurant', 'F2a Business First Shop', 'Berlin'
  );
  business_id := (onboarding -> 'seller' ->> 'id')::uuid;
  assert onboarding -> 'seller' ->> 'kind' = 'business';
  assert onboarding -> 'seller' ->> 'directory_type' = 'restaurant';
  insert into pg_temp.f2a_context values ('business_first_business', business_id::text);

  catalog := public.get_my_identity_catalog();
  assert jsonb_array_length(catalog -> 'identities') = 2;
  assert catalog -> 'identities' -> 0 -> 'seller_id' = 'null'::jsonb;
  assert catalog -> 'identities' -> 1 ->> 'seller_id' = business_id::text;

  prepared := public.prepare_listing_submission(
    null::uuid, 'private', 'F2a Business First Person', 'Berlin'
  );
  private_id := (prepared ->> 'seller_id')::uuid;
  assert prepared ->> 'seller_kind' = 'private';
  insert into pg_temp.f2a_context values ('business_first_private', private_id::text);

  assert (select count(*) = 2 from public.sellers
    where user_id = auth.uid());
  assert (select array_agg(kind order by kind::text)
    from public.sellers where user_id = auth.uid())
    = array['business','private']::public.seller_kind[];

  catalog := public.get_my_identity_catalog();
  assert catalog -> 'identities' -> 0 ->> 'seller_id' = private_id::text;
  assert catalog -> 'identities' -> 1 ->> 'seller_id' = business_id::text;

  prepared := public.prepare_listing_submission(
    null::uuid, 'private', 'Ignored Duplicate', 'Hamburg'
  );
  assert prepared ->> 'seller_id' = private_id::text,
    'lazy private preparation reuses the one private seller';
end;
$$;

select pg_temp.expect_error(
  $$select public.owner_start_directory(
    null::uuid, 'cafe', 'Second Business', 'Berlin')$$,
  '22023'
);
select pg_temp.expect_error(
  $$select public.owner_start_directory(
    'f2b00000-0000-0000-0000-000000000004'::uuid,
    'cafe', 'Foreign Business', 'Berlin')$$,
  '22023'
);

-- Private-first: the old no-ID start remains gated, while the explicit creator
-- verifies the exact private identity and adds one business row.
select pg_temp.act_as('f2a00000-0000-0000-0000-000000000003');
do $$
declare
  prepared jsonb := public.prepare_listing_submission(
    null::uuid, 'private', 'F2a Private First Person', 'Berlin'
  );
  private_id uuid;
begin
  private_id := (prepared ->> 'seller_id')::uuid;
  insert into pg_temp.f2a_context values ('private_first_private', private_id::text);
end;
$$;
select pg_temp.expect_error(
  $$select public.owner_start_directory('cafe', 'Legacy Must Not Add Second', 'Berlin')$$,
  '42501'
);
do $$
declare
  onboarding jsonb;
  private_id uuid := (select value::uuid from pg_temp.f2a_context
    where key = 'private_first_private');
  business_id uuid;
begin
  onboarding := public.owner_start_directory(
    private_id, 'cafe', 'F2a Private First Business', 'Berlin'
  );
  business_id := (onboarding -> 'seller' ->> 'id')::uuid;
  insert into pg_temp.f2a_context values ('private_first_business', business_id::text);
  assert (select count(*) = 2 from public.sellers where user_id = auth.uid());
end;
$$;
select pg_temp.expect_error(
  $$select public.owner_start_directory(
    (select value::uuid from pg_temp.f2a_context where key='private_first_private'),
    'restaurant', 'Second Business', 'Berlin')$$,
  '22023'
);

-- The legacy listing wrapper can create only the first identity and remains
-- deterministic thereafter, preserving the shipping client's one-row behavior.
select pg_temp.act_as('f2a00000-0000-0000-0000-000000000007');
do $$
declare
  first_result jsonb := public.prepare_listing_submission(
    'business', 'F2a Legacy Business', 'Berlin'
  );
  second_result jsonb;
begin
  second_result := public.prepare_listing_submission(
    'private', 'Must Be Ignored', 'Hamburg'
  );
  assert first_result ->> 'seller_id' = second_result ->> 'seller_id';
  assert second_result ->> 'seller_kind' = 'business';
  assert (select count(*) = 1 from public.sellers where user_id = auth.uid());
end;
$$;

-- Explicit selection rejects foreign IDs and kind mismatches.
select pg_temp.act_as('f2a00000-0000-0000-0000-000000000002');
select pg_temp.expect_error(format(
  $sql$select public.prepare_listing_submission(%L, 'private', 'Foreign', 'Berlin')$sql$,
  (select value from pg_temp.f2a_context where key = 'private_first_private')
), '42501');
select pg_temp.expect_error(format(
  $sql$select public.prepare_listing_submission(%L, 'private', 'Wrong Kind', 'Berlin')$sql$,
  (select value from pg_temp.f2a_context where key = 'business_first_business')
), '42501');
select pg_temp.expect_error(
  $$select public.prepare_listing_submission(
    null::uuid, 'business', 'No Explicit Business Creation', 'Berlin')$$,
  '22023'
);

-- The table invariant independently refuses a second same-kind row.
reset role;
select pg_temp.clear_auth();
select pg_temp.expect_error(format(
  $sql$insert into public.sellers(
      id,user_id,kind,status,shop_name,slug,city,country_code
    ) values(
      'f2b00000-0000-0000-0000-000000000099',
      'f2a00000-0000-0000-0000-000000000002',
      'private','pending','Duplicate Private','f2a-duplicate-private','Berlin','DE'
    )$sql$
), '23505');

-- Explicit directory owner APIs are seller-bound. Legacy reads deterministically
-- choose business once both identities exist.
set local role authenticated;
select pg_temp.act_as('f2a00000-0000-0000-0000-000000000002');
do $$
declare
  business_id uuid := (select value::uuid from pg_temp.f2a_context
    where key = 'business_first_business');
  result jsonb;
begin
  result := public.owner_set_directory_type(business_id, 'restaurant');
  assert result -> 'seller' ->> 'id' = business_id::text;

  result := public.owner_upsert_directory_profile(
    p_seller_id => business_id,
    p_type => 'restaurant',
    p_description => 'A deterministic F2a restaurant profile used for identity acceptance.',
    p_phone => '030 28092026',
    p_website => 'https://example.invalid/f2a',
    p_cover_image_path => null,
    p_languages => array['german','kurdish']::public.directory_spoken_language[],
    p_cuisines => array['kurdish']::public.directory_cuisine[],
    p_price_level => 2::smallint,
    p_has_halal => true,
    p_is_published => true
  );
  assert result ->> 'seller_id' = business_id::text;

  result := public.owner_replace_directory_hours(
    business_id,
    '[{"weekday":1,"opens_at":"10:00","closes_at":"22:00","sort_order":0}]'
  );
  assert jsonb_array_length(result) = 1;

  result := public.owner_replace_directory_menu(
    business_id,
    '[{"name":"F2a Menu","sort_order":0,"items":[{"name":"F2a Dish","description":"Acceptance dish","price_cents":1299,"is_halal":true}]}]'
  );
  assert jsonb_array_length(result) = 1;
  assert result -> 0 -> 'items' -> 0 ->> 'name' = 'F2a Dish';

  result := public.get_my_directory_onboarding(business_id);
  assert result -> 'seller' ->> 'id' = business_id::text;
  assert jsonb_array_length(result -> 'hours') = 1;
  assert jsonb_array_length(result -> 'menu') = 1;
  assert public.get_my_directory_onboarding() -> 'seller' ->> 'id' = business_id::text,
    'legacy getter deterministically chooses business';
end;
$$;

select pg_temp.expect_error(format(
  $sql$select public.get_my_directory_onboarding(%L)$sql$,
  (select value from pg_temp.f2a_context where key = 'business_first_private')
), '42501');
select pg_temp.expect_error(format(
  $sql$select public.owner_set_directory_type(%L, 'cafe')$sql$,
  'f2b00000-0000-0000-0000-000000000004'
), '42501');
select pg_temp.expect_error(format(
  $sql$select public.owner_replace_directory_hours(%L, '[]'::jsonb)$sql$,
  'f2b00000-0000-0000-0000-000000000004'
), '42501');
select pg_temp.expect_error(format(
  $sql$select public.owner_replace_directory_menu(%L, '[]'::jsonb)$sql$,
  'f2b00000-0000-0000-0000-000000000004'
), '42501');
select pg_temp.expect_error(format(
  $sql$select public.get_my_directory_onboarding(%L)$sql$,
  'f2b00000-0000-0000-0000-000000000004'
), '42501');
select pg_temp.expect_error(format(
  $sql$select public.owner_upsert_directory_profile(
    p_seller_id=>%L,p_type=>'cafe',
    p_description=>'A valid foreign owner RPC profile description.',
    p_phone=>'030 999999',p_website=>null,p_cover_image_path=>null,
    p_languages=>array['german']::public.directory_spoken_language[],
    p_cuisines=>array['international']::public.directory_cuisine[],
    p_price_level=>1::smallint)$sql$,
  'f2b00000-0000-0000-0000-000000000004'
), '42501');

-- The profile trigger deliberately contains no caller-ownership check. Prove the
-- table's owner-write RLS alone rejects a direct foreign INSERT and exposes no row
-- to a direct foreign UPDATE; the legitimate owner's row remains byte-for-byte intact.
select pg_temp.act_as('f2a00000-0000-0000-0000-000000000004');
select pg_temp.expect_error(format(
  $sql$insert into public.business_directory_profiles(
      seller_id,type,description,phone,languages,cuisines,price_level,is_published
    ) values(
      %L,'cafe','A direct foreign profile insert that RLS must reject.',
      '030 444444',array['german']::public.directory_spoken_language[],
      array['international']::public.directory_cuisine[],1::smallint,false
    )$sql$,
  (select value from pg_temp.f2a_context where key='private_first_business')
), '42501');
do $$
declare
  changed integer;
begin
  update public.business_directory_profiles
  set description = 'A direct foreign profile update that RLS must reject.'
  where seller_id = (
    select value::uuid from pg_temp.f2a_context
    where key = 'business_first_business'
  );
  get diagnostics changed = row_count;
  assert changed = 0,
    'foreign direct profile UPDATE sees no writable row through owner RLS';
end;
$$;

select pg_temp.act_as('f2a00000-0000-0000-0000-000000000002');
do $$
begin
  assert (select description =
      'A deterministic F2a restaurant profile used for identity acceptance.'
    from public.business_directory_profiles
    where seller_id = (
      select value::uuid from pg_temp.f2a_context
      where key = 'business_first_business'
    )), 'foreign direct UPDATE leaves the owner profile unchanged';
end;
$$;

-- The explicit directory creator also rejects a foreign private identity before
-- it can create a business for the caller.
select pg_temp.act_as('f2a00000-0000-0000-0000-000000000001');
select pg_temp.expect_error(format(
  $sql$select public.owner_start_directory(
    %L,'cafe','Foreign Private Start','Berlin')$sql$,
  (select value from pg_temp.f2a_context where key='business_first_private')
), '42501');
select pg_temp.act_as('f2a00000-0000-0000-0000-000000000002');

-- Directory covers require an exact owned business path.
do $$
declare
  business_id uuid := (select value::uuid from pg_temp.f2a_context
    where key = 'business_first_business');
  cover_path text := business_id::text || '/f2c00000-0000-0000-0000-000000000010.webp';
begin
  assert public.can_manage_directory_cover_path(cover_path);
  assert not public.can_manage_directory_cover_path(
    (select value from pg_temp.f2a_context where key = 'business_first_private')
    || '/f2c00000-0000-0000-0000-000000000011.webp'
  );
  insert into storage.objects(bucket_id, name, owner, metadata)
  values('directory-covers', cover_path, auth.uid(), '{"mimetype":"image/webp"}');
  insert into pg_temp.f2a_context values ('business_first_cover', cover_path);
end;
$$;

select pg_temp.expect_error(format(
  $sql$insert into storage.objects(bucket_id,name,owner,metadata)
    values('directory-covers',%L,auth.uid(),'{"mimetype":"image/webp"}')$sql$,
  (select value from pg_temp.f2a_context where key = 'business_first_business')
    || '/nested/f2c00000-0000-0000-0000-000000000012.webp'
), '42501');
select pg_temp.expect_error(format(
  $sql$insert into storage.objects(bucket_id,name,owner,metadata)
    values('directory-covers',%L,auth.uid(),'{"mimetype":"image/gif"}')$sql$,
  (select value from pg_temp.f2a_context where key = 'business_first_business')
    || '/f2c00000-0000-0000-0000-000000000013.gif'
), '42501');
select pg_temp.expect_error(format(
  $sql$insert into storage.objects(bucket_id,name,owner,metadata)
    values('directory-covers',%L,auth.uid(),'{"mimetype":"image/webp"}')$sql$,
  'f2b00000-0000-0000-0000-000000000004/f2c00000-0000-0000-0000-000000000014.webp'
), '42501');

-- Create another owner's valid cover to prove profile-level cross-owner rejection.
select pg_temp.act_as('f2a00000-0000-0000-0000-000000000004');
insert into storage.objects(bucket_id, name, owner, metadata) values(
  'directory-covers',
  'f2b00000-0000-0000-0000-000000000004/f2c00000-0000-0000-0000-000000000015.webp',
  auth.uid(), '{"mimetype":"image/webp"}'
);

select pg_temp.act_as('f2a00000-0000-0000-0000-000000000002');
do $$
declare
  business_id uuid := (select value::uuid from pg_temp.f2a_context
    where key = 'business_first_business');
  cover_path text := (select value from pg_temp.f2a_context
    where key = 'business_first_cover');
begin
  perform public.owner_upsert_directory_profile(
    p_seller_id => business_id,
    p_type => 'restaurant',
    p_description => 'A deterministic F2a restaurant profile used for identity acceptance.',
    p_phone => '030 28092026',
    p_website => 'https://example.invalid/f2a',
    p_cover_image_path => cover_path,
    p_languages => array['german','kurdish']::public.directory_spoken_language[],
    p_cuisines => array['kurdish']::public.directory_cuisine[],
    p_price_level => 2::smallint,
    p_has_halal => true,
    p_is_published => true
  );
end;
$$;

select pg_temp.expect_error(format(
  $sql$select public.owner_upsert_directory_profile(
    p_seller_id=>%L,p_type=>'restaurant',p_description=>'A valid missing-object profile description.',
    p_phone=>'030 28092026',p_website=>null,p_cover_image_path=>%L,
    p_languages=>array['german']::public.directory_spoken_language[],
    p_cuisines=>array['kurdish']::public.directory_cuisine[],p_price_level=>2::smallint)$sql$,
  (select value from pg_temp.f2a_context where key = 'business_first_business'),
  (select value from pg_temp.f2a_context where key = 'business_first_business')
    || '/f2c00000-0000-0000-0000-000000000016.webp'
), '22023');
select pg_temp.expect_error(format(
  $sql$select public.owner_upsert_directory_profile(
    p_seller_id=>%L,p_type=>'restaurant',p_description=>'A valid cross-owner profile description.',
    p_phone=>'030 28092026',p_website=>null,p_cover_image_path=>%L,
    p_languages=>array['german']::public.directory_spoken_language[],
    p_cuisines=>array['kurdish']::public.directory_cuisine[],p_price_level=>2::smallint)$sql$,
  (select value from pg_temp.f2a_context where key = 'business_first_business'),
  'f2b00000-0000-0000-0000-000000000004/f2c00000-0000-0000-0000-000000000015.webp'
), '23514');

-- Storage's own SQL deletion guard prevents exercising object deletion directly in
-- a SQL suite. Assert that both mutable-object policies include the profile-reference
-- guard; upload/path/profile behavior above exercises the rest of the boundary.
do $$
declare
  update_guard text;
  delete_guard text;
begin
  select pg_get_expr(policy.polqual, policy.polrelid)
    into strict update_guard
  from pg_policy as policy
  where policy.polrelid = 'storage.objects'::regclass
    and policy.polname = 'directory_covers_update';
  select pg_get_expr(policy.polqual, policy.polrelid)
    into strict delete_guard
  from pg_policy as policy
  where policy.polrelid = 'storage.objects'::regclass
    and policy.polname = 'directory_covers_delete';
  assert update_guard like '%business_directory_profiles%cover_image_path%',
    'referenced covers cannot be renamed';
  assert delete_guard like '%business_directory_profiles%cover_image_path%',
    'referenced covers cannot be deleted';
end;
$$;

-- Submit one listing through each explicit identity and retain exact attachment.
set local role authenticated;
select pg_temp.act_as('f2a00000-0000-0000-0000-000000000002');
do $$
declare
  private_id uuid := (select value::uuid from pg_temp.f2a_context
    where key = 'business_first_private');
  business_id uuid := (select value::uuid from pg_temp.f2a_context
    where key = 'business_first_business');
  prepared jsonb;
  product_id uuid;
  image_path text;
  submitted jsonb;
begin
  prepared := public.prepare_listing_submission(
    private_id, 'private', 'Ignored', 'Berlin'
  );
  product_id := (prepared ->> 'product_id')::uuid;
  image_path := private_id || '/' || product_id || '/private.webp';
  insert into storage.objects(bucket_id,name,owner,metadata)
    values('product-images',image_path,auth.uid(),'{"mimetype":"image/webp"}');
  submitted := public.submit_listing(
    product_id, private_id, 'f2d00000-0000-0000-0000-000000000001',
    'F2a private listing', 'A private listing attached to the private identity.',
    'used', 3200, 'Berlin', array[image_path], '{"scope":"private"}', 4500
  );
  assert submitted ->> 'seller_id' = private_id::text;
  insert into pg_temp.f2a_context values ('private_product', product_id::text);

  prepared := public.prepare_listing_submission(
    business_id, 'business', 'Ignored', 'Berlin'
  );
  product_id := (prepared ->> 'product_id')::uuid;
  image_path := business_id || '/' || product_id || '/business.webp';
  insert into storage.objects(bucket_id,name,owner,metadata)
    values('product-images',image_path,auth.uid(),'{"mimetype":"image/webp"}');
  submitted := public.submit_listing(
    product_id, business_id, 'f2d00000-0000-0000-0000-000000000001',
    'F2a business listing', 'A business listing attached to the business identity.',
    'new', 6400, 'Berlin', array[image_path], '{"scope":"business"}'
  );
  assert submitted ->> 'seller_id' = business_id::text;
  insert into pg_temp.f2a_context values ('business_product', product_id::text);
end;
$$;

-- Listing moderation publishes both without changing either seller_id and adds
-- exact seller identity context to its existing notification payload.
select pg_temp.act_as('f2a00000-0000-0000-0000-000000000006', true);
do $$
declare
  product_id uuid;
  expected_seller uuid;
  result jsonb;
  notification_data jsonb;
begin
  for product_id, expected_seller in
    select value::uuid,
      case key when 'private_product' then
        (select value::uuid from pg_temp.f2a_context where key='business_first_private')
      else (select value::uuid from pg_temp.f2a_context where key='business_first_business') end
    from pg_temp.f2a_context
    where key in ('private_product','business_product')
    order by key
  loop
    result := public.moderate_listing(product_id, 'approve', null);
    assert (select seller_id = expected_seller and status = 'active'
      from public.products where id = product_id),
      'moderation preserves the submitted seller identity';
    select data into strict notification_data from public.notifications
      where id = (result ->> 'notification_id')::uuid;
    assert notification_data ->> 'sellerId' = expected_seller::text;
    assert notification_data ->> 'recipientRole' = 'seller';
    assert notification_data ? 'productId' and notification_data ? 'status';
  end loop;
end;
$$;

-- Private username profile never falls through to the business seller/listing.
set local request.jwt.claims = '{"role":"anon"}';
set local role anon;
do $$
declare
  profile jsonb := public.get_public_profile('F2A_BUSINESS_FIRST');
  private_id text := (select value from pg_temp.f2a_context
    where key = 'business_first_private');
begin
  assert profile -> 'seller' ->> 'id' = private_id;
  assert profile -> 'seller' ->> 'kind' = 'private';
  assert not (profile -> 'seller' ->> 'is_owned_by_current_user')::boolean;
  assert (profile ->> 'listing_count')::integer = 1,
    'only the private listing is projected';
  assert profile::text not like '%f2a00000-0000-0000-0000-000000000002%';
end;
$$;

set local role authenticated;
select pg_temp.act_as('f2a00000-0000-0000-0000-000000000002');
do $$
declare
  own_profile jsonb := public.get_my_profile();
  public_profile jsonb := public.get_public_profile('f2a_business_first');
begin
  assert own_profile -> 'seller' ->> 'id' =
    (select value from pg_temp.f2a_context where key='business_first_private');
  assert (own_profile ->> 'listing_count')::integer = 1;
  assert (public_profile -> 'seller' ->> 'is_owned_by_current_user')::boolean;
  assert (select bool_and(public.is_owned_by_current_user(seller))
    from public.sellers as seller where seller.user_id = auth.uid());
  assert not (select public.is_owned_by_current_user(seller)
    from public.sellers as seller
    where seller.id = 'f2b00000-0000-0000-0000-000000000004');
end;
$$;

-- Required business documents make the published directory profile verifiable.
reset role;
select pg_temp.clear_auth();
insert into public.seller_documents(
  seller_id, kind, storage_path, mime_type, status
) values
  ((select value::uuid from pg_temp.f2a_context where key='business_first_business'),
    'identity',
    (select value from pg_temp.f2a_context where key='business_first_business') || '/identity/f2a-approved.pdf',
    'application/pdf', 'approved'),
  ((select value::uuid from pg_temp.f2a_context where key='business_first_business'),
    'business_registration',
    (select value from pg_temp.f2a_context where key='business_first_business') || '/business_registration/f2a-approved.pdf',
    'application/pdf', 'approved');
do $$
begin
  assert public.is_verified_seller(
    (select value::uuid from pg_temp.f2a_context where key='business_first_business')
  );
end;
$$;

-- Same-user purchase and directory review guards operate at auth-user level,
-- not at whichever private/business seller is active on the device.
insert into public.orders(
  id, order_number, buyer_id, seller_id, status, payment_status,
  subtotal_cents, total_cents, shipping_address
) values
  ('f2e00000-0000-0000-0000-000000000001', 'ZR-F2A-SELF',
    'f2a00000-0000-0000-0000-000000000002',
    (select value::uuid from pg_temp.f2a_context where key='business_first_business'),
    'delivered', 'succeeded', 6400, 6400, '{}'),
  ('f2e00000-0000-0000-0000-000000000002', 'ZR-F2A-BUYER',
    'f2a00000-0000-0000-0000-000000000005',
    (select value::uuid from pg_temp.f2a_context where key='business_first_business'),
    'delivered', 'succeeded', 6400, 6400, '{}');
insert into public.order_items(
  id, order_id, product_id, seller_id, status, product_title, condition,
  quantity, unit_price_cents, vat_rate, total_cents
) values
  ('f2f00000-0000-0000-0000-000000000001',
    'f2e00000-0000-0000-0000-000000000001',
    (select value::uuid from pg_temp.f2a_context where key='business_product'),
    (select value::uuid from pg_temp.f2a_context where key='business_first_business'),
    'delivered', 'F2a business listing', 'new', 1, 6400, 0, 6400),
  ('f2f00000-0000-0000-0000-000000000002',
    'f2e00000-0000-0000-0000-000000000002',
    (select value::uuid from pg_temp.f2a_context where key='business_product'),
    (select value::uuid from pg_temp.f2a_context where key='business_first_business'),
    'delivered', 'F2a business listing', 'new', 1, 6400, 0, 6400);

set local role authenticated;
select pg_temp.act_as('f2a00000-0000-0000-0000-000000000002');
do $$
begin
  assert not public.can_review_order_item(
    'f2f00000-0000-0000-0000-000000000001', null,
    (select value::uuid from pg_temp.f2a_context where key='business_first_business'),
    'seller'
  ), 'person cannot review their own business seller';
end;
$$;
select pg_temp.expect_error(format(
  $sql$insert into public.reviews(
    kind,context,seller_id,order_item_id,reviewer_id,rating,body
  ) values('seller','purchase',%L,'f2f00000-0000-0000-0000-000000000001',auth.uid(),5,'Own business review')$sql$,
  (select value from pg_temp.f2a_context where key='business_first_business')
), '42501');
select pg_temp.expect_error(format(
  $sql$select public.upsert_directory_review(%L,5::smallint,'Own directory review')$sql$,
  (select value from pg_temp.f2a_context where key='business_first_business')
), '23514');

select pg_temp.act_as('f2a00000-0000-0000-0000-000000000005');
do $$
begin
  assert public.can_review_order_item(
    'f2f00000-0000-0000-0000-000000000002', null,
    (select value::uuid from pg_temp.f2a_context where key='business_first_business'),
    'seller'
  ), 'another buyer retains delivered-order review eligibility';
  assert public.upsert_directory_review(
    (select value::uuid from pg_temp.f2a_context where key='business_first_business'),
    5::smallint, 'A valid F2a directory review'
  ) ->> 'rating' = '5';
end;
$$;

-- No account can chat with either of its own seller identities.
select pg_temp.act_as('f2a00000-0000-0000-0000-000000000002');
select pg_temp.expect_error(format(
  $sql$select public.get_or_create_chat(%L)$sql$,
  (select value from pg_temp.f2a_context where key='business_first_private')
), '22023');
select pg_temp.expect_error(format(
  $sql$select public.get_or_create_chat(%L)$sql$,
  (select value from pg_temp.f2a_context where key='business_first_business')
), '22023');

-- Build the inbox matrix: this account is the person/buyer in one chat and the
-- exact private and business seller in two others.
do $$
declare
  chat public.chats;
begin
  chat := public.get_or_create_chat('f2b00000-0000-0000-0000-000000000004');
  insert into pg_temp.f2a_context values ('chat_as_buyer', chat.id::text);
end;
$$;
select pg_temp.act_as('f2a00000-0000-0000-0000-000000000005');
do $$
declare
  chat public.chats;
begin
  chat := public.get_or_create_chat(
    (select value::uuid from pg_temp.f2a_context where key='business_first_private')
  );
  insert into pg_temp.f2a_context values ('chat_as_private_seller', chat.id::text);
  chat := public.get_or_create_chat(
    (select value::uuid from pg_temp.f2a_context where key='business_first_business')
  );
  insert into pg_temp.f2a_context values ('chat_as_business_seller', chat.id::text);
end;
$$;

-- Incoming messages target each owned identity and the person-side buyer row.
insert into public.messages(chat_id,sender_id,kind,body) values
  ((select value::uuid from pg_temp.f2a_context where key='chat_as_private_seller'),
    auth.uid(),'text','Message to private identity'),
  ((select value::uuid from pg_temp.f2a_context where key='chat_as_business_seller'),
    auth.uid(),'text','Message to business identity');
select pg_temp.act_as('f2a00000-0000-0000-0000-000000000004');
insert into public.messages(chat_id,sender_id,kind,body) values(
  (select value::uuid from pg_temp.f2a_context where key='chat_as_buyer'),
  auth.uid(),'text','Message to person buyer'
);

-- An unread system row is deliberately excluded from both global and row counts.
reset role;
select pg_temp.clear_auth();
insert into public.messages(chat_id,kind,body,read_at) values(
  (select value::uuid from pg_temp.f2a_context where key='chat_as_business_seller'),
  'system','Unread system row must not count',null
);

set local role authenticated;
select pg_temp.act_as('f2a00000-0000-0000-0000-000000000002');
do $$
declare
  inbox jsonb := public.get_chat_inbox();
  private_item jsonb;
  business_item jsonb;
  buyer_item jsonb;
  private_id text := (select value from pg_temp.f2a_context where key='business_first_private');
  business_id text := (select value from pg_temp.f2a_context where key='business_first_business');
begin
  select item into strict private_item from jsonb_array_elements(inbox) item
    where item ->> 'id' = (select value from pg_temp.f2a_context where key='chat_as_private_seller');
  select item into strict business_item from jsonb_array_elements(inbox) item
    where item ->> 'id' = (select value from pg_temp.f2a_context where key='chat_as_business_seller');
  select item into strict buyer_item from jsonb_array_elements(inbox) item
    where item ->> 'id' = (select value from pg_temp.f2a_context where key='chat_as_buyer');

  assert private_item ->> 'viewer_role' = 'seller';
  assert private_item ->> 'viewer_identity_type' = 'person';
  assert private_item ->> 'viewer_seller_id' = private_id;
  assert private_item ->> 'seller_kind' = 'private';
  assert private_item ->> 'viewer_identity_name' = 'F2a Business First';

  assert business_item ->> 'viewer_role' = 'seller';
  assert business_item ->> 'viewer_identity_type' = 'business';
  assert business_item ->> 'viewer_seller_id' = business_id;
  assert business_item ->> 'seller_kind' = 'business';
  assert business_item ->> 'viewer_identity_name' = 'F2a Business First Shop';

  assert buyer_item ->> 'viewer_role' = 'buyer';
  assert buyer_item ->> 'viewer_identity_type' = 'person';
  assert buyer_item -> 'viewer_seller_id' = 'null'::jsonb;
  assert buyer_item ->> 'viewer_identity_name' = 'F2a Business First';
  assert buyer_item ->> 'seller_kind' = 'business';

  assert public.get_unread_chat_count() = 3,
    'unified count includes person/private/business incoming messages only';
  assert (select sum((item ->> 'unread_count')::integer)
    from jsonb_array_elements(inbox) item) = 3;
end;
$$;

-- Chat notifications bind recipient context to each immutable chat seller identity.
reset role;
select pg_temp.clear_auth();
do $$
declare
  data_row jsonb;
begin
  select data into strict data_row from public.notifications
    where user_id = 'f2a00000-0000-0000-0000-000000000002'
      and data ->> 'chatId' = (select value from pg_temp.f2a_context where key='chat_as_private_seller');
  assert data_row ->> 'sellerId' =
    (select value from pg_temp.f2a_context where key='business_first_private');
  assert data_row ->> 'sellerKind' = 'private';
  assert data_row ->> 'recipientRole' = 'seller';
  assert data_row ->> 'recipientIdentityType' = 'person';
  assert data_row ->> 'recipientSellerId' =
    (select value from pg_temp.f2a_context where key='business_first_private');
  assert data_row ? 'messageId' and data_row ? 'kind';

  select data into strict data_row from public.notifications
    where user_id = 'f2a00000-0000-0000-0000-000000000002'
      and data ->> 'chatId' = (select value from pg_temp.f2a_context where key='chat_as_business_seller');
  assert data_row ->> 'sellerId' =
    (select value from pg_temp.f2a_context where key='business_first_business');
  assert data_row ->> 'sellerKind' = 'business';
  assert data_row ->> 'recipientIdentityType' = 'business';

  select data into strict data_row from public.notifications
    where user_id = 'f2a00000-0000-0000-0000-000000000002'
      and data ->> 'chatId' = (select value from pg_temp.f2a_context where key='chat_as_buyer');
  assert data_row ->> 'sellerId' = 'f2b00000-0000-0000-0000-000000000004';
  assert data_row ->> 'recipientRole' = 'buyer';
  assert data_row ->> 'recipientIdentityType' = 'person';
  assert data_row ? 'recipientSellerId' and data_row -> 'recipientSellerId' = 'null'::jsonb;
end;
$$;

-- Order notifications preserve old keys and identify buyer-vs-seller recipient context.
do $$
declare
  buyer_data jsonb;
  seller_data jsonb;
begin
  select data into strict buyer_data from public.notifications
    where user_id = 'f2a00000-0000-0000-0000-000000000005'
      and data ->> 'orderId' = 'f2e00000-0000-0000-0000-000000000002';
  assert buyer_data ->> 'sellerId' =
    (select value from pg_temp.f2a_context where key='business_first_business');
  assert buyer_data ->> 'sellerKind' = 'business';
  assert buyer_data ->> 'recipientRole' = 'buyer';
  assert buyer_data ? 'orderNumber' and buyer_data ? 'paymentStatus';

  select data into strict seller_data from public.notifications
    where user_id = 'f2a00000-0000-0000-0000-000000000002'
      and data ->> 'orderId' = 'f2e00000-0000-0000-0000-000000000002';
  assert seller_data ->> 'recipientRole' = 'seller';
  assert seller_data ->> 'recipientIdentityType' = 'business';
  assert seller_data ->> 'recipientSellerId' =
    (select value from pg_temp.f2a_context where key='business_first_business');
end;
$$;

-- Price-drop notifications remain account-level buyer notifications with seller context.
set local role authenticated;
select pg_temp.act_as('f2a00000-0000-0000-0000-000000000005');
insert into public.favorites(user_id,product_id) values(
  auth.uid(), (select value::uuid from pg_temp.f2a_context where key='private_product')
);
reset role;
select pg_temp.clear_auth();
update public.products set price_cents = 2800
where id = (select value::uuid from pg_temp.f2a_context where key='private_product');
set local role authenticated;
select pg_temp.act_as('f2a00000-0000-0000-0000-000000000005');
do $$
declare
  data_row jsonb;
begin
  select data into strict data_row from public.notifications
    where user_id = auth.uid() and kind = 'price_drop'
      and data ->> 'productId' = (select value from pg_temp.f2a_context where key='private_product');
  assert data_row ->> 'sellerId' =
    (select value from pg_temp.f2a_context where key='business_first_private');
  assert data_row ->> 'sellerKind' = 'private';
  assert data_row ->> 'recipientRole' = 'buyer';
  assert data_row ->> 'recipientIdentityType' = 'person';
  assert data_row ? 'oldPriceCents' and data_row ? 'newPriceCents';
end;
$$;

-- Seller-document moderation and report blocking also retain old payload keys while
-- routing to the exact business identity.
reset role;
select pg_temp.clear_auth();
insert into public.seller_documents(
  id,seller_id,kind,storage_path,mime_type,status
) values(
  'f2c00000-0000-0000-0000-000000000020',
  (select value::uuid from pg_temp.f2a_context where key='business_first_business'),
  'other',
  (select value from pg_temp.f2a_context where key='business_first_business') || '/other/f2a-pending.pdf',
  'application/pdf','pending'
);
insert into public.reports(id,reporter_id,product_id,reason) values(
  'f2c00000-0000-0000-0000-000000000021',
  'f2a00000-0000-0000-0000-000000000005',
  (select value::uuid from pg_temp.f2a_context where key='business_product'),
  'spam'
);

set local role authenticated;
select pg_temp.act_as('f2a00000-0000-0000-0000-000000000006', true);
do $$
declare
  result jsonb;
  data_row jsonb;
begin
  result := public.moderate_seller_document(
    'f2c00000-0000-0000-0000-000000000020','approve',null
  );
  select data into strict data_row from public.notifications
    where user_id = 'f2a00000-0000-0000-0000-000000000002'
      and data ->> 'documentId' = 'f2c00000-0000-0000-0000-000000000020';
  assert data_row ->> 'sellerId' =
    (select value from pg_temp.f2a_context where key='business_first_business');
  assert data_row ->> 'sellerKind' = 'business';
  assert data_row ->> 'recipientRole' = 'seller';
  assert data_row ? 'kind';

  result := public.resolve_report(
    'f2c00000-0000-0000-0000-000000000021','block_listing','F2a report block'
  );
  assert result ->> 'product_status' = 'blocked';
  select data into strict data_row from public.notifications
    where user_id = 'f2a00000-0000-0000-0000-000000000002'
      and data ->> 'productId' = (select value from pg_temp.f2a_context where key='business_product')
      and title_key = 'notifications.listing.blocked.title';
  assert data_row ->> 'sellerId' =
    (select value from pg_temp.f2a_context where key='business_first_business');
  assert data_row ->> 'sellerKind' = 'business';
  assert data_row ->> 'recipientIdentityType' = 'business';
  assert data_row ->> 'reason' = 'F2a report block';
end;
$$;

-- Anonymous ownership probes are always false, even for visible approved sellers.
set local request.jwt.claims = '{"role":"anon"}';
set local role anon;
do $$
begin
  assert not exists (
    select 1 from public.sellers as seller
    where seller.id in (
      (select value::uuid from pg_temp.f2a_context where key='business_first_private'),
      (select value::uuid from pg_temp.f2a_context where key='business_first_business'),
      'f2b00000-0000-0000-0000-000000000004'
    ) and public.is_owned_by_current_user(seller)
  );
end;
$$;

reset role;
select pg_temp.clear_auth();

-- Every assertion and fixture above is non-persistent by contract.
rollback;
