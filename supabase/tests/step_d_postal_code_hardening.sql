-- Step D follow-up acceptance: products.postal_code is never persisted on a write,
-- regardless of role. Column-level REVOKE is inert here (table-level grants on
-- public.products silently override it), so enforcement is trigger-based, mirroring
-- how Step D already owns latitude/longitude. All fixtures roll back.
begin;

-- A direct write of postal_code is overwritten to NULL by the trigger, even when the
-- writing role (authenticated/postgres) holds the table-level INSERT/UPDATE grant.
do $$
declare
  probe_id uuid := 'e1000000-0000-0000-0000-000000000001';
  probe_desc text := 'Local-only probe description long enough to satisfy the products_description_check constraint (Step D postal_code hardening fixture).';
  stored text;
begin
  -- Probe: INSERT carrying an explicit PLZ. Must be forced to NULL by the trigger.
  insert into public.products (
    id, seller_id, category_id, title, slug, description,
    condition, status, price_cents, city, country_code, quantity, postal_code
  )
  select
    probe_id,
    seller_id, category_id, 'plz write probe', 'plz-write-probe', probe_desc,
    'new', 'active', 1, 'Berlin', 'DE', 1, '10115'
  from (select id, category_id, seller_id
        from public.products where country_code='DE' and status='active' limit 1) as src
  on conflict (id) do update
  set postal_code = '10115' || '-' || 'probe';

  select postal_code into stored
  from public.products where id = probe_id;

  assert stored is null,
    format('postal_code must be forced to NULL on INSERT, got %L', stored);
end;
$$;

-- UPDATE path is equally forced to NULL.
do $$
declare
  probe_id uuid := 'e1000000-0000-0000-0000-000000000001';
  stored text;
begin
  update public.products set postal_code = '10115' where id = probe_id;
  select postal_code into stored from public.products where id = probe_id;
  assert stored is null,
    format('postal_code UPDATE must be forced to NULL, got %L', stored);
end;
$$;

-- Sanity: the trigger exists and is attached to products, and no row retains a PLZ.
do $$
begin
  assert exists (
    select 1 from pg_trigger
    where tgname = 'null_unless_server_postal_code'
      and tgenabled = 'O'
  ), 'null_unless_server_postal_code trigger must be enabled on products';

  assert not exists (
    select 1 from public.products
    where postal_code is not null
  ), 'No products row should retain a persisted postal_code after hardening';
end;
$$;

rollback;
