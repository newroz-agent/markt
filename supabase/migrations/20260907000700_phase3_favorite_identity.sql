-- Do not silently redirect an explicit favorite owner after a session switch.
begin;
create or replace function public.protect_favorite_write()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if tg_op = 'INSERT' and auth.uid() is not null
    and new.user_id is not null and new.user_id <> auth.uid() then
    raise exception 'Favorite user must match the current session'
      using errcode = '42501';
  end if;
  if auth.uid() is not null and not public.is_admin() then
    if tg_op = 'INSERT' then
      -- Preserve shipped inserts that relied on server-assigned ownership.
      new.user_id = auth.uid();
    elsif new.user_id is distinct from old.user_id
      or new.product_id is distinct from old.product_id then
      raise exception 'Favorite ownership is immutable';
    end if;
  end if;

  select product.price_cents into new.price_snapshot_cents
  from public.products as product where product.id = new.product_id;
  return new;
end;
$$;
commit;
