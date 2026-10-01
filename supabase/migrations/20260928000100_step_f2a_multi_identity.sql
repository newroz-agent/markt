-- Step F2a: database-only multi-identity foundation.
--
-- This migration deliberately performs no data rewrite. Existing seller identities,
-- listings, directory rows, messages, orders, reviews, and notifications retain their
-- current seller_id values and meanings. New explicit-ID RPC overloads make identity
-- selection server-verifiable while deterministic wrappers keep the pre-F2a clients
-- operational until the F2b switcher is deployed.
begin;

-- ---------------------------------------------------------------------------
-- Fail-closed preflight
-- ---------------------------------------------------------------------------
-- Abort before any DDL unless the schema is exactly the effective E2-era shape this
-- migration was reviewed against. In particular, never silently repair covers or
-- identity duplicates: those require an explicit operator decision.
do $preflight$
declare
  missing_functions text[];
  unexpected_functions text[];
  missing_policies text[];
  missing_triggers text[];
begin
  if not exists (
    select 1
    from pg_catalog.pg_constraint as constraint_row
    join pg_catalog.pg_class as table_row
      on table_row.oid = constraint_row.conrelid
    join pg_catalog.pg_namespace as namespace_row
      on namespace_row.oid = table_row.relnamespace
    join pg_catalog.pg_attribute as user_id_column
      on user_id_column.attrelid = table_row.oid
      and user_id_column.attname = 'user_id'
      and not user_id_column.attisdropped
    join pg_catalog.pg_index as index_row
      on index_row.indexrelid = constraint_row.conindid
    where namespace_row.nspname = 'public'
      and table_row.relname = 'sellers'
      and constraint_row.conname = 'sellers_user_id_key'
      and constraint_row.contype = 'u'
      and constraint_row.conkey = array[user_id_column.attnum]::smallint[]
      and constraint_row.convalidated
      and not constraint_row.condeferrable
      and not constraint_row.condeferred
      and index_row.indisunique
      and index_row.indisvalid
      and index_row.indisready
      and index_row.indnkeyatts = 1
      and index_row.indnatts = 1
  ) then
    raise exception
      'F2a preflight failed: sellers_user_id_key must be the non-deferrable UNIQUE(user_id) constraint'
      using errcode = '55000';
  end if;

  if exists (
    select 1
    from pg_catalog.pg_constraint as constraint_row
    where constraint_row.conrelid = 'public.sellers'::regclass
      and constraint_row.conname = 'sellers_user_kind_key'
  ) or pg_catalog.to_regclass('public.sellers_user_kind_key') is not null then
    raise exception
      'F2a preflight failed: sellers_user_kind_key must not already exist'
      using errcode = '55000';
  end if;

  if exists (
    select 1
    from public.sellers as seller
    where seller.user_id is not null
    group by seller.user_id, seller.kind
    having count(*) > 1
  ) then
    raise exception
      'F2a preflight failed: duplicate non-null (user_id, kind) seller identities exist'
      using errcode = '55000';
  end if;

  select pg_catalog.array_agg(expected.signature order by expected.signature)
    into missing_functions
  from pg_catalog.unnest(array[
    'public.owns_seller(uuid)',
    'public.is_admin()',
    'public.is_marketplace_german_city(text)',
    'public.phase3_in_germany(public.sellers)',
    'public.is_verified_seller(uuid)',
    'public.directory_required_document_kinds(public.directory_business_type)',
    'public.create_user_notification(uuid,public.notification_kind,text,text,jsonb)',
    'public.prepare_listing_submission(public.seller_kind,text,text)',
    'public.can_manage_product_image_upload_path(text)',
    'public.submit_listing(uuid,uuid,uuid,text,text,public.product_condition,bigint,text,text[],jsonb,bigint)',
    'public.get_my_profile()',
    'public.get_public_profile(text)',
    'public.get_my_directory_onboarding()',
    'public.owner_set_directory_type(public.directory_business_type)',
    'public.owner_upsert_directory_profile(public.directory_business_type,text,text,text,text,public.directory_spoken_language[],public.directory_cuisine[],smallint,boolean,boolean,boolean,public.directory_doctor_specialty,public.directory_insurance,boolean)',
    'public.owner_replace_directory_hours(jsonb)',
    'public.owner_replace_directory_menu(jsonb)',
    'public.owner_start_directory(public.directory_business_type,text,text)',
    'public.get_chat_inbox(uuid)',
    'public.get_unread_chat_count()',
    'public.can_review_order_item(uuid,uuid,uuid,public.review_kind)',
    'public.notify_chat_message()',
    'public.notify_order_change()',
    'public.record_product_price_change()',
    'public.moderate_listing(uuid,text,text)',
    'public.moderate_seller_document(uuid,text,text)',
    'public.resolve_report(uuid,text,text)',
    'public.prepare_seller_write()',
    'public.queue_notification_delivery()',
    'public.sync_seller_directory_type()',
    'public.guard_seller_directory_type()',
    'public.approve_directory_seller_if_complete()',
    'public.validate_directory_menu_write()',
    'public.validate_directory_review_write()',
    'public.refresh_review_aggregates()',
    'public.recalculate_review_aggregates(uuid,uuid)',
    'public.validate_directory_profile_write()'
  ]::text[]) as expected(signature)
  where pg_catalog.to_regprocedure(expected.signature) is null;

  if coalesce(pg_catalog.cardinality(missing_functions), 0) <> 0 then
    raise exception 'F2a preflight failed: expected functions are missing: %', missing_functions
      using errcode = '55000';
  end if;

  -- Reject unreviewed overloads of every name whose parameter-key dispatch changes in
  -- this migration. This catches stale nine/ten-input listing functions and defaulted
  -- directory variants, not merely a single known obsolete identity.
  select pg_catalog.array_agg(procedure_row.oid::regprocedure::text order by procedure_row.oid::regprocedure::text)
    into unexpected_functions
  from pg_catalog.pg_proc as procedure_row
  join pg_catalog.pg_namespace as namespace_row
    on namespace_row.oid = procedure_row.pronamespace
  where namespace_row.nspname = 'public'
    and procedure_row.proname = any(array[
      'prepare_listing_submission',
      'submit_listing',
      'get_my_directory_onboarding',
      'owner_set_directory_type',
      'owner_upsert_directory_profile',
      'owner_replace_directory_hours',
      'owner_replace_directory_menu',
      'owner_start_directory',
      'get_chat_inbox'
    ]::name[])
    and procedure_row.oid <> all(array[
      pg_catalog.to_regprocedure('public.prepare_listing_submission(public.seller_kind,text,text)')::oid,
      pg_catalog.to_regprocedure('public.submit_listing(uuid,uuid,uuid,text,text,public.product_condition,bigint,text,text[],jsonb,bigint)')::oid,
      pg_catalog.to_regprocedure('public.get_my_directory_onboarding()')::oid,
      pg_catalog.to_regprocedure('public.owner_set_directory_type(public.directory_business_type)')::oid,
      pg_catalog.to_regprocedure('public.owner_upsert_directory_profile(public.directory_business_type,text,text,text,text,public.directory_spoken_language[],public.directory_cuisine[],smallint,boolean,boolean,boolean,public.directory_doctor_specialty,public.directory_insurance,boolean)')::oid,
      pg_catalog.to_regprocedure('public.owner_replace_directory_hours(jsonb)')::oid,
      pg_catalog.to_regprocedure('public.owner_replace_directory_menu(jsonb)')::oid,
      pg_catalog.to_regprocedure('public.owner_start_directory(public.directory_business_type,text,text)')::oid,
      pg_catalog.to_regprocedure('public.get_chat_inbox(uuid)')::oid
    ]::oid[]);

  if coalesce(pg_catalog.cardinality(unexpected_functions), 0) <> 0 then
    raise exception 'F2a preflight failed: unreviewed old function overloads exist: %', unexpected_functions
      using errcode = '55000';
  end if;

  -- The removed ten-input listing identity must stay absent; otherwise defaulted
  -- signatures become ambiguous to PostgREST and to positional SQL callers.
  if pg_catalog.to_regprocedure(
    'public.submit_listing(uuid,uuid,uuid,text,text,public.product_condition,bigint,text,text[],jsonb)'
  ) is not null then
    raise exception
      'F2a preflight failed: obsolete ten-input submit_listing still exists'
      using errcode = '55000';
  end if;

  select pg_catalog.array_agg(expected.signature order by expected.signature)
    into unexpected_functions
  from pg_catalog.unnest(array[
    'public.is_owned_by_current_user(public.sellers)',
    'public.get_my_identity_catalog()',
    'public.prepare_listing_submission(uuid,public.seller_kind,text,text)',
    'public.f2a_directory_onboarding_payload(uuid)',
    'public.get_my_directory_onboarding(uuid)',
    'public.owner_set_directory_type(uuid,public.directory_business_type)',
    'public.owner_upsert_directory_profile(uuid,public.directory_business_type,text,text,text,text,public.directory_spoken_language[],public.directory_cuisine[],smallint,boolean,boolean,boolean,public.directory_doctor_specialty,public.directory_insurance,boolean)',
    'public.owner_replace_directory_hours(uuid,jsonb)',
    'public.owner_replace_directory_menu(uuid,jsonb)',
    'public.owner_start_directory(uuid,public.directory_business_type,text,text)',
    'public.can_manage_directory_cover_path(text)'
  ]::text[]) as expected(signature)
  where pg_catalog.to_regprocedure(expected.signature) is not null;

  if coalesce(pg_catalog.cardinality(unexpected_functions), 0) <> 0 then
    raise exception 'F2a preflight failed: new F2a functions already exist: %', unexpected_functions
      using errcode = '55000';
  end if;

  select pg_catalog.array_agg(
      expected.schema_name || '.' || expected.table_name || '.' || expected.policy_name
      order by expected.schema_name, expected.table_name, expected.policy_name
    )
    into missing_policies
  from (values
    ('public', 'sellers', 'sellers_select_visible', 'r'),
    ('public', 'sellers', 'sellers_insert_own_application', 'a'),
    ('public', 'sellers', 'sellers_update_own', 'w'),
    ('public', 'sellers', 'sellers_delete_pending_own', 'd'),
    ('public', 'business_directory_profiles', 'directory_profiles_select', 'r'),
    ('public', 'business_directory_profiles', 'directory_profiles_owner_write', '*'),
    ('public', 'business_directory_hours', 'directory_hours_select', 'r'),
    ('public', 'business_directory_hours', 'directory_hours_owner_write', '*'),
    ('public', 'business_directory_menu_sections', 'directory_sections_select', 'r'),
    ('public', 'business_directory_menu_sections', 'directory_sections_owner_write', '*'),
    ('public', 'business_directory_menu_items', 'directory_items_select', 'r'),
    ('public', 'business_directory_menu_items', 'directory_items_owner_write', '*'),
    ('public', 'reviews', 'reviews_select_visible', 'r'),
    ('public', 'reviews', 'reviews_insert_allowed', 'a'),
    ('public', 'reviews', 'reviews_update_own', 'w'),
    ('storage', 'objects', 'directory_covers_insert', 'a'),
    ('storage', 'objects', 'directory_covers_update', 'w'),
    ('storage', 'objects', 'directory_covers_delete', 'd')
  ) as expected(schema_name, table_name, policy_name, command)
  where not exists (
    select 1
    from pg_catalog.pg_policy as policy_row
    join pg_catalog.pg_class as table_row
      on table_row.oid = policy_row.polrelid
    join pg_catalog.pg_namespace as namespace_row
      on namespace_row.oid = table_row.relnamespace
    where namespace_row.nspname = expected.schema_name
      and table_row.relname = expected.table_name
      and policy_row.polname = expected.policy_name
      and policy_row.polcmd::text = expected.command
      and (
        select role_row.oid
        from pg_catalog.pg_roles as role_row
        where role_row.rolname = 'authenticated'
      ) = any(policy_row.polroles)
  );

  if coalesce(pg_catalog.cardinality(missing_policies), 0) <> 0 then
    raise exception 'F2a preflight failed: expected policies are missing: %', missing_policies
      using errcode = '55000';
  end if;

  select pg_catalog.array_agg(
      expected.schema_name || '.' || expected.table_name || '.' || expected.trigger_name
      order by expected.schema_name, expected.table_name, expected.trigger_name
    )
    into missing_triggers
  from (values
    ('public', 'sellers', 'prepare_seller_write', 'public.prepare_seller_write()', 23),
    ('public', 'sellers', 'guard_seller_directory_type', 'public.guard_seller_directory_type()', 19),
    ('public', 'notifications', 'queue_notification_delivery', 'public.queue_notification_delivery()', 5),
    ('public', 'messages', 'notify_chat_message', 'public.notify_chat_message()', 5),
    ('public', 'orders', 'notify_order_change', 'public.notify_order_change()', 21),
    ('public', 'products', 'record_product_price_change', 'public.record_product_price_change()', 21),
    ('public', 'business_directory_profiles', 'validate_directory_profile_write', 'public.validate_directory_profile_write()', 23),
    ('public', 'business_directory_profiles', 'sync_seller_directory_type', 'public.sync_seller_directory_type()', 21),
    ('public', 'business_directory_menu_sections', 'validate_directory_menu_section_write', 'public.validate_directory_menu_write()', 23),
    ('public', 'business_directory_menu_items', 'validate_directory_menu_item_write', 'public.validate_directory_menu_write()', 23),
    ('public', 'seller_documents', 'approve_directory_seller_if_complete', 'public.approve_directory_seller_if_complete()', 17),
    ('public', 'reviews', 'validate_directory_review_write', 'public.validate_directory_review_write()', 23),
    ('public', 'reviews', 'refresh_review_aggregates', 'public.refresh_review_aggregates()', 29)
  ) as expected(schema_name, table_name, trigger_name, function_signature, trigger_type)
  where not exists (
    select 1
    from pg_catalog.pg_trigger as trigger_row
    join pg_catalog.pg_class as table_row
      on table_row.oid = trigger_row.tgrelid
    join pg_catalog.pg_namespace as namespace_row
      on namespace_row.oid = table_row.relnamespace
    where namespace_row.nspname = expected.schema_name
      and table_row.relname = expected.table_name
      and trigger_row.tgname = expected.trigger_name
      and not trigger_row.tgisinternal
      and trigger_row.tgenabled = 'O'
      and trigger_row.tgtype = expected.trigger_type
      and trigger_row.tgfoid = pg_catalog.to_regprocedure(expected.function_signature)
  );

  if coalesce(pg_catalog.cardinality(missing_triggers), 0) <> 0 then
    raise exception 'F2a preflight failed: expected triggers are missing: %', missing_triggers
      using errcode = '55000';
  end if;

  if exists (
    select 1
    from public.business_directory_profiles as profile
    where profile.cover_image_path is not null
      and (
        profile.cover_image_path !~ (
          '^' || profile.seller_id::text
          || '/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'
          || '[.](webp|jpg|jpeg|png)$'
        )
        or not exists (
          select 1
          from storage.objects as object_row
          where object_row.bucket_id = 'directory-covers'
            and object_row.name = profile.cover_image_path
        )
      )
  ) then
    raise exception
      'F2a preflight failed: every directory cover must be canonical, same-seller, and backed by a directory-covers object'
      using errcode = '55000';
  end if;
