-- Phase 1 database foundation for the marketplace.
-- Monetary amounts are stored as integer euro cents. Public clients never
-- receive a service-role key; privileged writes are performed by Edge Functions.

begin;

create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

create type public.app_language as enum ('de', 'en', 'ar', 'tr');
create type public.theme_preference as enum ('system', 'light', 'dark');
create type public.seller_kind as enum ('private', 'business');
create type public.seller_status as enum (
  'pending',
  'approved',
  'rejected',
  'suspended'
);
create type public.product_condition as enum ('new', 'used');
create type public.product_status as enum ('draft', 'active', 'sold', 'blocked');
create type public.cart_status as enum ('active', 'converted', 'abandoned');
create type public.order_status as enum (
  'pending_payment',
  'paid',
  'processing',
  'shipped',
  'delivered',
  'cancelled',
  'return_requested',
  'returned',
  'refunded'
);
create type public.order_item_status as enum (
  'ordered',
  'processing',
  'shipped',
  'delivered',
  'cancelled',
  'return_requested',
  'returned',
  'refunded'
);
create type public.payment_status as enum (
  'pending',
  'requires_action',
  'processing',
  'succeeded',
  'failed',
  'cancelled',
  'partially_refunded',
  'refunded'
);
create type public.payment_method as enum (
  'card',
  'paypal',
  'klarna',
  'sepa_debit',
  'apple_pay',
  'google_pay',
  'unknown'
);
create type public.review_kind as enum ('product', 'seller');
create type public.review_status as enum ('published', 'hidden', 'removed');
create type public.message_kind as enum ('text', 'image', 'product', 'system');
create type public.notification_kind as enum (
  'order',
  'chat',
  'offer',
  'price_drop',
  'system'
);
create type public.report_reason as enum (
  'spam',
  'fraud',
  'counterfeit',
  'prohibited_item',
  'harassment',
  'inappropriate_content',
  'other'
);
create type public.report_status as enum (
  'pending',
  'reviewing',
  'resolved',
  'dismissed'
);

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 80),
  avatar_path text,
  phone text,
  language public.app_language not null default 'de',
  theme public.theme_preference not null default 'system',
  notification_preferences jsonb not null default
    '{"orders":true,"chat":true,"offers":false,"priceDrops":true,"system":true}'::jsonb,
  analytics_consent boolean not null default false,
  analytics_consent_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_notification_preferences_object
    check (jsonb_typeof(notification_preferences) = 'object')
);

create table public.addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  label text not null default 'Zuhause' check (char_length(label) between 1 and 40),
  full_name text not null check (char_length(full_name) between 1 and 120),
  company text,
  street text not null check (char_length(street) between 1 and 120),
  house_number text not null check (char_length(house_number) between 1 and 20),
  address_addition text,
  postal_code text not null check (postal_code ~ '^[0-9]{5}$'),
  city text not null check (char_length(city) between 1 and 100),
  state text,
  country_code text not null default 'DE'
    check (country_code ~ '^[A-Z]{2}$'),
  phone text,
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index addresses_one_default_per_user_idx
  on public.addresses (user_id)
  where is_default;
create index addresses_user_id_idx on public.addresses (user_id);

create table public.sellers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique references auth.users (id) on delete set null,
  kind public.seller_kind not null,
  status public.seller_status not null default 'pending',
  shop_name text not null check (char_length(shop_name) between 2 and 100),
  slug text not null unique check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  bio text check (char_length(bio) <= 1000),
  avatar_path text,
  banner_path text,
  city text,
  response_time_minutes integer check (response_time_minutes is null or response_time_minutes >= 0),
  rating_average numeric(3, 2) not null default 0
    check (rating_average between 0 and 5),
  rating_count integer not null default 0 check (rating_count >= 0),
  approved_at timestamptz,
  rejection_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint sellers_approval_timestamp check (
    (status = 'approved' and approved_at is not null)
    or status <> 'approved'
  )
);

-- Sensitive onboarding, tax, and payout data is deliberately separated from
-- the publicly readable seller profile.
create table public.seller_private_details (
  seller_id uuid primary key references public.sellers (id) on delete cascade,
  legal_name text,
  legal_address jsonb,
  vat_id text,
  tax_number text,
  commercial_register_number text,
  stripe_account_id text unique,
  stripe_charges_enabled boolean not null default false,
  stripe_payouts_enabled boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint seller_private_legal_address_object
    check (legal_address is null or jsonb_typeof(legal_address) = 'object')
);

create index sellers_user_id_idx on public.sellers (user_id);
create index sellers_status_idx on public.sellers (status);

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid references public.categories (id) on delete restrict,
  slug text not null unique check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  name_de text not null,
  name_en text not null,
  name_ar text not null,
  name_tr text not null,
  icon_key text not null,
  image_url text not null,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint categories_not_own_parent check (parent_id is null or parent_id <> id)
);

create index categories_parent_sort_idx
  on public.categories (parent_id, sort_order, name_de);

