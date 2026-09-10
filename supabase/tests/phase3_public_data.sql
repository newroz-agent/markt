-- Run on local migrated DB with psql -v ON_ERROR_STOP=1. Fixtures roll back.
begin;

create function pg_temp.expect_error(command text, expected_state text)
returns void language plpgsql as $$
begin
  begin
    execute command;
  exception when others then
    if sqlstate = expected_state then return; end if;
    raise;
  end;
  raise exception 'Expected SQLSTATE % for %', expected_state, command;
end;
$$;

insert into auth.users (id, email) values
  ('e1000000-0000-0000-0000-000000000001', 'phase3-buyer@example.invalid'),
  ('e1000000-0000-0000-0000-000000000002', 'phase3-owner@example.invalid'),
  ('e1000000-0000-0000-0000-000000000003', 'phase3-other@example.invalid');
insert into public.sellers (id, user_id, kind, status, shop_name, slug, city, country_code) values
  ('e2000000-0000-0000-0000-000000000001', 'e1000000-0000-0000-0000-000000000002',
   'business', 'approved', 'Phase Three', 'phase3-sql-test', 'Berlin', 'DE'),
  ('e2000000-0000-0000-0000-000000000002', null,
   'business', 'approved', 'Foreign Address', 'phase3-foreign', 'Berlin', null),
  ('e2000000-0000-0000-0000-000000000003', null,
   'business', 'approved', 'Unknown Country', 'phase3-unknown', 'Berlin', null);
-- Omitted country on a new private seller defaults to DE, without tax details.
insert into public.sellers (id, kind, status, shop_name, slug, city) values
  ('e2000000-0000-0000-0000-000000000004', 'private', 'approved',
   'Private Pickup', 'phase3-private-pickup', null);
insert into public.seller_private_details (seller_id, legal_address) values
  ('e2000000-0000-0000-0000-000000000001', '{"country_code":"DE","city":"Berlin","street":"Private street"}'),
  ('e2000000-0000-0000-0000-000000000002', '{"country_code":"FR","city":"Berlin"}'),
  ('e2000000-0000-0000-0000-000000000003', '{"country_code":"DE","city":"Berlin"}');
insert into public.categories (id, slug, name_de, name_en, name_ar, name_tr, icon_key, image_url)
values ('e3000000-0000-0000-0000-000000000001', 'phase3-sql-test', 'Test', 'Test', 'Test', 'Test', 'test', 'test');
insert into public.products (id, seller_id, category_id, title, slug, description, condition, status, price_cents) values
  ('e4000000-0000-0000-0000-000000000001', 'e2000000-0000-0000-0000-000000000001',
   'e3000000-0000-0000-0000-000000000001', 'Phase Three Product', 'phase3-sql-test',
   'Phase three test description', 'new', 'active', 1200),
  ('e4000000-0000-0000-0000-000000000002', 'e2000000-0000-0000-0000-000000000001',
   'e3000000-0000-0000-0000-000000000001', 'Phase Three Draft', 'phase3-sql-draft',
    'Phase three draft description', 'new', 'draft', 1200);

insert into public.products (id, seller_id, category_id, title, slug, description,
  condition, status, price_cents, city, country_code, ships_to) values
  ('e4000000-0000-0000-0000-000000000003', 'e2000000-0000-0000-0000-000000000004',
   'e3000000-0000-0000-0000-000000000001', 'Private Pickup Product', 'phase3-pickup',
   'Private pickup without shipping or tax details', 'used', 'active', 1200, null, 'DE', '{}'),
  ('e4000000-0000-0000-0000-000000000004', 'e2000000-0000-0000-0000-000000000001',
   'e3000000-0000-0000-0000-000000000001', 'Unknown Item Country', 'phase3-unknown-item',
   'German city and delivery do not establish item country', 'used', 'active', 1200, 'Berlin', null, '{DE}'),
  ('e4000000-0000-0000-0000-000000000005', 'e2000000-0000-0000-0000-000000000003',
   'e3000000-0000-0000-0000-000000000001', 'Unknown Seller Country', 'phase3-unknown-seller',
   'German item country does not establish seller country', 'used', 'active', 1200, 'Berlin', 'DE', '{DE}');

