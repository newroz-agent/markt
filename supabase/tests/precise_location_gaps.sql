-- Acceptance for 20260927000800_precise_location_gaps.sql. Uses the seeded Atelier Lale
-- (Step D) and its own fixtures. Everything rolls back.
begin;

create function pg_temp.expect_error(command text, expected_state text)
returns void language plpgsql as $$
begin
  begin execute command;
  exception when others then
    assert sqlstate = expected_state,
      format('Expected SQLSTATE %s, got %s (%s)',expected_state,sqlstate,sqlerrm);
    return;
  end;
  raise exception 'Expected command to fail: %',command;
end; $$;

create function pg_temp.act_as(user_id text, admin boolean default false)
returns void language sql as $$
  select set_config('request.jwt.claims', jsonb_build_object('sub',user_id,'role','authenticated',
    'app_metadata', case when admin then '{"role":"admin"}'::jsonb else '{}'::jsonb end)::text, true);
$$;

create function pg_temp.pin_state(target text)
returns text language sql as $$
  select concat_ws('|', status, precise_location_opt_in::text, (latitude is not null)::text,
    (longitude is not null)::text, (address_line is not null)::text)
  from public.sellers where shop_name = target or id::text = target;
$$;

do $$ begin
  assert pg_temp.pin_state('Atelier Lale') = 'approved|true|true|true|true',
    format('precondition: Atelier Lale is an approved, opted-in precise pin: %s', pg_temp.pin_state('Atelier Lale'));
  assert public.is_verified_seller((select id from public.sellers where shop_name='Atelier Lale'));
end $$;

insert into auth.users(id,email,raw_user_meta_data) values
 ('e8100000-0000-0000-0000-000000000001','e8-admin@example.invalid','{"display_name":"E8 Admin"}'),
 ('e8100000-0000-0000-0000-000000000002','e8-doctor@example.invalid','{"display_name":"E8 Doctor"}'),
 ('e8100000-0000-0000-0000-000000000003','e8-restaurant@example.invalid','{"display_name":"E8 Restaurant"}'),
 ('e8100000-0000-0000-0000-000000000004','e8-pending@example.invalid','{"display_name":"E8 Pending"}'),
 ('e8100000-0000-0000-0000-000000000005','e8-rejectable@example.invalid','{"display_name":"E8 Rejectable"}');

insert into public.sellers(id,user_id,kind,status,shop_name,slug,city,country_code) values
 ('e8200000-0000-0000-0000-000000000002','e8100000-0000-0000-0000-000000000002','business','approved','E8 Praxis','e8-praxis','Berlin','DE'),
 ('e8200000-0000-0000-0000-000000000003','e8100000-0000-0000-0000-000000000003','business','approved','E8 Restaurant','e8-restaurant','Berlin','DE'),
 ('e8200000-0000-0000-0000-000000000004','e8100000-0000-0000-0000-000000000004','business','pending','E8 Pending','e8-pending','Berlin','DE'),
 ('e8200000-0000-0000-0000-000000000005','e8100000-0000-0000-0000-000000000005','business','approved','E8 Rejectable','e8-rejectable','Berlin','DE');
insert into public.seller_documents(seller_id,kind,storage_path,mime_type,status) values
 ('e8200000-0000-0000-0000-000000000002','identity','e8200000-0000-0000-0000-000000000002/identity/a.pdf','application/pdf','approved'),
 ('e8200000-0000-0000-0000-000000000002','medical_professional_registration','e8200000-0000-0000-0000-000000000002/medical/b.pdf','application/pdf','approved'),
 ('e8200000-0000-0000-0000-000000000003','identity','e8200000-0000-0000-0000-000000000003/identity/a.pdf','application/pdf','approved'),
 ('e8200000-0000-0000-0000-000000000003','business_registration','e8200000-0000-0000-0000-000000000003/business/b.pdf','application/pdf','approved'),
 ('e8200000-0000-0000-0000-000000000005','identity','e8200000-0000-0000-0000-000000000005/identity/a.pdf','application/pdf','approved'),
 ('e8200000-0000-0000-0000-000000000005','business_registration','e8200000-0000-0000-0000-000000000005/business/b.pdf','application/pdf','approved');
insert into public.business_directory_profiles(seller_id,type,description,phone,languages,cuisines,price_level,specialty,insurance,is_published) values
 ('e8200000-0000-0000-0000-000000000002','doctor','A doctor fixture for the precise-location gaps test.','030 800002',
  array['german']::public.directory_spoken_language[],'{}',null,'general_medicine','both',true),
 ('e8200000-0000-0000-0000-000000000003','restaurant','A restaurant fixture for the precise-location gaps test.','030 800003',
  array['german']::public.directory_spoken_language[],array['kurdish']::public.directory_cuisine[],2,null,null,true);
