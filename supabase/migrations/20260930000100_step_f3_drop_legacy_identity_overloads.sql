-- Step F3: remove the temporary no-ID compatibility overloads after every
-- Flutter, harness, seed, and current-schema SQL caller moved to UUID-first APIs.
-- This migration performs no table write and never uses CASCADE.
begin;

do $preflight$
declare
  legacy_signatures constant text[] := array[
    'public.prepare_listing_submission(public.seller_kind,text,text)',
    'public.get_my_directory_onboarding()',
    'public.owner_set_directory_type(public.directory_business_type)',
    'public.owner_upsert_directory_profile(public.directory_business_type,text,text,text,text,public.directory_spoken_language[],public.directory_cuisine[],smallint,boolean,boolean,boolean,public.directory_doctor_specialty,public.directory_insurance,boolean)',
    'public.owner_replace_directory_hours(jsonb)',
    'public.owner_replace_directory_menu(jsonb)',
    'public.owner_start_directory(public.directory_business_type,text,text)'
  ];
  explicit_signatures constant text[] := array[
    'public.prepare_listing_submission(uuid,public.seller_kind,text,text)',
    'public.get_my_directory_onboarding(uuid)',
    'public.owner_set_directory_type(uuid,public.directory_business_type)',
    'public.owner_upsert_directory_profile(uuid,public.directory_business_type,text,text,text,text,public.directory_spoken_language[],public.directory_cuisine[],smallint,boolean,boolean,boolean,public.directory_doctor_specialty,public.directory_insurance,boolean)',
    'public.owner_replace_directory_hours(uuid,jsonb)',
    'public.owner_replace_directory_menu(uuid,jsonb)',
    'public.owner_start_directory(uuid,public.directory_business_type,text,text)'
  ];
  missing text[];
  unexpected text[];
begin
  select array_agg(signature order by signature)
  into missing
  from unnest(legacy_signatures || explicit_signatures) signature
  where to_regprocedure(signature) is null;
  if cardinality(missing) > 0 then
    raise exception 'F3 preflight failed: expected overloads are missing: %', missing
      using errcode = '55000';
  end if;

  select array_agg(procedure_row.oid::regprocedure::text
    order by procedure_row.oid::regprocedure::text)
  into unexpected
  from pg_proc procedure_row
  join pg_namespace namespace_row on namespace_row.oid = procedure_row.pronamespace
  where namespace_row.nspname = 'public'
    and procedure_row.proname = any(array[
      'prepare_listing_submission',
      'get_my_directory_onboarding',
      'owner_set_directory_type',
      'owner_upsert_directory_profile',
      'owner_replace_directory_hours',
      'owner_replace_directory_menu',
      'owner_start_directory'
    ]::name[])
    and procedure_row.oid <> all(array(
      select to_regprocedure(signature)::oid
      from unnest(legacy_signatures || explicit_signatures) signature
    ));
  if cardinality(unexpected) > 0 then
    raise exception 'F3 preflight failed: unreviewed overloads exist: %', unexpected
      using errcode = '55000';
  end if;
end;
$preflight$;

drop function public.prepare_listing_submission(
  public.seller_kind, text, text
);
drop function public.get_my_directory_onboarding();
drop function public.owner_set_directory_type(
  public.directory_business_type
);
drop function public.owner_upsert_directory_profile(
  public.directory_business_type, text, text, text, text,
  public.directory_spoken_language[], public.directory_cuisine[], smallint,
  boolean, boolean, boolean, public.directory_doctor_specialty,
  public.directory_insurance, boolean
);
drop function public.owner_replace_directory_hours(jsonb);
drop function public.owner_replace_directory_menu(jsonb);
drop function public.owner_start_directory(
  public.directory_business_type, text, text
);

do $postflight$
declare
  legacy_signatures constant text[] := array[
    'public.prepare_listing_submission(public.seller_kind,text,text)',
    'public.get_my_directory_onboarding()',
    'public.owner_set_directory_type(public.directory_business_type)',
    'public.owner_upsert_directory_profile(public.directory_business_type,text,text,text,text,public.directory_spoken_language[],public.directory_cuisine[],smallint,boolean,boolean,boolean,public.directory_doctor_specialty,public.directory_insurance,boolean)',
    'public.owner_replace_directory_hours(jsonb)',
    'public.owner_replace_directory_menu(jsonb)',
    'public.owner_start_directory(public.directory_business_type,text,text)'
  ];
  explicit_signatures constant text[] := array[
    'public.prepare_listing_submission(uuid,public.seller_kind,text,text)',
    'public.get_my_directory_onboarding(uuid)',
    'public.owner_set_directory_type(uuid,public.directory_business_type)',
    'public.owner_upsert_directory_profile(uuid,public.directory_business_type,text,text,text,text,public.directory_spoken_language[],public.directory_cuisine[],smallint,boolean,boolean,boolean,public.directory_doctor_specialty,public.directory_insurance,boolean)',
    'public.owner_replace_directory_hours(uuid,jsonb)',
    'public.owner_replace_directory_menu(uuid,jsonb)',
    'public.owner_start_directory(uuid,public.directory_business_type,text,text)'
  ];
begin
  if exists (
    select 1 from unnest(legacy_signatures) signature
    where to_regprocedure(signature) is not null
  ) then
    raise exception 'F3 postflight failed: a legacy overload survived'
      using errcode = '55000';
  end if;
  if exists (
    select 1 from unnest(explicit_signatures) signature
    where to_regprocedure(signature) is null
  ) then
    raise exception 'F3 postflight failed: an explicit overload was removed'
      using errcode = '55000';
  end if;
end;
$postflight$;

notify pgrst, 'reload schema';
commit;
