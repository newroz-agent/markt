-- Step E1.5 acceptance against the effective local schema. All fixtures roll back.
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

create function pg_temp.fixture_places(first_name text default 'E15 Imbiss Eins')
returns jsonb language sql as $$
  select jsonb_build_array(
    jsonb_build_object('osm_type','node','osm_id',990000000000001,'name',first_name,'type','fast_food',
      'cuisines',jsonb_build_array('kebab','turkish'),'osm_cuisine','turkish;kebab;pizza',
      'latitude',52.4990,'longitude',13.4180,'addr_street','Oranienstraße','addr_housenumber','1',
      'addr_postcode','10999','addr_city','Berlin','phone','+49 30 1234567','website','https://example.invalid',
      'email','e15-secret-one@example.invalid','has_halal',true,'has_vegetarian',null,'has_vegan',null,
      'hours',jsonb_build_array(jsonb_build_object('weekday',1,'opens_at','22:00','closes_at','02:00'))),
    jsonb_build_object('osm_type','way','osm_id',990000000000002,'name','E15 Restaurant Zwei','type','restaurant',
      'cuisines',jsonb_build_array('lebanese'),'osm_cuisine','lebanese',
      'latitude',52.5000,'longitude',13.4000,'email','e15-secret-two@example.invalid','hours','[]'::jsonb),
    jsonb_build_object('osm_type','node','osm_id',990000000000003,'name','=E15 Formula Café','type','cafe',
      'cuisines',jsonb_build_array('arabic'),'osm_cuisine','arab',
      'latitude',52.5100,'longitude',13.3900,'email',null,'hours','[]'::jsonb)
  );
$$;

do $$ begin
  assert exists(select 1 from pg_enum e join pg_type t on t.oid=e.enumtypid
    where t.typname='directory_business_type' and e.enumlabel='fast_food');
  assert (select count(*) from pg_enum e join pg_type t on t.oid=e.enumtypid
    where t.typname='directory_cuisine'
      and e.enumlabel in ('lebanese','iraqi','middle_eastern','kebab','falafel'))=5;
  assert not has_table_privilege('anon','public.directory_outreach_contacts','select'),
    'anon has no table privilege on outreach contacts';
  assert not has_table_privilege('authenticated','public.directory_outreach_contacts','select'),
    'authenticated has no table privilege on outreach contacts';
  assert not has_table_privilege('authenticated','public.directory_import_suppressions','select');
  assert not has_table_privilege('anon','public.directory_imported_places','select');
  assert not has_function_privilege('anon','public.import_osm_directory_places(jsonb,date)','execute');
  assert not has_function_privilege('authenticated','public.import_osm_directory_places(jsonb,date)','execute');
end $$;

insert into auth.users(id,email,raw_user_meta_data) values
 ('e1500000-0000-0000-0000-000000000001','e15-admin@example.invalid','{"display_name":"E15 Admin"}'),
 ('e1500000-0000-0000-0000-000000000002','e15-user@example.invalid','{"display_name":"E15 User"}'),
 ('e1500000-0000-0000-0000-000000000003','e15-owner@example.invalid','{"display_name":"E15 Owner"}');

insert into public.sellers(id,user_id,kind,status,shop_name,slug,city,country_code,approved_at)
values ('e1510000-0000-0000-0000-000000000001','e1500000-0000-0000-0000-000000000003',
  'business','approved','E15 Owner Imbiss','e15-owner-imbiss','Berlin','DE',now());
insert into public.seller_documents(seller_id,kind,storage_path,mime_type,status) values
 ('e1510000-0000-0000-0000-000000000001','identity','e15/identity.pdf','application/pdf','approved'),
 ('e1510000-0000-0000-0000-000000000001','business_registration','e15/business.pdf','application/pdf','approved');

-- First import inserts every fixture and creates one outreach row per place.
do $$
declare result jsonb;
begin
  result:=public.import_osm_directory_places(pg_temp.fixture_places(),'2026-09-27');
  assert (result->>'inserted')::int=3, format('first import inserts 3: %s',result);
  assert (select count(*) from public.directory_outreach_contacts contact
    join public.directory_imported_places place on place.id=contact.place_id
    where place.osm_id between 990000000000001 and 990000000000003)=3;
  assert (select source='osm' and claimed_seller_id is null and imported_at is not null
    from public.directory_imported_places where osm_type='node' and osm_id=990000000000001);
  assert public.directory_imported_place_is_open(
    (select id from public.directory_imported_places where osm_id=990000000000001),'2026-09-28 23:30:00+02'),
    'Imported overnight Monday interval is open';

  result:=public.import_osm_directory_places(pg_temp.fixture_places(),'2026-09-27');
  assert (result->>'inserted')::int=0 and (result->>'updated')::int=0 and (result->>'unchanged')::int=3,
    format('identical re-run changes nothing: %s',result);
