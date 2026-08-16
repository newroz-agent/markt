-- Phase 5: notifications, price alerts, DSGVO consent/data-subject requests,
-- analytics consent, legal document versions, and review/export media.

begin;

do $$
begin
  if not exists (
    select 1
    from pg_type as enum_type
    join pg_namespace as namespace on namespace.oid = enum_type.typnamespace
    where namespace.nspname = 'public' and enum_type.typname = 'push_platform'
  ) then
    create type public.push_platform as enum ('ios', 'android', 'web');
  end if;
end;
$$;

do $$
begin
  if not exists (
    select 1
    from pg_type as enum_type
    join pg_namespace as namespace on namespace.oid = enum_type.typnamespace
    where namespace.nspname = 'public' and enum_type.typname = 'notification_delivery_status'
  ) then
    create type public.notification_delivery_status as enum (
      'pending',
      'processing',
      'sent',
      'failed',
      'dead'
    );
  end if;
end;
$$;

do $$
begin
  if not exists (
    select 1
    from pg_type as enum_type
    join pg_namespace as namespace on namespace.oid = enum_type.typnamespace
    where namespace.nspname = 'public' and enum_type.typname = 'legal_document_kind'
  ) then
    create type public.legal_document_kind as enum (
      'imprint',
      'terms',
      'privacy',
      'withdrawal'
    );
  end if;
end;
$$;

do $$
begin
  if not exists (
    select 1
    from pg_type as enum_type
    join pg_namespace as namespace on namespace.oid = enum_type.typnamespace
    where namespace.nspname = 'public' and enum_type.typname = 'data_subject_request_kind'
  ) then
    create type public.data_subject_request_kind as enum ('export', 'deletion');
  end if;
end;
$$;

do $$
begin
  if not exists (
    select 1
    from pg_type as enum_type
    join pg_namespace as namespace on namespace.oid = enum_type.typnamespace
    where namespace.nspname = 'public' and enum_type.typname = 'data_subject_request_status'
  ) then
    create type public.data_subject_request_status as enum (
      'requested',
      'verifying',
      'processing',
      'completed',
      'rejected',
      'cancelled'
    );
  end if;
end;
$$;

alter table public.favorites
  add column price_snapshot_cents bigint
    check (price_snapshot_cents is null or price_snapshot_cents >= 0);

update public.favorites as favorite
set price_snapshot_cents = product.price_cents
from public.products as product
where product.id = favorite.product_id
  and favorite.price_snapshot_cents is null;

create table public.product_price_history (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products (id) on delete cascade,
  old_price_cents bigint,
  new_price_cents bigint not null check (new_price_cents >= 0),
  old_compare_at_price_cents bigint,
  new_compare_at_price_cents bigint,
  changed_at timestamptz not null default now(),
  constraint product_price_history_old_price_check
    check (old_price_cents is null or old_price_cents >= 0)
);

create index product_price_history_product_changed_idx
  on public.product_price_history (product_id, changed_at desc);

create table public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  token text not null unique check (char_length(token) between 20 and 4096),
  platform public.push_platform not null,
  app_version text,
  locale public.app_language not null default 'de',
  enabled boolean not null default true,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, platform, token)
);

create index device_tokens_user_enabled_idx
  on public.device_tokens (user_id, enabled, last_seen_at desc);

