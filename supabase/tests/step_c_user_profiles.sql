-- Local effective migrated DB only. All Step C fixtures roll back.
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

create table pg_temp.step_c_context (
  key text primary key,
  value text not null
);
grant all on pg_temp.step_c_context to authenticated;
grant select on pg_temp.step_c_context to anon;

insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
values
  ('c1000000-0000-0000-0000-000000000001', 'step-c-owner@example.invalid',
   '{"display_name":"Initial Owner"}', '{}'),
  ('c1000000-0000-0000-0000-000000000002', 'step-c-buyer@example.invalid',
   '{"display_name":"Buyer Person"}', '{}'),
  ('c1000000-0000-0000-0000-000000000003', 'step-c-business@example.invalid',
   '{"display_name":"Business Operator"}', '{}'),
  ('c1000000-0000-0000-0000-000000000004', 'step-c-admin@example.invalid',
   '{"display_name":"Platform Admin"}', '{"role":"admin"}');

insert into public.categories (
  id, slug, name_de, name_en, name_ar, name_tr, name_ku,
  icon_key, image_url, is_active
) values (
  'c2000000-0000-0000-0000-000000000001',
  'step-c-category', 'Test', 'Test', 'اختبار', 'Test', 'Test',
  'test', 'https://example.invalid/category.webp', true
);

insert into public.sellers (
  id, user_id, kind, status, shop_name, slug, city, country_code
) values
  ('c3000000-0000-0000-0000-000000000001',
   'c1000000-0000-0000-0000-000000000001',
   'private', 'approved', 'Stale Seller Name', 'step-c-private', 'Berlin', 'DE'),
  ('c3000000-0000-0000-0000-000000000002',
   'c1000000-0000-0000-0000-000000000003',
   'business', 'approved', 'Trusted Store', 'trusted-store', 'Hamburg', 'DE');

insert into public.seller_documents (
  seller_id, kind, storage_path, mime_type, status
) values
  ('c3000000-0000-0000-0000-000000000002', 'identity',
   'step-c/identity.pdf', 'application/pdf', 'approved'),
  ('c3000000-0000-0000-0000-000000000002', 'business_registration',
   'step-c/business.pdf', 'application/pdf', 'approved');

insert into public.products (
  id, seller_id, category_id, title, slug, description,
  condition, status, price_cents, city, country_code
) values
  ('c4000000-0000-0000-0000-000000000001',
   'c3000000-0000-0000-0000-000000000001',
   'c2000000-0000-0000-0000-000000000001',
   'Step C active listing', 'step-c-active', 'Public active profile listing.',
   'used', 'active', 2500, 'Berlin', 'DE'),
  ('c4000000-0000-0000-0000-000000000002',
   'c3000000-0000-0000-0000-000000000001',
   'c2000000-0000-0000-0000-000000000001',
   'Step C pending listing', 'step-c-pending', 'Private pending profile listing.',
   'used', 'pending_review', 2600, 'Berlin', 'DE'),
  ('c4000000-0000-0000-0000-000000000003',
   'c3000000-0000-0000-0000-000000000001',
   'c2000000-0000-0000-0000-000000000001',
   'Step C rejected listing', 'step-c-rejected', 'Private rejected profile listing.',
   'used', 'rejected', 2700, 'Berlin', 'DE'),
  ('c4000000-0000-0000-0000-000000000004',
   'c3000000-0000-0000-0000-000000000001',
   'c2000000-0000-0000-0000-000000000001',
   'Step C blocked listing', 'step-c-blocked', 'Private blocked profile listing.',
   'used', 'blocked', 2800, 'Berlin', 'DE');

set local role authenticated;
set local request.jwt.claims = '{"sub":"c1000000-0000-0000-0000-000000000001","role":"authenticated"}';

do $$
#variable_conflict use_variable
declare
  availability text;
  profile jsonb;
  prepared jsonb;
  avatar_path text;
  committed jsonb;