do $$ begin
  assert (select country_code = 'DE' from public.sellers where id = 'e2000000-0000-0000-0000-000000000004'), 'New seller omitted country defaults to DE';
  assert (select country_code = 'DE' from public.products where id = 'e4000000-0000-0000-0000-000000000001'), 'New product omitted country defaults to DE';
  assert (select country_code is null from public.sellers where id = 'e2000000-0000-0000-0000-000000000003'), 'Explicit seller NULL stays unknown';
  assert (select country_code is null from public.products where id = 'e4000000-0000-0000-0000-000000000004'), 'Explicit product NULL stays unknown';
  perform pg_temp.expect_error($q$update public.sellers set country_code = 'FR' where id = 'e2000000-0000-0000-0000-000000000001'$q$, '23514');
  perform pg_temp.expect_error($q$update public.products set country_code = 'FR' where id = 'e4000000-0000-0000-0000-000000000001'$q$, '23514');
  perform pg_temp.expect_error($q$update public.sellers set country_code = 'de' where id = 'e2000000-0000-0000-0000-000000000001'$q$, '23514');
  perform pg_temp.expect_error($q$update public.products set country_code = '' where id = 'e4000000-0000-0000-0000-000000000001'$q$, '23514');
end $$;

insert into public.seller_documents (seller_id, kind, storage_path, mime_type, status) values
  ('e2000000-0000-0000-0000-000000000001', 'other', 'phase3/other.pdf', 'application/pdf', 'approved');
do $$ begin
  assert not public.is_verified_seller('e2000000-0000-0000-0000-000000000001'), 'Unrelated approved document is not verification';
end $$;
insert into public.seller_documents (seller_id, kind, storage_path, mime_type, status) values
  ('e2000000-0000-0000-0000-000000000001', 'identity', 'phase3/identity.pdf', 'application/pdf', 'approved'),
  ('e2000000-0000-0000-0000-000000000001', 'business_registration', 'phase3/business.pdf', 'application/pdf', 'pending');
do $$ begin
  assert not public.is_verified_seller('e2000000-0000-0000-0000-000000000001'), 'Both required kinds must be approved';
end $$;
update public.seller_documents set status = 'approved' where storage_path = 'phase3/business.pdf';

set local role anon;
do $$ begin
  assert public.is_verified_seller('e2000000-0000-0000-0000-000000000001'), 'Anonymous sees only boolean verification';
  assert not public.is_verified_seller('e2000000-0000-0000-0000-000000000099'), 'Unknown seller is false';
  assert (select public.phase3_in_germany(s) from public.sellers s where id = 'e2000000-0000-0000-0000-000000000001'), 'Explicit seller DE passes';
  assert not (select public.phase3_in_germany(s) from public.sellers s where id = 'e2000000-0000-0000-0000-000000000002'), 'Foreign address and German city do not establish country';
  assert not (select public.phase3_in_germany(s) from public.sellers s where id = 'e2000000-0000-0000-0000-000000000003'), 'Even German legal address cannot override unknown explicit country';
  assert (select public.phase3_in_germany(s) from public.sellers s where id = 'e2000000-0000-0000-0000-000000000004'), 'Private seller without legal address or city passes';
  assert (
    select array_agg(p.id order by p.id) = array[
      'e4000000-0000-0000-0000-000000000001'::uuid,
      'e4000000-0000-0000-0000-000000000003'::uuid
    ]
    from public.products p join public.sellers s on s.id = p.seller_id
    where p.category_id = 'e3000000-0000-0000-0000-000000000001'
      and p.status = 'active' and p.quantity > 0 and s.status = 'approved'
      and public.phase3_in_germany(s) and p.country_code = 'DE'
  ), 'Phase3 includes pickup, excludes unknown item/seller countries and drafts';
  assert (
    select count(*) = 4 from public.products p join public.sellers s on s.id = p.seller_id
    where p.category_id = 'e3000000-0000-0000-0000-000000000001'
      and p.status = 'active' and p.quantity > 0
  ), 'Home query and RLS retain unknown-country active entries';
  perform pg_temp.expect_error('select * from public.seller_documents', '42501');
  assert (select count(*) = 0 from public.seller_private_details), 'Anonymous sees no private address rows';