create table public.notification_outbox (
  id uuid primary key default gen_random_uuid(),
  notification_id uuid not null unique references public.notifications (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  status public.notification_delivery_status not null default 'pending',
  attempts smallint not null default 0 check (attempts >= 0),
  available_at timestamptz not null default now(),
  locked_at timestamptz,
  sent_at timestamptz,
  last_error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index notification_outbox_claim_idx
  on public.notification_outbox (available_at, created_at)
  where status = 'pending';
create index notification_outbox_user_idx
  on public.notification_outbox (user_id, created_at desc);

create table public.analytics_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  event_name text not null check (event_name ~ '^[a-z][a-z0-9_.-]{1,79}$'),
  session_id text check (session_id is null or char_length(session_id) between 1 and 200),
  properties jsonb not null default '{}'::jsonb,
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  constraint analytics_events_properties_object
    check (jsonb_typeof(properties) = 'object')
);

create index analytics_events_user_occurred_idx
  on public.analytics_events (user_id, occurred_at desc);
create index analytics_events_name_occurred_idx
  on public.analytics_events (event_name, occurred_at desc);

create table public.legal_documents (
  id uuid primary key default gen_random_uuid(),
  kind public.legal_document_kind not null,
  locale public.app_language not null,
  version text not null check (version ~ '^[0-9]+\\.[0-9]+(?:\\.[0-9]+)?$'),
  title text not null check (char_length(title) between 1 and 200),
  content_markdown text not null check (char_length(content_markdown) between 1 and 500000),
  checksum text,
  effective_at timestamptz not null default now(),
  published_at timestamptz,
  is_active boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (kind, locale, version)
);

create unique index legal_documents_one_active_locale_idx
  on public.legal_documents (kind, locale)
  where is_active;
create index legal_documents_publication_idx
  on public.legal_documents (kind, locale, effective_at desc)
  where is_active;

create table public.user_consents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  consent_type text not null check (consent_type ~ '^[a-z][a-z0-9_.-]{1,79}$'),
  granted boolean not null,
  legal_document_id uuid references public.legal_documents (id) on delete set null,
  document_version text,
  ip_hash text,
  user_agent text,
  created_at timestamptz not null default now()
);

create index user_consents_user_created_idx
  on public.user_consents (user_id, consent_type, created_at desc);

create table public.data_subject_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  kind public.data_subject_request_kind not null,
  status public.data_subject_request_status not null default 'requested',
  reason text check (reason is null or char_length(reason) <= 2000),
  export_storage_path text,
  export_expires_at timestamptz,
  requested_at timestamptz not null default now(),
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint data_subject_export_fields check (
    kind <> 'export'
    or status <> 'completed'
    or export_storage_path is not null
  )
);

create unique index data_subject_one_open_request_idx
  on public.data_subject_requests (user_id, kind)
  where status in ('requested', 'verifying', 'processing');
create index data_subject_requests_user_created_idx
  on public.data_subject_requests (user_id, created_at desc);

drop trigger if exists set_updated_at on public.device_tokens;
create trigger set_updated_at
  before update on public.device_tokens
  for each row execute function public.set_updated_at();
drop trigger if exists set_updated_at on public.notification_outbox;
create trigger set_updated_at
  before update on public.notification_outbox
  for each row execute function public.set_updated_at();
drop trigger if exists set_updated_at on public.legal_documents;
create trigger set_updated_at
  before update on public.legal_documents
  for each row execute function public.set_updated_at();
drop trigger if exists set_updated_at on public.data_subject_requests;
create trigger set_updated_at
  before update on public.data_subject_requests
  for each row execute function public.set_updated_at();

