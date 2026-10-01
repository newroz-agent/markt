-- Additive admin moderation queues for seller verification and reports.
-- Existing listing moderation RPC is intentionally unchanged.
begin;

create or replace function public.get_admin_verification_queue(p_limit integer default 50)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare result jsonb;
begin
  if auth.uid() is null or not public.is_admin() then raise exception 'Administrator role required' using errcode='42501'; end if;
  select coalesce(jsonb_agg(row_to_json(q) order by q.created_at), '[]'::jsonb) into result
  from (
    select d.id, d.seller_id, d.kind, d.status, d.mime_type, d.storage_path, d.created_at,
           s.shop_name, s.kind as seller_kind
    from public.seller_documents d join public.sellers s on s.id=d.seller_id
    where d.status='pending'::public.seller_document_status
    order by d.created_at, d.id limit greatest(1, least(coalesce(p_limit,50),100))
  ) q;
  return jsonb_build_object('items', result, 'pending', jsonb_array_length(result));
end; $$;

create or replace function public.get_admin_reports(p_limit integer default 50)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare result jsonb;
begin
  if auth.uid() is null or not public.is_admin() then raise exception 'Administrator role required' using errcode='42501'; end if;
  select coalesce(jsonb_agg(row_to_json(q) order by q.created_at), '[]'::jsonb) into result
  from (
    select r.id, r.product_id, r.seller_id, r.review_id, r.message_id, r.reporter_id,
           case when r.product_id is not null then 'product' when r.seller_id is not null then 'seller' when r.review_id is not null then 'review' else 'message' end as target_type,
           r.reason, r.details, r.status, r.created_at,
           coalesce(p.title, s.shop_name, case when r.review_id is not null then 'Reported review' when r.message_id is not null then 'Reported message' end) as title,
           p.status as product_status, s.shop_name,
           m.kind as message_kind, m.body as message_body,
           case when r.message_id is not null then m.media_path else null end as message_media_path,
           case when r.message_id is not null then m.product_id else null end as message_product_id
    from public.reports r
    left join public.products p on p.id=r.product_id
    left join public.sellers s on s.id=coalesce(r.seller_id,p.seller_id)
    left join public.messages m on m.id=r.message_id
    where r.status in ('pending'::public.report_status,'reviewing'::public.report_status)
    order by r.created_at, r.id limit greatest(1, least(coalesce(p_limit,50),100))
  ) q;
  return jsonb_build_object('items', result, 'open', jsonb_array_length(result));
end; $$;

create or replace function public.moderate_seller_document(p_document_id uuid, p_decision text, p_note text default null)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare d public.seller_documents%rowtype; recipient uuid; decision text := lower(pg_catalog.btrim(coalesce(p_decision,''))); note text := nullif(pg_catalog.btrim(p_note),'');
begin
  if auth.uid() is null or not public.is_admin() then raise exception 'Administrator role required' using errcode='42501'; end if;
  if decision not in ('approve','reject') then raise exception 'Decision must be approve or reject' using errcode='22023'; end if;
  if note is not null and char_length(note)>2000 then raise exception 'Note too long' using errcode='22023'; end if;
  select * into d from public.seller_documents where id=p_document_id for update;
  if not found then raise exception 'Seller document not found' using errcode='P0002'; end if;
  if d.status <> 'pending' then raise exception 'Only pending documents can be moderated' using errcode='22023'; end if;
  update public.seller_documents set status=case when decision='approve' then 'approved'::public.seller_document_status else 'rejected'::public.seller_document_status end, admin_note=case when decision='reject' then note else null end, reviewed_by=auth.uid(), reviewed_at=now() where id=d.id returning * into d;
  select user_id into recipient from public.sellers where id=d.seller_id;
  if recipient is not null then perform public.create_user_notification(recipient,'system',case when decision='approve' then 'notifications.seller_document.approved.title' else 'notifications.seller_document.rejected.title' end,case when decision='approve' then 'notifications.seller_document.approved.body' else 'notifications.seller_document.rejected.body' end,jsonb_strip_nulls(jsonb_build_object('documentId',d.id,'kind',d.kind,'reason',d.admin_note))); end if;
  return jsonb_build_object('id',d.id,'status',d.status,'reviewed_at',d.reviewed_at);
end; $$;

create or replace function public.resolve_report(p_report_id uuid, p_action text, p_reason text default null)
returns jsonb language plpgsql security definer set search_path = '' as $$
#variable_conflict use_column
declare r public.reports%rowtype; product_row public.products%rowtype; recipient uuid; action text := lower(pg_catalog.btrim(coalesce(p_action,''))); reason text := nullif(pg_catalog.btrim(p_reason),'');
begin
  if auth.uid() is null or not public.is_admin() then raise exception 'Administrator role required' using errcode='42501'; end if;
  if action not in ('dismiss','block_listing') then raise exception 'Invalid report action' using errcode='22023'; end if;
  select * into r from public.reports where id=p_report_id for update;
  if not found then raise exception 'Report not found' using errcode='P0002'; end if;
  if r.status in ('resolved','dismissed') then return jsonb_build_object('id',r.id,'status',r.status); end if;
  if action='block_listing' and r.product_id is null then raise exception 'Only product reports can block a listing' using errcode='22023'; end if;
  if action='block_listing' then
    select * into product_row from public.products where id=r.product_id for update;
    if not found then raise exception 'Reported listing not found' using errcode='P0002'; end if;
    update public.products set status='blocked'::public.product_status, moderation_reason=reason, moderated_at=now(), moderated_by=auth.uid() where id=product_row.id returning * into product_row;
    select user_id into recipient from public.sellers where id=product_row.seller_id;
    if recipient is not null then perform public.create_user_notification(recipient,'system','notifications.listing.blocked.title','notifications.listing.blocked.body',jsonb_strip_nulls(jsonb_build_object('productId',product_row.id,'reason',reason))); end if;
  end if;
  update public.reports set status=case when action='dismiss' then 'dismissed'::public.report_status else 'resolved'::public.report_status end, admin_notes=reason, resolved_at=now() where id=r.id returning * into r;
  return jsonb_build_object('id',r.id,'status',r.status,'product_status',case when product_row.id is null then null else product_row.status end);
end; $$;

revoke all on function public.get_admin_verification_queue(integer) from public, anon;
revoke all on function public.get_admin_reports(integer) from public, anon;
revoke all on function public.moderate_seller_document(uuid,text,text) from public, anon;
revoke all on function public.resolve_report(uuid,text,text) from public, anon;
grant execute on function public.get_admin_verification_queue(integer) to authenticated;
grant execute on function public.get_admin_reports(integer) to authenticated;
grant execute on function public.moderate_seller_document(uuid,text,text) to authenticated;
grant execute on function public.resolve_report(uuid,text,text) to authenticated;
commit;
