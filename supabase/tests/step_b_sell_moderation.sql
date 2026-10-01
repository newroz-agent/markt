-- Local migrated DB only: psql -v ON_ERROR_STOP=1. All fixtures roll back.
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

create table pg_temp.step_b_context (
  key text primary key,
  value text not null
);
grant all on pg_temp.step_b_context to authenticated;
grant select on pg_temp.step_b_context to anon;

insert into auth.users (id, email, raw_user_meta_data)
values
  ('b1000000-0000-0000-0000-000000000001', 'step-b-owner@example.invalid', '{"display_name":"Step B Privat"}'),
  ('b1000000-0000-0000-0000-000000000002', 'step-b-business@example.invalid', '{"display_name":"Step B Geschäft"}'),
  ('b1000000-0000-0000-0000-000000000003', 'step-b-admin@example.invalid', '{"display_name":"Step B Admin"}');

insert into public.categories (
  id, slug, name_de, name_en, name_ar, name_tr, name_ku,
  icon_key, image_url, is_active
) values (
  'b2000000-0000-0000-0000-000000000001',
  'step-b-category', 'Test', 'Test', 'اختبار', 'Test', 'Test',
  'test', 'https://example.invalid/category.webp', true
);

set local role authenticated;
set local request.jwt.claims = '{"sub":"b1000000-0000-0000-0000-000000000001","role":"authenticated"}';

do $$
declare
  prepared jsonb;
  seller_id uuid;
  product_id uuid;
  image_path text;
  submitted jsonb;
begin
  prepared := public.prepare_listing_submission(
    null::uuid, 'private', 'Step B Privat', 'Berlin'
  );
  seller_id := (prepared ->> 'seller_id')::uuid;
  product_id := (prepared ->> 'product_id')::uuid;
  image_path := seller_id || '/' || product_id || '/one.webp';

  assert (select status = 'pending' and kind = 'private'
    from public.sellers where id = seller_id),
    'Private seller starts pending';
  assert public.can_manage_product_image_upload_path(image_path),
    'Owner can stage the documented two-folder path';

  insert into storage.objects (bucket_id, name, owner, metadata)
  values (
    'product-images', image_path, auth.uid(),
    '{"mimetype":"image/webp"}'::jsonb
  );

  perform pg_temp.expect_error(format(
    $q$select public.submit_listing(%L, %L, %L, 'No photo listing',
      'This listing intentionally has no uploaded photo.', 'used', 2500,
      'Berlin', array[]::text[], '{}'::jsonb)$q$,
    extensions.gen_random_uuid(), seller_id,
    'b2000000-0000-0000-0000-000000000001'
  ), '22023');

  submitted := public.submit_listing(
    product_id,
    seller_id,
    'b2000000-0000-0000-0000-000000000001',
    'Step B pending listing',
    'A complete listing submitted through the unified Step B flow.',
    'used',
    2599,
    'Berlin',
    array[image_path],
    '{"color":"petrol"}'::jsonb
  );

  assert submitted ->> 'status' = 'pending_review',
    'Submission RPC returns pending_review';
  assert (select status = 'pending_review' and published_at is null
    from public.products where id = product_id),
    'Persisted product is pending and unpublished';
  assert (select count(*) = 1 from public.product_images as image
    where image.product_id = (submitted ->> 'id')::uuid),
    'Submitted listing has its uploaded image row';

  insert into pg_temp.step_b_context values
    ('seller_id', seller_id::text),
    ('approved_product_id', product_id::text),
    ('approved_image_path', image_path);
end;
$$;

select pg_temp.expect_error(
  $q$insert into public.products (
    id, seller_id, category_id, title, slug, description,
    condition, status, price_cents, city
  ) values (
    extensions.gen_random_uuid(),
    (select value::uuid from pg_temp.step_b_context where key='seller_id'),
    'b2000000-0000-0000-0000-000000000001',
    'Bypass listing', 'step-b-bypass', 'Must not bypass submit listing',
    'used', 'pending_review', 100, 'Berlin'
  )$q$,
  '42501'
);

select pg_temp.expect_error(
  format(
    $q$update public.products set status='active' where id=%L$q$,
    (select value from pg_temp.step_b_context where key='approved_product_id')
  ),
  '42501'
);

select pg_temp.expect_error(
  'select public.get_moderation_dashboard(50)',
  '42501'
);
select pg_temp.expect_error(
  format(
    $q$select public.moderate_listing(%L, 'approve', null)$q$,
    (select value from pg_temp.step_b_context where key='approved_product_id')
  ),
  '42501'
);

set local role anon;
set local request.jwt.claims = '{"role":"anon"}';
do $$ begin
  assert not exists (
    select 1 from public.products
    where id = (select value::uuid from pg_temp.step_b_context
      where key='approved_product_id')
  ), 'Pending listing is hidden from public reads';
end $$;

set local role authenticated;
set local request.jwt.claims = '{"sub":"b1000000-0000-0000-0000-000000000003","role":"authenticated","app_metadata":{"role":"admin"}}';
do $$
declare
  product_id uuid := (
    select value::uuid from pg_temp.step_b_context where key='approved_product_id'
  );
  result jsonb;
  created_notification_id uuid;
