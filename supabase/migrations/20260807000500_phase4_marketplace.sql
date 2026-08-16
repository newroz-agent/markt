-- Phase 4: private listings, seller verification/dashboard data, payouts,
-- realtime chat helpers, and seller-owned media.

begin;

do $$
begin
  if not exists (
    select 1
    from pg_type as enum_type
    join pg_namespace as namespace on namespace.oid = enum_type.typnamespace
    where namespace.nspname = 'public' and enum_type.typname = 'seller_document_kind'
  ) then
    create type public.seller_document_kind as enum (
      'identity',
      'business_registration',
      'vat_certificate',
      'bank_account',
      'other'
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
    where namespace.nspname = 'public' and enum_type.typname = 'seller_document_status'
  ) then
    create type public.seller_document_status as enum ('pending', 'approved', 'rejected');
  end if;
end;
$$;

do $$
begin
  if not exists (
    select 1
    from pg_type as enum_type
    join pg_namespace as namespace on namespace.oid = enum_type.typnamespace
    where namespace.nspname = 'public' and enum_type.typname = 'payout_status'
  ) then
    create type public.payout_status as enum (
      'pending',
      'in_transit',
      'paid',
      'failed',
      'cancelled'
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
    where namespace.nspname = 'public' and enum_type.typname = 'ledger_entry_kind'
  ) then
    create type public.ledger_entry_kind as enum ('sale', 'refund', 'fee', 'adjustment');
  end if;
end;
$$;

alter table public.chats
  add column buyer_last_read_at timestamptz,
  add column seller_last_read_at timestamptz;

alter table public.orders
  add column platform_fee_cents bigint not null default 0
    check (platform_fee_cents >= 0 and platform_fee_cents <= total_cents);

create table public.seller_status_history (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.sellers (id) on delete cascade,
  from_status public.seller_status,
  to_status public.seller_status not null,
  actor_user_id uuid references auth.users (id) on delete set null,
  reason text check (reason is null or char_length(reason) <= 2000),
  created_at timestamptz not null default now()
);

create index seller_status_history_seller_created_idx
  on public.seller_status_history (seller_id, created_at desc);

