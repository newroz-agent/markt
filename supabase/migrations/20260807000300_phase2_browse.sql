-- Phase 2: browse, search, suggestions, and server-backed user history.
-- Guest history remains client-side; authenticated history is capped by RPCs.

begin;

create extension if not exists pg_trgm with schema extensions;

create table public.recent_product_views (
  user_id uuid not null references auth.users (id) on delete cascade,
  product_id uuid not null references public.products (id) on delete cascade,
  first_viewed_at timestamptz not null default now(),
  last_viewed_at timestamptz not null default now(),
  view_count integer not null default 1 check (view_count > 0),
  primary key (user_id, product_id)
);

create index recent_product_views_user_activity_idx
  on public.recent_product_views (user_id, last_viewed_at desc);

create table public.search_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  query text not null check (char_length(query) between 2 and 120),
  created_at timestamptz not null default now()
);

create unique index search_history_user_normalized_query_idx
  on public.search_history (user_id, lower(query));
create index search_history_user_created_idx
  on public.search_history (user_id, created_at desc);

create index products_title_trigram_idx
  on public.products using gin (lower(title) extensions.gin_trgm_ops)
  where status = 'active';
create index products_location_idx
  on public.products (latitude, longitude)
  where latitude is not null and longitude is not null;
create index products_home_newest_idx
  on public.products (published_at desc, id)
  where status = 'active';
create index products_home_rating_idx
  on public.products (rating_average desc, rating_count desc, published_at desc)
  where status = 'active';
create index products_discount_idx
  on public.products (published_at desc)
  where status = 'active' and compare_at_price_cents is not null;

create function public.marketplace_distance_km(
  latitude_one numeric,
  longitude_one numeric,
  latitude_two numeric,
  longitude_two numeric
)
returns double precision
language sql
immutable
parallel safe
set search_path = ''
as $$
  select case
    when latitude_one is null
      or longitude_one is null
      or latitude_two is null
      or longitude_two is null then null
    else 6371.0088 * pg_catalog.acos(
      least(
        1.0,
        greatest(
          -1.0,
          pg_catalog.sin(pg_catalog.radians(latitude_one::double precision))
            * pg_catalog.sin(pg_catalog.radians(latitude_two::double precision))
          + pg_catalog.cos(pg_catalog.radians(latitude_one::double precision))
            * pg_catalog.cos(pg_catalog.radians(latitude_two::double precision))
            * pg_catalog.cos(
              pg_catalog.radians(
                (longitude_two - longitude_one)::double precision
              )
            )
        )
      )
    )
  end;
$$;

create function public.search_marketplace_products(
  p_query text default null,
  p_category_id uuid default null,
  p_brand_id uuid default null,
  p_condition public.product_condition default null,
  p_seller_kind public.seller_kind default null,
  p_min_price_cents bigint default null,
  p_max_price_cents bigint default null,
  p_latitude numeric default null,
  p_longitude numeric default null,
  p_radius_km numeric default null,
  p_sort text default 'relevance',
  p_limit integer default 24,
  p_offset integer default 0
)
returns table (
  product_id uuid,
  product_slug text,
  title text,
  price_cents bigint,
  compare_at_price_cents bigint,
  currency text,
  vat_rate numeric,
  product_condition public.product_condition,
  free_shipping boolean,
  shipping_cost_cents bigint,
  rating_average numeric,
  rating_count integer,
  city text,
  published_at timestamptz,
  seller_id uuid,
  seller_name text,
  seller_kind public.seller_kind,
  category_id uuid,
  brand_id uuid,
  primary_image_path text,
  distance_km double precision,
  relevance real,
  total_count bigint
)
language plpgsql
stable
security invoker
set search_path = ''
as $$
declare
  normalized_query text := nullif(pg_catalog.btrim(p_query), '');
  normalized_sort text := coalesce(nullif(pg_catalog.btrim(p_sort), ''), 'relevance');
  bounded_limit integer := least(greatest(coalesce(p_limit, 24), 1), 100);
  bounded_offset integer := greatest(coalesce(p_offset, 0), 0);