begin
  availability := public.check_profile_username('Alice_Name');
  assert availability = 'available', 'New username is available';

  profile := public.update_my_profile(
    'Alice Public', 'Alice_Name', 'Berlin',
    'Eine kurze öffentliche Biografie.'
  );
  assert profile ->> 'display_name' = 'Alice Public';
  assert profile ->> 'username' = 'alice_name',
    'Username is normalized to lowercase';
  assert profile ->> 'city' = 'Berlin';
  assert profile ->> 'bio' = 'Eine kurze öffentliche Biografie.';
  assert not (profile ? 'id') and not (profile ? 'email') and not (profile ? 'phone'),
    'Own profile RPC still avoids returning private account identifiers';
  assert public.check_profile_username('ALICE_NAME') = 'available',
    'Current username remains available to its owner';

  prepared := public.prepare_profile_avatar_upload();
  avatar_path := prepared ->> 'avatar_object';
  assert public.can_manage_profile_avatar_path(avatar_path),
    'Opaque reserved avatar path belongs to the current profile';
  assert split_part(avatar_path, '/', 1) <> auth.uid()::text,
    'Opaque avatar path never exposes auth UUID';
  assert avatar_path ~ '\.webp$', 'Avatar reservation is WebP';

  insert into storage.objects (bucket_id, name, owner, metadata)
  values ('avatars', avatar_path, auth.uid(), '{"mimetype":"image/webp"}');
  committed := public.commit_profile_avatar(avatar_path);
  assert committed ->> 'avatar_object' = avatar_path;
  assert committed ->> 'previous_avatar_object' is null;
  assert (select p.avatar_path = avatar_path from public.profiles as p
    where p.id = auth.uid()), 'Committed object is stored on own profile';

  insert into pg_temp.step_c_context values ('avatar_path', avatar_path);
end;
$$;

select pg_temp.expect_error(
  $q$update public.profiles set avatar_path='arbitrary/object.webp'
    where id=auth.uid()$q$,
  '42501'
);
select pg_temp.expect_error(
  $q$insert into storage.objects (bucket_id,name,owner,metadata)
    values ('avatars','c1000000-0000-0000-0000-000000000001/bad.webp',auth.uid(),
      '{"mimetype":"image/webp"}')$q$,
  '42501'
);

set local request.jwt.claims = '{"sub":"c1000000-0000-0000-0000-000000000002","role":"authenticated"}';

do $$ begin
  assert public.check_profile_username('ALICE_NAME') = 'taken',
    'Case-insensitive conflict is reported';
  assert public.check_profile_username('root') = 'reserved',
    'System username is reserved';
  assert public.check_profile_username('trusted_store') = 'reserved',
    'Verified business identity cannot be impersonated';
  assert public.check_profile_username('ab') = 'invalid',
    'Length and safe-character rules are server-backed';
  assert not public.can_manage_profile_avatar_path(
    (select value from pg_temp.step_c_context where key='avatar_path')
  ), 'Another user cannot manage an opaque avatar path';
end $$;

select pg_temp.expect_error(
  $q$select public.update_my_profile('Conflict', 'ALICE_NAME', 'Hamburg', null)$q$,
  '23505'
);
select pg_temp.expect_error(
  $q$select public.update_my_profile('Reserved', 'trusted_store', 'Hamburg', null)$q$,
  '22023'
);
select pg_temp.expect_error(
  $q$select public.update_my_profile('Missing username', '', 'Hamburg', null)$q$,
  '22023'
);

select public.update_my_profile(
  'Buyer Person', 'buyer_profile', 'Hamburg', 'Käuferprofil'
);

-- Public profile message handoff reuses the existing productless seller chat RPC.
do $$
declare
  chat public.chats;
  inbox jsonb;
begin
  chat := public.get_or_create_chat(
    'c3000000-0000-0000-0000-000000000001', null
  );
  assert chat.product_id is null, 'Profile chat has no duplicate product path';
  inbox := public.get_chat_inbox(chat.id);
  assert jsonb_array_length(inbox) = 1;
  assert inbox -> 0 ->> 'shop_name' = 'Alice Public',
    'Private seller chat identity comes from public.profiles';
  assert inbox -> 0 ->> 'shop_profile_username' = 'alice_name';
  assert inbox -> 0 ->> 'shop_avatar_url' =
    (select value from pg_temp.step_c_context where key='avatar_path');
end;
$$;

set local role anon;
set local request.jwt.claims = '{"role":"anon"}';

do $$
#variable_conflict use_variable
declare
  profile jsonb := public.get_public_profile('ALICE_NAME');
  summaries jsonb := public.get_public_profile_summaries(
    array['c3000000-0000-0000-0000-000000000001'::uuid]
  );
  avatar_path text := (select value from pg_temp.step_c_context where key='avatar_path');
