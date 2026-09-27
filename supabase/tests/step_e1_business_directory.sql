-- Step E1 acceptance against the effective local schema. All fixtures roll back.
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

-- Pages through every search result so assertions target fixture ids and never depend
-- on how much other data (e.g. imported OSM places) the local database holds.
create function pg_temp.search_all() returns setof jsonb language plpgsql as $$
declare page jsonb; page_offset integer := 0;
begin
  loop
    page := public.search_business_directory(p_limit=>100,p_offset=>page_offset);
    return query select value from jsonb_array_elements(page->'items');
    page_offset := page_offset + 100;
    exit when page_offset >= (page->>'total_count')::integer;
  end loop;
end; $$;

do $$ begin
  assert exists(select 1 from pg_enum e join pg_type t on t.oid=e.enumtypid
    where t.typname='seller_document_kind' and e.enumlabel='medical_professional_registration');
  assert to_regclass('public.business_directory_profiles') is not null;
  assert (select is_nullable='YES' from information_schema.columns
    where table_schema='public' and table_name='reviews' and column_name='order_item_id');
end $$;

insert into auth.users(id,email,raw_user_meta_data) values
 ('e1000000-0000-0000-0000-000000000001','e1-restaurant@example.invalid','{"display_name":"Restaurant Owner"}'),
 ('e1000000-0000-0000-0000-000000000002','e1-doctor@example.invalid','{"display_name":"Doctor Owner"}'),
 ('e1000000-0000-0000-0000-000000000003','e1-unverified@example.invalid','{"display_name":"Unverified Owner"}'),
 ('e1000000-0000-0000-0000-000000000004','e1-reviewer@example.invalid','{"display_name":"Reviewer"}');

insert into public.sellers(id,user_id,kind,status,shop_name,slug,city,country_code,approved_at)
values
 ('e2000000-0000-0000-0000-000000000001','e1000000-0000-0000-0000-000000000001','business','approved','E1 Restaurant','e1-restaurant','Berlin','DE',now()),
 ('e2000000-0000-0000-0000-000000000002','e1000000-0000-0000-0000-000000000002','business','approved','E1 Praxis','e1-praxis','Berlin','DE',now()),
 ('e2000000-0000-0000-0000-000000000003','e1000000-0000-0000-0000-000000000003','business','approved','E1 Unverified','e1-unverified','Berlin','DE',now());

insert into public.seller_documents(seller_id,kind,storage_path,mime_type,status) values
 ('e2000000-0000-0000-0000-000000000001','identity','e1/restaurant-identity.pdf','application/pdf','approved'),
 ('e2000000-0000-0000-0000-000000000001','business_registration','e1/restaurant-business.pdf','application/pdf','approved'),
 ('e2000000-0000-0000-0000-000000000002','identity','e1/doctor-identity.pdf','application/pdf','approved'),
 ('e2000000-0000-0000-0000-000000000002','medical_professional_registration','e1/doctor-medical.pdf','application/pdf','approved'),
 ('e2000000-0000-0000-0000-000000000003','identity','e1/unverified-identity.pdf','application/pdf','approved');

insert into public.business_directory_profiles(
 seller_id,type,description,phone,languages,cuisines,price_level,is_published,specialty,insurance
) values
 ('e2000000-0000-0000-0000-000000000001','restaurant','A restaurant fixture for directory acceptance.','030 100000',array['german']::public.directory_spoken_language[],array['kurdish']::public.directory_cuisine[],2,true,null,null),
 ('e2000000-0000-0000-0000-000000000002','doctor','A medical practice fixture for directory acceptance.','030 200000',array['german','kurdish']::public.directory_spoken_language[],'{}',null,true,'general_medicine','both'),
 ('e2000000-0000-0000-0000-000000000003','cafe','An unverified cafe fixture for directory acceptance.','030 300000',array['german']::public.directory_spoken_language[],array['international']::public.directory_cuisine[],1,true,null,null);

insert into public.business_directory_hours(seller_id,weekday,opens_at,closes_at)
values('e2000000-0000-0000-0000-000000000001',1,'22:00','02:00');

