-- Local-only E3 demo catalog. Run only through tools/demo/e3_local_demo.sh.
-- All created IDs and slugs begin e3d0. Images are Pexels CDN URLs; no Storage
-- objects are uploaded. Each photo's Pexels source page is saved in specifications.
\set ON_ERROR_STOP on
\ir step_e3_demo_local_guard.sql

begin;

-- Never create a second catalog alongside real active listings in these leaves.
do $$
begin
  if exists (
    select 1 from public.products p join public.categories c on c.id = p.category_id
    where p.status = 'active'
      and c.slug in ('anzuege', 'goldschmuck', 'silberschmuck', 'eheringe',
                     'saiteninstrumente', 'schlaginstrumente',
                     'gewuerze-importwaren', 'suesswaren')
      and p.id::text not like 'e3d0%'
  ) then
    raise exception 'Target categories now contain non-E3 active listings; re-audit before seeding';
  end if;
  if exists (select 1 from storage.objects where bucket_id = 'product-images' and name like 'e3d0/%') then
    raise exception 'E3 Storage objects already exist; inspect them before seeding';
  end if;
end;
$$;

-- These accounts are fixtures, not login credentials. Password hashes are random and
-- inaccessible, avoiding another hardcoded fixture password.
insert into auth.users (id, email, encrypted_password, email_confirmed_at, role, aud)
select ('e3d00000-0000-4000-8000-' || lpad(n::text, 12, '0'))::uuid,
       'e3d0-demo-' || n || '@local.invalid',
       crypt(gen_random_uuid()::text, gen_salt('bf')),
       '2026-10-01 12:00:00+00'::timestamptz,
       'authenticated', 'authenticated'
from generate_series(1, 4) as n
on conflict (id) do nothing;

with seller_seed (n, kind, name, slug, city) as (
  values
    (1, 'private', 'Mira Kaya', 'e3d0-mira-kaya', 'Berlin'),
    (2, 'private', 'Baran Demir', 'e3d0-baran-demir', 'Köln'),
    (3, 'business', 'Roj Atelier', 'e3d0-roj-atelier', 'Hamburg'),
    (4, 'business', 'Zagros Feinkost', 'e3d0-zagros-feinkost', 'München')
)
insert into public.sellers (
  id, user_id, kind, status, shop_name, slug, city, country_code,
  accepts_returns, approved_at, bio
)
select ('e3d00000-0000-4000-8001-' || lpad(n::text, 12, '0'))::uuid,
       ('e3d00000-0000-4000-8000-' || lpad(n::text, 12, '0'))::uuid,
       kind::public.seller_kind, 'approved'::public.seller_status,
       name, slug, city, 'DE', true, '2026-10-01 12:00:00+00'::timestamptz,
       'Lokales Zêrîn-Demoprofil für die Kategorie- und Kartenansicht.'
from seller_seed
on conflict (id) do update set
  shop_name = excluded.shop_name, city = excluded.city, country_code = excluded.country_code,
  bio = excluded.bio;

-- One primary image per listing. Photo page URL is kept per image in the product's
-- demo_image_source_url specification; the CDN URL is the displayed image.
create temp table e3_demo_items (
  n integer primary key, seller_n integer not null, category_slug text not null,
  title text not null, description text not null, condition text not null,
  price_cents bigint not null, compare_at_price_cents bigint, city text not null,
  photo_id bigint not null, photo_page text not null
) on commit drop;