create table public.brands (
  id uuid primary key default gen_random_uuid(),
  category_id uuid references public.categories (id) on delete set null,
  name text not null check (char_length(name) between 1 and 100),
  slug text not null unique check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  logo_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index brands_category_id_idx on public.brands (category_id);

create table public.products (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.sellers (id) on delete restrict,
  category_id uuid not null references public.categories (id) on delete restrict,
  brand_id uuid references public.brands (id) on delete set null,
  title text not null check (char_length(title) between 3 and 180),
  slug text not null unique check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  description text not null check (char_length(description) between 10 and 10000),
  condition public.product_condition not null,
  status public.product_status not null default 'draft',
  price_cents bigint not null check (price_cents >= 0),
  compare_at_price_cents bigint check (
    compare_at_price_cents is null or compare_at_price_cents > price_cents
  ),
  currency text not null default 'EUR' check (currency ~ '^[A-Z]{3}$'),
  vat_rate numeric(5, 2) not null default 19.00 check (vat_rate between 0 and 100),
  price_includes_vat boolean not null default true check (price_includes_vat),
  quantity integer not null default 1 check (quantity >= 0),
  sku text,
  specifications jsonb not null default '{}'::jsonb,
  city text,
  postal_code text check (postal_code is null or postal_code ~ '^[0-9]{5}$'),
  latitude numeric(9, 6) check (latitude is null or latitude between -90 and 90),
  longitude numeric(9, 6) check (longitude is null or longitude between -180 and 180),
  ships_to text[] not null default array['DE']::text[],
  shipping_cost_cents bigint not null default 0 check (shipping_cost_cents >= 0),
  free_shipping boolean not null default false,
  rating_average numeric(3, 2) not null default 0
    check (rating_average between 0 and 5),
  rating_count integer not null default 0 check (rating_count >= 0),
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  search_vector tsvector generated always as (
    setweight(to_tsvector('german'::regconfig, coalesce(title, '')), 'A')
    || setweight(to_tsvector('german'::regconfig, coalesce(description, '')), 'B')
  ) stored,
  constraint products_specifications_object check (jsonb_typeof(specifications) = 'object'),
  constraint products_free_shipping_cost check (not free_shipping or shipping_cost_cents = 0)
);

create index products_search_vector_idx on public.products using gin (search_vector);
create index products_browse_idx
  on public.products (status, category_id, published_at desc);
create index products_seller_status_idx on public.products (seller_id, status);
create index products_brand_id_idx on public.products (brand_id);
create index products_price_idx on public.products (price_cents);

create table public.product_images (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products (id) on delete cascade,
  storage_path text not null unique,
  alt_text text,
  sort_order integer not null default 0 check (sort_order >= 0),
  width integer check (width is null or width > 0),
  height integer check (height is null or height > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (product_id, sort_order)
);

create index product_images_product_id_idx on public.product_images (product_id);

create table public.favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  product_id uuid not null references public.products (id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, product_id)
);

create index favorites_user_created_idx
  on public.favorites (user_id, created_at desc);

create table public.carts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  status public.cart_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index carts_one_active_per_user_idx
  on public.carts (user_id)
  where status = 'active';

create table public.cart_items (
  id uuid primary key default gen_random_uuid(),
  cart_id uuid not null references public.carts (id) on delete cascade,
  product_id uuid not null references public.products (id) on delete cascade,
  quantity integer not null default 1 check (quantity between 1 and 99),
  saved_for_later boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (cart_id, product_id)
);

create index cart_items_cart_id_idx on public.cart_items (cart_id);

-- A checkout containing multiple vendors creates one order per seller. This
-- prevents one vendor from seeing another vendor's line items or revenue.
create table public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number text not null unique default (
    'ZR-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 12))
  ),
  buyer_id uuid references auth.users (id) on delete set null,
  seller_id uuid not null references public.sellers (id) on delete restrict,
  status public.order_status not null default 'pending_payment',
  payment_status public.payment_status not null default 'pending',
  currency text not null default 'EUR' check (currency ~ '^[A-Z]{3}$'),
  subtotal_cents bigint not null check (subtotal_cents >= 0),
  shipping_cents bigint not null default 0 check (shipping_cents >= 0),
  discount_cents bigint not null default 0 check (discount_cents >= 0),
  vat_cents bigint not null default 0 check (vat_cents >= 0),
  total_cents bigint not null check (total_cents >= 0),
  shipping_address jsonb not null,
  billing_address jsonb,
  shipping_method jsonb not null default '{}'::jsonb,
  placed_at timestamptz,
  paid_at timestamptz,
  shipped_at timestamptz,
  delivered_at timestamptz,
  cancelled_at timestamptz,
  withdrawal_deadline timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint orders_shipping_address_object check (jsonb_typeof(shipping_address) = 'object'),
  constraint orders_billing_address_object check (
    billing_address is null or jsonb_typeof(billing_address) = 'object'
  ),
  constraint orders_shipping_method_object check (jsonb_typeof(shipping_method) = 'object'),
  constraint orders_total_calculation check (
    total_cents = subtotal_cents + shipping_cents - discount_cents
  ),
  constraint orders_vat_is_included check (vat_cents <= total_cents)
);

create index orders_buyer_created_idx on public.orders (buyer_id, created_at desc);
create index orders_seller_created_idx on public.orders (seller_id, created_at desc);
create index orders_status_idx on public.orders (status);

create table public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  product_id uuid references public.products (id) on delete set null,
  seller_id uuid not null references public.sellers (id) on delete restrict,
  status public.order_item_status not null default 'ordered',
  product_title text not null,
  product_sku text,
  product_image_url text,
  condition public.product_condition not null,
  quantity integer not null check (quantity > 0),
  unit_price_cents bigint not null check (unit_price_cents >= 0),
  vat_rate numeric(5, 2) not null check (vat_rate between 0 and 100),
  vat_cents bigint not null default 0 check (vat_cents >= 0),
  total_cents bigint not null check (total_cents >= 0),
  tracking_carrier text,
  tracking_number text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint order_items_total_calculation check (
    total_cents = unit_price_cents * quantity
  ),
  constraint order_items_vat_is_included check (vat_cents <= total_cents)
);

create index order_items_order_id_idx on public.order_items (order_id);
create index order_items_product_id_idx on public.order_items (product_id);
create index order_items_seller_id_idx on public.order_items (seller_id);

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete restrict,
  stripe_payment_intent_id text unique,
  stripe_charge_id text,
  method public.payment_method not null default 'unknown',
  status public.payment_status not null default 'pending',
  amount_cents bigint not null check (amount_cents >= 0),
  refunded_cents bigint not null default 0 check (
    refunded_cents >= 0 and refunded_cents <= amount_cents
  ),
  currency text not null default 'EUR' check (currency ~ '^[A-Z]{3}$'),
  failure_code text,
  failure_message text,
  provider_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint payments_provider_payload_object check (jsonb_typeof(provider_payload) = 'object')
);

