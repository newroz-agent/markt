-- Run against the effective local schema as an authenticated admin, then roll back.
begin;
-- Self-contained fixture user. Do not depend on any seeded step account.
insert into auth.users (id, email, raw_app_meta_data, raw_user_meta_data)
values (
  'a1000000-0000-0000-0000-000000000001',
  'admin-expansion@example.invalid',
  '{"role":"admin"}',
  '{"display_name":"Admin Expansion"}'
);
set local role authenticated;
select set_config('request.jwt.claim.sub','a1000000-0000-0000-0000-000000000001',true);
select set_config('request.jwt.claims','{"sub":"a1000000-0000-0000-0000-000000000001","role":"authenticated","app_metadata":{"role":"admin"}}',true);
do $$
declare
  doc public.seller_documents%rowtype;
  report_row public.reports%rowtype;
  result jsonb;
begin
  -- Insert valid fixtures using existing schema requirements. This assertion proves
  -- RPC updates pass protect_seller_document_write's admin-field guard.
  insert into public.seller_documents(seller_id,kind,storage_path,mime_type)
  select id,'other','admin-test/'||gen_random_uuid()||'.pdf','application/pdf'
  from public.sellers limit 1 returning * into doc;
  result := public.moderate_seller_document(doc.id,'approve',null);
  select * into doc from public.seller_documents where id=doc.id;
  assert doc.status='approved' and doc.reviewed_by=auth.uid() and doc.reviewed_at is not null,
    'seller document RPC must update protected review fields';

  insert into public.reports(product_id,reporter_id,reason)
  select id,null,'spam'::public.report_reason from public.products limit 1 returning * into report_row;
  result := public.resolve_report(report_row.id,'dismiss',null);
  select * into report_row from public.reports where id=report_row.id;
  assert report_row.status='dismissed' and report_row.resolved_at is not null,
    'dismiss must pass protect_report_fields and set resolved_at';

  insert into public.reports(seller_id,reporter_id,reason)
  select id,null,'fraud'::public.report_reason from public.sellers limit 1 returning * into report_row;
  result := public.resolve_report(report_row.id,'block_listing',null);
  assert false, 'non-product target must not be blockable';
exception when sqlstate '22023' then
  -- Expected: product blocking is prohibited for seller/review/message reports.
  null;
end $$;
rollback;