begin
  assert (select count(*) = 0 from public.profiles),
    'Mixed private profile rows remain hidden from anonymous callers';
  assert profile is not null;
  assert profile ->> 'display_name' = 'Alice Public';
  assert profile ->> 'username' = 'alice_name';
  assert profile ->> 'city' = 'Berlin';
  assert (profile ->> 'listing_count')::int = 1;
  assert profile ->> 'avatar_object' = avatar_path;
  assert not (profile ? 'id')
    and not (profile ? 'email')
    and not (profile ? 'phone')
    and not (profile ? 'avatar_path')
    and not (profile ? 'notification_preferences')
    and not (profile ? 'analytics_consent'),
    'Public projection omits auth/private profile columns and raw column names';
  assert profile::text not like '%step-c-owner@example.invalid%';
  assert profile::text not like '%c1000000-0000-0000-0000-000000000001%';
  assert profile -> 'seller' ->> 'id' =
    'c3000000-0000-0000-0000-000000000001',
    'Only the non-auth seller ID is projected for chat/listings';
  assert public.get_public_profile('missing_profile') is null;

  assert jsonb_array_length(summaries) = 1;
  assert summaries -> 0 ->> 'display_name' = 'Alice Public';
  assert summaries::text not like '%c1000000-0000-0000-0000-000000000001%';
  assert summaries::text not like '%step-c-owner@example.invalid%';

  assert (select count(*) = 1 from public.products
    where seller_id = 'c3000000-0000-0000-0000-000000000001'),
    'Public RLS reveals only the active profile listing';
  assert not exists (
    select 1 from public.products
    where id in (
      'c4000000-0000-0000-0000-000000000002',
      'c4000000-0000-0000-0000-000000000003',
      'c4000000-0000-0000-0000-000000000004'
    )
  ), 'Pending, rejected, and blocked listings never reach public profiles';
  assert (select count(*) = 0 from public.seller_private_details),
    'Sensitive seller details remain private';
end;
$$;

set local role authenticated;
set local request.jwt.claims = '{"sub":"c1000000-0000-0000-0000-000000000004","role":"authenticated","app_metadata":{"role":"admin"}}';

update public.sellers
set precise_location_opt_in = true,
    latitude = 53.551086,
    longitude = 9.993682,
    address_line = '  Mönckebergstraße 1  '
where id = 'c3000000-0000-0000-0000-000000000002';

do $$ begin
  assert (select precise_location_opt_in
      and latitude = 53.551086
      and longitude = 9.993682
      and address_line = 'Mönckebergstraße 1'
    from public.sellers
    where id = 'c3000000-0000-0000-0000-000000000002'),
    'Verified opted-in business can store its public precise point';
end $$;

select pg_temp.expect_error(
  $q$update public.sellers set precise_location_opt_in=true,
      latitude=52.5,longitude=13.4,address_line='Private address'
    where id='c3000000-0000-0000-0000-000000000001'$q$,
  '42501'
);

update public.seller_documents
set status = 'rejected'
where seller_id = 'c3000000-0000-0000-0000-000000000002'
  and kind = 'identity';

do $$ begin
  assert (select not precise_location_opt_in
      and latitude is null and longitude is null and address_line is null
    from public.sellers
    where id = 'c3000000-0000-0000-0000-000000000002'),
    'Revoked verification immediately clears precise public location';
end $$;

select pg_temp.expect_error(
  $q$update public.sellers set precise_location_opt_in=true,
      latitude=53.5,longitude=10.0,address_line='No longer verified'
    where id='c3000000-0000-0000-0000-000000000002'$q$,
  '42501'
);

set local request.jwt.claims = '{"sub":"c1000000-0000-0000-0000-000000000001","role":"authenticated"}';

do $$
#variable_conflict use_variable
declare
  cleared jsonb;
  avatar_path text := (select value from pg_temp.step_c_context where key='avatar_path');
begin
  cleared := public.clear_my_profile_avatar();
  assert cleared ->> 'previous_avatar_object' = avatar_path;
  assert (select p.avatar_path is null from public.profiles as p where p.id = auth.uid());
  assert exists (
    select 1 from storage.objects
    where bucket_id = 'avatars' and name = avatar_path
  ), 'Clear returns the object key for subsequent Storage API deletion';
end;
$$;

reset role;
rollback;