begin
  if normalized_sort not in (
    'relevance',
    'price_asc',
    'price_desc',
    'newest',
    'best_rated'
  ) then
    raise exception 'Unsupported product sort: %', normalized_sort
      using errcode = '22023';
  end if;

  if p_min_price_cents is not null and p_min_price_cents < 0 then
    raise exception 'Minimum price cannot be negative' using errcode = '22023';
  end if;

  if p_max_price_cents is not null and p_max_price_cents < 0 then
    raise exception 'Maximum price cannot be negative' using errcode = '22023';
  end if;

  if p_min_price_cents is not null
    and p_max_price_cents is not null
    and p_min_price_cents > p_max_price_cents then
    raise exception 'Minimum price cannot exceed maximum price'
      using errcode = '22023';
  end if;

  if p_radius_km is not null then
    if p_radius_km <= 0 or p_radius_km > 500 then
      raise exception 'Radius must be between 0 and 500 kilometres'
        using errcode = '22023';
    end if;

    if p_latitude is null or p_longitude is null then
      raise exception 'Coordinates are required when a radius is supplied'
        using errcode = '22023';
    end if;
  end if;

  return query
  with search_input as (
    select case
      when normalized_query is null then null::pg_catalog.tsquery
      else pg_catalog.websearch_to_tsquery(
        'pg_catalog.german'::pg_catalog.regconfig,
        normalized_query
      )
    end as query
  ), candidates as (
    select
      product.id as product_id,
      product.slug as product_slug,
      product.title,
      product.price_cents,
      product.compare_at_price_cents,
      product.currency,
      product.vat_rate,
      product.condition as product_condition,
      product.free_shipping,
      product.shipping_cost_cents,
      product.rating_average,
      product.rating_count,
      product.city,
      product.published_at,
      seller.id as seller_id,
      seller.shop_name as seller_name,
      seller.kind as seller_kind,
      product.category_id,
      product.brand_id,
      primary_image.storage_path as primary_image_path,
      public.marketplace_distance_km(
        p_latitude,
        p_longitude,
        product.latitude,
        product.longitude
      ) as distance_km,
      case
        when search_input.query is null then 0::real
        else pg_catalog.ts_rank_cd(product.search_vector, search_input.query)
      end as relevance
    from public.products as product
    join public.sellers as seller on seller.id = product.seller_id
    join public.categories as category on category.id = product.category_id
    cross join search_input
    left join lateral (
      select image.storage_path
      from public.product_images as image
      where image.product_id = product.id
      order by image.sort_order, image.created_at, image.id
      limit 1
    ) as primary_image on true
    where product.status = 'active'
      and product.quantity > 0
      and seller.status = 'approved'
      and category.is_active
      and (
        search_input.query is null
        or product.search_vector @@ search_input.query
      )
      and (
        p_category_id is null
        or product.category_id = p_category_id
        or category.parent_id = p_category_id
      )
      and (p_brand_id is null or product.brand_id = p_brand_id)
      and (p_condition is null or product.condition = p_condition)
      and (p_seller_kind is null or seller.kind = p_seller_kind)
      and (p_min_price_cents is null or product.price_cents >= p_min_price_cents)
      and (p_max_price_cents is null or product.price_cents <= p_max_price_cents)
      and (
        p_radius_km is null
        or public.marketplace_distance_km(
          p_latitude,
          p_longitude,
          product.latitude,
          product.longitude
        ) <= p_radius_km::double precision
      )
  ), counted as (
    select candidates.*, count(*) over () as total_count
    from candidates
  )
  select
    counted.product_id,
    counted.product_slug,
    counted.title,
    counted.price_cents,
    counted.compare_at_price_cents,
    counted.currency,
    counted.vat_rate,
    counted.product_condition,
    counted.free_shipping,
    counted.shipping_cost_cents,
    counted.rating_average,
    counted.rating_count,
    counted.city,
    counted.published_at,
    counted.seller_id,
    counted.seller_name,
    counted.seller_kind,
    counted.category_id,
    counted.brand_id,
    counted.primary_image_path,
    counted.distance_km,
    counted.relevance,
    counted.total_count
  from counted
  order by
    case when normalized_sort = 'relevance' then counted.relevance end desc,
    case when normalized_sort = 'price_asc' then counted.price_cents end asc,
    case when normalized_sort = 'price_desc' then counted.price_cents end desc,
    case when normalized_sort = 'newest' then counted.published_at end desc,
    case when normalized_sort = 'best_rated' then counted.rating_average end desc,
    case when normalized_sort = 'best_rated' then counted.rating_count end desc,
    counted.published_at desc,
    counted.product_id
  limit bounded_limit
  offset bounded_offset;
end;
$$;

