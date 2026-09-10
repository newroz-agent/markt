-- "Verifiziert" may only be shown when backed by the actual verification
-- state: an approved business seller with at least one approved verification
-- document. Verification documents are hidden from clients by RLS, so the
-- check runs server-side and exposes only a boolean.
begin;

create or replace function public.is_verified_seller(target_seller_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.sellers as seller
    join public.seller_documents as document
      on document.seller_id = seller.id
    where seller.id = target_seller_id
      and seller.kind = 'business'
      and seller.status = 'approved'
      and document.status = 'approved'
  );
$$;

revoke all on function public.is_verified_seller(uuid) from public, anon;
grant execute on function public.is_verified_seller(uuid) to anon, authenticated;

commit;