insert into e3_demo_items values
  ( 1, 1, 'anzuege', 'Dunkelblauer Herrenanzug, Größe 50', 'Gepflegter zweiteiliger Herrenanzug in Dunkelblau, frisch gereinigt und sofort tragbar.', 'used', 8900, null, 'Berlin', 7955865, 'https://www.pexels.com/photo/man-in-a-suit-jacket-7955865/'),
  ( 2, 3, 'anzuege', 'Schwarzer Business-Anzug, Größe 52', 'Klassischer schwarzer Anzug mit sauberem Schnitt für Büro und besondere Anlässe.', 'new', 17900, 22900, 'Hamburg', 6766295, 'https://www.pexels.com/photo/a-man-wearing-a-black-suit-jacket-6766295/'),
  ( 3, 2, 'anzuege', 'Eleganter Hochzeitsanzug, Größe 48', 'Eleganter Anzug für Hochzeit oder Feier, wenig getragen und ohne sichtbare Mängel.', 'used', 12900, null, 'Köln', 7599275, 'https://www.pexels.com/photo/man-in-black-suit-jacket-7599275/'),
  ( 4, 3, 'anzuege', 'Formeller Zweiteiler mit Weste, Größe 50', 'Formeller Herren-Zweiteiler mit passender Weste, sorgfältig ausgewählt für festliche Tage.', 'new', 21900, 26900, 'Hamburg', 991089, 'https://www.pexels.com/photo/grayscale-photography-of-a-man-in-formal-suit-jacket-991089/'),
  ( 5, 3, 'goldschmuck', 'Goldene Halskette, 14 Karat', 'Feine goldene Halskette mit schlichtem Anhänger, geprüft und in Geschenkverpackung.', 'new', 28900, 34900, 'Hamburg', 12194382, 'https://www.pexels.com/photo/gold-thin-necklace-in-close-up-photography-12194382/'),
  ( 6, 1, 'goldschmuck', 'Goldanhänger mit filigranem Muster', 'Filigraner Goldanhänger aus privatem Besitz, mit gepflegter Oberfläche und Etui.', 'used', 16900, null, 'Berlin', 13292955, 'https://www.pexels.com/photo/close-up-photo-of-a-gold-necklace-13292955/'),
  ( 7, 2, 'silberschmuck', 'Silberkette mit handgearbeitetem Anhänger', 'Handgearbeitete Silberkette mit dekorativem Anhänger, sehr guter gebrauchter Zustand.', 'used', 7900, null, 'Köln', 14579309, 'https://www.pexels.com/photo/close-up-shot-of-silver-necklaces-14579309/'),
  ( 8, 3, 'eheringe', 'Ehering-Set in Gelbgold, zwei Größen', 'Zwei schlichte Eheringe in Gelbgold, neu und bereit für eine persönliche Gravur.', 'new', 43900, 49900, 'Hamburg', 230290, 'https://www.pexels.com/photo/silver-and-gold-couple-ring-230290/'),
  ( 9, 1, 'saiteninstrumente', 'Saz Bağlama mit Tasche', 'Spielbare Saz Bağlama mit warmem Klang, inklusive gepolsterter Transporttasche.', 'used', 24000, null, 'Berlin', 32100596, 'https://www.pexels.com/photo/street-musician-with-baglama-in-istanbul-32100596/'),
  (10, 2, 'saiteninstrumente', 'Oud mit Holzkorpus', 'Oud mit traditionellem Holzkorpus und klarer Ansprache, frisch besaitet.', 'used', 39000, null, 'Köln', 11970797, 'https://www.pexels.com/photo/brown-wooden-musical-instrument-11970797/'),
  (11, 1, 'schlaginstrumente', 'Def Rahmentrommel, handgefertigt', 'Handgefertigte Def Rahmentrommel mit kräftigem Klang und stabilem Rahmen.', 'used', 12000, null, 'Berlin', 17697530, 'https://www.pexels.com/photo/a-woman-in-traditional-clothing-holding-a-daf-17697530/'),
  (12, 3, 'saiteninstrumente', 'Saz Bağlama für Einsteiger', 'Gut eingestellte Saz Bağlama für Einsteiger, mit Plektrum und Schutzhülle.', 'new', 28500, 33000, 'Hamburg', 28831294, 'https://www.pexels.com/photo/man-playing-turkish-baglama-in-outdoor-setting-28831294/'),
  (13, 4, 'gewuerze-importwaren', 'Paprika und Kurkuma, 2er-Set', 'Aromatisches Set aus Paprika und Kurkuma für Reisgerichte, Eintöpfe und Marinaden.', 'new', 790, 990, 'München', 6808985, 'https://www.pexels.com/photo/bowls-of-chili-and-turmeric-powders-6808985/'),
  (14, 4, 'gewuerze-importwaren', 'Orientalisches Gewürz-Set, vier Sorten', 'Vier ausgewählte Gewürzmischungen für die orientalische Küche in wiederverschließbaren Beuteln.', 'new', 1690, 1990, 'München', 4194077, 'https://www.pexels.com/photo/set-of-condiments-in-store-4194077/'),
  (15, 4, 'gewuerze-importwaren', 'Safranfäden, 2 g', 'Intensive Safranfäden für Reisgerichte und Desserts, sorgfältig portioniert.', 'new', 1490, null, 'München', 33654800, 'https://www.pexels.com/photo/vibrant-saffron-spice-close-up-display-33654800/'),
  (16, 2, 'gewuerze-importwaren', 'Gewürzauswahl vom Markt, fünf Sorten', 'Private Gewürzauswahl mit fünf aromatischen Sorten, trocken und sicher gelagert.', 'new', 1250, null, 'Köln', 11703280, 'https://www.pexels.com/photo/assorted-herbs-and-spices-in-the-market-11703280/'),
  (17, 4, 'suesswaren', 'Pistazien-Baklava, 500 g', 'Frische Pistazien-Baklava in einer 500-Gramm-Schachtel, ideal zum Teilen.', 'new', 1890, 2290, 'München', 20644682, 'https://www.pexels.com/photo/baklava-pastry-with-pistachios-20644682/'),
  (18, 4, 'suesswaren', 'Lokum mit Pistazien, 400 g', 'Weiches Lokum mit Pistazien in einer 400-Gramm-Geschenkpackung.', 'new', 1190, null, 'München', 9415579, 'https://www.pexels.com/photo/closeup-of-turkish-delight-traditional-dessert-9415579/'),
  (19, 4, 'suesswaren', 'Pistazien-Lokum, 350 g', 'Weiches Pistazien-Lokum, frisch verpackt und als kleines Geschenk geeignet.', 'new', 990, 1290, 'München', 25388904, 'https://www.pexels.com/photo/traditional-turkish-delight-25388904/'),
  (20, 1, 'suesswaren', 'Lokum-Mix aus privatem Vorrat, 500 g', 'Ungeöffnete 500-Gramm-Packung mit gemischtem Lokum aus privatem Vorrat.', 'new', 850, null, 'Berlin', 5336704, 'https://www.pexels.com/photo/turkish-traditional-delights-in-the-market-5336704/');