end;
$preflight$;

-- ---------------------------------------------------------------------------
-- Seller cardinality and direct-write boundary
-- ---------------------------------------------------------------------------
-- Drop the constraint, not its backing index, then permit at most one private and
-- one business identity per non-null auth user. Orphaned identities remain allowed.
alter table public.sellers
  drop constraint sellers_user_id_key;
alter table public.sellers
  add constraint sellers_user_kind_key unique (user_id, kind);

-- Identity creation now happens only inside reviewed security-definer workflows.
drop policy sellers_insert_own_application on public.sellers;
revoke insert on table public.sellers from authenticated;

-- Safe computed ownership: no user_id leaves the server and anonymous callers get false.
create function public.is_owned_by_current_user(seller public.sellers)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    auth.uid() is not null
    and seller.id is not null
    and public.owns_seller(seller.id),
    false
  );
$$;
revoke all on function public.is_owned_by_current_user(public.sellers)
  from public, anon, authenticated, service_role;
grant execute on function public.is_owned_by_current_user(public.sellers)
  to anon, authenticated;

-- ---------------------------------------------------------------------------
-- Authenticated identity catalog
-- ---------------------------------------------------------------------------
-- The person entry is permanent even before its lazy private seller exists. Business
-- appears only when provisioned through directory onboarding. The payload intentionally
-- excludes auth UUIDs, email, phone, documents, and all seller-private data.
create function public.get_my_identity_catalog()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  profile_row public.profiles%rowtype;
  private_seller public.sellers%rowtype;
  business_seller public.sellers%rowtype;
  person_avatar text;
  identities jsonb;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select profile.* into profile_row
  from public.profiles as profile
  where profile.id = auth.uid();

  select seller.* into private_seller
  from public.sellers as seller
  where seller.user_id = auth.uid() and seller.kind = 'private'
  order by seller.id
  limit 1;

  select seller.* into business_seller
  from public.sellers as seller
  where seller.user_id = auth.uid() and seller.kind = 'business'
  order by seller.id
  limit 1;

  if profile_row.avatar_path ~ (
    '^' || profile_row.avatar_key::text
    || '/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}[.]webp$'
  ) then
    person_avatar := profile_row.avatar_path;
  end if;

  identities := jsonb_build_array(jsonb_build_object(
    'identity_type', 'person',
    'seller_id', private_seller.id,
    'kind', 'private',
    'status', private_seller.status,
    'label', coalesce(
      nullif(pg_catalog.btrim(profile_row.display_name), ''),
      nullif(pg_catalog.btrim(private_seller.shop_name), ''),
      'Zêrîn Nutzer'
    ),
    'avatar_url', person_avatar,
    'username', profile_row.username
  ));

  if business_seller.id is not null then
    identities := identities || jsonb_build_array(jsonb_build_object(
      'identity_type', 'business',
      'seller_id', business_seller.id,
      'kind', business_seller.kind,
      'status', business_seller.status,
      'label', business_seller.shop_name,
      'avatar_url', business_seller.avatar_url,
      'username', null
    ));
  end if;

  return jsonb_build_object('identities', identities);
end;
$$;
revoke all on function public.get_my_identity_catalog()
  from public, anon, authenticated, service_role;
grant execute on function public.get_my_identity_catalog() to authenticated;

