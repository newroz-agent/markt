-- Phase 3: transactional checkout, payment allocation, order history,
-- shipping methods, invoices, and the German withdrawal/return workflow.

begin;

create type public.checkout_status as enum (
  'open',
  'processing',
  'completed',
  'expired',
  'cancelled',
  'failed'
);
create type public.inventory_reservation_status as enum (
  'active',
  'consumed',
  'released',
  'expired'
);
create type public.return_request_status as enum (
  'requested',
  'approved',
  'rejected',
  'label_issued',
  'in_transit',
  'received',
  'refunded',
  'cancelled'
);
create type public.invoice_status as enum ('pending', 'ready', 'failed');

alter table public.sellers
  add column accepts_returns boolean not null default true,
  add column return_window_days smallint not null default 14
    check (return_window_days between 0 and 90),
  add constraint sellers_business_return_requirement
    check (kind <> 'business' or accepts_returns);

create table public.shipping_methods (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.sellers (id) on delete cascade,
  name_i18n jsonb not null,
  description_i18n jsonb not null default '{}'::jsonb,
  price_cents bigint not null default 0 check (price_cents >= 0),
  free_from_cents bigint check (free_from_cents is null or free_from_cents >= 0),
  estimated_days_min smallint not null check (estimated_days_min between 0 and 90),
  estimated_days_max smallint not null check (estimated_days_max between 0 and 90),
  is_pickup boolean not null default false,
  supports_tracking boolean not null default true,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint shipping_methods_name_object check (jsonb_typeof(name_i18n) = 'object'),
  constraint shipping_methods_description_object
    check (jsonb_typeof(description_i18n) = 'object'),
  constraint shipping_methods_delivery_range
    check (estimated_days_max >= estimated_days_min),
  constraint shipping_methods_pickup_cost
    check (not is_pickup or price_cents = 0)
);

create index shipping_methods_seller_active_idx
  on public.shipping_methods (seller_id, is_active, created_at);

