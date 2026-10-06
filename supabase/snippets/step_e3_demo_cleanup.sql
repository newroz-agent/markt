-- Local-only E3 demo cleanup. Run only through tools/demo/e3_local_demo.sh cleanup.
-- The wrapper removes any matching Storage objects through the Storage API first.
\set ON_ERROR_STOP on
\ir step_e3_demo_local_guard.sql

begin;

do $$
begin
  if exists (select 1 from storage.objects where bucket_id = 'product-images' and name like 'e3d0/%') then
    raise exception 'E3 Storage objects remain; remove them through the Storage API first';
  end if;
  if exists (
    select 1 from public.products
    where id::text like 'e3d0%'
      and (slug not like 'e3d0-%' or specifications->>'demo_batch' is distinct from 'e3d0')
  ) then
    raise exception 'Unexpected E3 product identity; inspect before cleanup';
  end if;
  if exists (
    select 1 from public.chats where seller_id::text like 'e3d0%'
  ) or exists (
    select 1 from public.reviews where seller_id::text like 'e3d0%'
  ) or exists (
    select 1 from public.order_items where seller_id::text like 'e3d0%'
  ) or exists (
    select 1 from public.inventory_reservations where product_id::text like 'e3d0%'
  ) then
    raise exception 'E3 rows have non-demo interactions; inspect before cleanup';
  end if;
end;
$$;

delete from public.product_images where id::text like 'e3d0%';
delete from public.products where id::text like 'e3d0%' and specifications->>'demo_batch' = 'e3d0';
delete from public.sellers where id::text like 'e3d0%' and slug like 'e3d0-%';
delete from auth.users where id::text like 'e3d0%' and email like 'e3d0-demo-%@local.invalid';

commit;