-- ---------------------------------------------------------------------------
-- Listing preparation and submission
-- ---------------------------------------------------------------------------
-- Explicit F2b path. A non-null ID must identify the exact caller-owned identity and
-- kind and is locked before a product upload namespace is returned. JSON null is the
-- sole lazy-creation path and can only create/reuse the caller's private identity.
create function public.prepare_listing_submission(
  p_seller_id uuid,
  p_seller_kind public.seller_kind,
  p_seller_name text,
  p_city text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  seller_row public.sellers%rowtype;
  new_seller_id uuid;
  reserved_product_id uuid := extensions.gen_random_uuid();
  normalized_name text := nullif(pg_catalog.btrim(p_seller_name), '');
  normalized_city text := pg_catalog.btrim(coalesce(p_city, ''));
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if not public.is_marketplace_german_city(normalized_city) then
    raise exception 'Choose a supported German city' using errcode = '22023';
  end if;

  if p_seller_id is not null then
    select seller.* into seller_row
    from public.sellers as seller
    where seller.id = p_seller_id
      and seller.user_id = auth.uid()
      and seller.kind = p_seller_kind
    for update;

    if not found then
      raise exception 'Seller identity is not owned by caller or has the wrong kind'
        using errcode = '42501';
    end if;
  else
    if p_seller_kind is distinct from 'private'::public.seller_kind then
      raise exception 'Lazy listing identity creation is private-only'
        using errcode = '22023';
    end if;

    perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(
      'f2a:seller-identities:' || auth.uid()::text, 0
    ));

    select seller.* into seller_row
    from public.sellers as seller
    where seller.user_id = auth.uid() and seller.kind = 'private'
    order by seller.id
    limit 1
    for update;

    if not found then
      if normalized_name is null then
        select nullif(pg_catalog.btrim(profile.display_name), '')
          into normalized_name
        from public.profiles as profile
        where profile.id = auth.uid();
      end if;
      normalized_name := coalesce(normalized_name, 'Zêrîn Nutzer');
      if char_length(normalized_name) < 2 or char_length(normalized_name) > 100 then
        raise exception 'Seller name must contain 2 to 100 characters'
          using errcode = '22023';
      end if;

      new_seller_id := extensions.gen_random_uuid();
      insert into public.sellers (
        id, user_id, kind, status, shop_name, slug, city, country_code
      ) values (
        new_seller_id,
        auth.uid(),
        'private',
        'pending',
        normalized_name,
        'seller-' || replace(left(new_seller_id::text, 18), '-', ''),
        normalized_city,
        'DE'
      )
      returning * into seller_row;
    end if;
  end if;

  return jsonb_build_object(
    'seller_id', seller_row.id,
    'seller_kind', seller_row.kind,
    'seller_name', seller_row.shop_name,
    'product_id', reserved_product_id
  );
end;
$$;
revoke all on function public.prepare_listing_submission(
  uuid, public.seller_kind, text, text
) from public, anon, authenticated, service_role;
grant execute on function public.prepare_listing_submission(
  uuid, public.seller_kind, text, text
) to authenticated;

-- Legacy three-key PostgREST contract. It can create the first identity exactly as
-- before, but once any identity exists it deterministically reuses one and can never
-- create the account's second identity. Requested kind wins, then private, then business.
create or replace function public.prepare_listing_submission(
  p_seller_kind public.seller_kind,
  p_seller_name text,
  p_city text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  seller_row public.sellers%rowtype;
  new_seller_id uuid;
  reserved_product_id uuid := extensions.gen_random_uuid();
  normalized_name text := nullif(pg_catalog.btrim(p_seller_name), '');
  normalized_city text := pg_catalog.btrim(coalesce(p_city, ''));
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if not public.is_marketplace_german_city(normalized_city) then
    raise exception 'Choose a supported German city' using errcode = '22023';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(
    'f2a:seller-identities:' || auth.uid()::text, 0
  ));

  select seller.* into seller_row
  from public.sellers as seller
  where seller.user_id = auth.uid()
  order by
    case
      when seller.kind = p_seller_kind then 0
      when seller.kind = 'private' then 1
      else 2
    end,
    seller.id
  limit 1
  for update;

  if not found then
    if p_seller_kind is null then
      raise exception 'Seller kind required' using errcode = '22023';
    end if;
    if normalized_name is null then
      select nullif(pg_catalog.btrim(profile.display_name), '')
        into normalized_name
      from public.profiles as profile
      where profile.id = auth.uid();
    end if;
    normalized_name := coalesce(normalized_name, 'Zêrîn Nutzer');
    if char_length(normalized_name) < 2 or char_length(normalized_name) > 100 then
      raise exception 'Seller name must contain 2 to 100 characters'
        using errcode = '22023';
    end if;

    new_seller_id := extensions.gen_random_uuid();
    insert into public.sellers (
      id, user_id, kind, status, shop_name, slug, city, country_code
    ) values (
      new_seller_id,
      auth.uid(),
      p_seller_kind,
      'pending',
      normalized_name,
      'seller-' || replace(left(new_seller_id::text, 18), '-', ''),
      normalized_city,
      'DE'
    )
    returning * into seller_row;
  end if;

  return jsonb_build_object(
    'seller_id', seller_row.id,
    'seller_kind', seller_row.kind,
    'seller_name', seller_row.shop_name,
    'product_id', reserved_product_id
  );
end;
$$;