create or replace function public.notification_preference_enabled(
  target_user_id uuid,
  target_kind public.notification_kind
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((
    select case target_kind
      when 'order' then coalesce(
        profile.notification_preferences -> 'orders' = 'true'::jsonb,
        true
      )
      when 'chat' then coalesce(
        profile.notification_preferences -> 'chat' = 'true'::jsonb,
        true
      )
      when 'offer' then coalesce(
        profile.notification_preferences -> 'offers' = 'true'::jsonb,
        false
      )
      when 'price_drop' then coalesce(
        profile.notification_preferences -> 'priceDrops' = 'true'::jsonb,
        true
      )
      when 'system' then coalesce(
        profile.notification_preferences -> 'system' = 'true'::jsonb,
        true
      )
    end
    from public.profiles as profile
    where profile.id = target_user_id
  ), true);
$$;

create or replace function public.create_user_notification(
  p_user_id uuid,
  p_kind public.notification_kind,
  p_title_key text,
  p_body_key text,
  p_data jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  notification_id uuid;
begin
  if p_user_id is null
    or nullif(pg_catalog.btrim(p_title_key), '') is null
    or nullif(pg_catalog.btrim(p_body_key), '') is null then
    raise exception 'Notification recipient and keys are required' using errcode = '22023';
  end if;

  if jsonb_typeof(coalesce(p_data, '{}'::jsonb)) <> 'object' then
    raise exception 'Notification data must be an object' using errcode = '22023';
  end if;

  insert into public.notifications (
    user_id,
    kind,
    title_key,
    body_key,
    data
  )
  values (
    p_user_id,
    p_kind,
    pg_catalog.btrim(p_title_key),
    pg_catalog.btrim(p_body_key),
    coalesce(p_data, '{}'::jsonb)
  )
  returning id into notification_id;

  return notification_id;
end;
$$;

create or replace function public.queue_notification_delivery()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if public.notification_preference_enabled(new.user_id, new.kind) then
    insert into public.notification_outbox (notification_id, user_id)
    values (new.id, new.user_id)
    on conflict (notification_id) do nothing;
  end if;

  return new;
end;
$$;

drop trigger if exists queue_notification_delivery on public.notifications;
create trigger queue_notification_delivery
  after insert on public.notifications
  for each row execute function public.queue_notification_delivery();

create or replace function public.notify_chat_message()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  recipient_id uuid;
begin
  if new.sender_id is null or new.kind = 'system' then
    return new;
  end if;

  select case
    when chat.buyer_id = new.sender_id then seller.user_id
    else chat.buyer_id
  end
    into recipient_id
  from public.chats as chat
  join public.sellers as seller on seller.id = chat.seller_id
  where chat.id = new.chat_id;

  if recipient_id is not null and recipient_id is distinct from new.sender_id then
    perform public.create_user_notification(
      recipient_id,
      'chat',
      'notifications.chat.title',
      'notifications.chat.body',
      jsonb_build_object(
        'chatId', new.chat_id,
        'messageId', new.id,
        'kind', new.kind
      )
    );
  end if;

  return new;
end;
$$;

drop trigger if exists notify_chat_message on public.messages;
create trigger notify_chat_message
  after insert on public.messages
  for each row execute function public.notify_chat_message();

create or replace function public.notify_order_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  seller_user_id uuid;
  title_key text;
  body_key text;
begin
  if tg_op = 'UPDATE'
    and new.status is not distinct from old.status
    and new.payment_status is not distinct from old.payment_status then
    return new;
  end if;

  select seller.user_id into seller_user_id
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
        'paymentStatus', new.payment_status
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
        'paymentStatus', new.payment_status
      )
    );
  end if;

  return new;
end;
$$;

drop trigger if exists notify_order_change on public.orders;
create trigger notify_order_change
  after insert or update of status, payment_status on public.orders
  for each row execute function public.notify_order_change();

create or replace function public.protect_favorite_write()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is not null and not public.is_admin() then
    if tg_op = 'INSERT' then
      new.user_id = auth.uid();
    elsif new.user_id is distinct from old.user_id
      or new.product_id is distinct from old.product_id then
      raise exception 'Favorite ownership is immutable';
    end if;
  end if;

  select product.price_cents
    into new.price_snapshot_cents
  from public.products as product
  where product.id = new.product_id;

  return new;
end;
$$;

drop trigger if exists protect_favorite_write on public.favorites;
create trigger protect_favorite_write
  before insert or update of user_id, product_id on public.favorites
  for each row execute function public.protect_favorite_write();

create or replace function public.record_product_price_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  favorite_row record;
begin
  if tg_op = 'INSERT' then
    insert into public.product_price_history (
      product_id,
      old_price_cents,
      new_price_cents,
      old_compare_at_price_cents,
      new_compare_at_price_cents
    )
    values (
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
  )
  values (
    new.id,
    old.price_cents,
    new.price_cents,
    old.compare_at_price_cents,
    new.compare_at_price_cents
  );

  if new.status = 'active' and new.price_cents < old.price_cents then
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
          'newPriceCents', new.price_cents
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

drop trigger if exists record_product_price_change on public.products;
create trigger record_product_price_change
  after insert or update of price_cents, compare_at_price_cents, status
  on public.products
  for each row execute function public.record_product_price_change();

insert into public.product_price_history (
  product_id,
  old_price_cents,
  new_price_cents,
  old_compare_at_price_cents,
  new_compare_at_price_cents
)
select
  product.id,
  null,
  product.price_cents,
  null,
  product.compare_at_price_cents
from public.products as product
where not exists (
  select 1
  from public.product_price_history as history
  where history.product_id = product.id
);