begin
  assert (public.get_moderation_dashboard(50) -> 'counts' ->> 'pending')::int >= 1,
    'Admin dashboard counts pending listings';
  assert exists (
    select 1
    from jsonb_array_elements(public.get_moderation_dashboard(50) -> 'items') item
    where item ->> 'id' = product_id::text
  ), 'Admin queue contains submitted listing';

  result := public.moderate_listing(product_id, 'approve', null);
  created_notification_id := (result ->> 'notification_id')::uuid;
  assert result ->> 'status' = 'active', 'Approval returns active';
  assert (select status = 'active' and published_at is not null
    from public.products where id = product_id),
    'Approval publishes product';
  assert (select status = 'approved' from public.sellers
    where id = (select value::uuid from pg_temp.step_b_context where key='seller_id')),
    'Approval reuses seller approval transition';
  assert (select kind = 'system' and user_id =
      'b1000000-0000-0000-0000-000000000001'
    from public.notifications where id = created_notification_id),
    'Approval creates existing system notification';
  assert exists (select 1 from public.notification_outbox as outbox
    where outbox.notification_id = created_notification_id and outbox.status = 'pending'),
    'Approval queues existing notification outbox delivery';
end;
$$;

set local role anon;
set local request.jwt.claims = '{"role":"anon"}';
do $$ begin
  assert exists (
    select 1 from public.products
    where id = (select value::uuid from pg_temp.step_b_context
      where key='approved_product_id')
  ), 'Approved listing is publicly visible';
end $$;

set local role authenticated;
set local request.jwt.claims = '{"sub":"b1000000-0000-0000-0000-000000000001","role":"authenticated"}';
do $$
declare
  prepared jsonb;
  seller_id uuid := (
    select value::uuid from pg_temp.step_b_context where key='seller_id'
  );
  product_id uuid;
  image_path text;
begin
  prepared := public.prepare_listing_submission(
    seller_id, 'private', 'Ignored', 'Hamburg'
  );
  assert prepared ->> 'seller_id' = seller_id::text,
    'Explicit retry preparation remains bound to the existing private seller';
  product_id := (prepared ->> 'product_id')::uuid;
  image_path := seller_id || '/' || product_id || '/reject.webp';
  insert into storage.objects (bucket_id, name, owner, metadata)
  values ('product-images', image_path, auth.uid(), '{"mimetype":"image/webp"}');
  perform public.submit_listing(
    product_id, seller_id,
    'b2000000-0000-0000-0000-000000000001',
    'Step B rejected listing',
    'A second complete listing used to verify rejection behavior.',
    'new', 4999, 'Hamburg', array[image_path], '{}'::jsonb
  );
  insert into pg_temp.step_b_context values ('rejected_product_id', product_id::text);
end;
$$;

set local request.jwt.claims = '{"sub":"b1000000-0000-0000-0000-000000000002","role":"authenticated"}';
do $$
declare
  onboarding jsonb;
  prepared jsonb;
  business_seller_id uuid;
begin
  onboarding := public.owner_start_directory(
    null::uuid, 'restaurant', 'Step B Geschäft', 'München'
  );
  business_seller_id := (onboarding -> 'seller' ->> 'id')::uuid;
  prepared := public.prepare_listing_submission(
    business_seller_id, 'business', 'Step B Geschäft', 'München'
  );
  assert prepared ->> 'seller_id' = business_seller_id::text,
    'Explicit preparation stays bound to the directory-created business';
  assert prepared ->> 'seller_kind' = 'business',
    'The explicit preparation path supports business sellers';
  assert (select status = 'pending' from public.sellers
    where id = (prepared ->> 'seller_id')::uuid),
    'Business seller also starts pending';
end;
$$;

set local request.jwt.claims = '{"sub":"b1000000-0000-0000-0000-000000000003","role":"authenticated","app_metadata":{"role":"admin"}}';
do $$
declare
  product_id uuid := (
    select value::uuid from pg_temp.step_b_context where key='rejected_product_id'
  );
  result jsonb;
begin
  result := public.moderate_listing(product_id, 'reject', 'Bitte Beschreibung ergänzen.');
  assert result ->> 'status' = 'rejected', 'Rejection returns rejected';
  assert (select status = 'rejected'
      and moderation_reason = 'Bitte Beschreibung ergänzen.'
      and published_at is null
    from public.products where id = product_id),
    'Rejection stores optional reason and stays private';
  assert exists (
    select 1 from public.notifications
    where id = (result ->> 'notification_id')::uuid
      and data ->> 'reason' = 'Bitte Beschreibung ergänzen.'
  ), 'Rejection notifies through existing notification data';
end;
$$;

set local role anon;
set local request.jwt.claims = '{"role":"anon"}';
do $$ begin
  assert not exists (
    select 1 from public.products
    where id = (select value::uuid from pg_temp.step_b_context
      where key='rejected_product_id')
  ), 'Rejected listing remains hidden from public reads';
end $$;

reset role;
do $$ begin
  assert exists (
    select 1 from pg_catalog.pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public' and tablename = 'products'
  ), 'Products are in the existing Realtime publication';
  assert (select relreplident = 'f' from pg_catalog.pg_class
    where oid = 'public.products'::regclass),
    'Products use full replica identity for Realtime updates';
end $$;

rollback;
