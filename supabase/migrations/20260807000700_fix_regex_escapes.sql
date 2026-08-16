-- Fixes two regex literals that were written with doubled backslashes.
--
-- With standard_conforming_strings on (the default), '\\s' in a plain
-- string literal is a literal backslash followed by 's', not the whitespace
-- class. Verified against PostgreSQL 14:
--
--   select '1.0' ~ '^[0-9]+\\.[0-9]+(?:\\.[0-9]+)?$';        -- false
--   select regexp_replace('a   b', '\\s+', ' ', 'g');        -- 'a   b'
--
-- Neither call site is cosmetic:
--   * legal_documents rejected every version string, so no imprint, terms,
--     privacy or withdrawal document could be inserted at all.
--   * save_recent_search stored raw queries, so "nike  schuhe" and
--     "nike schuhe" were kept as separate history entries and the dedupe
--     compare below them never matched.

begin;

alter table public.legal_documents
  drop constraint if exists legal_documents_version_check;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'legal_documents_version_check'
      and conrelid = 'public.legal_documents'::regclass
  ) then
    alter table public.legal_documents
      add constraint legal_documents_version_check
      check (version ~ '^[0-9]+\.[0-9]+(?:\.[0-9]+)?$');
  end if;
end;
$$;

create or replace function public.save_recent_search(p_query text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  normalized_query text := regexp_replace(pg_catalog.btrim(p_query), '\s+', ' ', 'g');
begin
  if current_user_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  if normalized_query is null
    or char_length(normalized_query) not between 2 and 120 then
    raise exception 'Search query must contain between 2 and 120 characters'
      using errcode = '22023';
  end if;

  delete from public.search_history as history
  where history.user_id = current_user_id
    and lower(history.query) = lower(normalized_query);

  insert into public.search_history (user_id, query)
  values (current_user_id, normalized_query);

  delete from public.search_history as history
  where history.user_id = current_user_id
    and history.id in (
      select oldest.id
      from public.search_history as oldest
      where oldest.user_id = current_user_id
      order by oldest.created_at desc, oldest.id desc
      offset 20
    );
end;
$$;

-- Collapse whitespace in history rows written while the pattern was inert,
-- then drop the duplicates this reveals, keeping the most recent per user.
update public.search_history
set query = regexp_replace(pg_catalog.btrim(query), '\s+', ' ', 'g')
where query <> regexp_replace(pg_catalog.btrim(query), '\s+', ' ', 'g');

delete from public.search_history as history
where history.id in (
  select id
  from (
    select
      id,
      row_number() over (
        partition by user_id, lower(query)
        order by created_at desc, id desc
      ) as rank
    from public.search_history
  ) as ranked
  where ranked.rank > 1
);

commit;
