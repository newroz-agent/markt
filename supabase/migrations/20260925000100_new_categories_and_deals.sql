-- Zêrîn new marketplace categories: Gold/Suits/Music/Supermarket expansion.
-- Additive only. No new tables, no new columns, no RPC changes.
--
-- Audit basis (live schema 2026-09-25, 55 rows):
-- - "Uhren & Schmuck" EXISTS as top-level (slug uhren-schmuck, id
--   a751d5c8-2d42-4997-9068-60c398d6af38) with children uhren + schmuck.
--   Gold rows go UNDER it, not as a new overlapping top-level.
-- - "Mode Herren" EXISTS as top-level (slug mode-herren, id
--   b9aba147-3b63-4ceb-a3c6-c0940db47e27) with 4 children.
--   Anzüge goes UNDER it.
-- - No music category exists (slug/name LIKE '%musik%'/'%instrument%' = 0 rows).
--   Musikinstrumente is a genuinely new top-level.
-- - "Lebensmittel & Süßes" EXISTS (slug lebensmittel-suesses, id
--   22f20234-87bc-47d3-bf0f-d238171b2abe) but the whole tree is
--   is_active=false. Getränke + Süßwaren already exist as children;
--   only Frische Lebensmittel + Gewürze & Importwaren are new.
--   The parent and its spec-listed children are activated here.
-- - products.compare_at_price_cents EXISTS (nullable bigint, 19/33 rows set).
--   Home already reads it via discountedOnly filter and already renders the
--   "Angebote" section (homeDealsTitle in all 5 ARBs). No column added.
--
-- Data shape matches 20260807000200_seed_categories.sql exactly:
-- id, parent_id, slug, name_de, name_en, name_ar, name_tr, name_ku,
-- icon_key (Material icon name), image_url (unsplash), sort_order, is_active.
-- Slugs follow categories_slug_check (lowercase, hyphens, no umlauts).
-- Kurdish names follow the category_kurdish.sql slug-mapping pattern.
begin;

-- 1) New top-level: Musikinstrumente (sort_order 95, between Sport 90 and
-- Kinder 100). No existing music category overlaps.
insert into public.categories (
  parent_id, slug, name_de, name_en, name_ar, name_tr, name_ku,
  icon_key, image_url, sort_order, is_active
)
values (
  null, 'musikinstrumente',
  'Musikinstrumente', 'Musical Instruments', 'آلات موسيقية',
  'Müzik Aletleri', 'Amûrên Muzîkê',
  'music_note',
  'https://images.unsplash.com/photo-1511379938547-c1f69419868d?auto=format&fit=crop&w=1200&q=80',
  95, true
)
on conflict (slug) do update set
  name_de = excluded.name_de,
  name_en = excluded.name_en,
  name_ar = excluded.name_ar,
  name_tr = excluded.name_tr,
  name_ku = excluded.name_ku,
  icon_key = excluded.icon_key,
  image_url = excluded.image_url,
  sort_order = excluded.sort_order,
  is_active = excluded.is_active;