insert into public.products(
 id,seller_id,category_id,title,slug,description,condition,status,price_cents,city,country_code,quantity
) values(
 'e3000000-0000-0000-0000-000000000001','e2000000-0000-0000-0000-000000000001',
 (select id from public.categories where is_active order by id limit 1),
 'E1 purchase fixture','e1-purchase-fixture','A delivered product retained to prove purchase-review behavior.','new','active',1000,'Berlin','DE',1
);
insert into public.orders(
 id,buyer_id,seller_id,status,payment_status,subtotal_cents,total_cents,shipping_address
) values(
 'e4000000-0000-0000-0000-000000000001','e1000000-0000-0000-0000-000000000004',
 'e2000000-0000-0000-0000-000000000001','delivered','succeeded',1000,1000,'{}'
);
insert into public.order_items(
 id,order_id,product_id,seller_id,status,product_title,condition,quantity,unit_price_cents,vat_rate,total_cents
) values(
 'e5000000-0000-0000-0000-000000000001','e4000000-0000-0000-0000-000000000001',
 'e3000000-0000-0000-0000-000000000001','e2000000-0000-0000-0000-000000000001',
 'delivered','E1 purchase fixture','new',1,1000,0,1000
);

do $$
begin
  assert public.is_verified_seller('e2000000-0000-0000-0000-000000000001'),
    'Non-doctor remains verified by business registration';
  assert public.is_verified_seller('e2000000-0000-0000-0000-000000000002'),
    'Doctor accepts medical professional registration';
  assert not public.is_verified_seller('e2000000-0000-0000-0000-000000000003'),
    'Identity alone is not verified';
  assert public.directory_is_open('e2000000-0000-0000-0000-000000000001','2026-09-28 23:30:00+02'),
    'Overnight interval is open on starting day';
  assert public.directory_is_open('e2000000-0000-0000-0000-000000000001','2026-09-29 01:30:00+02'),
    'Overnight interval remains open after midnight';
  assert not public.directory_is_open('e2000000-0000-0000-0000-000000000001','2026-09-29 02:00:00+02'),
    'Closing boundary is exclusive';
  assert exists(select 1 from pg_temp.search_all() i where i->>'seller_id'='e2000000-0000-0000-0000-000000000001')
    and exists(select 1 from pg_temp.search_all() i where i->>'seller_id'='e2000000-0000-0000-0000-000000000002'),
    'Verified published fixtures are listed';
  assert not exists(select 1 from pg_temp.search_all() i where i->>'seller_id'='e2000000-0000-0000-0000-000000000003'),
    'Unverified published businesses stay hidden';
  assert public.get_business_directory_detail('e2000000-0000-0000-0000-000000000003') is null,
    'Unverified detail stays hidden';
end $$;

-- Current directory type is evaluated live. A doctor changing to cafe immediately
-- loses the medical-proof exception; ordinary businesses remain unchanged.
update public.business_directory_profiles set
 type='cafe',cuisines=array['international']::public.directory_cuisine[],price_level=2,
 specialty=null,insurance=null
where seller_id='e2000000-0000-0000-0000-000000000002';
do $$ begin
  assert not public.is_verified_seller('e2000000-0000-0000-0000-000000000002'),
    'Switching away from doctor requires business registration immediately';
  assert public.is_verified_seller('e2000000-0000-0000-0000-000000000001'),
    'Doctor rule does not change ordinary business verification';
end $$;
update public.business_directory_profiles set
 type='doctor',cuisines='{}',price_level=null,specialty='general_medicine',insurance='both'
where seller_id='e2000000-0000-0000-0000-000000000002';

set local role authenticated;
select set_config('request.jwt.claims','{"sub":"e1000000-0000-0000-0000-000000000004","role":"authenticated"}',true);
select pg_temp.expect_error(
 $$select public.upsert_directory_review('e2000000-0000-0000-0000-000000000002',5::smallint,'Doctor review forbidden')$$,
 '23514'
);
select pg_temp.expect_error(
 $$select public.upsert_directory_review('e2000000-0000-0000-0000-000000000003',5::smallint,'Unverified review forbidden')$$,
 '23514'
);
select pg_temp.expect_error(
 $$select public.search_business_directory(p_type=>'doctor',p_min_rating=>4)$$,
 '22023'
);

-- Omitting the discriminator preserves the original verified-purchase path.
insert into public.reviews(kind,seller_id,order_item_id,reviewer_id,rating,body)
values(
 'seller','e2000000-0000-0000-0000-000000000001','e5000000-0000-0000-0000-000000000001',
 auth.uid(),5,'Verified purchase review'
);
do $$ begin
  assert (select context='purchase' and verified_purchase and status='published'
    from public.reviews where order_item_id='e5000000-0000-0000-0000-000000000001'),
    'Existing purchase review defaults and eligibility remain unchanged';