create or replace function public.prepare_profile_privacy_preferences()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  preference_key text;
begin
  foreach preference_key in array array[
    'orders',
    'chat',
    'offers',
    'priceDrops',
    'system'
  ] loop
    if new.notification_preferences ? preference_key
      and jsonb_typeof(new.notification_preferences -> preference_key) <> 'boolean' then
      raise exception 'Notification preference % must be boolean', preference_key
        using errcode = '22023';
    end if;
  end loop;

  if tg_op = 'INSERT' then
    new.analytics_consent_at := case when new.analytics_consent then now() else null end;
  elsif new.analytics_consent is distinct from old.analytics_consent then
    new.analytics_consent_at := case when new.analytics_consent then now() else null end;
  elsif new.analytics_consent_at is distinct from old.analytics_consent_at then
    raise exception 'Analytics consent timestamp is server-managed';
  end if;

  return new;
end;
$$;

drop trigger if exists prepare_profile_privacy_preferences on public.profiles;
create trigger prepare_profile_privacy_preferences
  before insert or update of analytics_consent, analytics_consent_at, notification_preferences
  on public.profiles
  for each row execute function public.prepare_profile_privacy_preferences();

create or replace function public.protect_device_token_write()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if auth.uid() is not null and not public.is_admin() then
    if tg_op = 'INSERT' then
      new.user_id = auth.uid();
    elsif new.id is distinct from old.id
      or new.user_id is distinct from old.user_id
      or new.token is distinct from old.token then
      raise exception 'Device token identity is immutable';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists protect_device_token_write on public.device_tokens;
create trigger protect_device_token_write
  before insert or update on public.device_tokens
  for each row execute function public.protect_device_token_write();

create or replace function public.claim_notification_outbox(p_limit integer default 50)
returns table (
  outbox_id uuid,
  user_id uuid,
  notification_id uuid,
  kind public.notification_kind,
  title_key text,
  body_key text,
  data jsonb,
  device_tokens text[],
  attempt_number smallint
)
language sql
security definer
set search_path = ''
as $$
  with candidates as (
    select outbox.id
    from public.notification_outbox as outbox
    where outbox.status = 'pending'
      and outbox.available_at <= now()
    order by outbox.created_at
    limit least(greatest(coalesce(p_limit, 50), 1), 500)
    for update skip locked
  ), claimed as (
    update public.notification_outbox as outbox
    set
      status = 'processing',
      attempts = outbox.attempts + 1,
      locked_at = now(),
      updated_at = now()
    from candidates
    where outbox.id = candidates.id
    returning outbox.*
  )
  select
    claimed.id,
    claimed.user_id,
    notification.id,
    notification.kind,
    notification.title_key,
    notification.body_key,
    notification.data,
    coalesce(
      array_agg(device.token order by device.last_seen_at desc)
        filter (where device.token is not null),
      '{}'::text[]
    ),
    claimed.attempts
  from claimed
  join public.notifications as notification on notification.id = claimed.notification_id
  left join public.device_tokens as device
    on device.user_id = claimed.user_id and device.enabled
  group by
    claimed.id,
    claimed.user_id,
    notification.id,
    notification.kind,
    notification.title_key,
    notification.body_key,
    notification.data,
    claimed.attempts;
$$;

create or replace function public.complete_notification_delivery(
  p_outbox_id uuid,
  p_success boolean,
  p_error text default null
)
returns public.notification_delivery_status
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_outbox public.notification_outbox%rowtype;
  next_status public.notification_delivery_status;
begin
  select outbox.*
    into current_outbox
  from public.notification_outbox as outbox
  where outbox.id = p_outbox_id
  for update;

  if not found then
    raise exception 'Notification delivery not found' using errcode = 'P0002';
  end if;

  if p_success then
    next_status := 'sent';
    update public.notification_outbox
    set
      status = next_status,
      sent_at = now(),
      locked_at = null,
      last_error = null
    where id = p_outbox_id;
  elsif current_outbox.attempts >= 5 then
    next_status := 'dead';
    update public.notification_outbox
    set
      status = next_status,
      locked_at = null,
      last_error = left(coalesce(p_error, 'delivery_failed'), 2000)
    where id = p_outbox_id;
  else
    next_status := 'pending';
    update public.notification_outbox
    set
      status = next_status,
      available_at = now() + pg_catalog.make_interval(
        mins => least(current_outbox.attempts * 5, 60)
      ),
      locked_at = null,
      last_error = left(coalesce(p_error, 'delivery_failed'), 2000)
    where id = p_outbox_id;
  end if;

  return next_status;
