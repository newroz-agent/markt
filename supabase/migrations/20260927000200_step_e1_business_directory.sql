-- Step E1: business directory schema, policies, verification, and RPC contracts.
begin;

create type public.directory_business_type as enum ('restaurant', 'cafe', 'doctor');
create type public.directory_spoken_language as enum ('kurdish', 'arabic', 'turkish', 'german', 'english');
create type public.directory_cuisine as enum (
  'kurdish', 'syrian', 'turkish', 'arabic', 'persian', 'german',
  'italian', 'mediterranean', 'indian', 'asian', 'international'
);
create type public.directory_doctor_specialty as enum (
  'general_medicine', 'internal_medicine', 'pediatrics', 'gynecology',
  'dermatology', 'orthopedics', 'neurology', 'psychiatry', 'ophthalmology',
  'ent', 'dentistry', 'cardiology', 'urology', 'other'
);
create type public.directory_insurance as enum ('statutory', 'private', 'both');
create type public.review_context as enum ('purchase', 'directory');

create table public.business_directory_profiles (
  seller_id uuid primary key references public.sellers(id) on delete cascade,
  type public.directory_business_type not null,
  description text not null check (char_length(btrim(description)) between 20 and 3000),
  phone text not null check (char_length(btrim(phone)) between 5 and 40),
  website text check (website is null or website ~ '^https://[^[:space:]]+$'),
  cover_image_path text check (
    cover_image_path is null or
    cover_image_path ~ '^[0-9a-f-]{36}/[0-9a-f-]{36}\.(webp|jpg|jpeg|png)$'
  ),
  languages public.directory_spoken_language[] not null check (cardinality(languages) between 1 and 5),
  cuisines public.directory_cuisine[] not null default '{}',
  price_level smallint check (price_level between 1 and 4),
  has_halal boolean not null default false,
  has_vegetarian_options boolean not null default false,
  has_vegan_options boolean not null default false,
  specialty public.directory_doctor_specialty,
  insurance public.directory_insurance,
  is_published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint directory_type_fields check (
    (
      type in ('restaurant', 'cafe')
      and specialty is null and insurance is null
      and cardinality(cuisines) >= 1 and price_level is not null
    ) or (
      type = 'doctor'
      and specialty is not null and insurance is not null
      and cardinality(cuisines) = 0 and price_level is null
      and not has_halal and not has_vegetarian_options and not has_vegan_options
    )
  )
);

create table public.business_directory_hours (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.business_directory_profiles(seller_id) on delete cascade,
  weekday smallint not null check (weekday between 0 and 6),
  opens_at time not null,
  closes_at time not null,
  sort_order smallint not null default 0 check (sort_order between 0 and 20),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (seller_id, weekday, opens_at, closes_at),
  check (opens_at <> closes_at)
);

create index business_directory_hours_lookup_idx
  on public.business_directory_hours(seller_id, weekday, opens_at);