-- Keep the effective eleven-input contract byte-for-behavior equivalent, including
-- its own exact seller ownership check. No ten-input overload is recreated.
create or replace function public.submit_listing(
  p_product_id uuid,
  p_seller_id uuid,
  p_category_id uuid,
  p_title text,
  p_description text,
  p_condition public.product_condition,
  p_price_cents bigint,
  p_city text,
  p_image_paths text[],
  p_specifications jsonb default '{}'::jsonb,
  p_compare_at_price_cents bigint default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  normalized_title text := pg_catalog.btrim(coalesce(p_title, ''));
  normalized_description text := pg_catalog.btrim(coalesce(p_description, ''));
  normalized_city text := pg_catalog.btrim(coalesce(p_city, ''));
  image_count integer := coalesce(cardinality(p_image_paths), 0);
  inserted_product public.products%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if not exists (
    select 1 from public.sellers as seller
    where seller.id = p_seller_id and seller.user_id = auth.uid()
  ) then
    raise exception 'Seller identity is not owned by caller' using errcode = '42501';
  end if;
  if not exists (
    select 1 from public.categories as category
    where category.id = p_category_id and category.is_active
  ) then
    raise exception 'Choose an active category' using errcode = '22023';
  end if;
  if not public.is_marketplace_german_city(normalized_city) then
    raise exception 'Choose a supported German city' using errcode = '22023';
  end if;
  if char_length(normalized_title) < 3 or char_length(normalized_title) > 180 then
    raise exception 'Title must contain 3 to 180 characters' using errcode = '22023';
  end if;
  if char_length(normalized_description) < 10
    or char_length(normalized_description) > 10000 then
    raise exception 'Description must contain 10 to 10000 characters'
      using errcode = '22023';
  end if;
  if p_price_cents is null or p_price_cents <= 0 then
    raise exception 'Price must be greater than zero' using errcode = '22023';
  end if;
  if p_compare_at_price_cents is not null
    and p_compare_at_price_cents <= p_price_cents then
    raise exception 'Compare-at price must be greater than the price'
      using errcode = '22023';
  end if;
  if jsonb_typeof(coalesce(p_specifications, '{}'::jsonb)) <> 'object' then
    raise exception 'Specifications must be an object' using errcode = '22023';
  end if;
  if image_count < 1 or image_count > 10 then
    raise exception 'A listing requires between 1 and 10 photos'
      using errcode = '22023';
  end if;
  if (select count(distinct path) from unnest(p_image_paths) as path) <> image_count then
    raise exception 'Listing photo paths must be unique' using errcode = '22023';
  end if;
  if exists (
    select 1
    from unnest(p_image_paths) as path
    where split_part(path, '/', 1) <> p_seller_id::text
      or split_part(path, '/', 2) <> p_product_id::text
      or array_length(storage.foldername(path), 1) <> 2
      or lower(path) !~ '\.webp$'
  ) then
    raise exception 'Listing photo path does not match the reserved listing'
      using errcode = '42501';
  end if;
  if (
    select count(*)
    from storage.objects as object
    where object.bucket_id = 'product-images'
      and object.name = any(p_image_paths)
  ) <> image_count then
    raise exception 'Every listing photo must be uploaded before submission'
      using errcode = '22023';
  end if;

  insert into public.products (
    id,
    seller_id,
    category_id,
    title,
    slug,
    description,
    condition,
    status,
    price_cents,
    compare_at_price_cents,
    specifications,
    city,
    country_code,
    quantity
  ) values (
    p_product_id,
    p_seller_id,
    p_category_id,
    normalized_title,
    'listing-' || replace(left(p_product_id::text, 18), '-', ''),
    normalized_description,
    p_condition,
    'draft',
    p_price_cents,
    p_compare_at_price_cents,
    coalesce(p_specifications, '{}'::jsonb),
    normalized_city,
    'DE',
    1
  )
  returning * into inserted_product;

  insert into public.product_images (product_id, storage_path, sort_order)
  select p_product_id, image.path, image.ordinality - 1
  from unnest(p_image_paths) with ordinality as image(path, ordinality);

  return jsonb_build_object(
    'id', inserted_product.id,
    'seller_id', inserted_product.seller_id,
    'status', inserted_product.status,
    'title', inserted_product.title,
    'created_at', inserted_product.created_at
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- Person profile selection
-- ---------------------------------------------------------------------------
create or replace function public.get_my_profile()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  profile_row public.profiles%rowtype;
  seller_row public.sellers%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select profile.* into profile_row
  from public.profiles as profile
  where profile.id = auth.uid();
  if not found then
    raise exception 'Profile not found' using errcode = 'P0002';
  end if;

  select seller.* into seller_row
  from public.sellers as seller
  where seller.user_id = profile_row.id
    and seller.kind = 'private'
  order by seller.id
  limit 1;

  return jsonb_build_object(
    'display_name', profile_row.display_name,
    'username', profile_row.username,
    'city', profile_row.city,
    'bio', profile_row.bio,
    'avatar_object', profile_row.avatar_path,
    'listing_count', case when seller_row.id is null then 0 else (
      select count(*)
      from public.products as product
      where product.seller_id = seller_row.id
        and product.status = 'active'
        and product.quantity > 0
    ) end,
    'seller', case when seller_row.id is null then null else jsonb_build_object(
      'id', seller_row.id,
      'kind', seller_row.kind,
      'status', seller_row.status,
      'store_name', case when seller_row.kind = 'business'
        then seller_row.shop_name else null end,
      'verified', public.is_verified_seller(seller_row.id)
    ) end
  );
end;
$$;

create or replace function public.get_public_profile(p_username text)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  profile_row public.profiles%rowtype;
  seller_row public.sellers%rowtype;
  safe_avatar text;
begin
  select profile.* into profile_row
  from public.profiles as profile
  where lower(profile.username) = lower(pg_catalog.btrim(coalesce(p_username, '')))
    and profile.username is not null;
  if not found then
    return null;
  end if;

  select seller.* into seller_row
  from public.sellers as seller
  where seller.user_id = profile_row.id
    and seller.kind = 'private'
    and seller.status = 'approved'
    and seller.country_code = 'DE'
    and public.phase3_in_germany(seller)
  order by seller.id
  limit 1;

  if profile_row.avatar_path ~ (
    '^' || profile_row.avatar_key::text
    || '/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}[.]webp$'
  ) then
    safe_avatar := profile_row.avatar_path;
  end if;

  return jsonb_build_object(
    'display_name', profile_row.display_name,
    'username', profile_row.username,
    'city', profile_row.city,
    'bio', profile_row.bio,
    'avatar_object', safe_avatar,
    'is_self', auth.uid() is not null and profile_row.id = auth.uid(),
    'listing_count', case when seller_row.id is null then 0 else (
      select count(*)
      from public.products as product
      where product.seller_id = seller_row.id
        and product.status = 'active'
        and product.quantity > 0
        and product.country_code = 'DE'
    ) end,
    'seller', case when seller_row.id is null then null else jsonb_build_object(
      'id', seller_row.id,
      'kind', seller_row.kind,
      'store_name', case when seller_row.kind = 'business'
        then seller_row.shop_name else null end,
      'verified', public.is_verified_seller(seller_row.id),
      'is_owned_by_current_user', public.is_owned_by_current_user(seller_row)
    ) end
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- Directory onboarding payload and explicit identity overloads
-- ---------------------------------------------------------------------------
-- Internal renderer containing the latest E2 shape. Access checks stay in the public
-- entry points, and this helper has no client execution privilege.
create function public.f2a_directory_onboarding_payload(p_seller_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  seller_row public.sellers%rowtype;
  result jsonb;
begin
  select seller.* into seller_row
  from public.sellers as seller
  where seller.id = p_seller_id;

  if not found then
    return jsonb_build_object(
      'seller', null,
      'is_verified', false,
      'required_document_kinds', '[]'::jsonb,
      'documents', '[]'::jsonb,
      'profile', null,
      'hours', '[]'::jsonb,
      'menu', '[]'::jsonb
    );
  end if;

  select jsonb_build_object(
    'seller', jsonb_build_object(
      'id', seller_row.id,
      'kind', seller_row.kind,
      'status', seller_row.status,
      'shop_name', seller_row.shop_name,
      'city', seller_row.city,
      'directory_type', seller_row.directory_type
    ),
    'is_verified', public.is_verified_seller(seller_row.id),
    'required_document_kinds',
      to_jsonb(public.directory_required_document_kinds(seller_row.directory_type)),
    'documents', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'id', document.id,
        'kind', document.kind,
        'status', document.status,
        'admin_note', document.admin_note,
        'mime_type', document.mime_type,
        'storage_path', document.storage_path,
        'created_at', document.created_at,
        'reviewed_at', document.reviewed_at
      ) order by document.created_at desc), '[]'::jsonb)
      from public.seller_documents as document
      where document.seller_id = seller_row.id
    ),
    'profile', (
      select jsonb_build_object(
        'type', profile.type,
        'description', profile.description,
        'phone', profile.phone,
        'website', profile.website,
        'cover_image_path', profile.cover_image_path,
        'languages', profile.languages,
        'cuisines', profile.cuisines,
        'price_level', profile.price_level,
        'has_halal', profile.has_halal,
        'has_vegetarian_options', profile.has_vegetarian_options,
        'has_vegan_options', profile.has_vegan_options,
        'specialty', profile.specialty,
        'insurance', profile.insurance,
        'is_published', profile.is_published
      )
      from public.business_directory_profiles as profile
      where profile.seller_id = seller_row.id
    ),
    'hours', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'weekday', hours.weekday,
        'opens_at', to_char(hours.opens_at, 'HH24:MI'),
        'closes_at', to_char(hours.closes_at, 'HH24:MI')
      ) order by hours.weekday, hours.sort_order, hours.opens_at), '[]'::jsonb)
      from public.business_directory_hours as hours
      where hours.seller_id = seller_row.id
    ),
    'menu', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'id', section.id,
        'name', section.name,
        'sort_order', section.sort_order,
        'items', (
          select coalesce(jsonb_agg(jsonb_build_object(
            'id', item.id,
            'name', item.name,
            'description', item.description,
            'price_cents', item.price_cents,
            'is_available', item.is_available,
            'is_halal', item.is_halal,
            'is_vegetarian', item.is_vegetarian,
            'is_vegan', item.is_vegan,
            'sort_order', item.sort_order
          ) order by item.sort_order, item.id), '[]'::jsonb)
          from public.business_directory_menu_items as item
          where item.section_id = section.id
        )
      ) order by section.sort_order, section.id), '[]'::jsonb)
      from public.business_directory_menu_sections as section
      where section.seller_id = seller_row.id
    )
  ) into result;

  return result;
end;
$$;
revoke all on function public.f2a_directory_onboarding_payload(uuid)
  from public, anon, authenticated, service_role;

