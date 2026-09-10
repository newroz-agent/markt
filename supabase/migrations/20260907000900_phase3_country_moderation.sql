-- Existing unknown countries require moderation, not owner self-validation.
begin;

create function public.protect_phase3_country_update()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  -- Match seller/product moderation: authenticated owners cannot change
  -- managed fields; admins and trusted server-side maintenance can.
  if auth.uid() is not null and not public.is_admin()
    and new.country_code is distinct from old.country_code then
    raise exception 'Country changes require admin validation'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

create trigger protect_phase3_country_update
  before update of country_code on public.sellers
  for each row execute function public.protect_phase3_country_update();
create trigger protect_phase3_country_update
  before update of country_code on public.products
  for each row execute function public.protect_phase3_country_update();

commit;