create table public.seller_documents (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.sellers (id) on delete cascade,
  uploaded_by uuid references auth.users (id) on delete set null,
  kind public.seller_document_kind not null,
  storage_path text not null unique,
  mime_type text not null,
  status public.seller_document_status not null default 'pending',
  admin_note text check (admin_note is null or char_length(admin_note) <= 2000),
  reviewed_by uuid references auth.users (id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint seller_documents_mime_type check (
    mime_type in ('application/pdf', 'image/webp', 'image/jpeg', 'image/png')
  )
);

create index seller_documents_seller_status_idx
  on public.seller_documents (seller_id, status, created_at desc);

create table public.seller_payouts (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.sellers (id) on delete restrict,
  stripe_payout_id text unique,
  amount_cents bigint not null check (amount_cents >= 0),
  currency text not null default 'EUR' check (currency ~ '^[A-Z]{3}$'),
  status public.payout_status not null default 'pending',
  arrival_date date,
  failure_code text,
  failure_message text,
  provider_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint seller_payouts_payload_object check (jsonb_typeof(provider_payload) = 'object')
);

create index seller_payouts_seller_created_idx
  on public.seller_payouts (seller_id, created_at desc);
create index seller_payouts_status_arrival_idx
  on public.seller_payouts (status, arrival_date);

create table public.seller_balance_transactions (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.sellers (id) on delete restrict,
  order_id uuid references public.orders (id) on delete set null,
  order_item_id uuid references public.order_items (id) on delete set null,
  payout_id uuid references public.seller_payouts (id) on delete set null,
  kind public.ledger_entry_kind not null,
  source_key text not null unique,
  amount_cents bigint not null,
  currency text not null default 'EUR' check (currency ~ '^[A-Z]{3}$'),
  available_at timestamptz,
  description text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint seller_balance_transactions_metadata_object
    check (jsonb_typeof(metadata) = 'object')
);

create index seller_balance_transactions_seller_created_idx
  on public.seller_balance_transactions (seller_id, created_at desc);
create index seller_balance_transactions_available_idx
  on public.seller_balance_transactions (seller_id, available_at)
  where available_at is not null;

create or replace function public.prepare_seller_write()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- Private listings are moderated by the product/report flow and can go
  -- live immediately. Business vendors remain pending until verification.
  if new.kind = 'private' then
    new.status = 'approved';
    new.approved_at = coalesce(new.approved_at, now());
    new.rejection_reason = null;
  elsif new.status = 'approved' then
    new.approved_at = coalesce(new.approved_at, now());
    new.rejection_reason = null;
  else
    new.approved_at = null;
  end if;

  if auth.uid() is not null and not public.is_admin() then
    if tg_op = 'INSERT' then
      if new.user_id is distinct from auth.uid() then
        raise exception 'A seller application must belong to the authenticated user';
      end if;

      if new.kind <> 'private' then
        new.status = 'pending';
        new.approved_at = null;
        new.rejection_reason = null;
      end if;

      new.rating_average = 0;
      new.rating_count = 0;
    else
      if new.user_id is distinct from old.user_id
        or new.kind is distinct from old.kind
        or new.status is distinct from old.status
        or new.approved_at is distinct from old.approved_at
        or new.rejection_reason is distinct from old.rejection_reason
        or new.rating_average is distinct from old.rating_average
        or new.rating_count is distinct from old.rating_count then
        raise exception 'Managed seller fields cannot be changed by clients';
      end if;
    end if;
  end if;

  if new.kind = 'private' then
    new.status = 'approved';
    new.approved_at = coalesce(new.approved_at, now());
    new.rejection_reason = null;
  end if;

  return new;
end;
$$;

update public.sellers
set status = 'approved', approved_at = coalesce(approved_at, now()), rejection_reason = null
where kind = 'private' and status <> 'approved';

drop policy if exists sellers_insert_own_application on public.sellers;
create policy sellers_insert_own_application
  on public.sellers for insert to authenticated
  with check (
    public.is_admin()
    or (
      user_id = auth.uid()
      and (
        (kind = 'private' and status = 'approved')
        or (kind = 'business' and status = 'pending')
      )
    )
  );

create or replace function public.record_seller_status_history()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' and new.status is not distinct from old.status then
    return new;
  end if;

  insert into public.seller_status_history (
    seller_id,
    from_status,
    to_status,
    actor_user_id,
    reason
  )
  values (
    new.id,
    case when tg_op = 'UPDATE' then old.status else null end,
    new.status,
    auth.uid(),
    new.rejection_reason
  );

  return new;
end;
$$;

drop trigger if exists record_seller_status_history on public.sellers;
create trigger record_seller_status_history
  after insert or update of status on public.sellers
  for each row execute function public.record_seller_status_history();

create or replace function public.prepare_private_product_tax()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  seller_kind_value public.seller_kind;
begin
  select seller.kind
    into seller_kind_value
  from public.sellers as seller
  where seller.id = new.seller_id;

  if seller_kind_value = 'private' then
    new.vat_rate = 0;
  elsif auth.uid() is not null and not public.is_admin()
    and tg_op = 'UPDATE'
    and new.vat_rate is distinct from old.vat_rate then
    raise exception 'VAT rate is managed for business products';
  end if;

  return new;
end;
$$;

drop trigger if exists prepare_private_product_tax on public.products;
create trigger prepare_private_product_tax
  before insert or update of seller_id, vat_rate on public.products
  for each row execute function public.prepare_private_product_tax();

update public.products as product
set vat_rate = 0
from public.sellers as seller
where seller.id = product.seller_id
  and seller.kind = 'private'
  and product.vat_rate <> 0;

create or replace function public.protect_seller_document_write()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if auth.uid() is null or public.is_admin() then
    return new;
  end if;

  if tg_op = 'INSERT' then
    new.uploaded_by = auth.uid();
    new.status = 'pending';
    new.reviewed_by = null;
    new.reviewed_at = null;
    new.admin_note = null;
  elsif new.seller_id is distinct from old.seller_id
    or new.uploaded_by is distinct from old.uploaded_by
    or new.kind is distinct from old.kind
    or new.storage_path is distinct from old.storage_path
    or new.mime_type is distinct from old.mime_type
    or new.status is distinct from old.status
    or new.reviewed_by is distinct from old.reviewed_by
    or new.reviewed_at is distinct from old.reviewed_at
    or new.admin_note is distinct from old.admin_note then
    raise exception 'Seller document moderation fields are server-managed';
  end if;

  return new;
end;
$$;

drop trigger if exists protect_seller_document_write on public.seller_documents;
create trigger protect_seller_document_write
  before insert or update on public.seller_documents
  for each row execute function public.protect_seller_document_write();
drop trigger if exists set_updated_at on public.seller_documents;
create trigger set_updated_at
  before update on public.seller_documents
  for each row execute function public.set_updated_at();
drop trigger if exists set_updated_at on public.seller_payouts;
create trigger set_updated_at
  before update on public.seller_payouts
  for each row execute function public.set_updated_at();

create or replace function public.validate_message_context()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  chat_seller_id uuid;
  referenced_seller_id uuid;
begin
  if new.kind = 'product' then
    select chat.seller_id
      into chat_seller_id
    from public.chats as chat
    where chat.id = new.chat_id;

    select product.seller_id
      into referenced_seller_id
    from public.products as product
    where product.id = new.product_id;

    if chat_seller_id is null or referenced_seller_id is distinct from chat_seller_id then
      raise exception 'Message product must belong to chat seller';
    end if;
  end if;

  if new.kind = 'image'
    and new.media_path is not null
    and split_part(new.media_path, '/', 1) <> new.chat_id::text then
    raise exception 'Chat media must be stored under the chat folder';
  end if;

  return new;
end;
$$;

drop trigger if exists validate_message_context on public.messages;
create trigger validate_message_context
  before insert on public.messages
  for each row execute function public.validate_message_context();

create or replace function public.get_or_create_chat(
  p_seller_id uuid,
  p_product_id uuid default null,
  p_buyer_id uuid default null
)
returns public.chats
language plpgsql
security definer
set search_path = ''
as $$
declare
  resolved_buyer_id uuid := coalesce(p_buyer_id, auth.uid());
  chat_row public.chats%rowtype;
  seller_user_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select seller.user_id
    into seller_user_id
  from public.sellers as seller
  where seller.id = p_seller_id
    and seller.status = 'approved';

  if not found then
    raise exception 'Seller is not available' using errcode = 'P0002';
  end if;

  if resolved_buyer_id is null or resolved_buyer_id = seller_user_id then
    raise exception 'A chat needs two distinct participants' using errcode = '22023';
  end if;

  if not (resolved_buyer_id = auth.uid() or seller_user_id = auth.uid() or public.is_admin()) then
    raise exception 'Chat participant mismatch' using errcode = '42501';
  end if;

  if p_product_id is not null and not exists (
    select 1
    from public.products as product
    where product.id = p_product_id
      and product.seller_id = p_seller_id
      and product.status = 'active'
  ) then
    raise exception 'Product is not available for chat' using errcode = 'P0002';
  end if;

  if p_product_id is null then
    select chat.*
      into chat_row
    from public.chats as chat
    where chat.buyer_id = resolved_buyer_id
      and chat.seller_id = p_seller_id
      and chat.product_id is null
      and chat.closed_at is null
    limit 1;
  else
    select chat.*
      into chat_row
    from public.chats as chat
    where chat.buyer_id = resolved_buyer_id
      and chat.seller_id = p_seller_id
      and chat.product_id = p_product_id
      and chat.closed_at is null
    limit 1;
  end if;

  if found then
    return chat_row;
  end if;

  begin
    insert into public.chats (buyer_id, seller_id, product_id)
    values (resolved_buyer_id, p_seller_id, p_product_id)
    returning * into chat_row;
  exception when unique_violation then
    select chat.*
      into chat_row
    from public.chats as chat
    where chat.buyer_id = resolved_buyer_id
      and chat.seller_id = p_seller_id
      and chat.product_id is not distinct from p_product_id
      and chat.closed_at is null
    limit 1;
  end;

  return chat_row;
end;
$$;

create or replace function public.mark_chat_read(p_chat_id uuid)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  marked_count integer;
  chat_row public.chats%rowtype;
begin
  select chat.*
    into chat_row
  from public.chats as chat
  join public.sellers as seller on seller.id = chat.seller_id
  where chat.id = p_chat_id
    and (chat.buyer_id = auth.uid() or seller.user_id = auth.uid() or public.is_admin())
  for update of chat;

  if not found then
    raise exception 'Chat access denied' using errcode = '42501';
  end if;

  update public.messages
  set read_at = coalesce(read_at, now())
  where chat_id = p_chat_id
    and sender_id is distinct from auth.uid()
    and read_at is null;
  get diagnostics marked_count = row_count;

  update public.chats
  set
    buyer_last_read_at = case when chat_row.buyer_id = auth.uid() then now() else buyer_last_read_at end,
    seller_last_read_at = case
      when exists (
        select 1 from public.sellers as seller
        where seller.id = chat_row.seller_id and seller.user_id = auth.uid()
      ) then now()
      else seller_last_read_at
    end
  where id = p_chat_id;

  return marked_count;
end;
$$;

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
    and message.sender_id is distinct from auth.uid()
    and (chat.buyer_id = auth.uid() or seller.user_id = auth.uid());
$$;

create or replace function public.get_seller_dashboard_metrics(
  p_seller_id uuid,
  p_from timestamptz default (now() - interval '30 days'),
  p_to timestamptz default now()
)
returns table (
  orders_count bigint,
  items_count bigint,
  gross_sales_cents bigint,
  platform_fees_cents bigint,
  net_sales_cents bigint,
  pending_orders_count bigint,
  average_order_cents numeric
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not (public.owns_seller(p_seller_id) or public.is_admin()) then
    raise exception 'Seller dashboard access denied' using errcode = '42501';
  end if;

  if p_to < p_from then
    raise exception 'Dashboard end date must be after start date' using errcode = '22023';
  end if;

  return query
  with order_scope as (
    select
      marketplace_order.id,
      marketplace_order.status,
      marketplace_order.total_cents,
      marketplace_order.platform_fee_cents,
      coalesce(sum(order_item.quantity), 0)::bigint as item_quantity
    from public.orders as marketplace_order
    left join public.order_items as order_item
      on order_item.order_id = marketplace_order.id
    where marketplace_order.seller_id = p_seller_id
      and marketplace_order.created_at >= p_from
      and marketplace_order.created_at < p_to
    group by marketplace_order.id
  )
  select
    count(*),
    coalesce(sum(order_scope.item_quantity), 0)::bigint,
    coalesce(sum(order_scope.total_cents), 0)::bigint,
    coalesce(sum(order_scope.platform_fee_cents), 0)::bigint,
    coalesce(
      sum(order_scope.total_cents - order_scope.platform_fee_cents),
      0
    )::bigint,
    count(*) filter (
      where order_scope.status in ('pending_payment', 'paid', 'processing')
    ),
    coalesce(avg(order_scope.total_cents), 0)::numeric
  from order_scope;
end;
$$;

create or replace function public.owns_seller_path(target_seller_id text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.sellers as seller
    where seller.id::text = target_seller_id
      and seller.user_id = auth.uid()
  );
$$;

create or replace function public.can_manage_seller_document_path(target_storage_path text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    public.owns_seller_path((storage.foldername(target_storage_path))[1])
    and not exists (
      select 1
      from public.seller_documents as seller_document
      where seller_document.storage_path = target_storage_path
        and seller_document.status <> 'pending'
    );
$$;

create or replace function public.record_seller_ledger_entry()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (tg_op = 'INSERT' and new.payment_status = 'succeeded')
    or (
      tg_op = 'UPDATE'
      and old.payment_status is distinct from new.payment_status
      and new.payment_status = 'succeeded'
    ) then
    insert into public.seller_balance_transactions (
      seller_id,
      order_id,
      kind,
      source_key,
      amount_cents,
      currency,
      available_at,
      description
    )
    values (
      new.seller_id,
      new.id,
      'sale',
      'order-sale:' || new.id::text,
      new.total_cents - new.platform_fee_cents,
      new.currency,
      now() + interval '14 days',
      'Marketplace sale'
    )
    on conflict (source_key) do nothing;
  end if;

  if tg_op = 'UPDATE'
    and old.status is distinct from new.status
    and new.status = 'refunded' then
    insert into public.seller_balance_transactions (
      seller_id,
      order_id,
      kind,
      source_key,
      amount_cents,
      currency,
      description
    )
    values (
      new.seller_id,
      new.id,
      'refund',
      'order-refund:' || new.id::text,
      -new.total_cents,
      new.currency,
      'Marketplace refund'
    )
    on conflict (source_key) do nothing;
  end if;

  return new;
end;
$$;

drop trigger if exists record_seller_ledger_entry on public.orders;
create trigger record_seller_ledger_entry
  after insert or update of payment_status, status on public.orders
  for each row execute function public.record_seller_ledger_entry();

alter table public.seller_status_history enable row level security;
alter table public.seller_documents enable row level security;
alter table public.seller_payouts enable row level security;
alter table public.seller_balance_transactions enable row level security;

drop policy if exists seller_status_history_select_own on public.seller_status_history;
create policy seller_status_history_select_own
  on public.seller_status_history for select to authenticated
  using (public.owns_seller(seller_id) or public.is_admin());
drop policy if exists seller_status_history_manage_admin on public.seller_status_history;
create policy seller_status_history_manage_admin
  on public.seller_status_history for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists seller_documents_select_own on public.seller_documents;
create policy seller_documents_select_own
  on public.seller_documents for select to authenticated
  using (public.owns_seller(seller_id) or public.is_admin());
drop policy if exists seller_documents_insert_own on public.seller_documents;
create policy seller_documents_insert_own
  on public.seller_documents for insert to authenticated
  with check (public.owns_seller(seller_id) or public.is_admin());
drop policy if exists seller_documents_delete_pending_own on public.seller_documents;
create policy seller_documents_delete_pending_own
  on public.seller_documents for delete to authenticated
  using (
    public.is_admin()
    or (
      public.owns_seller(seller_id)
      and status = 'pending'
    )
  );
drop policy if exists seller_documents_manage_admin on public.seller_documents;
create policy seller_documents_manage_admin
  on public.seller_documents for update to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists seller_payouts_select_own on public.seller_payouts;
create policy seller_payouts_select_own
  on public.seller_payouts for select to authenticated
  using (public.owns_seller(seller_id) or public.is_admin());
drop policy if exists seller_payouts_manage_admin on public.seller_payouts;
create policy seller_payouts_manage_admin
  on public.seller_payouts for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists seller_balance_transactions_select_own on public.seller_balance_transactions;
create policy seller_balance_transactions_select_own
  on public.seller_balance_transactions for select to authenticated
  using (public.owns_seller(seller_id) or public.is_admin());
drop policy if exists seller_balance_transactions_manage_admin on public.seller_balance_transactions;
create policy seller_balance_transactions_manage_admin
  on public.seller_balance_transactions for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

grant select, insert, update, delete on table public.seller_status_history to authenticated;
grant select, insert, update, delete on table public.seller_documents to authenticated;
grant select, insert, update, delete on table public.seller_payouts to authenticated;
grant select, insert, update, delete on table public.seller_balance_transactions to authenticated;
grant all on table public.seller_status_history to service_role;
grant all on table public.seller_documents to service_role;
grant all on table public.seller_payouts to service_role;
grant all on table public.seller_balance_transactions to service_role;

revoke all on function public.get_or_create_chat(uuid, uuid, uuid) from public;
revoke all on function public.mark_chat_read(uuid) from public;
revoke all on function public.get_unread_chat_count() from public;
revoke all on function public.get_seller_dashboard_metrics(uuid, timestamptz, timestamptz)
  from public;
revoke all on function public.owns_seller_path(text) from public;
revoke all on function public.can_manage_seller_document_path(text) from public;
grant execute on function public.get_or_create_chat(uuid, uuid, uuid) to authenticated;
grant execute on function public.mark_chat_read(uuid) to authenticated;
grant execute on function public.get_unread_chat_count() to authenticated;
grant execute on function public.get_seller_dashboard_metrics(
  uuid, timestamptz, timestamptz
) to authenticated;
grant execute on function public.owns_seller_path(text) to authenticated;
grant execute on function public.can_manage_seller_document_path(text) to authenticated;

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'seller-documents',
  'seller-documents',
  false,
  15728640,
  array['application/pdf', 'image/webp', 'image/jpeg', 'image/png']::text[]
)
on conflict (id) do update set
  name = excluded.name,
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists seller_documents_storage_select on storage.objects;
create policy seller_documents_storage_select
  on storage.objects for select to authenticated
  using (
    bucket_id = 'seller-documents'
    and (
      public.owns_seller_path((storage.foldername(name))[1])
      or public.is_admin()
    )
  );
drop policy if exists seller_documents_storage_insert on storage.objects;
create policy seller_documents_storage_insert
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'seller-documents'
    and array_length(storage.foldername(name), 1) >= 2
    and (
      public.owns_seller_path((storage.foldername(name))[1])
      or public.is_admin()
    )
  );
drop policy if exists seller_documents_storage_update on storage.objects;
create policy seller_documents_storage_update
  on storage.objects for update to authenticated
  using (
    bucket_id = 'seller-documents'
    and (
      public.can_manage_seller_document_path(name)
      or public.is_admin()
    )
  )
  with check (
    bucket_id = 'seller-documents'
    and (
      public.can_manage_seller_document_path(name)
      or public.is_admin()
    )
  );
drop policy if exists seller_documents_storage_delete on storage.objects;
create policy seller_documents_storage_delete
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'seller-documents'
    and (
      public.can_manage_seller_document_path(name)
      or public.is_admin()
    )
  );

do $$
declare
  realtime_table text;
begin
  if exists (
    select 1 from pg_catalog.pg_publication where pubname = 'supabase_realtime'
  ) then
    foreach realtime_table in array array[
      'chats',
      'messages',
      'notifications',
      'orders',
      'order_status_history',
      'return_requests',
      'seller_payouts'
    ] loop
      if not exists (
        select 1
        from pg_catalog.pg_publication_tables
        where pubname = 'supabase_realtime'
          and schemaname = 'public'
          and tablename = realtime_table
      ) then
        execute format(
          'alter publication supabase_realtime add table public.%I',
          realtime_table
        );
      end if;
    end loop;
  end if;
end;
$$;

alter table public.chats replica identity full;
alter table public.messages replica identity full;
alter table public.notifications replica identity full;
alter table public.orders replica identity full;
alter table public.order_status_history replica identity full;
alter table public.return_requests replica identity full;

commit;