create function public.get_my_directory_onboarding(p_seller_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if not exists (
    select 1
    from public.sellers as seller
    where seller.id = p_seller_id
      and seller.user_id = auth.uid()
      and seller.kind = 'business'
  ) then
    raise exception 'Business seller identity is not owned by caller'
      using errcode = '42501';
  end if;

  return public.f2a_directory_onboarding_payload(p_seller_id);
end;
$$;
revoke all on function public.get_my_directory_onboarding(uuid)
  from public, anon, authenticated, service_role;
grant execute on function public.get_my_directory_onboarding(uuid) to authenticated;

-- Business wins once present. Before that, retain the E2 no-seller empty shape and
-- private-seller fallback used by existing onboarding tests and current Flutter code.
create or replace function public.get_my_directory_onboarding()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  target_seller_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select seller.id into target_seller_id
  from public.sellers as seller
  where seller.user_id = auth.uid()
  order by
    case when seller.kind = 'business' then 0 else 1 end,
    seller.id
  limit 1;

  if target_seller_id is null then
    return jsonb_build_object(
      'seller', null,
      'is_verified', false,
      'required_document_kinds', '[]'::jsonb,
      'documents', '[]'::jsonb,
      'profile', null,
      'hours', '[]'::jsonb,
      'menu', '[]'::jsonb
    );
  end if;

  return public.f2a_directory_onboarding_payload(target_seller_id);
end;
$$;

create function public.owner_set_directory_type(
  p_seller_id uuid,
  p_directory_type public.directory_business_type
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  seller_row public.sellers%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if p_directory_type is null then
    raise exception 'Directory type required' using errcode = '22023';
  end if;

  select seller.* into seller_row
  from public.sellers as seller
  where seller.id = p_seller_id
    and seller.user_id = auth.uid()
    and seller.kind = 'business'
  for update;
  if not found then
    raise exception 'Business seller identity is not owned by caller'
      using errcode = '42501';
  end if;

  update public.sellers
  set directory_type = p_directory_type
  where id = seller_row.id;

  return public.get_my_directory_onboarding(seller_row.id);
end;
$$;
revoke all on function public.owner_set_directory_type(
  uuid, public.directory_business_type
) from public, anon, authenticated, service_role;
grant execute on function public.owner_set_directory_type(
  uuid, public.directory_business_type
) to authenticated;

create or replace function public.owner_set_directory_type(
  p_directory_type public.directory_business_type
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_seller_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if p_directory_type is null then
    raise exception 'Directory type required' using errcode = '22023';
  end if;

  select seller.id into target_seller_id
  from public.sellers as seller
  where seller.user_id = auth.uid() and seller.kind = 'business'
  order by seller.id
  limit 1;

  if target_seller_id is not null then
    return public.owner_set_directory_type(target_seller_id, p_directory_type);
  end if;
  if exists (
    select 1 from public.sellers as seller
    where seller.user_id = auth.uid() and seller.kind = 'private'
  ) then
    raise exception 'Private seller accounts cannot join the business directory'
      using errcode = '42501';
  end if;
  raise exception 'No seller exists yet' using errcode = 'P0002';
end;
$$;

create function public.owner_upsert_directory_profile(
  p_seller_id uuid,
  p_type public.directory_business_type,
  p_description text,
  p_phone text,
  p_website text,
  p_cover_image_path text,
  p_languages public.directory_spoken_language[],
  p_cuisines public.directory_cuisine[] default '{}',
  p_price_level smallint default null,
  p_has_halal boolean default false,
  p_has_vegetarian_options boolean default false,
  p_has_vegan_options boolean default false,
  p_specialty public.directory_doctor_specialty default null,
  p_insurance public.directory_insurance default null,
  p_is_published boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  seller_row public.sellers%rowtype;
  result public.business_directory_profiles%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select seller.* into seller_row
  from public.sellers as seller
  where seller.id = p_seller_id
    and seller.user_id = auth.uid()
    and seller.kind = 'business'
  for update;
  if not found then
    raise exception 'Business seller identity is not owned by caller'
      using errcode = '42501';
  end if;

  insert into public.business_directory_profiles (
    seller_id,
    type,
    description,
    phone,
    website,
    cover_image_path,
    languages,
    cuisines,
    price_level,
    has_halal,
    has_vegetarian_options,
    has_vegan_options,
    specialty,
    insurance,
    is_published
  ) values (
    seller_row.id,
    p_type,
    btrim(p_description),
    btrim(p_phone),
    nullif(btrim(p_website), ''),
    p_cover_image_path,
    p_languages,
    coalesce(p_cuisines, '{}'),
    p_price_level,
    coalesce(p_has_halal, false),
    coalesce(p_has_vegetarian_options, false),
    coalesce(p_has_vegan_options, false),
    p_specialty,
    p_insurance,
    coalesce(p_is_published, false)
  )
  on conflict (seller_id) do update set
    type = excluded.type,
    description = excluded.description,
    phone = excluded.phone,
    website = excluded.website,
    cover_image_path = excluded.cover_image_path,
    languages = excluded.languages,
    cuisines = excluded.cuisines,
    price_level = excluded.price_level,
    has_halal = excluded.has_halal,
    has_vegetarian_options = excluded.has_vegetarian_options,
    has_vegan_options = excluded.has_vegan_options,
    specialty = excluded.specialty,
    insurance = excluded.insurance,
    is_published = excluded.is_published,
    updated_at = now()
  returning * into result;

  return to_jsonb(result);
end;
$$;
revoke all on function public.owner_upsert_directory_profile(
  uuid, public.directory_business_type, text, text, text, text,
  public.directory_spoken_language[], public.directory_cuisine[], smallint,
  boolean, boolean, boolean, public.directory_doctor_specialty,
  public.directory_insurance, boolean
) from public, anon, authenticated, service_role;
grant execute on function public.owner_upsert_directory_profile(
  uuid, public.directory_business_type, text, text, text, text,
  public.directory_spoken_language[], public.directory_cuisine[], smallint,
  boolean, boolean, boolean, public.directory_doctor_specialty,
  public.directory_insurance, boolean
) to authenticated;

create or replace function public.owner_upsert_directory_profile(
  p_type public.directory_business_type,
  p_description text,
  p_phone text,
  p_website text,
  p_cover_image_path text,
  p_languages public.directory_spoken_language[],
  p_cuisines public.directory_cuisine[] default '{}',
  p_price_level smallint default null,
  p_has_halal boolean default false,
  p_has_vegetarian_options boolean default false,
  p_has_vegan_options boolean default false,
  p_specialty public.directory_doctor_specialty default null,
  p_insurance public.directory_insurance default null,
  p_is_published boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_seller_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select seller.id into target_seller_id
  from public.sellers as seller
  where seller.user_id = auth.uid() and seller.kind = 'business'
  order by seller.id
  limit 1;
  if target_seller_id is null then
    raise exception 'Business seller required' using errcode = '42501';
  end if;

  return public.owner_upsert_directory_profile(
    target_seller_id,
    p_type,
    p_description,
    p_phone,
    p_website,
    p_cover_image_path,
    p_languages,
    p_cuisines,
    p_price_level,
    p_has_halal,
    p_has_vegetarian_options,
    p_has_vegan_options,
    p_specialty,
    p_insurance,
    p_is_published
  );
end;
$$;

create function public.owner_replace_directory_hours(
  p_seller_id uuid,
  p_intervals jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  seller_row public.sellers%rowtype;
  item jsonb;
  result jsonb;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select seller.* into seller_row
  from public.sellers as seller
  where seller.id = p_seller_id
    and seller.user_id = auth.uid()
    and seller.kind = 'business'
  for update;
  if not found then
    raise exception 'Business seller identity is not owned by caller'
      using errcode = '42501';
  end if;

  perform 1
  from public.business_directory_profiles as profile
  where profile.seller_id = seller_row.id
  for update;
  if not found then
    raise exception 'Directory profile required' using errcode = '42501';
  end if;

  if jsonb_typeof(coalesce(p_intervals, '[]')) <> 'array'
    or jsonb_array_length(coalesce(p_intervals, '[]')) > 42 then
    raise exception 'Hours must be an array of at most 42 intervals'
      using errcode = '22023';
  end if;

  delete from public.business_directory_hours
  where seller_id = seller_row.id;

  for item in
    select value from jsonb_array_elements(coalesce(p_intervals, '[]'))
  loop
    insert into public.business_directory_hours (
      seller_id, weekday, opens_at, closes_at, sort_order
    ) values (
      seller_row.id,
      (item ->> 'weekday')::smallint,
      (item ->> 'opens_at')::time,
      (item ->> 'closes_at')::time,
      coalesce((item ->> 'sort_order')::smallint, 0)
    );
  end loop;

  select coalesce(
    jsonb_agg(to_jsonb(hours) order by weekday, sort_order, opens_at),
    '[]'
  ) into result
  from public.business_directory_hours as hours
  where hours.seller_id = seller_row.id;

  return result;
end;
$$;
revoke all on function public.owner_replace_directory_hours(uuid, jsonb)
  from public, anon, authenticated, service_role;
grant execute on function public.owner_replace_directory_hours(uuid, jsonb)
  to authenticated;

create or replace function public.owner_replace_directory_hours(p_intervals jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_seller_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select seller.id into target_seller_id
  from public.sellers as seller
  where seller.user_id = auth.uid() and seller.kind = 'business'
  order by seller.id
  limit 1;
  if target_seller_id is null then
    raise exception 'Directory profile required' using errcode = '42501';
  end if;

  return public.owner_replace_directory_hours(target_seller_id, p_intervals);
end;
$$;

create function public.owner_replace_directory_menu(
  p_seller_id uuid,
  p_sections jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  seller_row public.sellers%rowtype;
  section jsonb;
  item jsonb;
  section_id uuid;
  result jsonb;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select seller.* into seller_row
  from public.sellers as seller
  where seller.id = p_seller_id
    and seller.user_id = auth.uid()
    and seller.kind = 'business'
  for update;
  if not found then
    raise exception 'Business seller identity is not owned by caller'
      using errcode = '42501';
  end if;

  perform 1
  from public.business_directory_profiles as profile
  where profile.seller_id = seller_row.id
    and profile.type in ('restaurant', 'cafe', 'fast_food')
  for update;
  if not found then
    raise exception 'Restaurant, cafe or fast food profile required'
      using errcode = '23514';
  end if;

  if jsonb_typeof(coalesce(p_sections, '[]')) <> 'array'
    or jsonb_array_length(coalesce(p_sections, '[]')) > 50 then
    raise exception 'Menu must be an array of at most 50 sections'
      using errcode = '22023';
  end if;

  delete from public.business_directory_menu_sections
  where seller_id = seller_row.id;

  for section in
    select value from jsonb_array_elements(coalesce(p_sections, '[]'))
  loop
    insert into public.business_directory_menu_sections (
      seller_id, name, sort_order
    ) values (
      seller_row.id,
      btrim(section ->> 'name'),
      coalesce((section ->> 'sort_order')::integer, 0)
    )
    returning id into section_id;

    if jsonb_typeof(coalesce(section -> 'items', '[]')) <> 'array'
      or jsonb_array_length(coalesce(section -> 'items', '[]')) > 200 then
      raise exception 'Menu section items must be an array of at most 200 items'
        using errcode = '22023';
    end if;

    for item in
      select value from jsonb_array_elements(coalesce(section -> 'items', '[]'))
    loop
      insert into public.business_directory_menu_items (
        section_id,
        seller_id,
        name,
        description,
        price_cents,
        is_available,
        is_halal,
        is_vegetarian,
        is_vegan,
        sort_order
      ) values (
        section_id,
        seller_row.id,
        btrim(item ->> 'name'),
        nullif(btrim(item ->> 'description'), ''),
        (item ->> 'price_cents')::bigint,
        coalesce((item ->> 'is_available')::boolean, true),
        coalesce((item ->> 'is_halal')::boolean, false),
        coalesce((item ->> 'is_vegetarian')::boolean, false),
        coalesce((item ->> 'is_vegan')::boolean, false),
        coalesce((item ->> 'sort_order')::integer, 0)
      );
    end loop;
  end loop;

  select coalesce(jsonb_agg(jsonb_build_object(
    'id', stored_section.id,
    'name', stored_section.name,
    'sort_order', stored_section.sort_order,
    'items', (
      select coalesce(
        jsonb_agg(to_jsonb(stored_item) order by stored_item.sort_order, stored_item.id),
        '[]'
      )
      from public.business_directory_menu_items as stored_item
      where stored_item.section_id = stored_section.id
    )
  ) order by stored_section.sort_order, stored_section.id), '[]')
    into result
  from public.business_directory_menu_sections as stored_section
  where stored_section.seller_id = seller_row.id;

  return result;
end;
$$;
revoke all on function public.owner_replace_directory_menu(uuid, jsonb)
  from public, anon, authenticated, service_role;
grant execute on function public.owner_replace_directory_menu(uuid, jsonb)
  to authenticated;

create or replace function public.owner_replace_directory_menu(p_sections jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_seller_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select seller.id into target_seller_id
  from public.sellers as seller
  where seller.user_id = auth.uid() and seller.kind = 'business'
  order by seller.id
  limit 1;
  if target_seller_id is null then
    raise exception 'Restaurant, cafe or fast food profile required'
      using errcode = '23514';
  end if;

  return public.owner_replace_directory_menu(target_seller_id, p_sections);
end;
$$;

-- Explicit second-identity creation. Null is the business-first case and is valid only
-- for an account with no seller. A non-null ID must be the caller's exact private seller.
create function public.owner_start_directory(
  p_existing_private_seller_id uuid,
  p_directory_type public.directory_business_type,
  p_shop_name text,
  p_city text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  private_seller public.sellers%rowtype;
  existing_business_id uuid;
  new_seller_id uuid := extensions.gen_random_uuid();
  normalized_name text := nullif(btrim(p_shop_name), '');
  normalized_city text := nullif(btrim(p_city), '');
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if p_directory_type is null then
    raise exception 'Directory type required' using errcode = '22023';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(
    'f2a:seller-identities:' || auth.uid()::text, 0
  ));

  select seller.id into existing_business_id
  from public.sellers as seller
  where seller.user_id = auth.uid() and seller.kind = 'business'
  order by seller.id
  limit 1
  for update;
  if existing_business_id is not null then
    raise exception 'A business seller already exists; set its directory type instead'
      using errcode = '22023';
  end if;

  if p_existing_private_seller_id is null then
    if exists (
      select 1 from public.sellers as seller
      where seller.user_id = auth.uid()
    ) then
      raise exception 'Existing private seller id required'
        using errcode = '42501';
    end if;
  else
    select seller.* into private_seller
    from public.sellers as seller
    where seller.id = p_existing_private_seller_id
      and seller.user_id = auth.uid()
      and seller.kind = 'private'
    for update;
    if not found then
      raise exception 'Private seller identity is not owned by caller'
        using errcode = '42501';
    end if;
  end if;

  if normalized_name is null or char_length(normalized_name) not between 2 and 100 then
    raise exception 'Business name must contain 2 to 100 characters'
      using errcode = '22023';
  end if;
  if normalized_city is null
    or not public.is_marketplace_german_city(normalized_city) then
    raise exception 'Choose a supported German city' using errcode = '22023';
  end if;

  insert into public.sellers (
    id, user_id, kind, status, shop_name, slug, city, country_code, directory_type
  ) values (
    new_seller_id,
    auth.uid(),
    'business',
    'pending',
    normalized_name,
    'seller-' || replace(left(new_seller_id::text, 18), '-', ''),
    normalized_city,
    'DE',
    p_directory_type
  );

  return public.get_my_directory_onboarding(new_seller_id);
end;
$$;
revoke all on function public.owner_start_directory(
  uuid, public.directory_business_type, text, text
) from public, anon, authenticated, service_role;
grant execute on function public.owner_start_directory(
  uuid, public.directory_business_type, text, text
) to authenticated;

-- Legacy directory start remains one-identity-safe: it may create the first business,
-- but a private identity still receives 42501 and an existing business receives 22023.
create or replace function public.owner_start_directory(
  p_directory_type public.directory_business_type,
  p_shop_name text,
  p_city text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  existing_business_id uuid;
  existing_private_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if p_directory_type is null then
    raise exception 'Directory type required' using errcode = '22023';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(
    'f2a:seller-identities:' || auth.uid()::text, 0
  ));

  select seller.id into existing_business_id
  from public.sellers as seller
  where seller.user_id = auth.uid() and seller.kind = 'business'
  order by seller.id
  limit 1
  for update;
  if existing_business_id is not null then
    raise exception 'A seller already exists; set its directory type instead'
      using errcode = '22023';
  end if;

  select seller.id into existing_private_id
  from public.sellers as seller
  where seller.user_id = auth.uid() and seller.kind = 'private'
  order by seller.id
  limit 1
  for update;
  if existing_private_id is not null then
    raise exception 'Private seller accounts cannot join the business directory'
      using errcode = '42501';
  end if;

  return public.owner_start_directory(
    null::uuid, p_directory_type, p_shop_name, p_city
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- Chat identity projection and unified unread behavior
-- ---------------------------------------------------------------------------
create or replace function public.get_chat_inbox(p_chat_id uuid default null)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  with caller as materialized (
    select auth.uid() as id
  ), participant_chats as materialized (
    select chat.*, 'buyer'::text as viewer_role
    from public.chats as chat
    where chat.buyer_id = (select id from caller)
      and (p_chat_id is null or chat.id = p_chat_id)
    union all
    select chat.*, 'seller'::text as viewer_role
    from public.chats as chat
    join public.sellers as owned_seller on owned_seller.id = chat.seller_id
    where owned_seller.user_id = (select id from caller)
      and chat.buyer_id is distinct from (select id from caller)
      and (p_chat_id is null or chat.id = p_chat_id)
  )
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'id', chat.id,
      'buyer_id', chat.buyer_id,
      'seller_id', chat.seller_id,
      'seller_user_id', seller.user_id,
      'shop_name', case when seller.kind = 'private'
        then coalesce(seller_profile.display_name, seller.shop_name)
        else seller.shop_name end,
      'shop_slug', seller.slug,
      'shop_profile_username', case when seller.kind = 'private'
        then seller_profile.username else null end,
      'shop_avatar_url', case when seller.kind = 'private'
        and seller_profile.avatar_path ~ (
          '^' || seller_profile.avatar_key::text
          || '/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}[.]webp$'
        ) then seller_profile.avatar_path
        else seller.avatar_url end,
      'buyer_name', buyer.display_name,
      'buyer_avatar_url', case when buyer.avatar_path ~ (
        '^' || buyer.avatar_key::text
        || '/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}[.]webp$'
      ) then buyer.avatar_path else null end,
      'last_message_at', chat.last_message_at,
      'last_message_preview', chat.last_message_preview,
      'created_at', chat.created_at,
      'unread_count', (
        select count(*)
        from public.messages as unread
        where unread.chat_id = chat.id
          and unread.read_at is null
          and unread.kind <> 'system'
          and unread.sender_id is distinct from (select id from caller)
      ),
      'product', case when product.id is not null then jsonb_build_object(
        'id', product.id,
        'title', product.title,
        'price_cents', product.price_cents,
        'currency', product.currency,
        'image_url', image.image_url
      ) else null end,
      'viewer_role', chat.viewer_role,
      'viewer_identity_type', case
        when chat.viewer_role = 'buyer' then 'person'
        when seller.kind = 'business' then 'business'
        else 'person'
      end,
      'viewer_seller_id', case when chat.viewer_role = 'seller'
        then chat.seller_id else null end,
      'viewer_identity_name', case when chat.viewer_role = 'buyer'
        then buyer.display_name
        when seller.kind = 'private'
          then coalesce(seller_profile.display_name, seller.shop_name)
        else seller.shop_name end,
      'viewer_identity_avatar_url', case when chat.viewer_role = 'buyer'
        then case when buyer.avatar_path ~ (
          '^' || buyer.avatar_key::text
          || '/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}[.]webp$'
        ) then buyer.avatar_path else null end
        when seller.kind = 'private' and seller_profile.avatar_path ~ (
          '^' || seller_profile.avatar_key::text
          || '/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}[.]webp$'
        ) then seller_profile.avatar_path
        else seller.avatar_url end,
      'seller_kind', seller.kind,
      'seller_identity_name', case when seller.kind = 'private'
        then coalesce(seller_profile.display_name, seller.shop_name)
        else seller.shop_name end,
      'seller_identity_avatar_url', case when seller.kind = 'private'
        and seller_profile.avatar_path ~ (
          '^' || seller_profile.avatar_key::text
          || '/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}[.]webp$'
        ) then seller_profile.avatar_path
        else seller.avatar_url end
    ) order by chat.last_message_at desc nulls last, chat.created_at desc, chat.id
  ), '[]'::jsonb)
  from participant_chats as chat
  join public.sellers as seller on seller.id = chat.seller_id
  left join public.profiles as seller_profile on seller_profile.id = seller.user_id
  left join public.profiles as buyer on buyer.id = chat.buyer_id
  left join lateral (
    select message.product_id
    from public.messages as message
    where message.chat_id = chat.id and message.kind = 'product'
    order by message.created_at, message.id
    limit 1
  ) as pinned on true
  left join public.products as product on product.id = pinned.product_id
  left join lateral (
    select product_image.image_url
    from public.product_images as product_image
    where product_image.product_id = product.id
    order by product_image.sort_order, product_image.created_at, product_image.id
    limit 1
  ) as image on true;
$$;

-- Account-wide unread remains keyed to the auth user and all of that user's seller
-- identities, while system rows are now excluded exactly as they are in each inbox row.
create or replace function public.get_unread_chat_count()
returns integer
language sql
stable
security definer
set search_path = ''
as $$
  select count(*)::integer
  from public.messages as message
  join public.chats as chat on chat.id = message.chat_id
  join public.sellers as seller on seller.id = chat.seller_id
  where message.read_at is null
    and message.kind <> 'system'
    and message.sender_id is distinct from auth.uid()
    and (
      chat.buyer_id = auth.uid()
      or seller.user_id = auth.uid()
    );
$$;

-- Retain every delivered-purchase rule and additionally reject review targets owned
-- by the buyer's own auth account, regardless of whether that seller is private/business.
create or replace function public.can_review_order_item(
  target_order_item_id uuid,
  target_product_id uuid,
  target_seller_id uuid,
  target_kind public.review_kind
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.order_items as item
    join public.orders as marketplace_order on marketplace_order.id = item.order_id
    where item.id = target_order_item_id
      and marketplace_order.buyer_id = auth.uid()
      and marketplace_order.status = 'delivered'
      and item.seller_id = target_seller_id
      and not exists (
        select 1
        from public.sellers as target_seller
        where target_seller.id = target_seller_id
          and target_seller.user_id = auth.uid()
      )
      and (
        (
          target_kind = 'product'
          and target_product_id is not null
          and item.product_id = target_product_id
        )
        or (
          target_kind = 'seller'
          and target_product_id is null
        )
      )
  );
$$;

-- ---------------------------------------------------------------------------
-- Server-derived notification identity context
-- ---------------------------------------------------------------------------
-- Payload keys remain camelCase. Existing IDs, localization keys, statuses, result
-- shapes, trigger timings, and idempotence rules are unchanged.
create or replace function public.notify_chat_message()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  recipient_id uuid;
  exact_seller_id uuid;
  exact_seller_kind public.seller_kind;
  sent_by_buyer boolean;
  recipient_role text;
  recipient_identity_type text;
  recipient_seller_id uuid;
begin
  if new.sender_id is null or new.kind = 'system' then
    return new;
  end if;

  select
    chat.seller_id,
    seller.kind,
    chat.buyer_id = new.sender_id,
    case when chat.buyer_id = new.sender_id then seller.user_id else chat.buyer_id end
  into exact_seller_id, exact_seller_kind, sent_by_buyer, recipient_id
  from public.chats as chat
  join public.sellers as seller on seller.id = chat.seller_id
  where chat.id = new.chat_id;

  if sent_by_buyer then
    recipient_role := 'seller';
    recipient_identity_type := case when exact_seller_kind = 'business'
      then 'business' else 'person' end;
    recipient_seller_id := exact_seller_id;
  else
    recipient_role := 'buyer';
    recipient_identity_type := 'person';
    recipient_seller_id := null;
  end if;

  if recipient_id is not null and recipient_id is distinct from new.sender_id then
    perform public.create_user_notification(
      recipient_id,
      'chat',
      'notifications.chat.title',
      'notifications.chat.body',
      jsonb_build_object(
        'chatId', new.chat_id,
        'messageId', new.id,
        'kind', new.kind,
        'sellerId', exact_seller_id,
        'sellerKind', exact_seller_kind,
        'recipientRole', recipient_role,
        'recipientIdentityType', recipient_identity_type,
        'recipientSellerId', recipient_seller_id
      )
    );
  end if;

  return new;
end;
$$;

create or replace function public.notify_order_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  seller_user_id uuid;
  exact_seller_kind public.seller_kind;
  title_key text;
  body_key text;
begin
  if tg_op = 'UPDATE'
    and new.status is not distinct from old.status
    and new.payment_status is not distinct from old.payment_status then
    return new;
  end if;

  select seller.user_id, seller.kind
    into seller_user_id, exact_seller_kind
  from public.sellers as seller
  where seller.id = new.seller_id;

  if tg_op = 'INSERT' or new.status is distinct from old.status then
    title_key := 'notifications.order.status.title';
    body_key := 'notifications.order.status.body';
  else
    title_key := 'notifications.order.payment.title';
    body_key := 'notifications.order.payment.body';
  end if;

  if new.buyer_id is not null then
    perform public.create_user_notification(
      new.buyer_id,
      'order',
      title_key,
      body_key,
      jsonb_build_object(
        'orderId', new.id,
        'orderNumber', new.order_number,
        'status', new.status,
        'paymentStatus', new.payment_status,
        'sellerId', new.seller_id,
        'sellerKind', exact_seller_kind,
        'recipientRole', 'buyer',
        'recipientIdentityType', 'person',
        'recipientSellerId', null
      )
    );
  end if;

  if seller_user_id is not null and seller_user_id is distinct from new.buyer_id then
    perform public.create_user_notification(
      seller_user_id,
      'order',
      title_key,
      body_key,
      jsonb_build_object(
        'orderId', new.id,
        'orderNumber', new.order_number,
        'status', new.status,
        'paymentStatus', new.payment_status,
        'sellerId', new.seller_id,
        'sellerKind', exact_seller_kind,
        'recipientRole', 'seller',
        'recipientIdentityType', case when exact_seller_kind = 'business'
          then 'business' else 'person' end,
        'recipientSellerId', new.seller_id
      )
    );
  end if;

  return new;
end;
$$;

create or replace function public.record_product_price_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  favorite_row record;
  exact_seller_kind public.seller_kind;
begin
  if tg_op = 'INSERT' then
    insert into public.product_price_history (
      product_id,
      old_price_cents,
      new_price_cents,
      old_compare_at_price_cents,
      new_compare_at_price_cents
    ) values (
      new.id,
      null,
      new.price_cents,
      null,
      new.compare_at_price_cents
    );
    return new;
  end if;

  if new.price_cents is not distinct from old.price_cents
    and new.compare_at_price_cents is not distinct from old.compare_at_price_cents then
    return new;
  end if;

  insert into public.product_price_history (
    product_id,
    old_price_cents,
    new_price_cents,
    old_compare_at_price_cents,
    new_compare_at_price_cents
  ) values (
    new.id,
    old.price_cents,
    new.price_cents,
    old.compare_at_price_cents,
    new.compare_at_price_cents
  );

  if new.status = 'active' and new.price_cents < old.price_cents then
    select seller.kind into exact_seller_kind
    from public.sellers as seller
    where seller.id = new.seller_id;

    for favorite_row in
      select favorite.user_id, favorite.price_snapshot_cents
      from public.favorites as favorite
      where favorite.product_id = new.id
        and favorite.price_snapshot_cents is not null
        and favorite.price_snapshot_cents > new.price_cents
    loop
      perform public.create_user_notification(
        favorite_row.user_id,
        'price_drop',
        'notifications.priceDrop.title',
        'notifications.priceDrop.body',
        jsonb_build_object(
          'productId', new.id,
          'oldPriceCents', favorite_row.price_snapshot_cents,
          'newPriceCents', new.price_cents,
          'sellerId', new.seller_id,
          'sellerKind', exact_seller_kind,
          'recipientRole', 'buyer',
          'recipientIdentityType', 'person',
          'recipientSellerId', null
        )
      );
    end loop;
  end if;

  update public.favorites
  set price_snapshot_cents = new.price_cents
  where product_id = new.id;

  return new;
end;
$$;

create or replace function public.moderate_listing(
  p_product_id uuid,
  p_decision text,
  p_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  normalized_decision text := lower(pg_catalog.btrim(coalesce(p_decision, '')));
  normalized_reason text := nullif(pg_catalog.btrim(p_reason), '');
  product_row public.products%rowtype;
  seller_user_id uuid;
  exact_seller_kind public.seller_kind;
  notification_id uuid;
begin
  if auth.uid() is null or not public.is_admin() then
    raise exception 'Administrator role required' using errcode = '42501';
  end if;
  if normalized_decision not in ('approve', 'reject') then
    raise exception 'Decision must be approve or reject' using errcode = '22023';
  end if;
  if normalized_reason is not null and char_length(normalized_reason) > 2000 then
    raise exception 'Moderation reason cannot exceed 2000 characters'
      using errcode = '22023';
  end if;

  select product.* into product_row
  from public.products as product
  where product.id = p_product_id
  for update;
  if not found then
    raise exception 'Listing not found' using errcode = 'P0002';
  end if;
  if product_row.status <> 'pending_review' then
    raise exception 'Only pending listings can be moderated' using errcode = '22023';
  end if;

  select seller.user_id, seller.kind
    into seller_user_id, exact_seller_kind
  from public.sellers as seller
  where seller.id = product_row.seller_id;

  update public.products
  set
    status = case normalized_decision
      when 'approve' then 'active'::public.product_status
      else 'rejected'::public.product_status
    end,
    moderation_reason = case when normalized_decision = 'reject'
      then normalized_reason else null end,
    moderated_at = now(),
    moderated_by = auth.uid()
  where id = p_product_id
  returning * into product_row;

  if seller_user_id is not null then
    notification_id := public.create_user_notification(
      seller_user_id,
      'system',
      case normalized_decision
        when 'approve' then 'notifications.listing.approved.title'
        else 'notifications.listing.rejected.title'
      end,
      case normalized_decision
        when 'approve' then 'notifications.listing.approved.body'
        else 'notifications.listing.rejected.body'
      end,
      jsonb_strip_nulls(jsonb_build_object(
        'productId', product_row.id,
        'status', product_row.status,
        'reason', product_row.moderation_reason,
        'sellerId', product_row.seller_id,
        'sellerKind', exact_seller_kind,
        'recipientRole', 'seller',
        'recipientIdentityType', case when exact_seller_kind = 'business'
          then 'business' else 'person' end,
        'recipientSellerId', product_row.seller_id
      ))
    );
  end if;

  return jsonb_build_object(
    'id', product_row.id,
    'status', product_row.status,
    'moderation_reason', product_row.moderation_reason,
    'moderated_at', product_row.moderated_at,
    'notification_id', notification_id
  );
end;
$$;

create or replace function public.moderate_seller_document(
  p_document_id uuid,
  p_decision text,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  d public.seller_documents%rowtype;
  recipient uuid;
  exact_seller_kind public.seller_kind;
  decision text := lower(pg_catalog.btrim(coalesce(p_decision, '')));
  note text := nullif(pg_catalog.btrim(p_note), '');
begin
  if auth.uid() is null or not public.is_admin() then
    raise exception 'Administrator role required' using errcode = '42501';
  end if;
  if decision not in ('approve', 'reject') then
    raise exception 'Decision must be approve or reject' using errcode = '22023';
  end if;
  if note is not null and char_length(note) > 2000 then
    raise exception 'Note too long' using errcode = '22023';
  end if;

  select * into d
  from public.seller_documents
  where id = p_document_id
  for update;
  if not found then
    raise exception 'Seller document not found' using errcode = 'P0002';
  end if;
  if d.status <> 'pending' then
    raise exception 'Only pending documents can be moderated' using errcode = '22023';
  end if;

  update public.seller_documents
  set
    status = case when decision = 'approve'
      then 'approved'::public.seller_document_status
      else 'rejected'::public.seller_document_status end,
    admin_note = case when decision = 'reject' then note else null end,
    reviewed_by = auth.uid(),
    reviewed_at = now()
  where id = d.id
  returning * into d;

  select seller.user_id, seller.kind
    into recipient, exact_seller_kind
  from public.sellers as seller
  where seller.id = d.seller_id;

  if recipient is not null then
    perform public.create_user_notification(
      recipient,
      'system',
      case when decision = 'approve'
        then 'notifications.seller_document.approved.title'
        else 'notifications.seller_document.rejected.title' end,
      case when decision = 'approve'
        then 'notifications.seller_document.approved.body'
        else 'notifications.seller_document.rejected.body' end,
      jsonb_strip_nulls(jsonb_build_object(
        'documentId', d.id,
        'kind', d.kind,
        'reason', d.admin_note,
        'sellerId', d.seller_id,
        'sellerKind', exact_seller_kind,
        'recipientRole', 'seller',
        'recipientIdentityType', case when exact_seller_kind = 'business'
          then 'business' else 'person' end,
        'recipientSellerId', d.seller_id
      ))
    );
  end if;

  return jsonb_build_object(
    'id', d.id,
    'status', d.status,
    'reviewed_at', d.reviewed_at
  );
end;
$$;

create or replace function public.resolve_report(
  p_report_id uuid,
  p_action text,
  p_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  r public.reports%rowtype;
  product_row public.products%rowtype;
  recipient uuid;
  exact_seller_kind public.seller_kind;
  action text := lower(pg_catalog.btrim(coalesce(p_action, '')));
  reason text := nullif(pg_catalog.btrim(p_reason), '');
begin
  if auth.uid() is null or not public.is_admin() then
    raise exception 'Administrator role required' using errcode = '42501';
  end if;
  if action not in ('dismiss', 'block_listing') then
    raise exception 'Invalid report action' using errcode = '22023';
  end if;

  select * into r
  from public.reports
  where id = p_report_id
  for update;
  if not found then
    raise exception 'Report not found' using errcode = 'P0002';
  end if;
  if r.status in ('resolved', 'dismissed') then
    return jsonb_build_object('id', r.id, 'status', r.status);
  end if;
  if action = 'block_listing' and r.product_id is null then
    raise exception 'Only product reports can block a listing' using errcode = '22023';
  end if;

  if action = 'block_listing' then
    select * into product_row
    from public.products
    where id = r.product_id
    for update;
    if not found then
      raise exception 'Reported listing not found' using errcode = 'P0002';
    end if;

    update public.products
    set
      status = 'blocked'::public.product_status,
      moderation_reason = reason,
      moderated_at = now(),
      moderated_by = auth.uid()
    where id = product_row.id
    returning * into product_row;

    select seller.user_id, seller.kind
      into recipient, exact_seller_kind
    from public.sellers as seller
    where seller.id = product_row.seller_id;

    if recipient is not null then
      perform public.create_user_notification(
        recipient,
        'system',
        'notifications.listing.blocked.title',
        'notifications.listing.blocked.body',
        jsonb_strip_nulls(jsonb_build_object(
          'productId', product_row.id,
          'reason', reason,
          'sellerId', product_row.seller_id,
          'sellerKind', exact_seller_kind,
          'recipientRole', 'seller',
          'recipientIdentityType', case when exact_seller_kind = 'business'
            then 'business' else 'person' end,
          'recipientSellerId', product_row.seller_id
        ))
      );
    end if;
  end if;

  update public.reports
  set
    status = case when action = 'dismiss'
      then 'dismissed'::public.report_status
      else 'resolved'::public.report_status end,
    admin_notes = reason,
    resolved_at = now()
  where id = r.id
  returning * into r;

  return jsonb_build_object(
    'id', r.id,
    'status', r.status,
    'product_status', case when product_row.id is null
      then null else product_row.status end
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- Directory cover canonicality, ownership, and object existence
-- ---------------------------------------------------------------------------
-- Parsing is text-only and fail-safe: malformed paths never reach a UUID cast.
create function public.can_manage_directory_cover_path(target_storage_path text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    auth.uid() is not null
    and target_storage_path ~ (
      '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'
      || '/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'
      || '[.](webp|jpg|jpeg|png)$'
    )
    and exists (
      select 1
      from public.sellers as seller
      where seller.id::text = split_part(target_storage_path, '/', 1)
        and seller.user_id = auth.uid()
        and seller.kind = 'business'
    ),
    false
  );
$$;
revoke all on function public.can_manage_directory_cover_path(text)
  from public, anon, authenticated, service_role;
grant execute on function public.can_manage_directory_cover_path(text)
  to authenticated;

-- The row itself now binds the canonical first path segment to its immutable seller_id.
alter table public.business_directory_profiles
  add constraint business_directory_profiles_cover_same_seller_check check (
    cover_image_path is null
    or cover_image_path ~ (
      '^' || seller_id::text
      || '/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'
      || '[.](webp|jpg|jpeg|png)$'
    )
  );

-- Preserve the latest separate-rating protections and doctor transition guard, then
-- add explicit owner binding and upload-before-save object verification.
create or replace function public.validate_directory_profile_write()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  seller_row public.sellers%rowtype;
begin
  select seller.* into seller_row
  from public.sellers as seller
  where seller.id = new.seller_id;
  if not found or seller_row.kind <> 'business' then
    raise exception 'Directory profiles require a business seller'
      using errcode = '23514';
  end if;

  if auth.uid() is not null and not public.is_admin() then
    if tg_op = 'INSERT' then
      new.rating_average := 0;
      new.rating_count := 0;
    else
      new.rating_average := old.rating_average;
      new.rating_count := old.rating_count;
    end if;
  end if;

  if tg_op = 'UPDATE' and new.seller_id is distinct from old.seller_id then
    raise exception 'Directory profile ownership is immutable' using errcode = '22023';
  end if;

  if new.cover_image_path is not null then
    if new.cover_image_path !~ (
      '^' || new.seller_id::text
      || '/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'
      || '[.](webp|jpg|jpeg|png)$'
    ) then
      raise exception 'Directory cover path must be canonical and same-seller'
        using errcode = '23514';
    end if;

    if auth.uid() is not null
      and not public.is_admin()
      and not public.can_manage_directory_cover_path(new.cover_image_path) then
      raise exception 'Directory cover path is not owned by caller'
        using errcode = '42501';
    end if;

    if not exists (
      select 1
      from storage.objects as object_row
      where object_row.bucket_id = 'directory-covers'
        and object_row.name = new.cover_image_path
    ) then
      raise exception 'Directory cover must be uploaded before profile save'
        using errcode = '22023';
    end if;
  end if;

  if tg_op = 'UPDATE'
    and new.type = 'doctor'
    and old.type <> 'doctor'
    and (
      exists (
        select 1
        from public.business_directory_menu_sections
        where seller_id = new.seller_id
      )
      or exists (
        select 1
        from public.reviews
        where seller_id = new.seller_id and context = 'directory'
      )
    ) then
    raise exception 'Remove menu and directory reviews before changing to doctor'
      using errcode = '23514';
  end if;

  return new;
end;
$$;
revoke all on function public.validate_directory_profile_write()
  from public, anon, authenticated, service_role;

-- Upload remains first, profile save second. Every object mutation uses the same strict
-- canonical parser and exact owned BUSINESS identity; null profile covers remain valid.
drop policy directory_covers_insert on storage.objects;
create policy directory_covers_insert
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'directory-covers'
    and public.can_manage_directory_cover_path(name)
  );

drop policy directory_covers_update on storage.objects;
create policy directory_covers_update
  on storage.objects for update to authenticated
  using (
    bucket_id = 'directory-covers'
    and public.can_manage_directory_cover_path(name)
    and not exists (
      select 1
      from public.business_directory_profiles as profile
      where profile.cover_image_path = storage.objects.name
    )
  )
  with check (
    bucket_id = 'directory-covers'
    and public.can_manage_directory_cover_path(name)
  );

drop policy directory_covers_delete on storage.objects;
create policy directory_covers_delete
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'directory-covers'
    and public.can_manage_directory_cover_path(name)
    and not exists (
      select 1
      from public.business_directory_profiles as profile
      where profile.cover_image_path = storage.objects.name
    )
  );

-- Trigger functions are never client RPCs. Their table triggers continue to invoke them
-- as before, but direct PostgREST execution is removed.
revoke all on function public.notify_chat_message()
  from public, anon, authenticated, service_role;
revoke all on function public.notify_order_change()
  from public, anon, authenticated, service_role;
revoke all on function public.record_product_price_change()
  from public, anon, authenticated, service_role;
revoke all on function public.queue_notification_delivery()
  from public, anon, authenticated, service_role;

-- Existing old-signature RPC ACLs were preserved by CREATE OR REPLACE. Exactly one
-- schema-cache notification follows all overload and policy changes.
notify pgrst, 'reload schema';
commit;
