-- One-time local upgrade test, BEFORE 008. Applies 008 without resetting data.
-- psql LOCAL_DB_URL -X -v ON_ERROR_STOP=1 -f supabase/tests/phase3_country_upgrade.sql
create temp table country_upgrade_sellers as select id, to_jsonb(s) as row from public.sellers s;
create temp table country_upgrade_products as select id, to_jsonb(p) as row from public.products p;

\ir ../migrations/20260907000800_phase3_explicit_country.sql

do $$ begin
  assert not exists (select 1 from public.sellers where country_code is not null), 'Existing seller countries stay NULL';
  assert not exists (select 1 from public.products where country_code is not null), 'Existing product countries stay NULL';
  assert not exists (
    select 1 from public.sellers s full join country_upgrade_sellers old using (id)
    where (to_jsonb(s) - 'country_code') is distinct from old.row
  ), 'All existing seller data and row counts preserved';
  assert not exists (
    select 1 from public.products p full join country_upgrade_products old using (id)
    where (to_jsonb(p) - 'country_code') is distinct from old.row
  ), 'All existing product data and row counts preserved';
end $$;