end $$;

select public.upsert_directory_review('e2000000-0000-0000-0000-000000000001',5::smallint,'Excellent food and service');
select public.upsert_directory_review('e2000000-0000-0000-0000-000000000001',4::smallint,'Updated directory review');
insert into public.reports(review_id,reporter_id,reason)
select id,auth.uid(),'other' from public.reviews
where seller_id='e2000000-0000-0000-0000-000000000001' and context='directory';
do $$ begin
  assert (select count(*)=1 from public.reviews where seller_id='e2000000-0000-0000-0000-000000000001' and context='directory');
  -- Ratings are never blended (decision 2026-09-27): the seller rating counts purchase
  -- reviews only, the directory rating counts directory reviews only.
  assert (select rating_average=5 and rating_count=1 from public.sellers where id='e2000000-0000-0000-0000-000000000001'),
    'Seller rating counts only the purchase review';
  assert (select rating_average=4 and rating_count=1 from public.business_directory_profiles
    where seller_id='e2000000-0000-0000-0000-000000000001'), 'Directory rating counts only the directory review';
  assert (public.get_business_directory_detail('e2000000-0000-0000-0000-000000000001')->>'rating_average')::numeric=4,
    'Directory detail shows the directory rating';
  assert public.delete_directory_review('e2000000-0000-0000-0000-000000000001');
  assert (select status='hidden' from public.reviews where seller_id='e2000000-0000-0000-0000-000000000001' and context='directory');
  assert exists(select 1 from public.reports report join public.reviews review on review.id=report.review_id
    where review.seller_id='e2000000-0000-0000-0000-000000000001'),
    'Soft delete preserves reported review and report target';
  assert (select rating_average=5 and rating_count=1 from public.sellers where id='e2000000-0000-0000-0000-000000000001'),
    'Soft delete leaves the purchase rating unchanged';
  assert (select rating_average=0 and rating_count=0 from public.business_directory_profiles
    where seller_id='e2000000-0000-0000-0000-000000000001'),
    'Soft delete removes the directory review from the directory rating';
end $$;

select set_config('request.jwt.claims','{"sub":"e1000000-0000-0000-0000-000000000001","role":"authenticated"}',true);
select pg_temp.expect_error(
 $$select public.upsert_directory_review('e2000000-0000-0000-0000-000000000001',5::smallint,'Owner review forbidden')$$,
 '23514'
);
update public.business_directory_profiles set rating_average=5,rating_count=99
where seller_id='e2000000-0000-0000-0000-000000000001';
do $$ begin
  assert (select rating_average=0 and rating_count=0 from public.business_directory_profiles
    where seller_id='e2000000-0000-0000-0000-000000000001'), 'Owners cannot write their directory rating';
end $$;

select set_config('request.jwt.claims','{"sub":"e1000000-0000-0000-0000-000000000002","role":"authenticated"}',true);
select pg_temp.expect_error(
 $$select public.owner_replace_directory_menu('[{"name":"Forbidden","items":[]}]')$$,
 '23514'
);

reset role;
select set_config('request.jwt.claims','{}',true);

set local role anon;
do $$ begin
  assert (select array_agg(seller_id order by seller_id) from public.business_directory_profiles
    where seller_id in ('e2000000-0000-0000-0000-000000000001','e2000000-0000-0000-0000-000000000002',
      'e2000000-0000-0000-0000-000000000003'))
    = array['e2000000-0000-0000-0000-000000000001','e2000000-0000-0000-0000-000000000002']::uuid[],
    'Anonymous direct reads see only published, currently verified profiles';
  assert not exists(select 1 from public.business_directory_menu_sections
    where seller_id in ('e2000000-0000-0000-0000-000000000001','e2000000-0000-0000-0000-000000000002',
      'e2000000-0000-0000-0000-000000000003')),
    'Fixture has no public menu sections';
end $$;
reset role;

-- Purchase-review defaults and eligibility contract remain intact.
do $$ begin
  assert (select column_default like '%purchase%' from information_schema.columns
    where table_schema='public' and table_name='reviews' and column_name='context');
  assert has_function_privilege('authenticated','public.can_review_order_item(uuid,uuid,uuid,public.review_kind)','EXECUTE');
end $$;

rollback;