end $$;

-- Fixture ids for sections running as roles without table access.
select set_config('e15.p'||n,(select id::text from public.directory_imported_places where osm_id=990000000000000+n),true)
from generate_series(1,3) n;

-- Public projections: source + claim state, never outreach data.
set local role anon;
select set_config('request.jwt.claims','{"role":"anon"}',true);
do $$
declare search_result jsonb; detail jsonb; item jsonb;
begin
  search_result:=public.search_business_directory(p_center_lat=>52.4990,p_center_lng=>13.4180,p_radius_km=>0.5);
  assert search_result::text not like '%e15-secret%', 'search never exposes outreach emails';
  select value into item from jsonb_array_elements(search_result->'items')
    where value->>'shop_name'='E15 Imbiss Eins';
  assert item->>'source'='osm' and (item->>'is_claimed')::boolean=false
    and (item->>'reviews_enabled')::boolean=false and item->>'place_id' is not null
    and item->>'seller_id' is null, format('search item carries source and claim flag: %s',item);
  assert not (item ? 'email'), 'search item has no email key';

  search_result:=public.search_business_directory(p_type=>'fast_food',p_cuisine=>'kebab',p_limit=>100);
  assert exists(select 1 from jsonb_array_elements(search_result->'items') i where i->>'shop_name'='E15 Imbiss Eins'),
    'fast_food and kebab filters match imports';
  search_result:=public.search_business_directory(p_language=>'kurdish');
  assert not exists(select 1 from jsonb_array_elements(search_result->'items') i where i->>'source'='osm'),
    'language filter excludes imports without language data';

  detail:=public.get_directory_imported_place_detail((item->>'place_id')::uuid);
  assert detail->>'source'='osm' and (detail->>'is_claimed')::boolean=false
    and (detail->>'reviews_enabled')::boolean=false and jsonb_array_length(detail->'hours')=1
    and detail->>'address'='Oranienstraße 1, 10999 Berlin', format('detail projection: %s',detail);
  assert detail::text not like '%e15-secret%', 'detail never exposes outreach emails';
end $$;
select pg_temp.expect_error($$select * from public.directory_outreach_contacts$$,'42501');
select pg_temp.expect_error($$select * from public.directory_imported_places$$,'42501');
select pg_temp.expect_error($$select public.import_osm_directory_places('[]','2026-09-27')$$,'42501');
select pg_temp.expect_error($$select public.admin_export_directory_outreach_csv()$$,'42501');
reset role;

-- Signed-in non-admins: no outreach access, and imported places reject reviews in the database.
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"e1500000-0000-0000-0000-000000000002","role":"authenticated"}',true);
select pg_temp.expect_error($$select * from public.directory_outreach_contacts$$,'42501');
select pg_temp.expect_error($$select * from public.directory_import_suppressions$$,'42501');
select pg_temp.expect_error($$select public.admin_export_directory_outreach_csv()$$,'42501');
select pg_temp.expect_error(format(
  $f$select public.admin_set_directory_outreach_status(%L,'contacted')$f$,
  current_setting('e15.p2')::uuid),'42501');
select pg_temp.expect_error(format(
  $f$select public.upsert_directory_review(%L,5::smallint,'Imported places cannot be reviewed')$f$,
  current_setting('e15.p1')::uuid),'23514');
select pg_temp.expect_error(format(
  $f$insert into public.reviews(kind,context,seller_id,reviewer_id,rating,verified_purchase,status)
     values('seller','directory',%L,'e1500000-0000-0000-0000-000000000002',5,false,'published')$f$,
  current_setting('e15.p1')::uuid),'23514');
reset role;

-- fast_food owner profiles behave like restaurants: menu and reviews allowed.
insert into public.business_directory_profiles(seller_id,type,description,phone,languages,cuisines,price_level,is_published)
values('e1510000-0000-0000-0000-000000000001','fast_food','A fast food owner fixture for E1.5 acceptance.',
  '030 400000',array['german']::public.directory_spoken_language[],array['kebab']::public.directory_cuisine[],1,true);
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"e1500000-0000-0000-0000-000000000003","role":"authenticated"}',true);
select public.owner_replace_directory_menu('[{"name":"Döner","items":[{"name":"Döner Kebab","price_cents":750}]}]');
select set_config('request.jwt.claims','{"sub":"e1500000-0000-0000-0000-000000000002","role":"authenticated"}',true);
select public.upsert_directory_review('e1510000-0000-0000-0000-000000000001',4::smallint,'Fast food review');
do $$
declare owner_item jsonb;
begin
  select value into owner_item from jsonb_array_elements(
    public.search_business_directory(p_type=>'fast_food',p_language=>'german')->'items')
  where value->>'seller_id'='e1510000-0000-0000-0000-000000000001';
  assert owner_item->>'source'='owner' and (owner_item->>'is_claimed')::boolean
    and (owner_item->>'reviews_enabled')::boolean, format('owner projection: %s',owner_item);
  assert (public.get_business_directory_detail('e1510000-0000-0000-0000-000000000001')->>'source')='owner';
