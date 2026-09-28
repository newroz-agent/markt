-- Local migrated DB only: psql -v ON_ERROR_STOP=1. All fixtures roll back.
begin;

create function pg_temp.expect_country_denied(command text)
returns void language plpgsql as $$
begin
  begin
    execute command;
  exception when insufficient_privilege then
    assert sqlerrm = 'Country changes require admin validation',
      'Must be rejected by the country guard, not an unrelated permission';
    return;
  end;
  raise exception 'Expected country moderation rejection: %', command;
end;
$$;

insert into auth.users (id, email) values
  ('d1000000-0000-0000-0000-000000000001', 'country-owner@example.invalid'),
  ('d1000000-0000-0000-0000-000000000002', 'country-new-owner@example.invalid'),
  ('d1000000-0000-0000-0000-000000000003', 'country-admin@example.invalid');
insert into public.sellers (id, user_id, kind, status, shop_name, slug, country_code)
values ('d2000000-0000-0000-0000-000000000001', 'd1000000-0000-0000-0000-000000000001',
  'private', 'approved', 'Country Test', 'country-guard-test', null);
insert into public.categories (id, slug, name_de, name_en, name_ar, name_tr, icon_key, image_url)
values ('d3000000-0000-0000-0000-000000000001', 'country-guard-test', 'Test', 'Test', 'Test', 'Test', 'test', 'test');
insert into public.products (id, seller_id, category_id, title, slug, description,
  condition, status, price_cents, country_code)
values ('d4000000-0000-0000-0000-000000000001', 'd2000000-0000-0000-0000-000000000001',
  'd3000000-0000-0000-0000-000000000001', 'Country Guard Product', 'country-guard-test',
  'Existing active product with unknown country', 'used', 'active', 1200, null);

set local role authenticated;
set local request.jwt.claims = '{"sub":"d1000000-0000-0000-0000-000000000001","role":"authenticated","user_metadata":{"role":"admin"}}';
do $$ begin
  assert not public.is_admin(), 'User-editable metadata must not confer admin';
  perform pg_temp.expect_country_denied($q$update public.sellers set country_code = 'DE' where id = 'd2000000-0000-0000-0000-000000000001'$q$);
  perform pg_temp.expect_country_denied($q$update public.products set country_code = 'DE' where id = 'd4000000-0000-0000-0000-000000000001'$q$);
  assert (select country_code is null from public.sellers where id = 'd2000000-0000-0000-0000-000000000001'), 'Seller remains unknown';
  assert (select country_code is null and status = 'active' from public.products where id = 'd4000000-0000-0000-0000-000000000001'), 'Active item remains unknown';
  -- A payload that resends the unchanged country must still be editable.
  update public.sellers set country_code = null, bio = 'Owner can edit biography'
    where id = 'd2000000-0000-0000-0000-000000000001';
  assert found, 'Owner seller update really reached a row';
  update public.products set country_code = null, title = 'Owner Edited Product'
    where id = 'd4000000-0000-0000-0000-000000000001';
  assert found, 'Owner product update really reached a row';
end $$;

set local request.jwt.claims = '{"sub":"d1000000-0000-0000-0000-000000000003","role":"authenticated","app_metadata":{"role":"admin"}}';
do $$ begin
  assert public.is_admin(), 'Admin comes from app metadata';
  update public.sellers set country_code = 'DE' where id = 'd2000000-0000-0000-0000-000000000001';
  assert found, 'Admin validates seller country';
  update public.products set country_code = 'DE' where id = 'd4000000-0000-0000-0000-000000000001';
  assert found, 'Admin validates product country';
  assert (select public.phase3_in_germany(s) from public.sellers s where id = 'd2000000-0000-0000-0000-000000000001'), 'Validated seller becomes Germany scoped';
  assert (select country_code = 'DE' and status = 'active' from public.products where id = 'd4000000-0000-0000-0000-000000000001'), 'Validated item stays active';
end $$;

set local request.jwt.claims = '{"sub":"d1000000-0000-0000-0000-000000000001","role":"authenticated"}';
do $$ begin
  perform pg_temp.expect_country_denied($q$update public.sellers set country_code = null where id = 'd2000000-0000-0000-0000-000000000001'$q$);
  perform pg_temp.expect_country_denied($q$update public.products set country_code = null where id = 'd4000000-0000-0000-0000-000000000001'$q$);
  update public.sellers set country_code = 'DE' where id = 'd2000000-0000-0000-0000-000000000001';
  assert found, 'Unchanged DE seller remains editable';
  update public.products set country_code = 'DE' where id = 'd4000000-0000-0000-0000-000000000001';
  assert found, 'Unchanged DE product remains editable';
end $$;

set local request.jwt.claims = '{"sub":"d1000000-0000-0000-0000-000000000002","role":"authenticated"}';
do $$
declare
  prepared jsonb;
  seller_id uuid;
  submitted_product_id uuid;
  image_path text;
  submitted jsonb;
begin
  prepared := public.prepare_listing_submission(
    'business', 'New Country Seller', 'Berlin'
  );
  seller_id := (prepared ->> 'seller_id')::uuid;
  submitted_product_id := (prepared ->> 'product_id')::uuid;
  image_path := seller_id || '/' || submitted_product_id || '/country-test.webp';

  assert (select country_code = 'DE' and status = 'pending'
    from public.sellers where id = seller_id),
    'New owner seller defaults DE but remains pending';

  insert into storage.objects (bucket_id, name, owner, metadata)
  values (
    'product-images', image_path, auth.uid(),
    '{"mimetype":"image/webp"}'::jsonb
  );

  submitted := public.submit_listing(
    submitted_product_id,
    seller_id,
    'd3000000-0000-0000-0000-000000000001',
    'New Country Product',
    'New product still requires normal moderation.',
    'used',
    1200,
    'Berlin',
    array[image_path],
    '{}'::jsonb
  );

  assert submitted ->> 'status' = 'pending_review',
    'Submission contract returns pending_review';
  assert (select country_code = 'DE' and status = 'pending_review'
    from public.products where id = submitted_product_id),
    'Submitted owner listing defaults DE and remains pending review';
  assert (select count(*) = 1 from public.product_images
    where product_images.product_id = submitted_product_id),
    'Submitted owner listing uses the protected image contract';
end $$;

rollback;
