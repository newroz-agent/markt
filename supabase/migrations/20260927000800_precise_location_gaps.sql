-- Close two precise-location gaps found in the E3 audit (2026-09-27) without weakening
-- the Step C/D privacy rules:
-- 1. An admin can always suspend or reject a seller. When a seller leaves 'approved', the
--    public precise-location fields are cleared in the same write instead of raising.
--    Every other attempt to publish a pin while ineligible still raises 42501.
-- 2. Verification depends on the directory profile type since E1, so creating, deleting
--    or re-typing a profile runs the same wipe as a document change whenever the seller
--    is no longer verified afterwards.
-- The owner's private address draft (E3, business_location_drafts) is never touched here,
-- so the pin can be republished after re-verification.
begin;

create or replace function public.protect_seller_precise_location()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  new.address_line := nullif(pg_catalog.btrim(new.address_line), '');

  -- Leaving 'approved' (suspension, rejection, back to pending) always succeeds and
  -- takes the public pin down in the same write.
  if tg_op = 'UPDATE' and old.status = 'approved' and new.status <> 'approved' then
    new.precise_location_opt_in := false;
  end if;

  if not new.precise_location_opt_in then
    new.latitude := null;
    new.longitude := null;
    new.address_line := null;
    return new;
  end if;

  if new.kind <> 'business'
    or new.status <> 'approved'
    or new.latitude is null
    or new.longitude is null
    or not public.is_verified_seller(new.id) then
    raise exception 'Precise location requires an opted-in verified business'
      using errcode = '42501';
  end if;

  return new;
end;
$$;

-- Reuses the Step D wipe (it only needs seller_id on NEW/OLD).
create trigger clear_unverified_seller_location
  after insert or delete or update of type on public.business_directory_profiles
  for each row execute function public.clear_unverified_seller_location();

commit;