end $$;
reset role;

-- Admin workflow: claim, removal/suppression, CSV export.
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"e1500000-0000-0000-0000-000000000001","role":"authenticated","app_metadata":{"role":"admin"}}',true);
select public.admin_set_directory_outreach_status(
  current_setting('e15.p1')::uuid,
  'claimed','Owner verified by phone','e1510000-0000-0000-0000-000000000001');
select public.admin_set_directory_outreach_status(
  current_setting('e15.p2')::uuid,
  'removal_requested','Owner asked to be removed');
select pg_temp.expect_error(format(
  $f$select public.admin_set_directory_outreach_status(%L,'not_contacted')$f$,
  current_setting('e15.p2')::uuid),'22023');
do $$
declare csv text;
begin
  csv:=public.admin_export_directory_outreach_csv();
  assert split_part(csv,E'\n',1)='name,cuisine,address,email,website,phone,status';
  assert csv like '%"E15 Imbiss Eins","kebab;turkish","Oranienstraße 1, 10999 Berlin","e15-secret-one@example.invalid","https://example.invalid","+49 30 1234567","claimed"%',
    'CSV row carries contact data for admins';
  assert csv like '%"''=E15 Formula Café"%', 'CSV neutralises formula prefixes';
  assert public.admin_export_directory_outreach_csv('removal_requested') like '%E15 Restaurant Zwei%';
end $$;
reset role;
select set_config('request.jwt.claims','{}',true);

do $$
declare result jsonb; search_result jsonb;
begin
  assert (select is_hidden from public.directory_imported_places where osm_id=990000000000002),
    'removal request hides the place immediately';
  assert exists(select 1 from public.directory_import_suppressions
    where osm_type='way' and osm_id=990000000000002 and reason='removal_requested');
  search_result:=public.search_business_directory(p_limit=>100,p_center_lat=>52.5,p_center_lng=>13.4,p_radius_km=>0.2);
  assert not exists(select 1 from jsonb_array_elements(search_result->'items') i
    where i->>'shop_name' in ('E15 Imbiss Eins','E15 Restaurant Zwei')),
    'claimed and removed imports leave public search';
  assert public.get_directory_imported_place_detail(
    current_setting('e15.p1')::uuid) is null;

  -- Re-run with a changed name for the claimed place: claimed rows stay untouched,
  -- the suppressed place is skipped, the untouched unclaimed place is unchanged.
  result:=public.import_osm_directory_places(pg_temp.fixture_places('Renamed by OSM'),'2026-10-01');
  assert (result->>'skipped_claimed')::int=1 and (result->>'skipped_suppressed')::int=1
    and (result->>'updated')::int=0 and (result->>'inserted')::int=0 and (result->>'unchanged')::int=1,
    format('claimed/suppressed re-run: %s',result);
  assert (select name='E15 Imbiss Eins' and source_snapshot='2026-09-27'
    from public.directory_imported_places where osm_id=990000000000001), 'claimed row untouched';

  -- Even if the suppressed row disappears, a re-import never brings it back.
  delete from public.directory_imported_places where osm_type='way' and osm_id=990000000000002;
  result:=public.import_osm_directory_places(pg_temp.fixture_places(),'2026-10-01');
  assert (result->>'skipped_suppressed')::int=1 and (result->>'inserted')::int=0, format('suppression holds: %s',result);
  assert not exists(select 1 from public.directory_imported_places where osm_type='way' and osm_id=990000000000002);

  -- Changed OSM data updates unclaimed rows only; vanished rows are reported, not deleted.
  result:=public.import_osm_directory_places(
    jsonb_build_array(jsonb_set(pg_temp.fixture_places()->2,'{name}','"E15 Café Neu"')),'2026-10-01');
  assert (result->>'updated')::int=1, format('changed unclaimed row updates: %s',result);
  assert (select name from public.directory_imported_places where osm_id=990000000000003)='E15 Café Neu';
  assert not exists(select 1 from jsonb_array_elements(result->'vanished') v where (v->>'osm_id')::bigint=990000000000001),
    'claimed rows are never reported as vanished';
  assert exists(select 1 from public.directory_imported_places where osm_id=990000000000001),
    'nothing is deleted automatically';
end $$;

rollback;