create index payments_order_id_idx on public.payments (order_id);

create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  kind public.review_kind not null,
  product_id uuid references public.products (id) on delete set null,
  seller_id uuid not null references public.sellers (id) on delete restrict,
  order_item_id uuid not null references public.order_items (id) on delete restrict,
  reviewer_id uuid references auth.users (id) on delete set null,
  rating smallint not null check (rating between 1 and 5),
  body text check (body is null or char_length(body) between 3 and 3000),
  photo_paths text[] not null default '{}'::text[],
  verified_purchase boolean not null default true,
  status public.review_status not null default 'published',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (order_item_id, kind),
  constraint reviews_kind_target check (
    (kind = 'product' and product_id is not null)
    or (kind = 'seller' and product_id is null)
  )
);

create index reviews_product_published_idx
  on public.reviews (product_id, created_at desc)
  where status = 'published' and kind = 'product';
create index reviews_seller_published_idx
  on public.reviews (seller_id, created_at desc)
  where status = 'published' and kind = 'seller';
create index reviews_reviewer_idx on public.reviews (reviewer_id);

create table public.chats (
  id uuid primary key default gen_random_uuid(),
  buyer_id uuid references auth.users (id) on delete set null,
  seller_id uuid not null references public.sellers (id) on delete restrict,
  product_id uuid references public.products (id) on delete set null,
  last_message_at timestamptz,
  last_message_preview text,
  closed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index chats_unique_product_context_idx
  on public.chats (buyer_id, seller_id, product_id)
  where product_id is not null and closed_at is null;
create unique index chats_unique_seller_context_idx
  on public.chats (buyer_id, seller_id)
  where product_id is null and closed_at is null;
create index chats_buyer_activity_idx on public.chats (buyer_id, last_message_at desc);
create index chats_seller_activity_idx on public.chats (seller_id, last_message_at desc);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  chat_id uuid not null references public.chats (id) on delete cascade,
  sender_id uuid references auth.users (id) on delete set null,
  kind public.message_kind not null default 'text',
  body text check (body is null or char_length(body) <= 5000),
  media_path text,
  product_id uuid references public.products (id) on delete set null,
  read_at timestamptz,
  created_at timestamptz not null default now(),
  constraint messages_content_for_kind check (
    (kind = 'text' and body is not null and char_length(trim(body)) > 0)
    or (kind = 'image' and media_path is not null)
    or (kind = 'product' and product_id is not null)
    or kind = 'system'
  )
);

create index messages_chat_created_idx on public.messages (chat_id, created_at desc);
create index messages_unread_idx on public.messages (chat_id, created_at)
  where read_at is null;

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  kind public.notification_kind not null,
  title_key text not null,
  body_key text not null,
  data jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  pushed_at timestamptz,
  created_at timestamptz not null default now(),
  constraint notifications_data_object check (jsonb_typeof(data) = 'object')
);

create index notifications_user_created_idx
  on public.notifications (user_id, created_at desc);
create index notifications_user_unread_idx
  on public.notifications (user_id, created_at desc)
  where read_at is null;

create table public.banners (
  id uuid primary key default gen_random_uuid(),
  title_i18n jsonb not null,
  subtitle_i18n jsonb not null default '{}'::jsonb,
  image_url text not null,
  deep_link text,
  sort_order integer not null default 0,
  starts_at timestamptz,
  ends_at timestamptz,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint banners_title_object check (jsonb_typeof(title_i18n) = 'object'),
  constraint banners_subtitle_object check (jsonb_typeof(subtitle_i18n) = 'object'),
  constraint banners_schedule check (
    starts_at is null or ends_at is null or ends_at > starts_at
  )
);

create index banners_schedule_idx
  on public.banners (is_active, sort_order, starts_at, ends_at);

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid references auth.users (id) on delete set null,
  product_id uuid references public.products (id) on delete set null,
  seller_id uuid references public.sellers (id) on delete set null,
  review_id uuid references public.reviews (id) on delete set null,
  message_id uuid references public.messages (id) on delete set null,
  reason public.report_reason not null,
  details text check (details is null or char_length(details) <= 3000),
  status public.report_status not null default 'pending',
  admin_notes text,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint reports_exactly_one_target check (
    num_nonnulls(product_id, seller_id, review_id, message_id) = 1
  )
);

create index reports_reporter_created_idx on public.reports (reporter_id, created_at desc);
create index reports_status_created_idx on public.reports (status, created_at);

-- ---------------------------------------------------------------------------
-- Authorization helpers
-- ---------------------------------------------------------------------------

