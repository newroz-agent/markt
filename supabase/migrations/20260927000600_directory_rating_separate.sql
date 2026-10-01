-- Directory rating decision (2026-09-27): directory and purchase ratings are separate.
-- business_directory_profiles.rating_* aggregates only context='directory' reviews and is
-- what search/detail show; sellers.rating_* aggregates only context='purchase' reviews.
-- Nothing is blended. Checkout was removed, so no new purchase reviews are created.
begin;

alter table public.business_directory_profiles
  add column rating_average numeric not null default 0 check (rating_average between 0 and 5),
  add column rating_count integer not null default 0 check (rating_count >= 0);

create or replace function public.validate_directory_profile_write()
returns trigger language plpgsql set search_path = '' as $$
declare seller_row public.sellers%rowtype;
begin
  select * into seller_row from public.sellers where id = new.seller_id;
  if not found or seller_row.kind <> 'business' then
    raise exception 'Directory profiles require a business seller' using errcode = '23514';
  end if;
  -- The directory rating is server-managed (recalculate_review_aggregates runs without
  -- caller claims); owners and other clients can never set it.
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
  if tg_op = 'UPDATE' and new.type = 'doctor' and old.type <> 'doctor' and (
    exists (select 1 from public.business_directory_menu_sections where seller_id = new.seller_id)
    or exists (select 1 from public.reviews where seller_id = new.seller_id and context = 'directory')
  ) then
    raise exception 'Remove menu and directory reviews before changing to doctor' using errcode = '23514';
  end if;
  return new;
end;
$$;

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
          where seller_id=target_seller_id and kind='seller' and context='purchase'
            and status='published') aggregate
    where seller.id=target_seller_id;
    update public.business_directory_profiles profile set
      rating_average = aggregate.average_rating, rating_count = aggregate.review_count
    from (select coalesce(round(avg(rating)::numeric,2),0) average_rating,
                 count(*)::integer review_count from public.reviews
          where seller_id=target_seller_id and kind='seller' and context='directory'
            and status='published') aggregate
    where profile.seller_id=target_seller_id;
  end if;
  perform set_config('request.jwt.claims',coalesce(prior_claims,'{}'),true);
end;
$$;

create or replace function public.search_business_directory(
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
  with owner_candidates as (
    select profile.seller_id,null::uuid place_id,'owner'::text source,true is_claimed,
      seller.shop_name,seller.city,profile.type,profile.description,profile.phone,profile.website,
      profile.cover_image_path,profile.languages,profile.cuisines,profile.price_level,profile.has_halal,
      profile.has_vegetarian_options,profile.has_vegan_options,profile.specialty,profile.insurance,
      case when profile.type='doctor' then null else profile.rating_average end rating_average,
      case when profile.type='doctor' then null else profile.rating_count end rating_count,
      profile.type <> 'doctor' reviews_enabled,
      public.directory_is_open(profile.seller_id,now()) is_open_now,
      exists(select 1 from public.business_directory_hours h where h.seller_id=profile.seller_id) has_hours,
      case when p_center_lat is null or not seller.precise_location_opt_in then null
        else public.marketplace_distance_km(p_center_lat,p_center_lng,seller.latitude,seller.longitude) end distance_km,
      case when seller.precise_location_opt_in then seller.latitude end latitude,
      case when seller.precise_location_opt_in then seller.longitude end longitude,
      case when seller.precise_location_opt_in then seller.address_line end address
    from public.business_directory_profiles profile join public.sellers seller on seller.id=profile.seller_id
    where profile.is_published and public.is_verified_seller(profile.seller_id)
      and (p_type is null or profile.type=p_type) and (p_cuisine is null or p_cuisine=any(profile.cuisines))
      and (p_price_level is null or profile.price_level=p_price_level)
      and (p_min_rating is null or (profile.type <> 'doctor' and profile.rating_average >= p_min_rating))
      and (p_open_now is null or public.directory_is_open(profile.seller_id,now())=p_open_now)
      and (p_language is null or p_language=any(profile.languages))
  ), imported_candidates as (
    -- OSM carries no rating, price level or spoken languages, so those filters exclude imports.
    select null::uuid seller_id,place.id place_id,place.source,false is_claimed,
      place.name shop_name,place.addr_city city,place.type,null::text description,place.phone,place.website,
      null::text cover_image_path,'{}'::public.directory_spoken_language[] languages,place.cuisines,
      null::smallint price_level,place.has_halal,place.has_vegetarian has_vegetarian_options,
      place.has_vegan has_vegan_options,null::public.directory_doctor_specialty specialty,
      null::public.directory_insurance insurance,null::numeric rating_average,null::integer rating_count,
      false reviews_enabled,
      public.directory_imported_place_is_open(place.id,now()) is_open_now,
      exists(select 1 from public.directory_imported_place_hours h where h.place_id=place.id) has_hours,
      case when p_center_lat is null then null
        else public.marketplace_distance_km(p_center_lat,p_center_lng,place.latitude,place.longitude) end distance_km,
      place.latitude,place.longitude,public.directory_imported_place_address(place) address
    from public.directory_imported_places place
    where place.claimed_seller_id is null and not place.is_hidden
      and (p_type is null or place.type=p_type) and (p_cuisine is null or p_cuisine=any(place.cuisines))
      and p_price_level is null and p_min_rating is null and p_language is null
      and (p_open_now is null or public.directory_imported_place_is_open(place.id,now())=p_open_now)
  ), candidates as (
    select * from owner_candidates union all select * from imported_candidates
  ), filtered as (select * from candidates where p_radius_km is null or distance_km <= p_radius_km),
  paged as (select *,count(*) over() total_count from filtered
    order by distance_km nulls last,shop_name,coalesce(seller_id,place_id) limit bounded_limit offset bounded_offset)
  select jsonb_build_object('items',coalesce(jsonb_agg(to_jsonb(paged)),'[]'),'total_count',coalesce(max(total_count),0)) into result from paged;
  return result;
end; $$;


create or replace function public.get_business_directory_detail(p_seller_id uuid)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare result jsonb;
begin
  select jsonb_build_object(
    'seller_id',profile.seller_id,'place_id',null,'source','owner','is_claimed',true,
    'reviews_enabled',profile.type <> 'doctor',
    'name',seller.shop_name,'city',seller.city,'type',profile.type,
    'description',profile.description,'phone',profile.phone,'website',profile.website,'cover_image_path',profile.cover_image_path,
    'languages',profile.languages,'cuisines',profile.cuisines,'price_level',profile.price_level,
    'has_halal',profile.has_halal,'has_vegetarian_options',profile.has_vegetarian_options,'has_vegan_options',profile.has_vegan_options,
    'specialty',profile.specialty,'insurance',profile.insurance,'open_now',public.directory_is_open(profile.seller_id,now()),
    'rating_average',case when profile.type='doctor' then null else profile.rating_average end,
    'rating_count',case when profile.type='doctor' then null else profile.rating_count end,
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


-- Targeted backfill: only sellers that actually have directory reviews change. Sellers
-- whose ratings were never derived from directory reviews are left untouched.
select public.recalculate_review_aggregates(null, seller_id)
from (select distinct seller_id from public.reviews where context='directory') directory_sellers;

notify pgrst,'reload schema';
commit;
