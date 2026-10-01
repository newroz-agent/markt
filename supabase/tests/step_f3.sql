-- Step F3 acceptance: temporary no-ID overloads are gone and every UUID-first
-- replacement keeps its reviewed identity shape and client ACL. No fixtures needed.
begin;

do $$
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
  signature text;
begin
  assert not exists (
    select 1 from unnest(legacy_signatures) value
    where to_regprocedure(value) is not null
  ), 'all seven temporary legacy overloads are absent';

  assert not exists (
    select 1 from unnest(explicit_signatures) value
    where to_regprocedure(value) is null
  ), 'all seven UUID-first overloads remain';

  foreach signature in array explicit_signatures loop
    assert has_function_privilege('authenticated', signature, 'execute'),
      format('authenticated keeps execute on %s', signature);
    assert not has_function_privilege('anon', signature, 'execute'),
      format('anon cannot execute %s', signature);
    assert not has_function_privilege('service_role', signature, 'execute'),
      format('service_role has no client RPC execute on %s', signature);
  end loop;

  assert (
    select proargnames = array[
      'p_seller_id','p_seller_kind','p_seller_name','p_city'
    ]
    from pg_proc
    where oid = to_regprocedure(
      'public.prepare_listing_submission(uuid,public.seller_kind,text,text)'
    )
  ), 'listing preparation keeps its four PostgREST parameter keys';

  assert (
    select proargnames = array['p_seller_id']
    from pg_proc
    where oid = to_regprocedure('public.get_my_directory_onboarding(uuid)')
  ), 'onboarding getter requires p_seller_id';

  assert (
    select proargnames[1] = 'p_seller_id'
    from pg_proc
    where oid = to_regprocedure(
      'public.owner_upsert_directory_profile(uuid,public.directory_business_type,text,text,text,text,public.directory_spoken_language[],public.directory_cuisine[],smallint,boolean,boolean,boolean,public.directory_doctor_specialty,public.directory_insurance,boolean)'
    )
  ), 'directory profile mutation is UUID-first';

  assert (
    select proargnames = array[
      'p_existing_private_seller_id','p_directory_type','p_shop_name','p_city'
    ]
    from pg_proc
    where oid = to_regprocedure(
      'public.owner_start_directory(uuid,public.directory_business_type,text,text)'
    )
  ), 'business start keeps the explicit nullable private-source key';

  assert (
    select count(*) = 7
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
  ), 'exactly one explicit overload remains for each migrated API';

  assert not has_table_privilege('authenticated','public.sellers','insert'),
    'dropping wrappers does not reopen direct seller creation';
  assert not exists (
    select 1 from public.sellers
    where user_id is not null
    group by user_id, kind
    having count(*) > 1
  ), 'one seller per kind remains intact';
end;
$$;

rollback;