create function public.is_admin()
returns boolean
language sql
stable
set search_path = ''
as $$
  select coalesce(
    (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin',
    false
  );
$$;

create function public.owns_seller(target_seller_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.sellers as seller
    where seller.id = target_seller_id
      and seller.user_id = auth.uid()
  );
$$;

create function public.is_approved_seller(target_seller_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.sellers as seller
    where seller.id = target_seller_id
      and seller.status = 'approved'
  );
$$;

create function public.owns_product(target_product_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.products as product
    join public.sellers as seller on seller.id = product.seller_id
    where product.id = target_product_id
      and seller.user_id = auth.uid()
  );
$$;

create function public.owns_cart(target_cart_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.carts as cart
    where cart.id = target_cart_id
      and cart.user_id = auth.uid()
  );
$$;

create function public.is_order_buyer(target_order_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.orders as marketplace_order
    where marketplace_order.id = target_order_id
      and marketplace_order.buyer_id = auth.uid()
  );
$$;

create function public.can_access_order(target_order_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.orders as marketplace_order
    left join public.sellers as seller on seller.id = marketplace_order.seller_id
    where marketplace_order.id = target_order_id
      and (
        marketplace_order.buyer_id = auth.uid()
        or seller.user_id = auth.uid()
      )
  );
$$;

create function public.is_chat_participant(target_chat_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.chats as chat
    join public.sellers as seller on seller.id = chat.seller_id
    where chat.id = target_chat_id
      and (
        chat.buyer_id = auth.uid()
        or seller.user_id = auth.uid()
      )
  );
$$;

create function public.is_chat_participant_path(target_chat_id text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.chats as chat
    join public.sellers as seller on seller.id = chat.seller_id
    where chat.id::text = target_chat_id
      and (
        chat.buyer_id = auth.uid()
        or seller.user_id = auth.uid()
      )
  );
$$;

create function public.chat_is_open(target_chat_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.chats as chat
    where chat.id = target_chat_id
      and chat.closed_at is null
  );
$$;

create function public.can_review_order_item(
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
-- Integrity and lifecycle triggers
-- ---------------------------------------------------------------------------

create function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  requested_language public.app_language;
begin
  requested_language := case new.raw_user_meta_data ->> 'language'
    when 'en' then 'en'::public.app_language
    when 'ar' then 'ar'::public.app_language
    when 'tr' then 'tr'::public.app_language
    else 'de'::public.app_language
  end;

  insert into public.profiles (id, display_name, language)
  values (
    new.id,
    coalesce(
      nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''),
      nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''),
      nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
      'Nutzer'
    ),
    requested_language
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_auth_user();

do $$
declare
  target_table text;
begin
  foreach target_table in array array[
    'profiles',
    'addresses',
    'sellers',
    'seller_private_details',
    'categories',
    'brands',
    'products',
    'product_images',
    'carts',
    'cart_items',
    'orders',
    'order_items',
    'payments',
    'reviews',
    'chats',
    'banners',
    'reports'
  ] loop
    execute format(
      'create trigger set_updated_at before update on public.%I '
      || 'for each row execute function public.set_updated_at()',
      target_table
    );
  end loop;
end;
$$;

create function public.validate_category_depth()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  parent_parent_id uuid;
begin
  if new.parent_id is null then
    return new;
  end if;

  select category.parent_id
    into parent_parent_id
  from public.categories as category
  where category.id = new.parent_id;

  if not found then
    raise exception 'Parent category does not exist';
  end if;

  if parent_parent_id is not null then
    raise exception 'Categories support exactly two levels';
  end if;

  if exists (
    select 1
    from public.categories as child
    where child.parent_id = new.id
  ) then
    raise exception 'A category with children cannot become a child category';
  end if;

  return new;
end;
$$;

create trigger validate_category_depth
  before insert or update of parent_id on public.categories
  for each row execute function public.validate_category_depth();

create function public.prepare_seller_write()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    if auth.uid() is not null and not public.is_admin() then
      if new.user_id is distinct from auth.uid() then
        raise exception 'A seller application must belong to the authenticated user';
      end if;
      new.status = 'pending';
      new.approved_at = null;
      new.rejection_reason = null;
      new.rating_average = 0;
      new.rating_count = 0;
    end if;
  elsif auth.uid() is not null and not public.is_admin() then
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

  if new.status = 'approved' then
    new.approved_at = coalesce(new.approved_at, now());
    new.rejection_reason = null;
  else
    new.approved_at = null;
  end if;

  return new;
end;
$$;

create trigger prepare_seller_write
  before insert or update on public.sellers
  for each row execute function public.prepare_seller_write();

create function public.protect_seller_private_fields()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if auth.uid() is null or public.is_admin() then
    return new;
  end if;

  if tg_op = 'INSERT' then
    new.stripe_account_id = null;
    new.stripe_charges_enabled = false;
    new.stripe_payouts_enabled = false;
  elsif new.seller_id is distinct from old.seller_id
    or new.stripe_account_id is distinct from old.stripe_account_id
    or new.stripe_charges_enabled is distinct from old.stripe_charges_enabled
    or new.stripe_payouts_enabled is distinct from old.stripe_payouts_enabled then
    raise exception 'Stripe onboarding fields are server-managed';
  end if;

  return new;
end;
$$;

create trigger protect_seller_private_fields
  before insert or update on public.seller_private_details
  for each row execute function public.protect_seller_private_fields();

create function public.prepare_product_write()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  slug_base text;
begin
  if new.slug is null or trim(new.slug) = '' then
    slug_base := trim(both '-' from regexp_replace(
      lower(translate(new.title, 'ÄÖÜäöüß', 'AOUaous')),
      '[^a-z0-9]+',
      '-',
      'g'
    ));
    new.slug := coalesce(nullif(slug_base, ''), 'produkt')
      || '-' || left(new.id::text, 8);
  end if;

  if auth.uid() is not null and not public.is_admin() then
    if tg_op = 'INSERT' and new.status = 'blocked' then
      raise exception 'Only administrators can block products';
    elsif tg_op = 'UPDATE'
      and (new.status = 'blocked' or old.status = 'blocked')
      and new.status is distinct from old.status then
      raise exception 'Only administrators can change blocked product status';
    end if;

    if tg_op = 'UPDATE'
      and (
        new.rating_average is distinct from old.rating_average
        or new.rating_count is distinct from old.rating_count
      ) then
      raise exception 'Product rating fields are server-managed';
    end if;
  end if;

  if new.status = 'active' and new.published_at is null then
    new.published_at = now();
  end if;

  return new;
end;
$$;

create trigger prepare_product_write
  before insert or update on public.products
  for each row execute function public.prepare_product_write();

create function public.validate_order_item_seller()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  order_seller_id uuid;
  product_seller_id uuid;
begin
  select marketplace_order.seller_id
    into order_seller_id
  from public.orders as marketplace_order
  where marketplace_order.id = new.order_id;

  if order_seller_id is distinct from new.seller_id then
    raise exception 'Order item seller must match order seller';
  end if;

  if new.product_id is not null then
    select product.seller_id
      into product_seller_id
    from public.products as product
    where product.id = new.product_id;

    if product_seller_id is distinct from new.seller_id then
      raise exception 'Order item product must belong to the order seller';
    end if;
  end if;

  return new;
end;
$$;

create trigger validate_order_item_seller
  before insert or update of order_id, product_id, seller_id on public.order_items
  for each row execute function public.validate_order_item_seller();

create function public.validate_chat_context()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  product_seller_id uuid;
  seller_user_id uuid;
begin
  select seller.user_id
    into seller_user_id
  from public.sellers as seller
  where seller.id = new.seller_id;

  if new.buyer_id is not null and new.buyer_id = seller_user_id then
    raise exception 'A seller cannot start a buyer chat with themselves';
  end if;

  if new.product_id is not null then
    select product.seller_id
      into product_seller_id
    from public.products as product
    where product.id = new.product_id;

    if product_seller_id is distinct from new.seller_id then
      raise exception 'Chat product must belong to the selected seller';
    end if;
  end if;

  return new;
end;
$$;

create trigger validate_chat_context
  before insert or update of buyer_id, seller_id, product_id on public.chats
  for each row execute function public.validate_chat_context();

create function public.protect_review_fields()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if auth.uid() is null or public.is_admin() then
    return new;
  end if;

  if tg_op = 'INSERT' then
    new.reviewer_id = auth.uid();
    new.verified_purchase = true;
    new.status = 'published';
  elsif new.kind is distinct from old.kind
    or new.product_id is distinct from old.product_id
    or new.seller_id is distinct from old.seller_id
    or new.order_item_id is distinct from old.order_item_id
    or new.reviewer_id is distinct from old.reviewer_id
    or new.verified_purchase is distinct from old.verified_purchase
    or new.status is distinct from old.status then
    raise exception 'Review ownership and moderation fields are immutable';
  end if;

  return new;
end;
$$;

create trigger protect_review_fields
  before insert or update on public.reviews
  for each row execute function public.protect_review_fields();

create function public.recalculate_review_aggregates(
  target_product_id uuid,
  target_seller_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if target_product_id is not null then
    update public.products as product
    set
      rating_average = aggregate.average_rating,
      rating_count = aggregate.review_count
    from (
      select
        coalesce(round(avg(review.rating)::numeric, 2), 0) as average_rating,
        count(*)::integer as review_count
      from public.reviews as review
      where review.product_id = target_product_id
        and review.kind = 'product'
        and review.status = 'published'
    ) as aggregate
    where product.id = target_product_id;
  end if;

  if target_seller_id is not null then
    update public.sellers as seller
    set
      rating_average = aggregate.average_rating,
      rating_count = aggregate.review_count
    from (
      select
        coalesce(round(avg(review.rating)::numeric, 2), 0) as average_rating,
        count(*)::integer as review_count
      from public.reviews as review
      where review.seller_id = target_seller_id
        and review.kind = 'seller'
        and review.status = 'published'
    ) as aggregate
    where seller.id = target_seller_id;
  end if;
end;
$$;

create function public.refresh_review_aggregates()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op <> 'INSERT' then
    perform public.recalculate_review_aggregates(old.product_id, old.seller_id);
  end if;

  if tg_op <> 'DELETE' then
    perform public.recalculate_review_aggregates(new.product_id, new.seller_id);
  end if;

  return coalesce(new, old);
end;
$$;

create trigger refresh_review_aggregates
  after insert or update or delete on public.reviews
  for each row execute function public.refresh_review_aggregates();

create function public.protect_message_update()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if auth.uid() is not null and not public.is_admin() then
    if new.id is distinct from old.id
      or new.chat_id is distinct from old.chat_id
      or new.sender_id is distinct from old.sender_id
      or new.kind is distinct from old.kind
      or new.body is distinct from old.body
      or new.media_path is distinct from old.media_path
      or new.product_id is distinct from old.product_id
      or new.created_at is distinct from old.created_at then
      raise exception 'Messages are immutable except for their read timestamp';
    end if;
  end if;

  return new;
end;
$$;

create trigger protect_message_update
  before update on public.messages
  for each row execute function public.protect_message_update();

create function public.touch_chat_from_message()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.chats
  set
    last_message_at = new.created_at,
    last_message_preview = left(coalesce(new.body, new.kind::text), 140)
  where id = new.chat_id;

  return new;
end;
$$;

create trigger touch_chat_from_message
  after insert on public.messages
  for each row execute function public.touch_chat_from_message();

create function public.protect_notification_update()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if auth.uid() is not null and not public.is_admin() then
    if new.id is distinct from old.id
      or new.user_id is distinct from old.user_id
      or new.kind is distinct from old.kind
      or new.title_key is distinct from old.title_key
      or new.body_key is distinct from old.body_key
      or new.data is distinct from old.data
      or new.pushed_at is distinct from old.pushed_at
      or new.created_at is distinct from old.created_at then
      raise exception 'Notification content is server-managed';
    end if;
  end if;

  return new;
end;
$$;

create trigger protect_notification_update
  before update on public.notifications
  for each row execute function public.protect_notification_update();

create function public.protect_report_fields()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if auth.uid() is not null and not public.is_admin() and tg_op = 'INSERT' then
    new.reporter_id = auth.uid();
    new.status = 'pending';
    new.admin_notes = null;
    new.resolved_at = null;
  end if;

  return new;
end;
$$;

create trigger protect_report_fields
  before insert on public.reports
  for each row execute function public.protect_report_fields();

-- ---------------------------------------------------------------------------
-- Row-level security
-- ---------------------------------------------------------------------------

do $$
declare
  target_table text;
begin
  foreach target_table in array array[
    'profiles',
    'addresses',
    'sellers',
    'seller_private_details',
    'categories',
    'brands',
    'products',
    'product_images',
    'favorites',
    'carts',
    'cart_items',
    'orders',
    'order_items',
    'payments',
    'reviews',
    'chats',
    'messages',
    'notifications',
    'banners',
    'reports'
  ] loop
    execute format('alter table public.%I enable row level security', target_table);
  end loop;
end;
$$;

create policy profiles_select_own
  on public.profiles for select to authenticated
  using (id = auth.uid() or public.is_admin());
create policy profiles_insert_own
  on public.profiles for insert to authenticated
  with check (id = auth.uid() or public.is_admin());
create policy profiles_update_own
  on public.profiles for update to authenticated
  using (id = auth.uid() or public.is_admin())
  with check (id = auth.uid() or public.is_admin());
create policy profiles_delete_admin
  on public.profiles for delete to authenticated
  using (public.is_admin());

create policy addresses_select_own
  on public.addresses for select to authenticated
  using (user_id = auth.uid() or public.is_admin());
create policy addresses_insert_own
  on public.addresses for insert to authenticated
  with check (user_id = auth.uid() or public.is_admin());
create policy addresses_update_own
  on public.addresses for update to authenticated
  using (user_id = auth.uid() or public.is_admin())
  with check (user_id = auth.uid() or public.is_admin());
create policy addresses_delete_own
  on public.addresses for delete to authenticated
  using (user_id = auth.uid() or public.is_admin());

create policy sellers_select_visible
  on public.sellers for select to anon, authenticated
  using (
    status = 'approved'
    or user_id = auth.uid()
    or public.is_admin()
  );
create policy sellers_insert_own_application
  on public.sellers for insert to authenticated
  with check (
    user_id = auth.uid()
    and status = 'pending'
  );
create policy sellers_update_own
  on public.sellers for update to authenticated
  using (user_id = auth.uid() or public.is_admin())
  with check (user_id = auth.uid() or public.is_admin());
create policy sellers_delete_pending_own
  on public.sellers for delete to authenticated
  using (
    public.is_admin()
    or (
      user_id = auth.uid()
      and status in ('pending', 'rejected')
    )
  );

create policy seller_private_select_own
  on public.seller_private_details for select to authenticated
  using (public.owns_seller(seller_id) or public.is_admin());
create policy seller_private_insert_own
  on public.seller_private_details for insert to authenticated
  with check (public.owns_seller(seller_id) or public.is_admin());
create policy seller_private_update_own
  on public.seller_private_details for update to authenticated
  using (public.owns_seller(seller_id) or public.is_admin())
  with check (public.owns_seller(seller_id) or public.is_admin());
create policy seller_private_delete_own_pending
  on public.seller_private_details for delete to authenticated
  using (
    public.is_admin()
    or exists (
      select 1
      from public.sellers as seller
      where seller.id = seller_id
        and seller.user_id = auth.uid()
        and seller.status in ('pending', 'rejected')
    )
  );

create policy categories_select_active
  on public.categories for select to anon, authenticated
  using (is_active or public.is_admin());
create policy categories_manage_admin
  on public.categories for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy brands_select_active
  on public.brands for select to anon, authenticated
  using (is_active or public.is_admin());
create policy brands_manage_admin
  on public.brands for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy products_select_visible
  on public.products for select to anon, authenticated
  using (
    (
      status = 'active'
      and public.is_approved_seller(seller_id)
    )
    or public.owns_seller(seller_id)
    or public.is_admin()
  );
create policy products_insert_own
  on public.products for insert to authenticated
  with check (
    public.is_admin()
    or (
      public.owns_seller(seller_id)
      and status <> 'blocked'
    )
  );
create policy products_update_own
  on public.products for update to authenticated
  using (public.owns_seller(seller_id) or public.is_admin())
  with check (public.owns_seller(seller_id) or public.is_admin());
create policy products_delete_own
  on public.products for delete to authenticated
  using (
    public.is_admin()
    or (
      public.owns_seller(seller_id)
      and status not in ('sold', 'blocked')
    )
  );

create policy product_images_select_visible
  on public.product_images for select to anon, authenticated
  using (
    exists (
      select 1
      from public.products as product
      where product.id = product_id
        and (
          (
            product.status = 'active'
            and public.is_approved_seller(product.seller_id)
          )
          or public.owns_seller(product.seller_id)
          or public.is_admin()
        )
    )
  );
create policy product_images_insert_own
  on public.product_images for insert to authenticated
  with check (public.owns_product(product_id) or public.is_admin());
create policy product_images_update_own
  on public.product_images for update to authenticated
  using (public.owns_product(product_id) or public.is_admin())
  with check (public.owns_product(product_id) or public.is_admin());
create policy product_images_delete_own
  on public.product_images for delete to authenticated
  using (public.owns_product(product_id) or public.is_admin());

create policy favorites_select_own
  on public.favorites for select to authenticated
  using (user_id = auth.uid() or public.is_admin());
create policy favorites_insert_own
  on public.favorites for insert to authenticated
  with check (
    (user_id = auth.uid() and exists (
      select 1
      from public.products as product
      where product.id = product_id
        and product.status = 'active'
        and public.is_approved_seller(product.seller_id)
    ))
    or public.is_admin()
  );
create policy favorites_delete_own
  on public.favorites for delete to authenticated
  using (user_id = auth.uid() or public.is_admin());

create policy carts_select_own
  on public.carts for select to authenticated
  using (user_id = auth.uid() or public.is_admin());
create policy carts_insert_own
  on public.carts for insert to authenticated
  with check (user_id = auth.uid() or public.is_admin());
create policy carts_update_own
  on public.carts for update to authenticated
  using (user_id = auth.uid() or public.is_admin())
  with check (user_id = auth.uid() or public.is_admin());
create policy carts_delete_own
  on public.carts for delete to authenticated
  using (user_id = auth.uid() or public.is_admin());

create policy cart_items_select_own
  on public.cart_items for select to authenticated
  using (public.owns_cart(cart_id) or public.is_admin());
create policy cart_items_insert_own
  on public.cart_items for insert to authenticated
  with check (
    public.is_admin()
    or (
      public.owns_cart(cart_id)
      and exists (
        select 1
        from public.products as product
        where product.id = product_id
          and product.status = 'active'
          and product.quantity > 0
          and public.is_approved_seller(product.seller_id)
      )
    )
  );
create policy cart_items_update_own
  on public.cart_items for update to authenticated
  using (public.owns_cart(cart_id) or public.is_admin())
  with check (public.owns_cart(cart_id) or public.is_admin());
create policy cart_items_delete_own
  on public.cart_items for delete to authenticated
  using (public.owns_cart(cart_id) or public.is_admin());

-- Orders, order items, and payments are written only by the service role.
create policy orders_select_participant
  on public.orders for select to authenticated
  using (
    buyer_id = auth.uid()
    or public.owns_seller(seller_id)
    or public.is_admin()
  );
create policy orders_manage_admin
  on public.orders for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy order_items_select_participant
  on public.order_items for select to authenticated
  using (public.can_access_order(order_id) or public.is_admin());
create policy order_items_manage_admin
  on public.order_items for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy payments_select_buyer
  on public.payments for select to authenticated
  using (public.is_order_buyer(order_id) or public.is_admin());
create policy payments_manage_admin
  on public.payments for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy reviews_select_visible
  on public.reviews for select to anon, authenticated
  using (
    status = 'published'
    or reviewer_id = auth.uid()
    or public.is_admin()
  );
create policy reviews_insert_verified_purchase
  on public.reviews for insert to authenticated
  with check (
    public.is_admin()
    or (
      reviewer_id = auth.uid()
      and verified_purchase
      and status = 'published'
      and public.can_review_order_item(
        order_item_id,
        product_id,
        seller_id,
        kind
      )
    )
  );
create policy reviews_update_own
  on public.reviews for update to authenticated
  using (reviewer_id = auth.uid() or public.is_admin())
  with check (
    public.is_admin()
    or (
      reviewer_id = auth.uid()
      and public.can_review_order_item(
        order_item_id,
        product_id,
        seller_id,
        kind
      )
    )
  );
create policy reviews_delete_own
  on public.reviews for delete to authenticated
  using (reviewer_id = auth.uid() or public.is_admin());

create policy chats_select_participant
  on public.chats for select to authenticated
  using (public.is_chat_participant(id) or public.is_admin());
create policy chats_insert_buyer
  on public.chats for insert to authenticated
  with check (
    public.is_admin()
    or (
      buyer_id = auth.uid()
      and public.is_approved_seller(seller_id)
      and not public.owns_seller(seller_id)
      and (
        product_id is null
        or exists (
          select 1
          from public.products as product
          where product.id = product_id
            and product.seller_id = seller_id
            and product.status = 'active'
        )
      )
    )
  );
create policy chats_manage_admin
  on public.chats for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy messages_select_participant
  on public.messages for select to authenticated
  using (public.is_chat_participant(chat_id) or public.is_admin());
create policy messages_insert_participant
  on public.messages for insert to authenticated
  with check (
    public.is_admin()
    or (
      sender_id = auth.uid()
      and kind <> 'system'
      and public.is_chat_participant(chat_id)
      and public.chat_is_open(chat_id)
    )
  );
create policy messages_mark_read_recipient
  on public.messages for update to authenticated
  using (
    public.is_admin()
    or (
      sender_id is distinct from auth.uid()
      and public.is_chat_participant(chat_id)
    )
  )
  with check (
    public.is_admin()
    or (
      sender_id is distinct from auth.uid()
      and public.is_chat_participant(chat_id)
    )
  );

create policy notifications_select_own
  on public.notifications for select to authenticated
  using (user_id = auth.uid() or public.is_admin());
create policy notifications_update_own
  on public.notifications for update to authenticated
  using (user_id = auth.uid() or public.is_admin())
  with check (user_id = auth.uid() or public.is_admin());
create policy notifications_delete_own
  on public.notifications for delete to authenticated
  using (user_id = auth.uid() or public.is_admin());
create policy notifications_manage_admin
  on public.notifications for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy banners_select_active
  on public.banners for select to anon, authenticated
  using (
    (
      is_active
      and (starts_at is null or starts_at <= now())
      and (ends_at is null or ends_at > now())
    )
    or public.is_admin()
  );
create policy banners_manage_admin
  on public.banners for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy reports_select_own
  on public.reports for select to authenticated
  using (reporter_id = auth.uid() or public.is_admin());
create policy reports_insert_own
  on public.reports for insert to authenticated
  with check (
    (reporter_id = auth.uid() and status = 'pending')
    or public.is_admin()
  );
create policy reports_manage_admin
  on public.reports for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- Table privileges are broad enough for PostgREST; RLS remains the authority.
grant usage on schema public to anon, authenticated;
grant select on all tables in schema public to anon, authenticated;
grant insert, update, delete on all tables in schema public to authenticated;
grant usage, select on all sequences in schema public to authenticated;

revoke all on function public.owns_seller(uuid) from public;
revoke all on function public.is_approved_seller(uuid) from public;
revoke all on function public.owns_product(uuid) from public;
revoke all on function public.owns_cart(uuid) from public;
revoke all on function public.is_order_buyer(uuid) from public;
revoke all on function public.can_access_order(uuid) from public;
revoke all on function public.is_chat_participant(uuid) from public;
revoke all on function public.is_chat_participant_path(text) from public;
revoke all on function public.chat_is_open(uuid) from public;
revoke all on function public.can_review_order_item(
  uuid, uuid, uuid, public.review_kind
) from public;
revoke all on function public.recalculate_review_aggregates(uuid, uuid) from public;
revoke all on function public.handle_new_auth_user() from public;
revoke all on function public.touch_chat_from_message() from public;

grant execute on function public.is_admin() to anon, authenticated;
grant execute on function public.owns_seller(uuid) to anon, authenticated;
grant execute on function public.is_approved_seller(uuid) to anon, authenticated;
grant execute on function public.owns_product(uuid) to authenticated;
grant execute on function public.owns_cart(uuid) to authenticated;
grant execute on function public.is_order_buyer(uuid) to authenticated;
grant execute on function public.can_access_order(uuid) to authenticated;
grant execute on function public.is_chat_participant(uuid) to authenticated;
grant execute on function public.is_chat_participant_path(text) to authenticated;
grant execute on function public.chat_is_open(uuid) to authenticated;
grant execute on function public.can_review_order_item(
  uuid, uuid, uuid, public.review_kind
) to authenticated;

-- ---------------------------------------------------------------------------
-- Storage buckets and path-scoped object policies
--
-- product-images: <seller_id>/<product_id>/<uuid>.webp
-- avatars:        <user_id>/<uuid>.webp
-- chat-media:     <chat_id>/<uuid>.<allowed extension>
-- ---------------------------------------------------------------------------

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values
  (
    'product-images',
    'product-images',
    false,
    10485760,
    array['image/webp']::text[]
  ),
  (
    'avatars',
    'avatars',
    true,
    5242880,
    array['image/webp']::text[]
  ),
  (
    'chat-media',
    'chat-media',
    false,
    10485760,
    array['image/webp', 'image/jpeg', 'image/png']::text[]
  )
on conflict (id) do update set
  name = excluded.name,
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists product_images_storage_select on storage.objects;
create policy product_images_storage_select
  on storage.objects for select to anon, authenticated
  using (
    bucket_id = 'product-images'
    and exists (
      select 1
      from public.products as product
      where product.id::text = (storage.foldername(name))[2]
        and product.seller_id::text = (storage.foldername(name))[1]
        and (
          (
            product.status = 'active'
            and public.is_approved_seller(product.seller_id)
          )
          or public.owns_seller(product.seller_id)
          or public.is_admin()
        )
    )
  );

drop policy if exists product_images_storage_insert on storage.objects;
create policy product_images_storage_insert
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'product-images'
    and array_length(storage.foldername(name), 1) >= 3
    and exists (
      select 1
      from public.products as product
      where product.id::text = (storage.foldername(name))[2]
        and product.seller_id::text = (storage.foldername(name))[1]
        and (public.owns_seller(product.seller_id) or public.is_admin())
    )
  );

drop policy if exists product_images_storage_update on storage.objects;
create policy product_images_storage_update
  on storage.objects for update to authenticated
  using (
    bucket_id = 'product-images'
    and exists (
      select 1
      from public.products as product
      where product.id::text = (storage.foldername(name))[2]
        and product.seller_id::text = (storage.foldername(name))[1]
        and (public.owns_seller(product.seller_id) or public.is_admin())
    )
  )
  with check (
    bucket_id = 'product-images'
    and exists (
      select 1
      from public.products as product
      where product.id::text = (storage.foldername(name))[2]
        and product.seller_id::text = (storage.foldername(name))[1]
        and (public.owns_seller(product.seller_id) or public.is_admin())
    )
  );

drop policy if exists product_images_storage_delete on storage.objects;
create policy product_images_storage_delete
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'product-images'
    and exists (
      select 1
      from public.products as product
      where product.id::text = (storage.foldername(name))[2]
        and product.seller_id::text = (storage.foldername(name))[1]
        and (public.owns_seller(product.seller_id) or public.is_admin())
    )
  );