create table public.business_directory_menu_sections (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.business_directory_profiles(seller_id) on delete cascade,
  name text not null check (char_length(btrim(name)) between 1 and 120),
  sort_order integer not null default 0 check (sort_order between 0 and 10000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (seller_id, id)
);

create table public.business_directory_menu_items (
  id uuid primary key default gen_random_uuid(),
  section_id uuid not null,
  seller_id uuid not null references public.business_directory_profiles(seller_id) on delete cascade,
  name text not null check (char_length(btrim(name)) between 1 and 160),
  description text check (description is null or char_length(btrim(description)) between 1 and 1000),
  price_cents bigint not null check (price_cents between 0 and 100000000),
  is_available boolean not null default true,
  is_halal boolean not null default false,
  is_vegetarian boolean not null default false,
  is_vegan boolean not null default false,
  sort_order integer not null default 0 check (sort_order between 0 and 10000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (seller_id, section_id)
    references public.business_directory_menu_sections(seller_id, id) on delete cascade,
  check (not is_vegan or is_vegetarian)
);

create index business_directory_menu_sections_order_idx
  on public.business_directory_menu_sections(seller_id, sort_order, id);
create index business_directory_menu_items_order_idx
  on public.business_directory_menu_items(section_id, sort_order, id);

alter table public.reviews add column context public.review_context not null default 'purchase';
alter table public.reviews alter column order_item_id drop not null;
alter table public.reviews drop constraint reviews_kind_target;
alter table public.reviews add constraint reviews_context_target check (
  (
    context = 'purchase' and order_item_id is not null
    and ((kind = 'product' and product_id is not null) or (kind = 'seller' and product_id is null))
  ) or (
    context = 'directory' and order_item_id is null and kind = 'seller'
    and product_id is null and not verified_purchase and cardinality(photo_paths) = 0
  )
);
create unique index reviews_one_directory_review_per_user
  on public.reviews(reviewer_id, seller_id) where context = 'directory';

create function public.is_directory_owner(target_seller_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.sellers seller
    where seller.id = target_seller_id and seller.user_id = auth.uid()
      and seller.kind = 'business'
  );
$$;

create function public.directory_is_open(
  target_seller_id uuid,
  at_time timestamptz default now()
) returns boolean language sql stable security definer set search_path = '' as $$
  with local_clock as (
    select at_time at time zone 'Europe/Berlin' as value
  ), parts as (
    select value::time as local_time, (extract(isodow from value)::integer % 7) as weekday
    from local_clock
  )
  select exists (
    select 1
    from public.business_directory_hours hours cross join parts
    where hours.seller_id = target_seller_id and (
      (hours.opens_at < hours.closes_at and hours.weekday = parts.weekday
        and parts.local_time >= hours.opens_at and parts.local_time < hours.closes_at)
      or (hours.opens_at > hours.closes_at and hours.weekday = parts.weekday
        and parts.local_time >= hours.opens_at)
      or (hours.opens_at > hours.closes_at and hours.weekday = ((parts.weekday + 6) % 7)
        and parts.local_time < hours.closes_at)
    )
  );
$$;

create function public.validate_directory_profile_write()
returns trigger language plpgsql set search_path = '' as $$
declare seller_row public.sellers%rowtype;
begin
  select * into seller_row from public.sellers where id = new.seller_id;
  if not found or seller_row.kind <> 'business' then
    raise exception 'Directory profiles require a business seller' using errcode = '23514';
  end if;
  if tg_op = 'UPDATE' and new.seller_id is distinct from old.seller_id then
    raise exception 'Directory profile ownership is immutable' using errcode = '22023';
  end if;
  if tg_op = 'UPDATE' and new.type = 'doctor' and old.type <> 'doctor' and (
    exists (select 1 from public.business_directory_menu_sections where seller_id = new.seller_id)
    or exists (select 1 from public.reviews where seller_id = new.seller_id and context = 'directory')
  ) then
    raise exception 'Remove menu and directory reviews before changing to doctor' using errcode = '23514';
  end if;
  return new;
end;
$$;

create trigger validate_directory_profile_write
  before insert or update on public.business_directory_profiles
  for each row execute function public.validate_directory_profile_write();

create function public.validate_directory_menu_write()
returns trigger language plpgsql set search_path = '' as $$
begin
  if not exists (
    select 1 from public.business_directory_profiles profile
    where profile.seller_id = new.seller_id and profile.type in ('restaurant', 'cafe')
  ) then
    raise exception 'Menus are only available to restaurants and cafes' using errcode = '23514';
  end if;
  return new;
end;
$$;
create trigger validate_directory_menu_section_write before insert or update
  on public.business_directory_menu_sections for each row execute function public.validate_directory_menu_write();
create trigger validate_directory_menu_item_write before insert or update
  on public.business_directory_menu_items for each row execute function public.validate_directory_menu_write();

create or replace function public.is_verified_seller(target_seller_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.sellers seller
    where seller.id = target_seller_id
      and seller.kind = 'business' and seller.status = 'approved'
      and exists (
        select 1 from public.seller_documents document
        where document.seller_id = seller.id and document.kind = 'identity'
          and document.status = 'approved'
      )
      and (
        (
          exists (
            select 1 from public.business_directory_profiles profile
            where profile.seller_id = seller.id and profile.type = 'doctor'
          )
          and exists (
            select 1 from public.seller_documents document
            where document.seller_id = seller.id
              and document.kind = 'medical_professional_registration'
              and document.status = 'approved'
          )
        ) or (
          not exists (
            select 1 from public.business_directory_profiles profile
            where profile.seller_id = seller.id and profile.type = 'doctor'
          )
          and exists (
            select 1 from public.seller_documents document
            where document.seller_id = seller.id and document.kind = 'business_registration'
              and document.status = 'approved'
          )
        )
      )
  );
$$;

create or replace function public.protect_review_fields()
returns trigger language plpgsql set search_path = '' as $$
begin
  if auth.uid() is null or public.is_admin() then return new; end if;
  if tg_op = 'INSERT' then
    new.reviewer_id = auth.uid();
    new.status = 'published';
    new.verified_purchase = new.context = 'purchase';
  elsif new.kind is distinct from old.kind
    or new.context is distinct from old.context
    or new.product_id is distinct from old.product_id
    or new.seller_id is distinct from old.seller_id
    or new.order_item_id is distinct from old.order_item_id
    or new.reviewer_id is distinct from old.reviewer_id
    or new.verified_purchase is distinct from old.verified_purchase
    or (
      new.status is distinct from old.status and not (
        new.context = 'directory'
        and old.status in ('published', 'hidden')
        and new.status in ('published', 'hidden')
      )
    ) then
    raise exception 'Review ownership and moderation fields are immutable';
  end if;
  return new;
end;
$$;

create function public.validate_directory_review_write()
returns trigger language plpgsql set search_path = '' as $$
begin
  if new.context = 'directory' then
    if not exists (
      select 1 from public.business_directory_profiles profile
      where profile.seller_id = new.seller_id and profile.type in ('restaurant', 'cafe')
        and profile.is_published and public.is_verified_seller(profile.seller_id)
    ) then raise exception 'Directory reviews are only available for restaurants and cafes' using errcode='23514'; end if;
    if exists (
      select 1 from public.sellers seller
      where seller.id = new.seller_id and seller.user_id = new.reviewer_id
    ) then raise exception 'Owners cannot review their own business' using errcode='23514'; end if;
  end if;
  return new;
end;
$$;
create trigger validate_directory_review_write before insert or update
  on public.reviews for each row execute function public.validate_directory_review_write();

create or replace function public.recalculate_review_aggregates(target_product_id uuid, target_seller_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare prior_claims text := current_setting('request.jwt.claims', true);
begin
  -- Aggregate columns are server-managed. Suppress the caller identity while the
  -- security-definer function performs only its deterministic aggregate updates.
  perform set_config('request.jwt.claims','{}',true);
  if target_product_id is not null then
    update public.products product set
      rating_average = aggregate.average_rating, rating_count = aggregate.review_count
    from (select coalesce(round(avg(rating)::numeric,2),0) average_rating,
                 count(*)::integer review_count from public.reviews
          where product_id=target_product_id and kind='product' and status='published') aggregate
    where product.id=target_product_id;
  end if;
  if target_seller_id is not null then
    perform pg_advisory_xact_lock(hashtext(target_seller_id::text));
    update public.sellers seller set
      rating_average = aggregate.average_rating, rating_count = aggregate.review_count
    from (select coalesce(round(avg(rating)::numeric,2),0) average_rating,
                 count(*)::integer review_count from public.reviews
          where seller_id=target_seller_id and kind='seller' and status='published') aggregate
    where seller.id=target_seller_id;
  end if;
  perform set_config('request.jwt.claims',coalesce(prior_claims,'{}'),true);
end;
$$;

drop policy reviews_select_visible on public.reviews;
create policy reviews_select_visible on public.reviews for select to anon, authenticated using (
  reviewer_id = auth.uid() or public.is_admin() or (
    status='published' and (
      context='purchase' or exists (
        select 1 from public.business_directory_profiles profile
        where profile.seller_id=reviews.seller_id and profile.is_published
          and profile.type in ('restaurant','cafe') and public.is_verified_seller(profile.seller_id)
      )
    )
  )
);
drop policy reviews_insert_verified_purchase on public.reviews;
create policy reviews_insert_allowed on public.reviews for insert to authenticated with check (
  public.is_admin() or (
    reviewer_id=auth.uid() and status='published' and (
      (context='purchase' and verified_purchase and public.can_review_order_item(order_item_id,product_id,seller_id,kind))
      or (context='directory' and not verified_purchase and order_item_id is null)
    )
  )
);
drop policy reviews_update_own on public.reviews;
create policy reviews_update_own on public.reviews for update to authenticated
  using (reviewer_id=auth.uid() or public.is_admin()) with check (
    public.is_admin() or (reviewer_id=auth.uid() and (
      (context='purchase' and public.can_review_order_item(order_item_id,product_id,seller_id,kind))
      or context='directory'
    ))
  );
drop policy reviews_delete_own on public.reviews;

alter table public.business_directory_profiles enable row level security;
alter table public.business_directory_hours enable row level security;
alter table public.business_directory_menu_sections enable row level security;
alter table public.business_directory_menu_items enable row level security;

create policy directory_profiles_select on public.business_directory_profiles for select to anon, authenticated using (
  public.is_directory_owner(seller_id) or public.is_admin()
  or (is_published and public.is_verified_seller(seller_id))
);
create policy directory_profiles_owner_write on public.business_directory_profiles for all to authenticated
  using (public.is_directory_owner(seller_id) or public.is_admin())
  with check (public.is_directory_owner(seller_id) or public.is_admin());
create policy directory_hours_select on public.business_directory_hours for select to anon, authenticated using (
  public.is_directory_owner(seller_id) or public.is_admin() or exists (
    select 1 from public.business_directory_profiles profile where profile.seller_id=business_directory_hours.seller_id
      and profile.is_published and public.is_verified_seller(profile.seller_id)
  )
);
create policy directory_hours_owner_write on public.business_directory_hours for all to authenticated
  using (public.is_directory_owner(seller_id) or public.is_admin()) with check (public.is_directory_owner(seller_id) or public.is_admin());
create policy directory_sections_select on public.business_directory_menu_sections for select to anon, authenticated using (
  public.is_directory_owner(seller_id) or public.is_admin() or exists (
    select 1 from public.business_directory_profiles profile where profile.seller_id=business_directory_menu_sections.seller_id
      and profile.is_published and public.is_verified_seller(profile.seller_id)
  )
);
create policy directory_sections_owner_write on public.business_directory_menu_sections for all to authenticated
  using (public.is_directory_owner(seller_id) or public.is_admin()) with check (public.is_directory_owner(seller_id) or public.is_admin());
create policy directory_items_select on public.business_directory_menu_items for select to anon, authenticated using (
  public.is_directory_owner(seller_id) or public.is_admin() or exists (
    select 1 from public.business_directory_profiles profile where profile.seller_id=business_directory_menu_items.seller_id
      and profile.is_published and public.is_verified_seller(profile.seller_id)
  )
);
create policy directory_items_owner_write on public.business_directory_menu_items for all to authenticated
  using (public.is_directory_owner(seller_id) or public.is_admin()) with check (public.is_directory_owner(seller_id) or public.is_admin());

grant select on public.business_directory_profiles,
  public.business_directory_hours,
  public.business_directory_menu_sections,
  public.business_directory_menu_items to anon;
grant select,insert,update,delete on public.business_directory_profiles,
  public.business_directory_hours,
  public.business_directory_menu_sections,
  public.business_directory_menu_items to authenticated;

create function public.owner_upsert_directory_profile(
  p_type public.directory_business_type, p_description text, p_phone text,
  p_website text, p_cover_image_path text, p_languages public.directory_spoken_language[],
  p_cuisines public.directory_cuisine[] default '{}', p_price_level smallint default null,
  p_has_halal boolean default false, p_has_vegetarian_options boolean default false,
  p_has_vegan_options boolean default false, p_specialty public.directory_doctor_specialty default null,
  p_insurance public.directory_insurance default null, p_is_published boolean default false
) returns jsonb language plpgsql security definer set search_path='' as $$
declare target_seller uuid; result public.business_directory_profiles%rowtype;
begin
  select id into target_seller from public.sellers where user_id=auth.uid() and kind='business';
  if target_seller is null then raise exception 'Business seller required' using errcode='42501'; end if;
  insert into public.business_directory_profiles(
    seller_id,type,description,phone,website,cover_image_path,languages,cuisines,price_level,
    has_halal,has_vegetarian_options,has_vegan_options,specialty,insurance,is_published
  ) values (
    target_seller,p_type,btrim(p_description),btrim(p_phone),nullif(btrim(p_website),''),p_cover_image_path,
    p_languages,coalesce(p_cuisines,'{}'),p_price_level,coalesce(p_has_halal,false),
    coalesce(p_has_vegetarian_options,false),coalesce(p_has_vegan_options,false),p_specialty,p_insurance,coalesce(p_is_published,false)
  ) on conflict(seller_id) do update set
    type=excluded.type,description=excluded.description,phone=excluded.phone,website=excluded.website,
    cover_image_path=excluded.cover_image_path,languages=excluded.languages,cuisines=excluded.cuisines,
    price_level=excluded.price_level,has_halal=excluded.has_halal,
    has_vegetarian_options=excluded.has_vegetarian_options,has_vegan_options=excluded.has_vegan_options,
    specialty=excluded.specialty,insurance=excluded.insurance,is_published=excluded.is_published,updated_at=now()
  returning * into result;
  return to_jsonb(result);
end; $$;

create function public.owner_replace_directory_hours(p_intervals jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare target_seller uuid; item jsonb; result jsonb;
begin
  select profile.seller_id into target_seller from public.business_directory_profiles profile
    join public.sellers seller on seller.id=profile.seller_id where seller.user_id=auth.uid();
  if target_seller is null then raise exception 'Directory profile required' using errcode='42501'; end if;
  if jsonb_typeof(coalesce(p_intervals,'[]')) <> 'array' or jsonb_array_length(coalesce(p_intervals,'[]')) > 42 then
    raise exception 'Hours must be an array of at most 42 intervals' using errcode='22023'; end if;
  delete from public.business_directory_hours where seller_id=target_seller;
  for item in select value from jsonb_array_elements(coalesce(p_intervals,'[]')) loop
    insert into public.business_directory_hours(seller_id,weekday,opens_at,closes_at,sort_order)
    values(target_seller,(item->>'weekday')::smallint,(item->>'opens_at')::time,(item->>'closes_at')::time,coalesce((item->>'sort_order')::smallint,0));
  end loop;
  select coalesce(jsonb_agg(to_jsonb(hours) order by weekday,sort_order,opens_at),'[]') into result
    from public.business_directory_hours hours where seller_id=target_seller;
  return result;
end; $$;

create function public.owner_replace_directory_menu(p_sections jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare target_seller uuid; section jsonb; item jsonb; section_id uuid; result jsonb;
begin
  select profile.seller_id into target_seller from public.business_directory_profiles profile
    join public.sellers seller on seller.id=profile.seller_id
    where seller.user_id=auth.uid() and profile.type in ('restaurant','cafe');
  if target_seller is null then raise exception 'Restaurant or cafe profile required' using errcode='23514'; end if;
  if jsonb_typeof(coalesce(p_sections,'[]')) <> 'array' or jsonb_array_length(coalesce(p_sections,'[]')) > 50 then
    raise exception 'Menu must be an array of at most 50 sections' using errcode='22023'; end if;
  delete from public.business_directory_menu_sections where seller_id=target_seller;
  for section in select value from jsonb_array_elements(coalesce(p_sections,'[]')) loop
    insert into public.business_directory_menu_sections(seller_id,name,sort_order)
      values(target_seller,btrim(section->>'name'),coalesce((section->>'sort_order')::integer,0)) returning id into section_id;
    if jsonb_typeof(coalesce(section->'items','[]')) <> 'array' or jsonb_array_length(coalesce(section->'items','[]')) > 200 then
      raise exception 'Menu section items must be an array of at most 200 items' using errcode='22023'; end if;
    for item in select value from jsonb_array_elements(coalesce(section->'items','[]')) loop
      insert into public.business_directory_menu_items(
        section_id,seller_id,name,description,price_cents,is_available,is_halal,is_vegetarian,is_vegan,sort_order
      ) values(section_id,target_seller,btrim(item->>'name'),nullif(btrim(item->>'description'),''),(item->>'price_cents')::bigint,
        coalesce((item->>'is_available')::boolean,true),coalesce((item->>'is_halal')::boolean,false),
        coalesce((item->>'is_vegetarian')::boolean,false),coalesce((item->>'is_vegan')::boolean,false),
        coalesce((item->>'sort_order')::integer,0));
    end loop;
  end loop;
  select coalesce(jsonb_agg(jsonb_build_object('id',s.id,'name',s.name,'sort_order',s.sort_order,
    'items',(select coalesce(jsonb_agg(to_jsonb(i) order by i.sort_order,i.id),'[]') from public.business_directory_menu_items i where i.section_id=s.id)) order by s.sort_order,s.id),'[]')
    into result from public.business_directory_menu_sections s where s.seller_id=target_seller;
  return result;
end; $$;

create function public.upsert_directory_review(p_seller_id uuid,p_rating smallint,p_body text default null)
returns jsonb language plpgsql security definer set search_path='' as $$
declare result public.reviews%rowtype;
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode='42501'; end if;
  insert into public.reviews(kind,context,seller_id,reviewer_id,rating,body,verified_purchase,status)
    values('seller','directory',p_seller_id,auth.uid(),p_rating,nullif(btrim(p_body),''),false,'published')
  on conflict(reviewer_id,seller_id) where context='directory' do update
    set rating=excluded.rating,body=excluded.body,status='published',updated_at=now()
  returning * into result;
  return jsonb_build_object('id',result.id,'rating',result.rating,'body',result.body,'updated_at',result.updated_at);
end; $$;

create function public.delete_directory_review(p_seller_id uuid)
returns boolean language plpgsql security definer set search_path='' as $$
declare changed integer;
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode='42501'; end if;
  update public.reviews set status='hidden',updated_at=now()
    where seller_id=p_seller_id and reviewer_id=auth.uid() and context='directory' and status <> 'hidden';
  get diagnostics changed = row_count;
  return changed > 0;
end; $$;

create function public.search_business_directory(
  p_type public.directory_business_type default null, p_center_lat numeric default null,
  p_center_lng numeric default null, p_radius_km numeric default null,
  p_cuisine public.directory_cuisine default null, p_price_level smallint default null,
  p_min_rating numeric default null, p_open_now boolean default null,
  p_language public.directory_spoken_language default null,
  p_limit integer default 20, p_offset integer default 0
) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare result jsonb; bounded_limit integer:=least(greatest(coalesce(p_limit,20),1),100); bounded_offset integer:=greatest(coalesce(p_offset,0),0);
begin
  if (p_center_lat is null) <> (p_center_lng is null) or (p_radius_km is not null and p_center_lat is null)
    or p_center_lat not between -90 and 90 or p_center_lng not between -180 and 180
    or (p_radius_km is not null and p_radius_km not between 0.1 and 500)
    then raise exception 'Valid center and radius required' using errcode='22023'; end if;
  if p_type='doctor' and p_min_rating is not null then raise exception 'Doctors cannot be filtered by rating' using errcode='22023'; end if;
  if p_min_rating is not null and p_min_rating not between 1 and 5 then raise exception 'Minimum rating must be 1-5' using errcode='22023'; end if;
  with candidates as (
    select profile.seller_id,seller.shop_name,seller.city,profile.type,profile.description,profile.phone,profile.website,
      profile.cover_image_path,profile.languages,profile.cuisines,profile.price_level,profile.has_halal,
      profile.has_vegetarian_options,profile.has_vegan_options,profile.specialty,profile.insurance,
      case when profile.type='doctor' then null else seller.rating_average end rating_average,
      case when profile.type='doctor' then null else seller.rating_count end rating_count,
      public.directory_is_open(profile.seller_id,now()) is_open_now,
      case when p_center_lat is null or not seller.precise_location_opt_in then null
        else public.marketplace_distance_km(p_center_lat,p_center_lng,seller.latitude,seller.longitude) end distance_km,
      case when seller.precise_location_opt_in then seller.latitude end latitude,
      case when seller.precise_location_opt_in then seller.longitude end longitude,
      case when seller.precise_location_opt_in then seller.address_line end address
    from public.business_directory_profiles profile join public.sellers seller on seller.id=profile.seller_id
    where profile.is_published and public.is_verified_seller(profile.seller_id)
      and (p_type is null or profile.type=p_type) and (p_cuisine is null or p_cuisine=any(profile.cuisines))
      and (p_price_level is null or profile.price_level=p_price_level)
      and (p_min_rating is null or (profile.type <> 'doctor' and seller.rating_average >= p_min_rating))
      and (p_open_now is null or public.directory_is_open(profile.seller_id,now())=p_open_now)
      and (p_language is null or p_language=any(profile.languages))
  ), filtered as (select * from candidates where p_radius_km is null or distance_km <= p_radius_km),
  paged as (select *,count(*) over() total_count from filtered order by distance_km nulls last,shop_name,seller_id limit bounded_limit offset bounded_offset)
  select jsonb_build_object('items',coalesce(jsonb_agg(to_jsonb(paged)),'[]'),'total_count',coalesce(max(total_count),0)) into result from paged;
  return result;
end; $$;

create function public.get_business_directory_detail(p_seller_id uuid)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare result jsonb;
begin
  select jsonb_build_object(
    'seller_id',profile.seller_id,'name',seller.shop_name,'city',seller.city,'type',profile.type,
    'description',profile.description,'phone',profile.phone,'website',profile.website,'cover_image_path',profile.cover_image_path,
    'languages',profile.languages,'cuisines',profile.cuisines,'price_level',profile.price_level,
    'has_halal',profile.has_halal,'has_vegetarian_options',profile.has_vegetarian_options,'has_vegan_options',profile.has_vegan_options,
    'specialty',profile.specialty,'insurance',profile.insurance,'open_now',public.directory_is_open(profile.seller_id,now()),
    'rating_average',case when profile.type='doctor' then null else seller.rating_average end,
    'rating_count',case when profile.type='doctor' then null else seller.rating_count end,
    'latitude',case when seller.precise_location_opt_in then seller.latitude end,
    'longitude',case when seller.precise_location_opt_in then seller.longitude end,
    'address',case when seller.precise_location_opt_in then seller.address_line end,
    'hours',(select coalesce(jsonb_agg(to_jsonb(h) order by h.weekday,h.sort_order,h.opens_at),'[]') from public.business_directory_hours h where h.seller_id=profile.seller_id),
    'menu',case when profile.type='doctor' then '[]'::jsonb else (select coalesce(jsonb_agg(jsonb_build_object('id',s.id,'name',s.name,'sort_order',s.sort_order,
      'items',(select coalesce(jsonb_agg(to_jsonb(i) order by i.sort_order,i.id),'[]') from public.business_directory_menu_items i where i.section_id=s.id)) order by s.sort_order,s.id),'[]') from public.business_directory_menu_sections s where s.seller_id=profile.seller_id) end
  ) into result
  from public.business_directory_profiles profile join public.sellers seller on seller.id=profile.seller_id
  where profile.seller_id=p_seller_id and profile.is_published and public.is_verified_seller(profile.seller_id);
  return result;
end; $$;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('directory-covers','directory-covers',true,8388608,array['image/webp','image/jpeg','image/png'])
on conflict(id) do update set public=true,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;
create policy directory_covers_insert on storage.objects for insert to authenticated with check (
  bucket_id='directory-covers' and exists(select 1 from public.sellers seller where seller.id::text=(storage.foldername(name))[1] and seller.user_id=auth.uid())
);
create policy directory_covers_update on storage.objects for update to authenticated using (
  bucket_id='directory-covers' and exists(select 1 from public.sellers seller where seller.id::text=(storage.foldername(name))[1] and seller.user_id=auth.uid())
) with check (
  bucket_id='directory-covers' and exists(select 1 from public.sellers seller where seller.id::text=(storage.foldername(name))[1] and seller.user_id=auth.uid())
);
create policy directory_covers_delete on storage.objects for delete to authenticated using (
  bucket_id='directory-covers' and exists(select 1 from public.sellers seller where seller.id::text=(storage.foldername(name))[1] and seller.user_id=auth.uid())
);

create trigger set_updated_at before update on public.business_directory_profiles for each row execute function public.set_updated_at();
create trigger set_updated_at before update on public.business_directory_hours for each row execute function public.set_updated_at();
create trigger set_updated_at before update on public.business_directory_menu_sections for each row execute function public.set_updated_at();
create trigger set_updated_at before update on public.business_directory_menu_items for each row execute function public.set_updated_at();

revoke all on function public.is_directory_owner(uuid) from public,anon,authenticated;
grant execute on function public.is_directory_owner(uuid) to anon,authenticated;
revoke all on function public.directory_is_open(uuid,timestamptz) from public;
grant execute on function public.directory_is_open(uuid,timestamptz) to anon,authenticated;
revoke all on function public.owner_upsert_directory_profile(public.directory_business_type,text,text,text,text,public.directory_spoken_language[],public.directory_cuisine[],smallint,boolean,boolean,boolean,public.directory_doctor_specialty,public.directory_insurance,boolean) from public,anon;
grant execute on function public.owner_upsert_directory_profile(public.directory_business_type,text,text,text,text,public.directory_spoken_language[],public.directory_cuisine[],smallint,boolean,boolean,boolean,public.directory_doctor_specialty,public.directory_insurance,boolean) to authenticated;
revoke all on function public.owner_replace_directory_hours(jsonb) from public,anon;
grant execute on function public.owner_replace_directory_hours(jsonb) to authenticated;
revoke all on function public.owner_replace_directory_menu(jsonb) from public,anon;
grant execute on function public.owner_replace_directory_menu(jsonb) to authenticated;
revoke all on function public.upsert_directory_review(uuid,smallint,text) from public,anon;
grant execute on function public.upsert_directory_review(uuid,smallint,text) to authenticated;
revoke all on function public.delete_directory_review(uuid) from public,anon;
grant execute on function public.delete_directory_review(uuid) to authenticated;
revoke all on function public.search_business_directory(public.directory_business_type,numeric,numeric,numeric,public.directory_cuisine,smallint,numeric,boolean,public.directory_spoken_language,integer,integer) from public;
grant execute on function public.search_business_directory(public.directory_business_type,numeric,numeric,numeric,public.directory_cuisine,smallint,numeric,boolean,public.directory_spoken_language,integer,integer) to anon,authenticated;
revoke all on function public.get_business_directory_detail(uuid) from public;
grant execute on function public.get_business_directory_detail(uuid) to anon,authenticated;

notify pgrst,'reload schema';
commit;
