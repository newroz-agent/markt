-- Step E1.5 follow-up: a claimed OSM place whose seller is deleted reverts to a regular
-- unclaimed entry (FK claimed_seller_id ON DELETE SET NULL). Menu and reviews cannot
-- follow it: owner menus/hours/profile cascade with the seller, reviews.seller_id is
-- ON DELETE RESTRICT (a reviewed seller cannot be deleted at all), and imported places
-- have no menu table and reject directory reviews. What remains is the outreach status,
-- which must stop saying "claimed" once no seller is linked.
begin;

create function public.directory_imported_place_unclaimed()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  update public.directory_outreach_contacts contact
    set status = 'contacted', contacted_at = coalesce(contact.contacted_at, old.claimed_at)
  where contact.place_id = new.id and contact.status = 'claimed';
  return null;
end;
$$;

create trigger directory_imported_place_unclaimed
  after update of claimed_seller_id on public.directory_imported_places
  for each row when (old.claimed_seller_id is not null and new.claimed_seller_id is null)
  execute function public.directory_imported_place_unclaimed();

revoke all on function public.directory_imported_place_unclaimed() from public, anon, authenticated;

commit;