end $$;

set local role authenticated;
set local request.jwt.claims = '{"sub":"e1000000-0000-0000-0000-000000000001","role":"authenticated"}';
insert into public.favorites (user_id, product_id) values
  (auth.uid(), 'e4000000-0000-0000-0000-000000000001') on conflict (user_id, product_id) do nothing;
insert into public.favorites (user_id, product_id) values
  (auth.uid(), 'e4000000-0000-0000-0000-000000000001') on conflict (user_id, product_id) do nothing;
do $$ begin
  assert (select count(*) = 1 from public.favorites where product_id = 'e4000000-0000-0000-0000-000000000001'), 'Favorite insertion is idempotent without UPDATE RLS';
  assert (select count(*) = 0 from public.seller_documents), 'Other user sees no verification documents';
  assert (select count(*) = 0 from public.seller_private_details), 'Other user sees no private addresses';
  perform pg_temp.expect_error($q$insert into public.favorites (user_id, product_id) values ('e1000000-0000-0000-0000-000000000003','e4000000-0000-0000-0000-000000000001')$q$, '42501');
end $$;

set local request.jwt.claims = '{"sub":"e1000000-0000-0000-0000-000000000003","role":"authenticated"}';
do $$ begin
  assert (select count(*) = 0 from public.favorites), 'Other account sees no favorites';
  delete from public.favorites where product_id = 'e4000000-0000-0000-0000-000000000001';
  assert not found, 'Other account cannot delete favorite';
end $$;
insert into public.favorites (user_id, product_id) values
  (auth.uid(), 'e4000000-0000-0000-0000-000000000001') on conflict (user_id, product_id) do nothing;

set local request.jwt.claims = '{"sub":"e1000000-0000-0000-0000-000000000003","role":"authenticated","app_metadata":{"role":"admin"}}';
do $$ begin
  perform pg_temp.expect_error($q$insert into public.favorites (user_id, product_id) values ('e1000000-0000-0000-0000-000000000001','e4000000-0000-0000-0000-000000000001') on conflict (user_id, product_id) do nothing$q$, '42501');
end $$;

set local request.jwt.claims = '{"sub":"e1000000-0000-0000-0000-000000000001","role":"authenticated"}';
delete from public.favorites where user_id = auth.uid() and product_id = 'e4000000-0000-0000-0000-000000000001';
do $$ begin
  assert not exists (select 1 from public.favorites), 'Own scoped delete succeeds';
end $$;
reset role;
set local request.jwt.claims = '{}';
do $$ begin
  assert exists (select 1 from public.favorites where user_id = 'e1000000-0000-0000-0000-000000000003'), 'Other favorite survives scoped delete';
end $$;

set local role authenticated;
set local request.jwt.claims = '{"sub":"e1000000-0000-0000-0000-000000000002","role":"authenticated"}';
do $$ begin
  assert exists (select 1 from public.products where id = 'e4000000-0000-0000-0000-000000000002'), 'Owner RLS permits drafts for management';
  assert not exists (
    select 1 from public.products p join public.sellers s on s.id = p.seller_id
    where p.id = 'e4000000-0000-0000-0000-000000000002'
      and p.status = 'active' and p.quantity > 0 and s.status = 'approved'
      and public.phase3_in_germany(s) and p.country_code = 'DE'
  ), 'Public detail query still excludes owner draft';
end $$;

reset role;
set local request.jwt.claims = '{}';
update public.seller_documents set status = 'rejected' where storage_path = 'phase3/identity.pdf';
do $$ begin
  assert not public.is_verified_seller('e2000000-0000-0000-0000-000000000001'), 'Revoked identity removes verification';
end $$;
update public.seller_documents set status = 'approved' where storage_path = 'phase3/identity.pdf';
update public.sellers set status = 'suspended' where id = 'e2000000-0000-0000-0000-000000000001';
do $$ begin
  assert not public.is_verified_seller('e2000000-0000-0000-0000-000000000001'), 'Unapproved seller never verified';
  assert not (select public.phase3_in_germany(s) from public.sellers s where id = 'e2000000-0000-0000-0000-000000000001'), 'Unapproved seller cannot reveal country scope';
end $$;
rollback;