create function public.marketplace_search_suggestions(
  p_query text,
  p_limit integer default 8
)
returns table (
  suggestion text,
  suggestion_kind text,
  target_id uuid
)
language sql
stable
security invoker
set search_path = ''
as $$
  with normalized as (
    select nullif(pg_catalog.btrim(p_query), '') as query
  ), suggestions as (
    select
      product.title as suggestion,
      'product'::text as suggestion_kind,
      product.id as target_id,
      extensions.similarity(lower(product.title), lower(normalized.query)) as score,
      product.rating_count as popularity
    from public.products as product
    join public.sellers as seller on seller.id = product.seller_id
    cross join normalized
    where normalized.query is not null
      and char_length(normalized.query) >= 2
      and product.status = 'active'
      and product.quantity > 0
      and seller.status = 'approved'
      and lower(product.title) like '%' || lower(normalized.query) || '%'

    union all

    select
      brand.name,
      'brand'::text,
      brand.id,
      extensions.similarity(lower(brand.name), lower(normalized.query)),
      0
    from public.brands as brand
    cross join normalized
    where normalized.query is not null
      and char_length(normalized.query) >= 2
      and brand.is_active
      and lower(brand.name) like '%' || lower(normalized.query) || '%'

    union all

    select
      category.name_de,
      'category'::text,
      category.id,
      extensions.similarity(lower(category.name_de), lower(normalized.query)),
      0
    from public.categories as category
    cross join normalized
    where normalized.query is not null
      and char_length(normalized.query) >= 2
      and category.is_active
      and lower(category.name_de) like '%' || lower(normalized.query) || '%'
  )
  select distinct on (lower(suggestions.suggestion), suggestions.suggestion_kind)
    suggestions.suggestion,
    suggestions.suggestion_kind,
    suggestions.target_id
  from suggestions
  order by
    lower(suggestions.suggestion),
    suggestions.suggestion_kind,
    suggestions.score desc,
    suggestions.popularity desc
  limit least(greatest(coalesce(p_limit, 8), 1), 20);
$$;

create function public.record_product_view(p_product_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
begin
  if current_user_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  if not exists (
    select 1
    from public.products as product
    where product.id = p_product_id
      and product.status = 'active'
      and public.is_approved_seller(product.seller_id)
  ) then
    raise exception 'Product is not available' using errcode = 'P0002';
  end if;

  insert into public.recent_product_views (
    user_id,
    product_id,
    first_viewed_at,
    last_viewed_at,
    view_count
  )
  values (current_user_id, p_product_id, now(), now(), 1)
  on conflict (user_id, product_id) do update set
    last_viewed_at = excluded.last_viewed_at,
    view_count = public.recent_product_views.view_count + 1;

  delete from public.recent_product_views as product_view
  where product_view.user_id = current_user_id
    and product_view.product_id in (
      select oldest.product_id
      from public.recent_product_views as oldest
      where oldest.user_id = current_user_id
      order by oldest.last_viewed_at desc
      offset 100
    );
end;
$$;

create function public.save_recent_search(p_query text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  normalized_query text := regexp_replace(pg_catalog.btrim(p_query), '\\s+', ' ', 'g');
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

alter table public.recent_product_views enable row level security;
alter table public.search_history enable row level security;

create policy recent_product_views_select_own
  on public.recent_product_views for select to authenticated
  using (user_id = auth.uid() or public.is_admin());
create policy recent_product_views_delete_own
  on public.recent_product_views for delete to authenticated
  using (user_id = auth.uid() or public.is_admin());

create policy search_history_select_own
  on public.search_history for select to authenticated
  using (user_id = auth.uid() or public.is_admin());
create policy search_history_delete_own
  on public.search_history for delete to authenticated
  using (user_id = auth.uid() or public.is_admin());

revoke all on table public.recent_product_views from anon, authenticated;
revoke all on table public.search_history from anon, authenticated;
grant select, delete on table public.recent_product_views to authenticated;
grant select, delete on table public.search_history to authenticated;

revoke all on function public.marketplace_distance_km(numeric, numeric, numeric, numeric)
  from public;
revoke all on function public.search_marketplace_products(
  text,
  uuid,
  uuid,
  public.product_condition,
  public.seller_kind,
  bigint,
  bigint,
  numeric,
  numeric,
  numeric,
  text,
  integer,
  integer
) from public;
revoke all on function public.marketplace_search_suggestions(text, integer)
  from public;
revoke all on function public.record_product_view(uuid) from public;
revoke all on function public.save_recent_search(text) from public;

grant execute on function public.marketplace_distance_km(numeric, numeric, numeric, numeric)
  to anon, authenticated;
grant execute on function public.search_marketplace_products(
  text,
  uuid,
  uuid,
  public.product_condition,
  public.seller_kind,
  bigint,
  bigint,
  numeric,
  numeric,
  numeric,
  text,
  integer,
  integer
) to anon, authenticated;
grant execute on function public.marketplace_search_suggestions(text, integer)
  to anon, authenticated;
grant execute on function public.record_product_view(uuid) to authenticated;
grant execute on function public.save_recent_search(text) to authenticated;

commit;
