-- Additive correction to the already-applied 005 badge function.
begin;

create or replace function public.is_verified_seller(target_seller_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.sellers as seller
    where seller.id = target_seller_id
      and seller.kind = 'business' and seller.status = 'approved'
      and exists (
        select 1 from public.seller_documents as document
        where document.seller_id = seller.id
          and document.kind = 'identity' and document.status = 'approved'
      )
      and exists (
        select 1 from public.seller_documents as document
        where document.seller_id = seller.id
          and document.kind = 'business_registration'
          and document.status = 'approved'
      )
  );
$$;
revoke all on function public.is_verified_seller(uuid) from public, anon, authenticated;
grant execute on function public.is_verified_seller(uuid) to anon, authenticated;

-- PostgREST computed field on sellers. Only a boolean is public; neither
-- legal addresses nor documents are exposed. Unknown country fails closed.
-- DE delivery alone, German-looking cities/postcodes, and coordinate bounding
-- boxes do not prove German origin. This scopes Phase3 to sellers explicitly
-- declaring Germany in their existing legal address, not physical item origin.
create or replace function public.phase3_in_germany(public.sellers)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.sellers as seller
    join public.seller_private_details as details on details.seller_id = seller.id
    where seller.id = $1.id and seller.status = 'approved'
      and details.legal_address ->> 'country_code' = 'DE'
  );
$$;
revoke all on function public.phase3_in_germany(public.sellers) from public, anon, authenticated;
grant execute on function public.phase3_in_germany(public.sellers) to anon, authenticated;

-- Favorites intentionally have no UPDATE policy. Clients insert explicit
-- auth.uid() with ON CONFLICT DO NOTHING, and scope reads/deletes by user_id.
notify pgrst, 'reload schema';
commit;