insert into public.products (
  id, seller_id, category_id, title, slug, description, condition, status,
  price_cents, compare_at_price_cents, city, country_code, quantity,
  specifications, published_at, created_at
)
select ('e3d00000-0000-4000-8002-' || lpad(i.n::text, 12, '0'))::uuid,
       ('e3d00000-0000-4000-8001-' || lpad(i.seller_n::text, 12, '0'))::uuid,
       c.id, i.title, 'e3d0-' || i.n, i.description,
       i.condition::public.product_condition, 'active'::public.product_status,
       i.price_cents, i.compare_at_price_cents, i.city, 'DE', 1,
       jsonb_build_object('demo', true, 'demo_batch', 'e3d0',
                          'demo_image_source_url', i.photo_page),
       ('2026-10-05 12:00:00+00'::timestamptz - (i.n || ' minutes')::interval),
       ('2026-10-05 12:00:00+00'::timestamptz - (i.n || ' minutes')::interval)
from e3_demo_items i join public.categories c on c.slug = i.category_slug
on conflict (id) do update set
  seller_id = excluded.seller_id, category_id = excluded.category_id,
  title = excluded.title, description = excluded.description,
  condition = excluded.condition, status = excluded.status,
  price_cents = excluded.price_cents,
  compare_at_price_cents = excluded.compare_at_price_cents,
  city = excluded.city, country_code = excluded.country_code,
  specifications = excluded.specifications;

insert into public.product_images (
  id, product_id, storage_path, image_url, alt_text, sort_order, width, height
)
select ('e3d00000-0000-4000-8003-' || lpad(i.n::text, 12, '0'))::uuid,
       ('e3d00000-0000-4000-8002-' || lpad(i.n::text, 12, '0'))::uuid,
       'e3d0/' || i.n || '/primary.jpg',
       'https://images.pexels.com/photos/' || i.photo_id || '/pexels-photo-' || i.photo_id || '.jpeg?auto=compress&cs=tinysrgb&w=900',
       i.title, 0, 900, 900
from e3_demo_items i
on conflict (id) do update set
  image_url = excluded.image_url, alt_text = excluded.alt_text,
  width = excluded.width, height = excluded.height;

do $$
begin
  if (select count(*) from public.products where id::text like 'e3d0%') <> 20
    or (select count(*) from public.product_images where id::text like 'e3d0%') <> 20
    or (select count(*) from public.sellers where id::text like 'e3d0%') <> 4 then
    raise exception 'E3 demo row counts are incomplete';
  end if;
  if (select count(*) from public.products where id::text like 'e3d0%' and compare_at_price_cents is not null) < 6 then
    raise exception 'E3 demo has too few Angebote';
  end if;
end;
$$;

commit;