update public.sellers set precise_location_opt_in=true, latitude=52.5, longitude=13.4, address_line='Teststraße 1'
where id in ('e8200000-0000-0000-0000-000000000002','e8200000-0000-0000-0000-000000000003','e8200000-0000-0000-0000-000000000005');

-- Gap 1: an admin suspends Atelier Lale; the write succeeds and takes the pin down.
set local role authenticated;
select pg_temp.act_as('e8100000-0000-0000-0000-000000000001',true);
update public.sellers set status='suspended' where shop_name='Atelier Lale';
update public.sellers set status='rejected', rejection_reason='Test rejection'
where id='e8200000-0000-0000-0000-000000000005';
reset role;
do $$ begin
  assert pg_temp.pin_state('Atelier Lale') = 'suspended|false|false|false|false',
    format('suspension clears the public pin: %s', pg_temp.pin_state('Atelier Lale'));
  assert exists(select 1 from public.seller_status_history h join public.sellers s on s.id=h.seller_id
    where s.shop_name='Atelier Lale' and h.from_status='approved' and h.to_status='suspended'
      and h.actor_user_id='e8100000-0000-0000-0000-000000000001'), 'suspension recorded with the admin';
  assert pg_temp.pin_state('e8200000-0000-0000-0000-000000000005') = 'rejected|false|false|false|false',
    'rejection clears the public pin';
end $$;

-- Re-approval does not republish anything: the pin stays down until the owner publishes.
set local role authenticated;
select pg_temp.act_as('e8100000-0000-0000-0000-000000000001',true);
update public.sellers set status='approved' where shop_name='Atelier Lale';
reset role;
do $$ begin
  assert pg_temp.pin_state('Atelier Lale') = 'approved|false|false|false|false',
    'the pin is not restored automatically after re-approval';
end $$;

-- Not weakened: publishing a pin while ineligible still raises.
select pg_temp.expect_error($$update public.sellers set precise_location_opt_in=true, latitude=52.5, longitude=13.4
  where id='e8200000-0000-0000-0000-000000000004'$$,'42501');
select pg_temp.expect_error($$update public.sellers set precise_location_opt_in=true, latitude=52.5, longitude=13.4
  where id='e8200000-0000-0000-0000-000000000005'$$,'42501');

-- Gap 2: a doctor verified by the medical proof changes the profile to café. Without a
-- business registration it is no longer verified, so the pin is wiped.
set local role authenticated;
select pg_temp.act_as('e8100000-0000-0000-0000-000000000002');
select public.owner_upsert_directory_profile(
  p_type=>'cafe',p_description=>'The doctor fixture now claims to be a cafe for this test.',
  p_phone=>'030 800002',p_website=>null,p_cover_image_path=>null,
  p_languages=>array['german']::public.directory_spoken_language[],
  p_cuisines=>array['international']::public.directory_cuisine[],p_price_level=>1::smallint);
reset role;
do $$ begin
  assert not public.is_verified_seller('e8200000-0000-0000-0000-000000000002');
  assert pg_temp.pin_state('e8200000-0000-0000-0000-000000000002') = 'approved|false|false|false|false',
    format('type change that loses verification wipes the pin: %s',
      pg_temp.pin_state('e8200000-0000-0000-0000-000000000002'));
end $$;

-- A type change that keeps verification (restaurant -> fast food) keeps the pin.
set local role authenticated;
select pg_temp.act_as('e8100000-0000-0000-0000-000000000003');
select public.owner_upsert_directory_profile(
  p_type=>'fast_food',p_description=>'A restaurant fixture for the precise-location gaps test.',
  p_phone=>'030 800003',p_website=>null,p_cover_image_path=>null,
  p_languages=>array['german']::public.directory_spoken_language[],
  p_cuisines=>array['kurdish']::public.directory_cuisine[],p_price_level=>2::smallint);
reset role;
do $$ begin
  assert public.is_verified_seller('e8200000-0000-0000-0000-000000000003');
  assert pg_temp.pin_state('e8200000-0000-0000-0000-000000000003') = 'approved|true|true|true|true',
    'a type change that keeps verification keeps the pin';
end $$;

-- Changing to doctor without a medical proof loses verification and wipes the pin.
set local role authenticated;
select pg_temp.act_as('e8100000-0000-0000-0000-000000000003');
select public.owner_upsert_directory_profile(
  p_type=>'doctor',p_description=>'A restaurant fixture that becomes a doctor for this test.',
  p_phone=>'030 800003',p_website=>null,p_cover_image_path=>null,
  p_languages=>array['german']::public.directory_spoken_language[],
  p_specialty=>'other',p_insurance=>'both');
reset role;
do $$ begin
  assert pg_temp.pin_state('e8200000-0000-0000-0000-000000000003') = 'approved|false|false|false|false',
    'becoming a doctor without medical proof wipes the pin';
end $$;

rollback;