drop policy if exists avatars_storage_select on storage.objects;
create policy avatars_storage_select
  on storage.objects for select to anon, authenticated
  using (bucket_id = 'avatars');

drop policy if exists avatars_storage_insert on storage.objects;
create policy avatars_storage_insert
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'avatars'
    and (
      (storage.foldername(name))[1] = auth.uid()::text
      or public.is_admin()
    )
  );

drop policy if exists avatars_storage_update on storage.objects;
create policy avatars_storage_update
  on storage.objects for update to authenticated
  using (
    bucket_id = 'avatars'
    and (
      (storage.foldername(name))[1] = auth.uid()::text
      or public.is_admin()
    )
  )
  with check (
    bucket_id = 'avatars'
    and (
      (storage.foldername(name))[1] = auth.uid()::text
      or public.is_admin()
    )
  );

drop policy if exists avatars_storage_delete on storage.objects;
create policy avatars_storage_delete
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'avatars'
    and (
      (storage.foldername(name))[1] = auth.uid()::text
      or public.is_admin()
    )
  );

drop policy if exists chat_media_storage_select on storage.objects;
create policy chat_media_storage_select
  on storage.objects for select to authenticated
  using (
    bucket_id = 'chat-media'
    and (
      public.is_chat_participant_path((storage.foldername(name))[1])
      or public.is_admin()
    )
  );

drop policy if exists chat_media_storage_insert on storage.objects;
create policy chat_media_storage_insert
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'chat-media'
    and array_length(storage.foldername(name), 1) >= 2
    and (
      public.is_chat_participant_path((storage.foldername(name))[1])
      or public.is_admin()
    )
  );

drop policy if exists chat_media_storage_update on storage.objects;
create policy chat_media_storage_update
  on storage.objects for update to authenticated
  using (
    bucket_id = 'chat-media'
    and (
      public.is_chat_participant_path((storage.foldername(name))[1])
      or public.is_admin()
    )
  )
  with check (
    bucket_id = 'chat-media'
    and (
      public.is_chat_participant_path((storage.foldername(name))[1])
      or public.is_admin()
    )
  );

drop policy if exists chat_media_storage_delete on storage.objects;
create policy chat_media_storage_delete
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'chat-media'
    and (
      public.is_chat_participant_path((storage.foldername(name))[1])
      or public.is_admin()
    )
  );

commit;
