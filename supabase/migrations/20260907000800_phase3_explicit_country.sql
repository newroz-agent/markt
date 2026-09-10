-- Explicit marketplace location, independent of legal/tax addresses or delivery.
begin;

-- Add without a default first: existing rows must remain unknown, not German.
alter table public.sellers
  add column country_code text check (country_code is null or country_code = 'DE');
alter table public.products
  add column country_code text check (country_code is null or country_code = 'DE');
alter table public.sellers alter column country_code set default 'DE';
alter table public.products alter column country_code set default 'DE';

comment on column public.sellers.country_code is
  'Explicit seller country. Existing NULL requires admin country validation before Phase3 availability; never infer from city or legal/tax address.';
comment on column public.products.country_code is
  'Explicit item country. Existing NULL requires admin country validation before Phase3 availability; ships_to and city are not country evidence.';

-- Preserve the PostgREST computed-field signature and approval check from 006.
create or replace function public.phase3_in_germany(public.sellers)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.sellers as seller
    where seller.id = $1.id and seller.status = 'approved'
      and seller.country_code = 'DE'
  );
$$;
revoke all on function public.phase3_in_germany(public.sellers) from public, anon, authenticated;
grant execute on function public.phase3_in_germany(public.sellers) to anon, authenticated;

-- No country RLS change: the existing Home feed intentionally remains ungated.
notify pgrst, 'reload schema';
commit;
