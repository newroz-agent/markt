-- Unified listing model: moderation triggers.
-- 1) Sellers (private AND business) always start pending; the legacy
--    private auto-approve path in prepare_seller_write() is removed.
-- 2) Products submitted by non-admins are forced to pending_review and
--    status transitions are reserved for moderation.
-- 3) Publishing a listing (status -> active) approves a pending/rejected
--    seller so the unified review queue is the single moderation entrypoint.
-- 4) Location is city-only by app scope: postal_code/latitude/longitude stay
--    in the schema but are quarantined (no client writes; reserved).

create or replace function public.prepare_seller_write()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is not null and not public.is_admin() then
    if tg_op = 'INSERT' then
      if new.user_id is distinct from auth.uid() then
        raise exception 'A seller application must belong to the authenticated user';
      end if;

      new.status = 'pending';
      new.approved_at = null;
      new.rejection_reason = null;
      new.rating_average = 0;
      new.rating_count = 0;
    else
      if new.user_id is distinct from old.user_id
        or new.kind is distinct from old.kind
        or new.status is distinct from old.status
        or new.approved_at is distinct from old.approved_at
        or new.rejection_reason is distinct from old.rejection_reason
        or new.rating_average is distinct from old.rating_average
        or new.rating_count is distinct from old.rating_count then
        raise exception 'Managed seller fields cannot be changed by clients';
      end if;
    end if;
  end if;

  if new.status = 'approved' then
    new.approved_at = coalesce(new.approved_at, now());
    new.rejection_reason = null;
  else
    new.approved_at = null;
  end if;

  return new;
end;
$$;

create or replace function public.prepare_product_write()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is not null and not public.is_admin() then
    if tg_op = 'INSERT' then
      new.status = 'pending_review';
      new.published_at = null;
    elsif new.status is distinct from old.status then
      raise exception 'Product status transitions are reserved for moderation';
    end if;
  end if;

  if new.status = 'active' then
    new.published_at = coalesce(new.published_at, now());

    update public.sellers as seller
    set status = 'approved',
        approved_at = coalesce(seller.approved_at, now()),
        rejection_reason = null
    where seller.id = new.seller_id
      and seller.status in ('pending', 'rejected');
  elsif new.status <> 'active' then
    new.published_at = null;
  end if;

  return new;
end;
$$;

drop trigger if exists prepare_product_write on public.products;
create trigger prepare_product_write
  before insert or update on public.products
  for each row execute function public.prepare_product_write();

revoke all on function public.prepare_product_write() from public;