create table public.product_shipping_methods (
  product_id uuid not null references public.products (id) on delete cascade,
  shipping_method_id uuid not null references public.shipping_methods (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (product_id, shipping_method_id)
);

create index product_shipping_methods_method_idx
  on public.product_shipping_methods (shipping_method_id, product_id);

create table public.checkout_sessions (
  id uuid primary key default gen_random_uuid(),
  buyer_id uuid references auth.users (id) on delete set null,
  cart_id uuid references public.carts (id) on delete set null,
  status public.checkout_status not null default 'open',
  idempotency_key text not null check (char_length(idempotency_key) between 8 and 200),
  currency text not null default 'EUR' check (currency ~ '^[A-Z]{3}$'),
  subtotal_cents bigint not null default 0 check (subtotal_cents >= 0),
  shipping_cents bigint not null default 0 check (shipping_cents >= 0),
  discount_cents bigint not null default 0 check (discount_cents >= 0),
  vat_cents bigint not null default 0 check (vat_cents >= 0),
  total_cents bigint not null default 0 check (total_cents >= 0),
  shipping_address jsonb not null,
  billing_address jsonb,
  stripe_payment_intent_id text unique,
  expires_at timestamptz not null default (now() + interval '30 minutes'),
  completed_at timestamptz,
  failure_code text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (buyer_id, idempotency_key),
  constraint checkout_shipping_address_object
    check (jsonb_typeof(shipping_address) = 'object'),
  constraint checkout_billing_address_object
    check (billing_address is null or jsonb_typeof(billing_address) = 'object'),
  constraint checkout_total_calculation check (
    total_cents = subtotal_cents + shipping_cents - discount_cents
  ),
  constraint checkout_vat_is_included check (vat_cents <= total_cents),
  constraint checkout_expiration_after_creation check (expires_at > created_at)
);

create index checkout_sessions_buyer_created_idx
  on public.checkout_sessions (buyer_id, created_at desc);
create index checkout_sessions_expiry_idx
  on public.checkout_sessions (expires_at)
  where status in ('open', 'processing');

create table public.checkout_session_orders (
  checkout_session_id uuid not null
    references public.checkout_sessions (id) on delete cascade,
  order_id uuid not null references public.orders (id) on delete restrict,
  created_at timestamptz not null default now(),
  primary key (checkout_session_id, order_id),
  unique (order_id)
);

create table public.inventory_reservations (
  id uuid primary key default gen_random_uuid(),
  checkout_session_id uuid not null
    references public.checkout_sessions (id) on delete cascade,
  product_id uuid not null references public.products (id) on delete restrict,
  quantity integer not null check (quantity > 0),
  unit_price_cents bigint not null check (unit_price_cents >= 0),
  status public.inventory_reservation_status not null default 'active',
  expires_at timestamptz not null,
  released_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (checkout_session_id, product_id),
  constraint inventory_reservation_expiry check (expires_at > created_at)
);

create index inventory_reservations_active_expiry_idx
  on public.inventory_reservations (expires_at, checkout_session_id)
  where status = 'active';
create index inventory_reservations_product_idx
  on public.inventory_reservations (product_id, status);

alter table public.payments
  alter column order_id drop not null,
  add column checkout_session_id uuid
    references public.checkout_sessions (id) on delete restrict,
  add constraint payments_exactly_one_target
    check (num_nonnulls(order_id, checkout_session_id) = 1);

create index payments_checkout_session_idx
  on public.payments (checkout_session_id);

create table public.payment_order_allocations (
  payment_id uuid not null references public.payments (id) on delete cascade,
  order_id uuid not null references public.orders (id) on delete restrict,
  amount_cents bigint not null check (amount_cents >= 0),
  created_at timestamptz not null default now(),
  primary key (payment_id, order_id)
);

create index payment_order_allocations_order_idx
  on public.payment_order_allocations (order_id, payment_id);

create table public.payment_provider_events (
  provider_event_id text primary key,
  event_type text not null,
  checkout_session_id uuid
    references public.checkout_sessions (id) on delete set null,
  payment_intent_id text,
  payload jsonb not null default '{}'::jsonb,
  processed_at timestamptz,
  processing_error text,
  created_at timestamptz not null default now(),
  constraint payment_provider_events_payload_object
    check (jsonb_typeof(payload) = 'object')
);

create index payment_provider_events_unprocessed_idx
  on public.payment_provider_events (created_at)
  where processed_at is null;

create table public.order_status_history (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  from_status public.order_status,
  to_status public.order_status not null,
  actor_user_id uuid references auth.users (id) on delete set null,
  actor_role text not null default 'system',
  note text check (note is null or char_length(note) <= 1000),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint order_status_history_metadata_object
    check (jsonb_typeof(metadata) = 'object')
);

create index order_status_history_order_created_idx
  on public.order_status_history (order_id, created_at, id);

create table public.return_requests (
  id uuid primary key default gen_random_uuid(),
  order_item_id uuid not null unique
    references public.order_items (id) on delete restrict,
  buyer_id uuid references auth.users (id) on delete set null,
  seller_id uuid not null references public.sellers (id) on delete restrict,
  status public.return_request_status not null default 'requested',
  reason text not null check (char_length(reason) between 2 and 80),
  details text check (details is null or char_length(details) <= 3000),
  evidence_paths text[] not null default '{}'::text[],
  decision_note text check (decision_note is null or char_length(decision_note) <= 2000),
  return_carrier text,
  return_tracking_number text,
  refund_amount_cents bigint check (refund_amount_cents is null or refund_amount_cents >= 0),
  requested_at timestamptz not null default now(),
  decided_at timestamptz,
  received_at timestamptz,
  refunded_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index return_requests_buyer_created_idx
  on public.return_requests (buyer_id, created_at desc);
create index return_requests_seller_status_idx
  on public.return_requests (seller_id, status, created_at);

create table public.invoices (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null unique references public.orders (id) on delete restrict,
  invoice_number text not null unique,
  status public.invoice_status not null default 'pending',
  storage_path text unique,
  issuer_snapshot jsonb not null,
  recipient_snapshot jsonb not null,
  subtotal_cents bigint not null check (subtotal_cents >= 0),
  shipping_cents bigint not null default 0 check (shipping_cents >= 0),
  vat_cents bigint not null default 0 check (vat_cents >= 0),
  total_cents bigint not null check (total_cents >= 0),
  currency text not null default 'EUR' check (currency ~ '^[A-Z]{3}$'),
  issued_at timestamptz,
  failure_message text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint invoices_issuer_snapshot_object
    check (jsonb_typeof(issuer_snapshot) = 'object'),
  constraint invoices_recipient_snapshot_object
    check (jsonb_typeof(recipient_snapshot) = 'object'),
  constraint invoices_total_calculation
    check (total_cents = subtotal_cents + shipping_cents),
  constraint invoices_vat_is_included check (vat_cents <= total_cents),
  constraint invoices_ready_has_file check (
    status <> 'ready' or (storage_path is not null and issued_at is not null)
  )
);

create index invoices_status_created_idx on public.invoices (status, created_at);

create function public.owns_checkout(target_checkout_session_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.checkout_sessions as checkout_session
    where checkout_session.id = target_checkout_session_id
      and checkout_session.buyer_id = auth.uid()
  );
$$;

create function public.can_access_return_request(target_return_request_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.return_requests as return_request
    where return_request.id = target_return_request_id
      and (
        return_request.buyer_id = auth.uid()
        or public.owns_seller(return_request.seller_id)
      )
  );
$$;

create function public.can_access_return_request_path(target_return_request_id text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.return_requests as return_request
    where return_request.id::text = target_return_request_id
      and (
        return_request.buyer_id = auth.uid()
        or public.owns_seller(return_request.seller_id)
      )
  );
$$;

create function public.can_access_invoice_path(target_storage_path text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.invoices as invoice
    where invoice.storage_path = target_storage_path
      and public.can_access_order(invoice.order_id)
  );
$$;

create function public.validate_product_shipping_method()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  product_seller_id uuid;
  method_seller_id uuid;
begin
  select product.seller_id
    into product_seller_id
  from public.products as product
  where product.id = new.product_id;

  select shipping_method.seller_id
    into method_seller_id
  from public.shipping_methods as shipping_method
  where shipping_method.id = new.shipping_method_id;

  if product_seller_id is distinct from method_seller_id then
    raise exception 'Product and shipping method must belong to the same seller';
  end if;

  return new;
end;
$$;

create trigger validate_product_shipping_method
  before insert or update on public.product_shipping_methods
  for each row execute function public.validate_product_shipping_method();

create trigger set_updated_at
  before update on public.shipping_methods
  for each row execute function public.set_updated_at();
create trigger set_updated_at
  before update on public.checkout_sessions
  for each row execute function public.set_updated_at();
create trigger set_updated_at
  before update on public.inventory_reservations
  for each row execute function public.set_updated_at();
create trigger set_updated_at
  before update on public.return_requests
  for each row execute function public.set_updated_at();
create trigger set_updated_at
  before update on public.invoices
  for each row execute function public.set_updated_at();

create function public.prepare_order_lifecycle()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  return_days smallint;
begin
  if tg_op = 'INSERT' then
    if new.status = 'pending_payment' then
      new.placed_at = coalesce(new.placed_at, now());
    end if;
    return new;
  end if;

  if new.status is not distinct from old.status then
    return new;
  end if;

  case new.status
    when 'paid' then
      new.paid_at = coalesce(new.paid_at, now());
    when 'shipped' then
      new.shipped_at = coalesce(new.shipped_at, now());
    when 'delivered' then
      new.delivered_at = coalesce(new.delivered_at, now());

      select case when seller.accepts_returns then seller.return_window_days else 0 end
        into return_days
      from public.sellers as seller
      where seller.id = new.seller_id;

      if coalesce(return_days, 0) > 0 then
        new.withdrawal_deadline = new.delivered_at
          + pg_catalog.make_interval(days => return_days);
      else
        new.withdrawal_deadline = null;
      end if;
    when 'cancelled' then
      new.cancelled_at = coalesce(new.cancelled_at, now());
    else
      null;
  end case;

  return new;
end;
$$;

create trigger prepare_order_lifecycle
  before insert or update of status on public.orders
  for each row execute function public.prepare_order_lifecycle();

create function public.record_order_status_history()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  resolved_actor_role text;
begin
  if tg_op = 'UPDATE' and new.status is not distinct from old.status then
    return new;
  end if;

  resolved_actor_role := case
    when public.is_admin() then 'admin'
    when auth.role() = 'service_role' then 'service_role'
    when auth.uid() is null then 'system'
    when new.buyer_id = auth.uid() then 'buyer'
    when public.owns_seller(new.seller_id) then 'seller'
    else 'authenticated'
  end;

  insert into public.order_status_history (
    order_id,
    from_status,
    to_status,
    actor_user_id,
    actor_role
  )
  values (
    new.id,
    case when tg_op = 'UPDATE' then old.status else null end,
    new.status,
    auth.uid(),
    resolved_actor_role
  );

  return new;
end;
$$;

create trigger record_order_status_history
  after insert or update of status on public.orders
  for each row execute function public.record_order_status_history();

-- Service-role only. The Edge Function verifies the caller and supplies the
-- immutable address snapshots and idempotency key.
create function public.create_marketplace_checkout(
  p_buyer_id uuid,
  p_cart_id uuid,
  p_shipping_address jsonb,
  p_billing_address jsonb default null,
  p_shipping_method_ids jsonb default '{}'::jsonb,
  p_idempotency_key text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  checkout_id uuid;
  checkout_expiry timestamptz := now() + interval '30 minutes';
  normalized_idempotency_key text := nullif(pg_catalog.btrim(p_idempotency_key), '');
  seller_row record;
  order_id uuid;
  selected_method_id uuid;
  selected_method public.shipping_methods%rowtype;
  seller_shipping_cents bigint;
  seller_shipping_vat_cents bigint;
  shipping_snapshot jsonb;
  checkout_subtotal_cents bigint := 0;
  checkout_shipping_cents bigint := 0;
  checkout_vat_cents bigint := 0;
begin
  if p_buyer_id is null then
    raise exception 'Buyer is required' using errcode = '22023';
  end if;

  if jsonb_typeof(p_shipping_address) <> 'object' then
    raise exception 'Shipping address must be an object' using errcode = '22023';
  end if;

  if p_billing_address is not null and jsonb_typeof(p_billing_address) <> 'object' then
    raise exception 'Billing address must be an object' using errcode = '22023';
  end if;

  if jsonb_typeof(coalesce(p_shipping_method_ids, '{}'::jsonb)) <> 'object' then
    raise exception 'Shipping method selection must be an object'
      using errcode = '22023';
  end if;

  if normalized_idempotency_key is null then
    normalized_idempotency_key := extensions.gen_random_uuid()::text;
  end if;

  select existing.id
    into checkout_id
  from public.checkout_sessions as existing
  where existing.buyer_id = p_buyer_id
    and existing.idempotency_key = normalized_idempotency_key;

  if checkout_id is not null then
    return checkout_id;
  end if;

  perform 1
  from public.carts as cart
  where cart.id = p_cart_id
    and cart.user_id = p_buyer_id
    and cart.status = 'active'
  for update;

  if not found then
    raise exception 'Active cart does not belong to buyer' using errcode = 'P0002';
  end if;

  if not exists (
    select 1
    from public.cart_items as cart_item
    where cart_item.cart_id = p_cart_id
      and not cart_item.saved_for_later
  ) then
    raise exception 'Cart has no checkout items' using errcode = '22023';
  end if;

  perform product.id
  from public.products as product
  join public.cart_items as cart_item on cart_item.product_id = product.id
  where cart_item.cart_id = p_cart_id
    and not cart_item.saved_for_later
  order by product.id
  for update of product;

  if exists (
    select 1
    from public.cart_items as cart_item
    join public.products as product on product.id = cart_item.product_id
    join public.sellers as seller on seller.id = product.seller_id
    where cart_item.cart_id = p_cart_id
      and not cart_item.saved_for_later
      and (
        product.status <> 'active'
        or seller.status <> 'approved'
        or product.quantity < cart_item.quantity
      )
  ) then
    raise exception 'One or more cart items are unavailable'
      using errcode = 'P0001';
  end if;

  insert into public.checkout_sessions (
    buyer_id,
    cart_id,
    idempotency_key,
    shipping_address,
    billing_address,
    expires_at
  )
  values (
    p_buyer_id,
    p_cart_id,
    normalized_idempotency_key,
    p_shipping_address,
    p_billing_address,
    checkout_expiry
  )
  returning id into checkout_id;

  insert into public.inventory_reservations (
    checkout_session_id,
    product_id,
    quantity,
    unit_price_cents,
    expires_at
  )
  select
    checkout_id,
    product.id,
    cart_item.quantity,
    product.price_cents,
    checkout_expiry
  from public.cart_items as cart_item
  join public.products as product on product.id = cart_item.product_id
  where cart_item.cart_id = p_cart_id
    and not cart_item.saved_for_later;

  update public.products as product
  set quantity = product.quantity - reservation.quantity
  from public.inventory_reservations as reservation
  where reservation.checkout_session_id = checkout_id
    and reservation.product_id = product.id;

  for seller_row in
    select
      seller.id as seller_id,
      seller.kind as seller_kind,
      sum(product.price_cents * cart_item.quantity)::bigint as subtotal_cents,
      sum(
        pg_catalog.round(
          (product.price_cents * cart_item.quantity)::numeric
          - (product.price_cents * cart_item.quantity)::numeric
            / (1 + product.vat_rate / 100)
        )
      )::bigint as product_vat_cents
    from public.cart_items as cart_item
    join public.products as product on product.id = cart_item.product_id
    join public.sellers as seller on seller.id = product.seller_id
    where cart_item.cart_id = p_cart_id
      and not cart_item.saved_for_later
    group by seller.id, seller.kind
    order by seller.id
  loop
    selected_method_id := null;
    if coalesce(p_shipping_method_ids, '{}'::jsonb) ? seller_row.seller_id::text then
      begin
        selected_method_id := nullif(
          p_shipping_method_ids ->> seller_row.seller_id::text,
          ''
        )::uuid;
      exception when invalid_text_representation then
        raise exception 'Invalid shipping method identifier for seller %',
          seller_row.seller_id using errcode = '22023';
      end;
    end if;

    if selected_method_id is not null then
      select shipping_method.*
        into selected_method
      from public.shipping_methods as shipping_method
      where shipping_method.id = selected_method_id
        and shipping_method.seller_id = seller_row.seller_id
        and shipping_method.is_active;

      if not found then
        raise exception 'Shipping method is not available for seller %',
          seller_row.seller_id using errcode = 'P0002';
      end if;

      if exists (
        select 1
        from public.cart_items as cart_item
        join public.products as product on product.id = cart_item.product_id
        where cart_item.cart_id = p_cart_id
          and not cart_item.saved_for_later
          and product.seller_id = seller_row.seller_id
          and exists (
            select 1
            from public.product_shipping_methods as any_mapping
            where any_mapping.product_id = product.id
          )
          and not exists (
            select 1
            from public.product_shipping_methods as allowed_mapping
            where allowed_mapping.product_id = product.id
              and allowed_mapping.shipping_method_id = selected_method_id
          )
      ) then
        raise exception 'Shipping method does not support every product'
          using errcode = '22023';
      end if;

      seller_shipping_cents := case
        when selected_method.free_from_cents is not null
          and seller_row.subtotal_cents >= selected_method.free_from_cents then 0
        else selected_method.price_cents
      end;

      shipping_snapshot := jsonb_build_object(
        'id', selected_method.id,
        'name', selected_method.name_i18n,
        'priceCents', seller_shipping_cents,
        'estimatedDaysMin', selected_method.estimated_days_min,
        'estimatedDaysMax', selected_method.estimated_days_max,
        'isPickup', selected_method.is_pickup,
        'supportsTracking', selected_method.supports_tracking
      );
    else
      select coalesce(sum(
        case when product.free_shipping then 0 else product.shipping_cost_cents end
      ), 0)::bigint
        into seller_shipping_cents
      from public.cart_items as cart_item
      join public.products as product on product.id = cart_item.product_id
      where cart_item.cart_id = p_cart_id
        and not cart_item.saved_for_later
        and product.seller_id = seller_row.seller_id;

      shipping_snapshot := jsonb_build_object(
        'id', null,
        'name', jsonb_build_object('de', 'Standardversand'),
        'priceCents', seller_shipping_cents,
        'source', 'product'
      );
    end if;

    seller_shipping_vat_cents := case
      when seller_row.seller_kind = 'business' and seller_shipping_cents > 0 then
        pg_catalog.round(
          seller_shipping_cents::numeric
          - seller_shipping_cents::numeric / 1.19
        )::bigint
      else 0
    end;

    insert into public.orders (
      buyer_id,
      seller_id,
      status,
      payment_status,
      subtotal_cents,
      shipping_cents,
      discount_cents,
      vat_cents,
      total_cents,
      shipping_address,
      billing_address,
      shipping_method,
      placed_at
    )
    values (
      p_buyer_id,
      seller_row.seller_id,
      'pending_payment',
      'pending',
      seller_row.subtotal_cents,
      seller_shipping_cents,
      0,
      seller_row.product_vat_cents + seller_shipping_vat_cents,
      seller_row.subtotal_cents + seller_shipping_cents,
      p_shipping_address,
      p_billing_address,
      shipping_snapshot,
      now()
    )
    returning id into order_id;

    insert into public.checkout_session_orders (checkout_session_id, order_id)
    values (checkout_id, order_id);

    insert into public.order_items (
      order_id,
      product_id,
      seller_id,
      product_title,
      product_sku,
      product_image_url,
      condition,
      quantity,
      unit_price_cents,
      vat_rate,
      vat_cents,
      total_cents
    )
    select
      order_id,
      product.id,
      product.seller_id,
      product.title,
      product.sku,
      primary_image.storage_path,
      product.condition,
      cart_item.quantity,
      product.price_cents,
      product.vat_rate,
      pg_catalog.round(
        (product.price_cents * cart_item.quantity)::numeric
        - (product.price_cents * cart_item.quantity)::numeric
          / (1 + product.vat_rate / 100)
      )::bigint,
      product.price_cents * cart_item.quantity
    from public.cart_items as cart_item
    join public.products as product on product.id = cart_item.product_id
    left join lateral (
      select image.storage_path
      from public.product_images as image
      where image.product_id = product.id
      order by image.sort_order, image.created_at, image.id
      limit 1
    ) as primary_image on true
    where cart_item.cart_id = p_cart_id
      and not cart_item.saved_for_later
      and product.seller_id = seller_row.seller_id;

    checkout_subtotal_cents := checkout_subtotal_cents + seller_row.subtotal_cents;
    checkout_shipping_cents := checkout_shipping_cents + seller_shipping_cents;
    checkout_vat_cents := checkout_vat_cents
      + seller_row.product_vat_cents
      + seller_shipping_vat_cents;
  end loop;

  update public.checkout_sessions
  set
    subtotal_cents = checkout_subtotal_cents,
    shipping_cents = checkout_shipping_cents,
    vat_cents = checkout_vat_cents,
    total_cents = checkout_subtotal_cents + checkout_shipping_cents
  where id = checkout_id;

  return checkout_id;
end;
$$;

create function public.release_checkout_inventory(
  p_checkout_session_id uuid,
  p_checkout_status public.checkout_status default 'cancelled',
  p_reason text default null
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_status public.checkout_status;
begin
  if p_checkout_status not in ('expired', 'cancelled', 'failed') then
    raise exception 'Invalid release status' using errcode = '22023';
  end if;

  select checkout_session.status
    into current_status
  from public.checkout_sessions as checkout_session
  where checkout_session.id = p_checkout_session_id
  for update;

  if not found then
    raise exception 'Checkout session not found' using errcode = 'P0002';
  end if;

  if current_status in ('completed', 'expired', 'cancelled', 'failed') then
    return false;
  end if;

  update public.products as product
  set
    quantity = product.quantity + reservation.quantity,
    status = case
      when product.status = 'sold' then 'active'::public.product_status
      else product.status
    end
  from public.inventory_reservations as reservation
  where reservation.checkout_session_id = p_checkout_session_id
    and reservation.status = 'active'
    and reservation.product_id = product.id;

  update public.inventory_reservations
  set
    status = case
      when p_checkout_status = 'expired' then 'expired'::public.inventory_reservation_status
      else 'released'::public.inventory_reservation_status
    end,
    released_reason = p_reason
  where checkout_session_id = p_checkout_session_id
    and status = 'active';

  update public.orders as marketplace_order
  set
    status = 'cancelled',
    payment_status = case
      when p_checkout_status = 'failed' then 'failed'::public.payment_status
      else 'cancelled'::public.payment_status
    end
  from public.checkout_session_orders as checkout_order
  where checkout_order.checkout_session_id = p_checkout_session_id
    and checkout_order.order_id = marketplace_order.id
    and marketplace_order.status = 'pending_payment';

  update public.checkout_sessions
  set
    status = p_checkout_status,
    failure_code = p_reason
  where id = p_checkout_session_id;

  return true;
end;
$$;

create function public.release_expired_checkouts(p_limit integer default 100)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  checkout_row record;
  released_count integer := 0;
begin
  for checkout_row in
    select checkout_session.id
    from public.checkout_sessions as checkout_session
    where checkout_session.status in ('open', 'processing')
      and checkout_session.expires_at <= now()
    order by checkout_session.expires_at
    limit least(greatest(coalesce(p_limit, 100), 1), 1000)
    for update skip locked
  loop
    if public.release_checkout_inventory(
      checkout_row.id,
      'expired',
      'checkout_expired'
    ) then
      released_count := released_count + 1;
    end if;
  end loop;

  return released_count;
end;
$$;

create function public.apply_payment_event(
  p_provider_event_id text,
  p_event_type text,
  p_checkout_session_id uuid,
  p_payment_intent_id text,
  p_method public.payment_method,
  p_status public.payment_status,
  p_payload jsonb default '{}'::jsonb
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  checkout_row public.checkout_sessions%rowtype;
  payment_id uuid;
begin
  if nullif(pg_catalog.btrim(p_provider_event_id), '') is null
    or nullif(pg_catalog.btrim(p_event_type), '') is null
    or nullif(pg_catalog.btrim(p_payment_intent_id), '') is null then
    raise exception 'Provider event, type, and payment intent are required'
      using errcode = '22023';
  end if;

  if jsonb_typeof(coalesce(p_payload, '{}'::jsonb)) <> 'object' then
    raise exception 'Payment payload must be an object' using errcode = '22023';
  end if;

  insert into public.payment_provider_events (
    provider_event_id,
    event_type,
    checkout_session_id,
    payment_intent_id,
    payload
  )
  values (
    p_provider_event_id,
    p_event_type,
    p_checkout_session_id,
    p_payment_intent_id,
    coalesce(p_payload, '{}'::jsonb)
  )
  on conflict (provider_event_id) do nothing;

  if not found then
    return false;
  end if;

  select checkout_session.*
    into checkout_row
  from public.checkout_sessions as checkout_session
  where checkout_session.id = p_checkout_session_id
  for update;

  if not found then
    raise exception 'Checkout session not found' using errcode = 'P0002';
  end if;

  if checkout_row.status = 'completed' and p_status <> 'succeeded' then
    update public.payment_provider_events
    set
      processed_at = now(),
      processing_error = 'Ignored non-success event after completed checkout'
    where provider_event_id = p_provider_event_id;
    return false;
  end if;

  if checkout_row.status in ('expired', 'cancelled', 'failed')
    and p_status = 'succeeded' then
    update public.payment_provider_events
    set
      processed_at = now(),
      processing_error = 'Payment succeeded after inventory was released; manual review required'
    where provider_event_id = p_provider_event_id;
    return false;
  end if;

  if checkout_row.stripe_payment_intent_id is not null
    and checkout_row.stripe_payment_intent_id <> p_payment_intent_id then
    raise exception 'Payment intent does not match checkout session'
      using errcode = '23514';
  end if;

  update public.checkout_sessions
  set stripe_payment_intent_id = p_payment_intent_id
  where id = p_checkout_session_id;

  insert into public.payments (
    order_id,
    checkout_session_id,
    stripe_payment_intent_id,
    method,
    status,
    amount_cents,
    currency,
    provider_payload
  )
  values (
    null,
    p_checkout_session_id,
    p_payment_intent_id,
    coalesce(p_method, 'unknown'),
    p_status,
    checkout_row.total_cents,
    checkout_row.currency,
    coalesce(p_payload, '{}'::jsonb)
  )
  on conflict (stripe_payment_intent_id) do update set
    method = excluded.method,
    status = excluded.status,
    provider_payload = excluded.provider_payload,
    updated_at = now()
  returning id into payment_id;

  if not exists (
    select 1
    from public.payments as payment
    where payment.id = payment_id
      and payment.checkout_session_id = p_checkout_session_id
  ) then
    raise exception 'Payment intent is already assigned to another checkout'
      using errcode = '23505';
  end if;

  insert into public.payment_order_allocations (payment_id, order_id, amount_cents)
  select payment_id, marketplace_order.id, marketplace_order.total_cents
  from public.checkout_session_orders as checkout_order
  join public.orders as marketplace_order on marketplace_order.id = checkout_order.order_id
  where checkout_order.checkout_session_id = p_checkout_session_id
  on conflict (payment_id, order_id) do update set
    amount_cents = excluded.amount_cents;

  if p_status = 'succeeded' then
    if checkout_row.status <> 'completed' then
      update public.inventory_reservations
      set status = 'consumed'
      where checkout_session_id = p_checkout_session_id
        and status = 'active';

      update public.products as product
      set status = 'sold'
      where product.quantity = 0
        and exists (
          select 1
          from public.inventory_reservations as reservation
          where reservation.checkout_session_id = p_checkout_session_id
            and reservation.product_id = product.id
        );

      update public.orders as marketplace_order
      set
        status = 'paid',
        payment_status = 'succeeded',
        paid_at = coalesce(marketplace_order.paid_at, now())
      from public.checkout_session_orders as checkout_order
      where checkout_order.checkout_session_id = p_checkout_session_id
        and checkout_order.order_id = marketplace_order.id
        and marketplace_order.status = 'pending_payment';

      update public.carts
      set status = 'converted'
      where id = checkout_row.cart_id
        and status = 'active';

      update public.checkout_sessions
      set
        status = 'completed',
        completed_at = coalesce(completed_at, now()),
        failure_code = null
      where id = p_checkout_session_id;
    end if;
  elsif p_status in ('failed', 'cancelled') then
    perform public.release_checkout_inventory(
      p_checkout_session_id,
      case
        when p_status = 'failed' then 'failed'::public.checkout_status
        else 'cancelled'::public.checkout_status
      end,
      p_event_type
    );
  elsif p_status = 'processing' then
    update public.checkout_sessions set status = 'processing'
    where id = p_checkout_session_id and status = 'open';

    update public.orders as marketplace_order
    set payment_status = 'processing'
    from public.checkout_session_orders as checkout_order
    where checkout_order.checkout_session_id = p_checkout_session_id
      and checkout_order.order_id = marketplace_order.id
      and marketplace_order.status = 'pending_payment';
  elsif p_status = 'requires_action' then
    update public.orders as marketplace_order
    set payment_status = 'requires_action'
    from public.checkout_session_orders as checkout_order
    where checkout_order.checkout_session_id = p_checkout_session_id
      and checkout_order.order_id = marketplace_order.id
      and marketplace_order.status = 'pending_payment';
  end if;

  update public.payment_provider_events
  set processed_at = now(), processing_error = null
  where provider_event_id = p_provider_event_id;

  return true;
end;
$$;

create function public.transition_order_status(
  p_order_id uuid,
  p_target_status public.order_status,
  p_tracking_carrier text default null,
  p_tracking_number text default null,
  p_note text default null
)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $$
declare
  order_row public.orders%rowtype;
  caller_is_buyer boolean;
  caller_is_seller boolean;
  caller_is_admin boolean := public.is_admin();
begin
  select marketplace_order.*
    into order_row
  from public.orders as marketplace_order
  where marketplace_order.id = p_order_id
  for update;

  if not found then
    raise exception 'Order not found' using errcode = 'P0002';
  end if;

  caller_is_buyer := order_row.buyer_id = auth.uid();
  caller_is_seller := public.owns_seller(order_row.seller_id);

  if not caller_is_admin then
    if caller_is_buyer then
      if not (order_row.status = 'pending_payment' and p_target_status = 'cancelled') then
        raise exception 'Buyer cannot perform this order transition'
          using errcode = '42501';
      end if;
    elsif caller_is_seller then
      if not (
        (order_row.status = 'paid' and p_target_status = 'processing')
        or (order_row.status in ('paid', 'processing') and p_target_status = 'shipped')
      ) then
        raise exception 'Seller cannot perform this order transition'
          using errcode = '42501';
      end if;
    else
      raise exception 'Order access denied' using errcode = '42501';
    end if;
  end if;

  if p_target_status = 'shipped' then
    if nullif(pg_catalog.btrim(p_tracking_number), '') is null then
      raise exception 'Tracking number is required for shipment'
        using errcode = '22023';
    end if;

    update public.order_items
    set
      status = 'shipped',
      tracking_carrier = nullif(pg_catalog.btrim(p_tracking_carrier), ''),
      tracking_number = pg_catalog.btrim(p_tracking_number)
    where order_id = p_order_id
      and status in ('ordered', 'processing');
  elsif p_target_status = 'processing' then
    update public.order_items
    set status = 'processing'
    where order_id = p_order_id and status = 'ordered';
  elsif p_target_status = 'cancelled' then
    update public.order_items
    set status = 'cancelled'
    where order_id = p_order_id
      and status in ('ordered', 'processing');
  end if;

  update public.orders
  set status = p_target_status
  where id = p_order_id
  returning * into order_row;

  if nullif(pg_catalog.btrim(p_note), '') is not null then
    update public.order_status_history
    set note = left(pg_catalog.btrim(p_note), 1000)
    where id = (
      select history.id
      from public.order_status_history as history
      where history.order_id = p_order_id
        and history.to_status = p_target_status
      order by history.created_at desc, history.id desc
      limit 1
    );
  end if;

  return order_row;
end;
$$;

create function public.request_order_item_return(
  p_order_item_id uuid,
  p_reason text,
  p_details text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  return_request_id uuid;
  eligible_item record;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select
    item.id,
    item.seller_id,
    item.total_cents,
    marketplace_order.buyer_id,
    marketplace_order.status,
    marketplace_order.withdrawal_deadline,
    seller.accepts_returns
  into eligible_item
  from public.order_items as item
  join public.orders as marketplace_order on marketplace_order.id = item.order_id
  join public.sellers as seller on seller.id = item.seller_id
  where item.id = p_order_item_id
  for update of item;

  if not found or eligible_item.buyer_id is distinct from auth.uid() then
    raise exception 'Order item not found' using errcode = 'P0002';
  end if;

  if eligible_item.status <> 'delivered'
    or not eligible_item.accepts_returns
    or eligible_item.withdrawal_deadline is null
    or eligible_item.withdrawal_deadline < now() then
    raise exception 'Order item is outside the return window'
      using errcode = '22023';
  end if;

  if char_length(pg_catalog.btrim(p_reason)) not between 2 and 80 then
    raise exception 'Return reason must contain between 2 and 80 characters'
      using errcode = '22023';
  end if;

  insert into public.return_requests (
    order_item_id,
    buyer_id,
    seller_id,
    reason,
    details,
    refund_amount_cents
  )
  values (
    p_order_item_id,
    auth.uid(),
    eligible_item.seller_id,
    pg_catalog.btrim(p_reason),
    nullif(pg_catalog.btrim(p_details), ''),
    eligible_item.total_cents
  )
  returning id into return_request_id;

  update public.order_items
  set status = 'return_requested'
  where id = p_order_item_id;

  update public.orders
  set status = 'return_requested'
  where id = (
    select item.order_id
    from public.order_items as item
    where item.id = p_order_item_id
  )
    and status = 'delivered';

  return return_request_id;
end;
$$;

create function public.add_return_evidence(
  p_return_request_id uuid,
  p_storage_paths text[]
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if coalesce(array_length(p_storage_paths, 1), 0) = 0
    or array_length(p_storage_paths, 1) > 8 then
    raise exception 'Between 1 and 8 evidence files are required'
      using errcode = '22023';
  end if;

  update public.return_requests as return_request
  set evidence_paths = (
    select array_agg(distinct evidence.path)
    from unnest(return_request.evidence_paths || p_storage_paths) as evidence(path)
  )
  where return_request.id = p_return_request_id
    and return_request.buyer_id = auth.uid()
    and return_request.status = 'requested';

  if not found then
    raise exception 'Return request cannot be updated' using errcode = '42501';
  end if;
end;
$$;

create function public.transition_return_request(
  p_return_request_id uuid,
  p_target_status public.return_request_status,
  p_note text default null,
  p_tracking_carrier text default null,
  p_tracking_number text default null
)
returns public.return_requests
language plpgsql
security definer
set search_path = ''
as $$
declare
  return_row public.return_requests%rowtype;
  caller_is_buyer boolean;
  caller_is_seller boolean;
  caller_is_admin boolean := public.is_admin();
begin
  select return_request.*
    into return_row
  from public.return_requests as return_request
  where return_request.id = p_return_request_id
  for update;

  if not found then
    raise exception 'Return request not found' using errcode = 'P0002';
  end if;

  caller_is_buyer := return_row.buyer_id = auth.uid();
  caller_is_seller := public.owns_seller(return_row.seller_id);

  if not caller_is_admin then
    if caller_is_buyer then
      if not (
        (return_row.status = 'requested' and p_target_status = 'cancelled')
        or (
          return_row.status in ('approved', 'label_issued')
          and p_target_status = 'in_transit'
        )
      ) then
        raise exception 'Buyer cannot perform this return transition'
          using errcode = '42501';
      end if;
    elsif caller_is_seller then
      if not (
        (return_row.status = 'requested' and p_target_status in ('approved', 'rejected'))
        or (return_row.status = 'in_transit' and p_target_status = 'received')
      ) then
        raise exception 'Seller cannot perform this return transition'
          using errcode = '42501';
      end if;
    else
      raise exception 'Return access denied' using errcode = '42501';
    end if;
  end if;

  if p_target_status = 'in_transit'
    and nullif(pg_catalog.btrim(p_tracking_number), '') is null then
    raise exception 'Return tracking number is required' using errcode = '22023';
  end if;

  update public.return_requests
  set
    status = p_target_status,
    decision_note = case
      when p_target_status in ('approved', 'rejected')
        then nullif(pg_catalog.btrim(p_note), '')
      else decision_note
    end,
    decided_at = case
      when p_target_status in ('approved', 'rejected') then now()
      else decided_at
    end,
    return_carrier = case
      when p_target_status = 'in_transit'
        then nullif(pg_catalog.btrim(p_tracking_carrier), '')
      else return_carrier
    end,
    return_tracking_number = case
      when p_target_status = 'in_transit' then pg_catalog.btrim(p_tracking_number)
      else return_tracking_number
    end,
    received_at = case
      when p_target_status = 'received' then now()
      else received_at
    end,
    refunded_at = case
      when p_target_status = 'refunded' then now()
      else refunded_at
    end
  where id = p_return_request_id
  returning * into return_row;

  if p_target_status = 'refunded' then
    update public.order_items
    set status = 'refunded'
    where id = return_row.order_item_id;
  elsif p_target_status = 'received' then
    update public.order_items
    set status = 'returned'
    where id = return_row.order_item_id;
  end if;

  return return_row;
end;
$$;

alter table public.shipping_methods enable row level security;
alter table public.product_shipping_methods enable row level security;
alter table public.checkout_sessions enable row level security;
alter table public.checkout_session_orders enable row level security;
alter table public.inventory_reservations enable row level security;
alter table public.payment_order_allocations enable row level security;
alter table public.payment_provider_events enable row level security;
alter table public.order_status_history enable row level security;
alter table public.return_requests enable row level security;
alter table public.invoices enable row level security;

create policy shipping_methods_select_visible
  on public.shipping_methods for select to anon, authenticated
  using (is_active or public.owns_seller(seller_id) or public.is_admin());
create policy shipping_methods_manage_own
  on public.shipping_methods for all to authenticated
  using (public.owns_seller(seller_id) or public.is_admin())
  with check (public.owns_seller(seller_id) or public.is_admin());

create policy product_shipping_methods_select_visible
  on public.product_shipping_methods for select to anon, authenticated
  using (
    exists (
      select 1
      from public.shipping_methods as shipping_method
      where shipping_method.id = shipping_method_id
        and (
          shipping_method.is_active
          or public.owns_seller(shipping_method.seller_id)
          or public.is_admin()
        )
    )
  );
create policy product_shipping_methods_manage_own
  on public.product_shipping_methods for all to authenticated
  using (public.owns_product(product_id) or public.is_admin())
  with check (public.owns_product(product_id) or public.is_admin());

create policy checkout_sessions_select_own
  on public.checkout_sessions for select to authenticated
  using (buyer_id = auth.uid() or public.is_admin());
create policy checkout_sessions_manage_admin
  on public.checkout_sessions for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy checkout_session_orders_select_participant
  on public.checkout_session_orders for select to authenticated
  using (
    public.owns_checkout(checkout_session_id)
    or public.can_access_order(order_id)
    or public.is_admin()
  );
create policy checkout_session_orders_manage_admin
  on public.checkout_session_orders for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy inventory_reservations_select_buyer
  on public.inventory_reservations for select to authenticated
  using (public.owns_checkout(checkout_session_id) or public.is_admin());
create policy inventory_reservations_manage_admin
  on public.inventory_reservations for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy payment_order_allocations_select_participant
  on public.payment_order_allocations for select to authenticated
  using (public.can_access_order(order_id) or public.is_admin());
create policy payment_order_allocations_manage_admin
  on public.payment_order_allocations for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy payment_provider_events_manage_admin
  on public.payment_provider_events for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy order_status_history_select_participant
  on public.order_status_history for select to authenticated
  using (public.can_access_order(order_id) or public.is_admin());
create policy order_status_history_manage_admin
  on public.order_status_history for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy return_requests_select_participant
  on public.return_requests for select to authenticated
  using (
    buyer_id = auth.uid()
    or public.owns_seller(seller_id)
    or public.is_admin()
  );
create policy return_requests_manage_admin
  on public.return_requests for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy invoices_select_participant
  on public.invoices for select to authenticated
  using (public.can_access_order(order_id) or public.is_admin());
create policy invoices_manage_admin
  on public.invoices for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy payments_select_buyer on public.payments;
create policy payments_select_participant
  on public.payments for select to authenticated
  using (
    public.is_admin()
    or (order_id is not null and public.can_access_order(order_id))
    or (checkout_session_id is not null and public.owns_checkout(checkout_session_id))
  );

grant select on table public.shipping_methods to anon, authenticated;
grant insert, update, delete on table public.shipping_methods to authenticated;
grant select on table public.product_shipping_methods to anon, authenticated;
grant insert, update, delete on table public.product_shipping_methods to authenticated;
grant select on table public.checkout_sessions to authenticated;
grant select on table public.checkout_session_orders to authenticated;
grant select on table public.inventory_reservations to authenticated;
grant select on table public.payment_order_allocations to authenticated;
grant select, insert, update, delete on table public.payment_provider_events to authenticated;
grant select on table public.order_status_history to authenticated;
grant select on table public.return_requests to authenticated;
grant select on table public.invoices to authenticated;
grant all on table public.shipping_methods to service_role;
grant all on table public.product_shipping_methods to service_role;
grant all on table public.checkout_sessions to service_role;
grant all on table public.checkout_session_orders to service_role;
grant all on table public.inventory_reservations to service_role;
grant all on table public.payment_order_allocations to service_role;
grant all on table public.payment_provider_events to service_role;
grant all on table public.order_status_history to service_role;
grant all on table public.return_requests to service_role;
grant all on table public.invoices to service_role;

revoke all on function public.owns_checkout(uuid) from public;
revoke all on function public.can_access_return_request(uuid) from public;
revoke all on function public.can_access_return_request_path(text) from public;
revoke all on function public.can_access_invoice_path(text) from public;
revoke all on function public.create_marketplace_checkout(
  uuid, uuid, jsonb, jsonb, jsonb, text
) from public;
revoke all on function public.release_checkout_inventory(
  uuid, public.checkout_status, text
) from public;
revoke all on function public.release_expired_checkouts(integer) from public;
revoke all on function public.apply_payment_event(
  text,
  text,
  uuid,
  text,
  public.payment_method,
  public.payment_status,
  jsonb
) from public;
revoke all on function public.transition_order_status(
  uuid, public.order_status, text, text, text
) from public;
revoke all on function public.request_order_item_return(uuid, text, text) from public;
revoke all on function public.add_return_evidence(uuid, text[]) from public;
revoke all on function public.transition_return_request(
  uuid, public.return_request_status, text, text, text
) from public;

grant execute on function public.owns_checkout(uuid) to authenticated;
grant execute on function public.can_access_return_request(uuid) to authenticated;
grant execute on function public.can_access_return_request_path(text) to authenticated;
grant execute on function public.can_access_invoice_path(text) to authenticated;
grant execute on function public.create_marketplace_checkout(
  uuid, uuid, jsonb, jsonb, jsonb, text
) to service_role;
grant execute on function public.release_checkout_inventory(
  uuid, public.checkout_status, text
) to service_role;
grant execute on function public.release_expired_checkouts(integer) to service_role;
grant execute on function public.apply_payment_event(
  text,
  text,
  uuid,
  text,
  public.payment_method,
  public.payment_status,
  jsonb
) to service_role;
grant execute on function public.transition_order_status(
  uuid, public.order_status, text, text, text
) to authenticated;
grant execute on function public.request_order_item_return(uuid, text, text)
  to authenticated;
grant execute on function public.add_return_evidence(uuid, text[]) to authenticated;
grant execute on function public.transition_return_request(
  uuid, public.return_request_status, text, text, text
) to authenticated, service_role;

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values
  (
    'invoice-documents',
    'invoice-documents',
    false,
    10485760,
    array['application/pdf']::text[]
  ),
  (
    'return-media',
    'return-media',
    false,
    10485760,
    array['image/webp', 'image/jpeg', 'image/png']::text[]
  )
on conflict (id) do update set
  name = excluded.name,
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy invoice_documents_storage_select
  on storage.objects for select to authenticated
  using (
    bucket_id = 'invoice-documents'
    and (public.can_access_invoice_path(name) or public.is_admin())
  );
create policy invoice_documents_storage_manage_admin
  on storage.objects for all to authenticated
  using (bucket_id = 'invoice-documents' and public.is_admin())
  with check (bucket_id = 'invoice-documents' and public.is_admin());

create policy return_media_storage_select
  on storage.objects for select to authenticated
  using (
    bucket_id = 'return-media'
    and (
      public.can_access_return_request_path((storage.foldername(name))[1])
      or public.is_admin()
    )
  );
create policy return_media_storage_insert
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'return-media'
    and array_length(storage.foldername(name), 1) >= 2
    and (
      public.can_access_return_request_path((storage.foldername(name))[1])
      or public.is_admin()
    )
  );
create policy return_media_storage_update
  on storage.objects for update to authenticated
  using (
    bucket_id = 'return-media'
    and (
      public.can_access_return_request_path((storage.foldername(name))[1])
      or public.is_admin()
    )
  )
  with check (
    bucket_id = 'return-media'
    and (
      public.can_access_return_request_path((storage.foldername(name))[1])
      or public.is_admin()
    )
  );
create policy return_media_storage_delete
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'return-media'
    and (
      public.can_access_return_request_path((storage.foldername(name))[1])
      or public.is_admin()
    )
  );

commit;
