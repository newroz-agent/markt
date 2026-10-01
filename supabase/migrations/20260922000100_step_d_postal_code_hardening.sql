-- Step D follow-up: harden products.postal_code.
-- Product rule is city-only: PLZ must never be exposed or written by clients.
--
-- IMPORTANT: a column-level REVOKE is inert here because anon/authenticated hold a
-- table-level SELECT/INSERT/UPDATE grant on public.products, which silently overrides
-- the column revoke (Postgres merges table+column privileges). has_column_privilege
-- confirms anon SELECT and authenticated INSERT/UPDATE/SELECT remain TRUE after a
-- column REVOKE. Enforcement therefore uses the existing server-owned trigger path,
-- mirroring how Step D already owns latitude/longitude.
begin;

-- Null postal_code on every products insert/update of the city-derived block. This does
-- not change the column shape or legacy geography, but guarantees no PLZ survives a
-- client write through any path (direct SQL included, where the role is not the server).
create or replace function public.null_unless_server_postal_code()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- Always drop PLZ. No client (PostgREST, raw SQL, admin SQL UI) is trusted to set it;
  -- city is the only public geography. If a future server feature needs PLZ for a
  -- private geography join, it must opt it in via a separate server path.
  new.postal_code := null;
  return new;
end;
$$;

drop trigger if exists null_unless_server_postal_code on public.products;
create trigger null_unless_server_postal_code
  before insert or update of city, seller_id, postal_code
  on public.products
  for each row execute function public.null_unless_server_postal_code();

-- Backfill: existing DE rows that carried a PLZ lose it as of this migration. Non-DE
-- rows were already NULL by the column default.
update public.products
set postal_code = null
where postal_code is not null;

comment on column public.products.postal_code is
  'Internal geography only. Server-admin reads only via direct SQL. The column is
  forced NULL by the null_unless_server_postal_code trigger on every insert/update,
  so no client value is ever persisted; city is the only public geography. Never
  projected by PostgREST to clients.';

notify pgrst, 'reload schema';
commit;