end;
$$;

create or replace function public.requeue_stale_notification_outbox(
  p_age interval default interval '10 minutes'
)
returns integer
language sql
security definer
set search_path = ''
as $$
  with stale as (
    update public.notification_outbox
    set
      status = 'pending',
      available_at = now(),
      locked_at = null,
      last_error = 'stale_processing_lock'
    where status = 'processing'
      and locked_at < now() - p_age
    returning id
  )
  select count(*)::integer from stale;
$$;

create or replace function public.track_analytics_event(
  p_event_name text,
  p_properties jsonb default '{}'::jsonb,
  p_session_id text default null,
  p_occurred_at timestamptz default now()
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  event_id uuid;
  analytics_allowed boolean;
begin
  if auth.uid() is null then
    raise exception 'Authentication required for analytics' using errcode = '42501';
  end if;

  select profile.analytics_consent into analytics_allowed
  from public.profiles as profile
  where profile.id = auth.uid();

  if not coalesce(analytics_allowed, false) then
    return null;
  end if;

  if p_event_name is null or p_event_name !~ '^[a-z][a-z0-9_.-]{1,79}$' then
    raise exception 'Invalid analytics event name' using errcode = '22023';
  end if;

  if jsonb_typeof(coalesce(p_properties, '{}'::jsonb)) <> 'object'
    or pg_catalog.octet_length(coalesce(p_properties, '{}'::jsonb)::text) > 20000 then
    raise exception 'Analytics properties must be an object under 20 KB'
      using errcode = '22023';
  end if;

  insert into public.analytics_events (
    user_id,
    event_name,
    session_id,
    properties,
    occurred_at
  )
  values (
    auth.uid(),
    p_event_name,
    nullif(pg_catalog.btrim(p_session_id), ''),
    coalesce(p_properties, '{}'::jsonb),
    coalesce(p_occurred_at, now())
  )
  returning id into event_id;

  return event_id;
end;
$$;

create or replace function public.request_data_export()
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  request_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select request.id into request_id
  from public.data_subject_requests as request
  where request.user_id = auth.uid()
    and request.kind = 'export'
    and request.status in ('requested', 'verifying', 'processing')
  order by request.created_at desc
  limit 1;

  if request_id is not null then
    return request_id;
  end if;

  insert into public.data_subject_requests (user_id, kind)
  values (auth.uid(), 'export')
  returning id into request_id;

  return request_id;
end;
$$;

create or replace function public.request_account_deletion(
  p_confirmation text,
  p_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  request_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  if upper(pg_catalog.btrim(coalesce(p_confirmation, ''))) <> 'DELETE' then
    raise exception 'Confirmation text must be DELETE' using errcode = '22023';
  end if;

  select request.id into request_id
  from public.data_subject_requests as request
  where request.user_id = auth.uid()
    and request.kind = 'deletion'
    and request.status in ('requested', 'verifying', 'processing')
  order by request.created_at desc
  limit 1;

  if request_id is not null then
    return request_id;
  end if;

  insert into public.data_subject_requests (user_id, kind, reason)
  values (auth.uid(), 'deletion', nullif(pg_catalog.btrim(p_reason), ''))
  returning id into request_id;

  return request_id;
end;
$$;

create or replace function public.cancel_account_deletion()
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.data_subject_requests
  set status = 'cancelled'
  where user_id = auth.uid()
    and kind = 'deletion'
    and status in ('requested', 'verifying');
  return found;
end;
$$;

create or replace function public.protect_user_consent_write()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if auth.uid() is not null and not public.is_admin() then
    if tg_op = 'INSERT' then
      new.user_id = auth.uid();
    else
      raise exception 'Consent records are immutable';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists protect_user_consent_write on public.user_consents;
create trigger protect_user_consent_write
  before insert or update on public.user_consents
  for each row execute function public.protect_user_consent_write();

create or replace function public.validate_review_photo_paths()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  photo_path text;
begin
  foreach photo_path in array coalesce(new.photo_paths, '{}'::text[]) loop
    if split_part(photo_path, '/', 1) <> new.reviewer_id::text
      or array_length(string_to_array(photo_path, '/'), 1) < 2 then
      raise exception 'Review photos must be stored under reviewer folder';
    end if;
  end loop;
  return new;
end;
$$;

drop trigger if exists validate_review_photo_paths on public.reviews;
create trigger validate_review_photo_paths
  before insert or update of photo_paths, reviewer_id on public.reviews
  for each row execute function public.validate_review_photo_paths();

alter table public.product_price_history enable row level security;
alter table public.device_tokens enable row level security;
alter table public.notification_outbox enable row level security;
alter table public.analytics_events enable row level security;
alter table public.legal_documents enable row level security;
alter table public.user_consents enable row level security;
alter table public.data_subject_requests enable row level security;

drop policy if exists product_price_history_select_visible on public.product_price_history;
create policy product_price_history_select_visible
  on public.product_price_history for select to authenticated
  using (
    public.owns_product(product_id)
    or public.is_admin()
  );

drop policy if exists device_tokens_select_own on public.device_tokens;
create policy device_tokens_select_own
  on public.device_tokens for select to authenticated
  using (user_id = auth.uid() or public.is_admin());
drop policy if exists device_tokens_insert_own on public.device_tokens;
create policy device_tokens_insert_own
  on public.device_tokens for insert to authenticated
  with check (user_id = auth.uid() or public.is_admin());
drop policy if exists device_tokens_update_own on public.device_tokens;
create policy device_tokens_update_own
  on public.device_tokens for update to authenticated
  using (user_id = auth.uid() or public.is_admin())
  with check (user_id = auth.uid() or public.is_admin());
drop policy if exists device_tokens_delete_own on public.device_tokens;
create policy device_tokens_delete_own
  on public.device_tokens for delete to authenticated
  using (user_id = auth.uid() or public.is_admin());

drop policy if exists notification_outbox_manage_admin on public.notification_outbox;
create policy notification_outbox_manage_admin
  on public.notification_outbox for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists analytics_events_select_own on public.analytics_events;
create policy analytics_events_select_own
  on public.analytics_events for select to authenticated
  using (user_id = auth.uid() or public.is_admin());
drop policy if exists analytics_events_manage_admin on public.analytics_events;
create policy analytics_events_manage_admin
  on public.analytics_events for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists legal_documents_select_published on public.legal_documents;
create policy legal_documents_select_published
  on public.legal_documents for select to anon, authenticated
  using ((is_active and published_at is not null and published_at <= now()) or public.is_admin());
drop policy if exists legal_documents_manage_admin on public.legal_documents;
create policy legal_documents_manage_admin
  on public.legal_documents for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists user_consents_select_own on public.user_consents;
create policy user_consents_select_own
  on public.user_consents for select to authenticated
  using (user_id = auth.uid() or public.is_admin());
drop policy if exists user_consents_insert_own on public.user_consents;
create policy user_consents_insert_own
  on public.user_consents for insert to authenticated
  with check (user_id = auth.uid() or public.is_admin());
drop policy if exists user_consents_manage_admin on public.user_consents;
create policy user_consents_manage_admin
  on public.user_consents for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists data_subject_requests_select_own on public.data_subject_requests;
create policy data_subject_requests_select_own
  on public.data_subject_requests for select to authenticated
  using (user_id = auth.uid() or public.is_admin());
drop policy if exists data_subject_requests_manage_admin on public.data_subject_requests;
create policy data_subject_requests_manage_admin
  on public.data_subject_requests for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

grant select on table public.product_price_history to authenticated;
grant select, insert, update, delete on table public.device_tokens to authenticated;
grant select on table public.analytics_events to authenticated;
grant select on table public.legal_documents to anon, authenticated;
grant insert, update, delete on table public.legal_documents to authenticated;
grant select, insert on table public.user_consents to authenticated;
grant select on table public.data_subject_requests to authenticated;
grant insert, update, delete on table public.data_subject_requests to authenticated;
grant select, update on table public.notification_outbox to authenticated;
grant all on table public.product_price_history to service_role;
grant all on table public.device_tokens to service_role;
grant all on table public.notification_outbox to service_role;
grant all on table public.analytics_events to service_role;
grant all on table public.legal_documents to service_role;
grant all on table public.user_consents to service_role;
grant all on table public.data_subject_requests to service_role;

revoke all on function public.notification_preference_enabled(uuid, public.notification_kind)
  from public;
revoke all on function public.create_user_notification(
  uuid, public.notification_kind, text, text, jsonb
) from public;
revoke all on function public.claim_notification_outbox(integer) from public;
revoke all on function public.complete_notification_delivery(uuid, boolean, text)
  from public;
revoke all on function public.requeue_stale_notification_outbox(interval) from public;
revoke all on function public.track_analytics_event(text, jsonb, text, timestamptz)
  from public;
revoke all on function public.request_data_export() from public;
revoke all on function public.request_account_deletion(text, text) from public;
revoke all on function public.cancel_account_deletion() from public;

grant execute on function public.create_user_notification(
  uuid, public.notification_kind, text, text, jsonb
) to service_role;
grant execute on function public.claim_notification_outbox(integer) to service_role;
grant execute on function public.complete_notification_delivery(uuid, boolean, text)
  to service_role;
grant execute on function public.requeue_stale_notification_outbox(interval) to service_role;
grant execute on function public.track_analytics_event(text, jsonb, text, timestamptz)
  to authenticated;
grant execute on function public.request_data_export() to authenticated;
grant execute on function public.request_account_deletion(text, text) to authenticated;
grant execute on function public.cancel_account_deletion() to authenticated;

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values
  (
    'review-media',
    'review-media',
    false,
    10485760,
    array['image/webp', 'image/jpeg', 'image/png']::text[]
  ),
  (
    'data-exports',
    'data-exports',
    false,
    52428800,
    array['application/zip', 'application/json']::text[]
  )
on conflict (id) do update set
  name = excluded.name,
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create or replace function public.can_access_review_media_path(target_storage_path text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    split_part(target_storage_path, '/', 1) = auth.uid()::text
    or exists (
      select 1
      from public.reviews as review
      where target_storage_path = any(review.photo_paths)
        and review.status = 'published'
    )
    or public.is_admin();
$$;

create or replace function public.owns_export_path(target_storage_path text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select split_part(target_storage_path, '/', 1) = auth.uid()::text
    or public.is_admin();
$$;

create or replace function public.can_manage_review_media_path(target_storage_path text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    split_part(target_storage_path, '/', 1) = auth.uid()::text
    and not exists (
      select 1
      from public.reviews as review
      where target_storage_path = any(review.photo_paths)
        and review.status = 'published'
    );
$$;

drop policy if exists review_media_storage_select on storage.objects;
create policy review_media_storage_select
  on storage.objects for select to anon, authenticated
  using (
    bucket_id = 'review-media'
    and public.can_access_review_media_path(name)
  );
drop policy if exists review_media_storage_insert on storage.objects;
create policy review_media_storage_insert
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'review-media'
    and array_length(storage.foldername(name), 1) >= 2
    and split_part(name, '/', 1) = auth.uid()::text
  );
drop policy if exists review_media_storage_update on storage.objects;
create policy review_media_storage_update
  on storage.objects for update to authenticated
  using (
    bucket_id = 'review-media'
    and public.can_manage_review_media_path(name)
  )
  with check (
    bucket_id = 'review-media'
    and public.can_manage_review_media_path(name)
  );
drop policy if exists review_media_storage_delete on storage.objects;
create policy review_media_storage_delete
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'review-media'
    and public.can_manage_review_media_path(name)
  );

drop policy if exists data_exports_storage_select on storage.objects;
create policy data_exports_storage_select
  on storage.objects for select to authenticated
  using (
    bucket_id = 'data-exports'
    and public.owns_export_path(name)
  );
drop policy if exists data_exports_storage_manage_admin on storage.objects;
create policy data_exports_storage_manage_admin
  on storage.objects for all to authenticated
  using (bucket_id = 'data-exports' and public.is_admin())
  with check (bucket_id = 'data-exports' and public.is_admin());

revoke all on function public.can_access_review_media_path(text) from public;
revoke all on function public.can_manage_review_media_path(text) from public;
revoke all on function public.owns_export_path(text) from public;
grant execute on function public.can_access_review_media_path(text)
  to anon, authenticated;
grant execute on function public.can_manage_review_media_path(text) to authenticated;
grant execute on function public.owns_export_path(text) to authenticated;

alter table public.notifications replica identity full;
alter table public.device_tokens replica identity full;
alter table public.data_subject_requests replica identity full;

commit;