-- 2) New subcategories (parent resolved by slug; idempotent via slug).
insert into public.categories (
  parent_id, slug, name_de, name_en, name_ar, name_tr, name_ku,
  icon_key, image_url, sort_order, is_active
)
values
  -- §1 Gold & Schmuck: under existing uhren-schmuck (existing children
  -- uhren=10, schmuck=20).
  ((select id from public.categories where slug = 'uhren-schmuck'),
   'goldschmuck',
   'Goldschmuck', 'Gold Jewelry', 'مجوهرات ذهبية',
   'Altın Takılar', 'Zîverên Zêrîn',
   'diamond',
   'https://images.unsplash.com/photo-1523170335258-f5ed11844a49?auto=format&fit=crop&w=1200&q=80',
   30, true),
  ((select id from public.categories where slug = 'uhren-schmuck'),
   'silberschmuck',
   'Silberschmuck', 'Silver Jewelry', 'مجوهرات فضية',
   'Gümüş Takılar', 'Zîverên Zîvîn',
   'diamond',
   'https://images.unsplash.com/photo-1523170335258-f5ed11844a49?auto=format&fit=crop&w=1200&q=80',
   40, true),
  ((select id from public.categories where slug = 'uhren-schmuck'),
   'eheringe',
   'Eheringe', 'Wedding Rings', 'خواتم الزواج',
   'Alyanslar', 'Gustîlên Zewacê',
   'favorite',
   'https://images.unsplash.com/photo-1523170335258-f5ed11844a49?auto=format&fit=crop&w=1200&q=80',
   50, true),
  ((select id from public.categories where slug = 'uhren-schmuck'),
   'antiker-schmuck',
   'Antiker Schmuck', 'Antique Jewelry', 'مجوهرات عتيقة',
   'Antika Takılar', 'Zîverên Kevin',
   'history',
   'https://images.unsplash.com/photo-1523170335258-f5ed11844a49?auto=format&fit=crop&w=1200&q=80',
   60, true),
  -- §2 Anzüge: under existing mode-herren (existing children 10-40).
  ((select id from public.categories where slug = 'mode-herren'),
   'anzuege',
   'Anzüge', 'Suits', 'بدلات',
   'Takım Elbiseler', 'Kincên Fermî',
   'dry_cleaning',
   'https://images.unsplash.com/photo-1617137968427-85924c800a22?auto=format&fit=crop&w=1200&q=80',
   50, true),
  -- §3 Musikinstrumente children (Kurdish/Middle Eastern instruments named
  -- explicitly in the German copy per spec).
  ((select id from public.categories where slug = 'musikinstrumente'),
   'tasteninstrumente',
   'Tasteninstrumente', 'Keyboard Instruments', 'آلات المفاتيح',
   'Tuşlu Çalgılar', 'Amûrên Bişkokî',
   'piano',
   'https://images.unsplash.com/photo-1511379938547-c1f69419868d?auto=format&fit=crop&w=1200&q=80',
   10, true),
  ((select id from public.categories where slug = 'musikinstrumente'),
   'saiteninstrumente',
   'Saiteninstrumente (Saz, Oud)', 'String Instruments (Saz, Oud)',
   'آلات وترية (ساز، عود)', 'Telli Çalgılar (Saz, Ud)',
   'Amûrên Têlî (Saz, Ûd)',
   'music_note',
   'https://images.unsplash.com/photo-1511379938547-c1f69419868d?auto=format&fit=crop&w=1200&q=80',
   20, true),
  ((select id from public.categories where slug = 'musikinstrumente'),
   'schlaginstrumente',
   'Schlaginstrumente (Def)', 'Percussion Instruments (Daf)',
   'آلات إيقاعية (دف)', 'Vurmalı Çalgılar (Def)',
   'Amûrên Lêdanê (Def)',
   'album',
   'https://images.unsplash.com/photo-1511379938547-c1f69419868d?auto=format&fit=crop&w=1200&q=80',
   30, true),
  ((select id from public.categories where slug = 'musikinstrumente'),
   'blasinstrumente',
   'Blasinstrumente (Zurna)', 'Wind Instruments (Zurna)',
   'آلات النفخ (زورنا)', 'Nefesli Çalgılar (Zurna)',
   'Amûrên Bayê (Zirne)',
   'mic',
   'https://images.unsplash.com/photo-1511379938547-c1f69419868d?auto=format&fit=crop&w=1200&q=80',
   40, true),
  ((select id from public.categories where slug = 'musikinstrumente'),
   'zubehoer-noten',
   'Zubehör & Noten', 'Accessories & Sheet Music',
   'إكسسوارات ونوتات موسيقية', 'Aksesuar ve Notalar',
   'Aksesuar & Nota',
   'library_music',
   'https://images.unsplash.com/photo-1511379938547-c1f69419868d?auto=format&fit=crop&w=1200&q=80',
   50, true),
  -- §4 Supermarkt: under existing lebensmittel-suesses. Getränke + Süßwaren
  -- already exist; only these two are new.
  ((select id from public.categories where slug = 'lebensmittel-suesses'),
   'frische-lebensmittel',
   'Frische Lebensmittel', 'Fresh Groceries', 'مواد غذائية طازجة',
   'Taze Gıdalar', 'Xurekên Teze',
   'local_grocery_store',
   'https://images.unsplash.com/photo-1606312619070-d48b4c652a52?auto=format&fit=crop&w=1200&q=80',
   40, true),
  ((select id from public.categories where slug = 'lebensmittel-suesses'),
   'gewuerze-importwaren',
   'Gewürze & Importwaren (kurdische/orientalische Spezialitäten)',
   'Spices & Import Goods (Kurdish/Oriental specialties)',
   'توابل ومنتجات مستوردة (تخصصات كردية/شرقية)',
   'Baharat ve İthal Ürünler (Kürt/Doğu spesiyaliteleri)',
   'Biharat & Tiştên Hawirdekirî (Taybetmendiyên Kurdî/Rojhilatî)',
   'storefront',
   'https://images.unsplash.com/photo-1606312619070-d48b4c652a52?auto=format&fit=crop&w=1200&q=80',
   50, true)
on conflict (slug) do update set
  parent_id = excluded.parent_id,
  name_de = excluded.name_de,
  name_en = excluded.name_en,
  name_ar = excluded.name_ar,
  name_tr = excluded.name_tr,
  name_ku = excluded.name_ku,
  icon_key = excluded.icon_key,
  image_url = excluded.image_url,
  sort_order = excluded.sort_order,
  is_active = excluded.is_active;

-- 3) Activate the Lebensmittel tree: the parent and its spec-listed children
-- (suesswaren, getraenke) were is_active=false and therefore invisible to
-- fetchActiveCategories. Restaurants is not in the spec list and stays as-is.
update public.categories
set is_active = true, updated_at = now()
where slug in ('lebensmittel-suesses', 'suesswaren', 'getraenke')
  and is_active is distinct from true;

commit;
