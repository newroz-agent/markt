-- Branded Home content and deterministic demo catalog for browse acceptance.

begin;

alter table public.sellers
  add column if not exists avatar_url text,
  add column if not exists banner_url text;

alter table public.product_images
  add column if not exists image_url text;

create table if not exists public.ad_campaigns (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
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
  constraint ad_campaigns_title_object
    check (jsonb_typeof(title_i18n) = 'object'),
  constraint ad_campaigns_subtitle_object
    check (jsonb_typeof(subtitle_i18n) = 'object'),
  constraint ad_campaigns_schedule
    check (starts_at is null or ends_at is null or ends_at > starts_at)
);

create index if not exists ad_campaigns_active_sort_idx
  on public.ad_campaigns (is_active, sort_order, starts_at, ends_at);

drop trigger if exists set_updated_at on public.ad_campaigns;
create trigger set_updated_at
  before update on public.ad_campaigns
  for each row execute function public.set_updated_at();

alter table public.ad_campaigns enable row level security;

drop policy if exists ad_campaigns_select_active on public.ad_campaigns;
create policy ad_campaigns_select_active
  on public.ad_campaigns for select to anon, authenticated
  using (
    (
      is_active
      and (starts_at is null or starts_at <= now())
      and (ends_at is null or ends_at > now())
    )
    or public.is_admin()
  );

drop policy if exists ad_campaigns_manage_admin on public.ad_campaigns;
create policy ad_campaigns_manage_admin
  on public.ad_campaigns for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

grant select on table public.ad_campaigns to anon, authenticated;
grant all on table public.ad_campaigns to service_role;

insert into public.ad_campaigns (
  id,
  slug,
  title_i18n,
  subtitle_i18n,
  image_url,
  deep_link,
  sort_order,
  starts_at,
  ends_at,
  is_active
)
values
  (
    'a0000000-0000-4000-8000-000000000001',
    'technik-die-weiterdenkt',
    '{"de":"Technik, die weiterdenkt","en":"Technology that thinks ahead","ar":"تقنية تفكر للمستقبل","tr":"Geleceği düşünen teknoloji","ku":"Teknolojiya ku pêşerojê difikire"}'::jsonb,
    '{"de":"Ausgewählte Geräte für Arbeit, Alltag und Freizeit.","en":"Selected devices for work, everyday life and leisure.","ar":"أجهزة مختارة للعمل والحياة اليومية والترفيه.","tr":"İş, günlük yaşam ve eğlence için seçili cihazlar.","ku":"Amûrên bijartî ji bo kar, rojane û demên vala."}'::jsonb,
    'https://images.unsplash.com/photo-1498049794561-7780e7231661?auto=format&fit=crop&w=1600&h=900&q=88',
    null,
    10,
    '2026-01-01T00:00:00Z',
    '2027-01-01T00:00:00Z',
    true
  ),
  (
    'a0000000-0000-4000-8000-000000000002',
    'stil-mit-haltung',
    '{"de":"Stil mit Haltung","en":"Style with purpose","ar":"أناقة ذات معنى","tr":"Duruşu olan stil","ku":"Şêwazek bi helwest"}'::jsonb,
    '{"de":"Neue Favoriten von unabhängigen Shops.","en":"New favourites from independent stores.","ar":"قطع مفضلة جديدة من متاجر مستقلة.","tr":"Bağımsız mağazalardan yeni favoriler.","ku":"Bijarteyên nû ji firoşgehên serbixwe."}'::jsonb,
    'https://images.unsplash.com/photo-1445205170230-053b83016050?auto=format&fit=crop&w=1600&h=900&q=88',
    null,
    20,
    '2026-01-01T00:00:00Z',
    '2027-01-01T00:00:00Z',
    true
  ),
  (
    'a0000000-0000-4000-8000-000000000003',
    'zuhause-neu-gedacht',
    '{"de":"Zuhause neu gedacht","en":"A fresh take on home","ar":"منزل بروح جديدة","tr":"Eve yeni bir bakış","ku":"Nêrînek nû ji bo malê"}'::jsonb,
    '{"de":"Zeitlose Möbel, Licht und Werkzeuge für gute Räume.","en":"Timeless furniture, lighting and tools for better spaces.","ar":"أثاث وإضاءة وأدوات خالدة لمساحات أجمل.","tr":"Daha iyi alanlar için zamansız mobilya, ışık ve araçlar.","ku":"Mobîlya, ronahî û amûrên bêdem ji bo cihên çêtir."}'::jsonb,
    'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&w=1600&h=900&q=88',
    null,
    30,
    '2026-01-01T00:00:00Z',
    '2027-01-01T00:00:00Z',
    true
  )
on conflict (slug) do update set
  title_i18n = excluded.title_i18n,
  subtitle_i18n = excluded.subtitle_i18n,
  image_url = excluded.image_url,
  deep_link = excluded.deep_link,
  sort_order = excluded.sort_order,
  starts_at = excluded.starts_at,
  ends_at = excluded.ends_at,
  is_active = excluded.is_active;

insert into public.sellers (
  id,
  user_id,
  kind,
  status,
  shop_name,
  slug,
  bio,
  avatar_url,
  banner_url,
  city,
  response_time_minutes,
  rating_average,
  rating_count,
  approved_at
)
values
  (
    'b0000000-0000-4000-8000-000000000001',
    null,
    'business',
    'approved',
    'Nordlicht Technik',
    'nordlicht-technik',
    'Durchdachte Technik, fair ausgewählt und schnell aus Hamburg versendet.',
    'https://images.unsplash.com/photo-1497366811353-6870744d04b2?auto=format&fit=crop&w=400&h=400&q=85',
    'https://images.unsplash.com/photo-1498049794561-7780e7231661?auto=format&fit=crop&w=1400&h=700&q=85',
    'Hamburg',
    18,
    4.91,
    428,
    '2025-03-01T10:00:00Z'
  ),
  (
    'b0000000-0000-4000-8000-000000000002',
    null,
    'business',
    'approved',
    'Atelier Lale',
    'atelier-lale',
    'Mode und Beauty mit klarer Herkunft, kuratiert in Berlin.',
    'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?auto=format&fit=crop&w=400&h=400&q=85',
    'https://images.unsplash.com/photo-1445205170230-053b83016050?auto=format&fit=crop&w=1400&h=700&q=85',
    'Berlin',
    32,
    4.87,
    316,
    '2025-04-12T10:00:00Z'
  ),
  (
    'b0000000-0000-4000-8000-000000000003',
    null,
    'business',
    'approved',
    'Werk & Wohn',
    'werk-und-wohn',
    'Gutes Werkzeug und langlebige Dinge für ein Zuhause mit Charakter.',
    'https://images.unsplash.com/photo-1452860606245-08befc0ff44b?auto=format&fit=crop&w=400&h=400&q=85',
    'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&w=1400&h=700&q=85',
    'Köln',
    24,
    4.83,
    267,
    '2025-05-20T10:00:00Z'
  )
on conflict (slug) do update set
  kind = excluded.kind,
  status = excluded.status,
  shop_name = excluded.shop_name,
  bio = excluded.bio,
  avatar_url = excluded.avatar_url,
  banner_url = excluded.banner_url,
  city = excluded.city,
  response_time_minutes = excluded.response_time_minutes,
  rating_average = excluded.rating_average,
  rating_count = excluded.rating_count,
  approved_at = excluded.approved_at,
  rejection_reason = null;

with product_seed (
  id,
  seller_slug,
  category_slug,
  title,
  slug,
  description,
  condition,
  price_cents,
  compare_at_price_cents,
  quantity,
  sku,
  city,
  postal_code,
  free_shipping,
  shipping_cost_cents,
  rating_average,
  rating_count,
  published_at
) as (
  values
    ('c0000000-0000-4000-8000-000000000001'::uuid, 'nordlicht-technik', 'audio', 'Wireless Kopfhörer Nova X', 'wireless-kopfhoerer-nova-x', 'Kabelloser Over-Ear-Kopfhörer mit aktiver Geräuschunterdrückung und 40 Stunden Laufzeit.', 'new', 12999, 15999, 24, 'NL-NOVA-X', 'Hamburg', '20095', true, 0, 4.88, 184, '2026-08-16T18:00:00Z'::timestamptz),
    ('c0000000-0000-4000-8000-000000000002'::uuid, 'nordlicht-technik', 'smartphones', 'Refurbished Smartphone Pro 128 GB', 'refurbished-smartphone-pro-128', 'Geprüftes Smartphone mit sehr gutem Akku, OLED Display und zwölf Monaten Gewährleistung.', 'used', 54900, 64900, 8, 'NL-PHONE-128', 'Hamburg', '20095', true, 0, 4.76, 96, '2026-08-16T15:00:00Z'::timestamptz),
    ('c0000000-0000-4000-8000-000000000003'::uuid, 'nordlicht-technik', 'laptops-tablets', 'Ultrabook Air 14 Zoll', 'ultrabook-air-14-zoll', 'Leichtes Aluminium Ultrabook mit hochauflösendem Display und ganztägiger Akkulaufzeit.', 'new', 89900, null, 11, 'NL-AIR-14', 'Hamburg', '20095', true, 0, 4.92, 73, '2026-08-16T12:00:00Z'::timestamptz),
    ('c0000000-0000-4000-8000-000000000004'::uuid, 'nordlicht-technik', 'audio', 'Bluetooth Speaker Fjord', 'bluetooth-speaker-fjord', 'Kompakter, wasserfester Lautsprecher mit warmem Klang und 18 Stunden Wiedergabezeit.', 'new', 7999, 9999, 31, 'NL-FJORD', 'Hamburg', '20095', false, 499, 4.72, 129, '2026-08-15T18:00:00Z'::timestamptz),
    ('c0000000-0000-4000-8000-000000000005'::uuid, 'nordlicht-technik', 'konsolen-gaming', 'Gaming Controller Elite', 'gaming-controller-elite', 'Präziser kabelloser Controller mit anpassbaren Tasten und strukturierter Grifffläche.', 'new', 6999, null, 19, 'NL-GAME-ELITE', 'Hamburg', '20095', false, 499, 4.69, 88, '2026-08-15T12:00:00Z'::timestamptz),
    ('c0000000-0000-4000-8000-000000000006'::uuid, 'nordlicht-technik', 'elektronik-zubehoer', 'USB-C Dock 12-in-1', 'usb-c-dock-12-in-1', 'Vielseitiges Aluminium Dock mit HDMI, Ethernet, Kartenleser und 100 Watt Power Delivery.', 'new', 8999, 11999, 22, 'NL-DOCK-12', 'Hamburg', '20095', true, 0, 4.81, 142, '2026-08-14T18:00:00Z'::timestamptz),
    ('c0000000-0000-4000-8000-000000000007'::uuid, 'nordlicht-technik', 'uhren', 'Smartwatch Pulse', 'smartwatch-pulse', 'Schlanke Smartwatch mit Gesundheitsfunktionen, GPS und brillantem Always-on Display.', 'new', 14999, 17999, 14, 'NL-PULSE', 'Hamburg', '20095', true, 0, 4.74, 107, '2026-08-14T12:00:00Z'::timestamptz),
    ('c0000000-0000-4000-8000-000000000008'::uuid, 'nordlicht-technik', 'auto-elektronik', 'Dashcam Roadview 4K', 'dashcam-roadview-4k', 'Kompakte 4K Dashcam mit Nachtsicht, Parkmodus und unauffälliger Scheibenhalterung.', 'new', 11999, null, 17, 'NL-ROAD-4K', 'Hamburg', '20095', false, 499, 4.66, 61, '2026-08-13T18:00:00Z'::timestamptz),
    ('c0000000-0000-4000-8000-000000000009'::uuid, 'nordlicht-technik', 'audio', 'Noise Cancelling Earbuds', 'noise-cancelling-earbuds', 'Leichte In-Ear-Kopfhörer mit adaptiver Geräuschunterdrückung und kabellosem Ladecase.', 'new', 9999, 12999, 27, 'NL-BUDS-NC', 'Hamburg', '20095', true, 0, 4.79, 203, '2026-08-13T12:00:00Z'::timestamptz),
    ('c0000000-0000-4000-8000-000000000010'::uuid, 'nordlicht-technik', 'elektronik-zubehoer', 'Mechanische Tastatur Compact', 'mechanische-tastatur-compact', 'Kompakte mechanische Tastatur mit leisem Tastenprofil und kabelloser Verbindung.', 'new', 10999, null, 16, 'NL-KEY-C', 'Hamburg', '20095', true, 0, 4.85, 118, '2026-08-12T18:00:00Z'::timestamptz),

    ('c0000000-0000-4000-8000-000000000011'::uuid, 'atelier-lale', 'damen-kleidung', 'Leinenblazer Mira', 'leinenblazer-mira', 'Locker geschnittener Blazer aus europäischem Leinen mit sauberer, ungefütterter Verarbeitung.', 'new', 13900, 17900, 13, 'AL-MIRA-BL', 'Berlin', '10115', true, 0, 4.91, 84, '2026-08-16T16:00:00Z'::timestamptz),
    ('c0000000-0000-4000-8000-000000000012'::uuid, 'atelier-lale', 'damen-taschen', 'Lederhandtasche Mira', 'lederhandtasche-mira', 'Zeitlose Handtasche aus pflanzlich gegerbtem Leder mit verstellbarem Schulterriemen.', 'new', 18900, null, 7, 'AL-MIRA-BAG', 'Berlin', '10115', true, 0, 4.95, 112, '2026-08-16T13:00:00Z'::timestamptz),
    ('c0000000-0000-4000-8000-000000000013'::uuid, 'atelier-lale', 'damen-schuhe', 'Sneaker Studio 01', 'sneaker-studio-01', 'Minimalistischer Ledersneaker mit recycelter Sohle und weichem, atmungsaktivem Futter.', 'new', 11900, 14900, 18, 'AL-STUDIO-01', 'Berlin', '10115', true, 0, 4.82, 146, '2026-08-15T16:00:00Z'::timestamptz),
    ('c0000000-0000-4000-8000-000000000014'::uuid, 'atelier-lale', 'damen-accessoires', 'Kaschmirschal Noa', 'kaschmirschal-noa', 'Weicher Schal aus verantwortungsvoll bezogenem Kaschmir in einer großzügigen Länge.', 'new', 8900, null, 21, 'AL-NOA-SCARF', 'Berlin', '10115', false, 399, 4.78, 63, '2026-08-15T10:00:00Z'::timestamptz),
    ('c0000000-0000-4000-8000-000000000015'::uuid, 'atelier-lale', 'parfuem', 'Eau de Parfum Sera', 'eau-de-parfum-sera', 'Moderner Duft mit Bergamotte, Iris und warmem Zedernholz, abgefüllt in Berlin.', 'new', 7900, 9900, 26, 'AL-SERA-50', 'Berlin', '10115', true, 0, 4.89, 174, '2026-08-14T16:00:00Z'::timestamptz),
    ('c0000000-0000-4000-8000-000000000016'::uuid, 'atelier-lale', 'haarpflege', 'Pflege-Set Botanica', 'pflege-set-botanica', 'Sanftes Shampoo, Conditioner und Haaröl mit pflanzlichen Wirkstoffen für den Alltag.', 'new', 4900, 5900, 34, 'AL-BOTANICA', 'Berlin', '10115', false, 399, 4.73, 91, '2026-08-14T10:00:00Z'::timestamptz),
    ('c0000000-0000-4000-8000-000000000017'::uuid, 'atelier-lale', 'herren-kleidung', 'Herren Overshirt Oslo', 'herren-overshirt-oslo', 'Strukturiertes Overshirt aus schwerer Bio-Baumwolle für drinnen und draußen.', 'new', 9900, 12900, 15, 'AL-OSLO-OS', 'Berlin', '10115', true, 0, 4.86, 77, '2026-08-13T16:00:00Z'::timestamptz),
    ('c0000000-0000-4000-8000-000000000018'::uuid, 'atelier-lale', 'herren-uhren', 'Chronograph Atlas', 'chronograph-atlas', 'Klarer Edelstahl-Chronograph mit Saphirglas und präzisem Quarzwerk.', 'new', 22900, null, 6, 'AL-ATLAS-CH', 'Berlin', '10115', true, 0, 4.93, 58, '2026-08-13T10:00:00Z'::timestamptz),
    ('c0000000-0000-4000-8000-000000000019'::uuid, 'atelier-lale', 'herren-accessoires', 'Ledergürtel Klassik', 'lederguertel-klassik', 'Schlichter Gürtel aus vollnarbigem Leder mit gebürsteter Metallschließe.', 'new', 5900, null, 29, 'AL-BELT-01', 'Berlin', '10115', false, 399, 4.71, 54, '2026-08-12T16:00:00Z'::timestamptz),
    ('c0000000-0000-4000-8000-000000000020'::uuid, 'atelier-lale', 'make-up', 'Make-up Pinselset Pro', 'make-up-pinselset-pro', 'Zehnteiliges Pinselset mit weichen synthetischen Fasern und stabilem Etui.', 'new', 4400, 5500, 38, 'AL-BRUSH-PRO', 'Berlin', '10115', false, 399, 4.77, 132, '2026-08-12T10:00:00Z'::timestamptz),

    ('c0000000-0000-4000-8000-000000000021'::uuid, 'werk-und-wohn', 'kochgeschirr', 'Gusseisen Pfannenset', 'gusseisen-pfannenset', 'Zwei langlebige Gusseisenpfannen mit gleichmäßiger Wärmeverteilung für alle Herdarten.', 'new', 8900, 10900, 20, 'WW-PFANNE-2', 'Köln', '50667', true, 0, 4.90, 154, '2026-08-16T14:00:00Z'::timestamptz),
    ('c0000000-0000-4000-8000-000000000022'::uuid, 'werk-und-wohn', 'kuechengeraete', 'Küchenmaschine Compact', 'kuechenmaschine-compact', 'Leistungsstarke Küchenmaschine mit Metallgehäuse, fünf Litern Volumen und drei Aufsätzen.', 'new', 27900, 32900, 9, 'WW-MIX-5', 'Köln', '50667', true, 0, 4.87, 83, '2026-08-15T14:00:00Z'::timestamptz),
    ('c0000000-0000-4000-8000-000000000023'::uuid, 'werk-und-wohn', 'beleuchtung', 'Stehleuchte Luma', 'stehleuchte-luma', 'Dimmbare Stehleuchte aus pulverbeschichtetem Metall mit warmem, blendfreiem Licht.', 'new', 15900, null, 12, 'WW-LUMA-F', 'Köln', '50667', false, 699, 4.84, 69, '2026-08-15T08:00:00Z'::timestamptz),
    ('c0000000-0000-4000-8000-000000000024'::uuid, 'werk-und-wohn', 'moebel', 'Beistelltisch Eiche', 'beistelltisch-eiche', 'Kompakter Beistelltisch aus massiver, geölter Eiche mit ruhiger handwerklicher Form.', 'new', 21900, 25900, 5, 'WW-EICHE-S', 'Köln', '50667', true, 0, 4.96, 47, '2026-08-14T14:00:00Z'::timestamptz),
    ('c0000000-0000-4000-8000-000000000025'::uuid, 'werk-und-wohn', 'elektrowerkzeuge', 'Akkuschrauber 18V', 'akkuschrauber-18v', 'Kompakter bürstenloser Akkuschrauber mit zwei Akkus, Ladegerät und robustem Koffer.', 'new', 14900, 17900, 16, 'WW-AKKU-18', 'Köln', '50667', true, 0, 4.88, 193, '2026-08-14T08:00:00Z'::timestamptz),
    ('c0000000-0000-4000-8000-000000000026'::uuid, 'werk-und-wohn', 'handwerkzeuge', 'Werkzeugkoffer 108-teilig', 'werkzeugkoffer-108-teilig', 'Vollständiger Werkzeugkoffer aus Chrom-Vanadium-Stahl für Haushalt und Werkstatt.', 'new', 12900, 15900, 23, 'WW-TOOLS-108', 'Köln', '50667', true, 0, 4.81, 221, '2026-08-13T14:00:00Z'::timestamptz),
    ('c0000000-0000-4000-8000-000000000027'::uuid, 'werk-und-wohn', 'fitness', 'Yoga Set Balance', 'yoga-set-balance', 'Rutschfeste Matte, zwei Blöcke und Gurt aus langlebigen, schadstoffarmen Materialien.', 'new', 6900, 7900, 28, 'WW-YOGA-B', 'Köln', '50667', false, 499, 4.75, 105, '2026-08-13T08:00:00Z'::timestamptz),
    ('c0000000-0000-4000-8000-000000000028'::uuid, 'werk-und-wohn', 'outdoor', 'Trekking Rucksack 35L', 'trekking-rucksack-35l', 'Leichter Tagesrucksack mit belüftetem Rücken, Regenhülle und durchdachter Fächeraufteilung.', 'new', 10900, null, 17, 'WW-TREK-35', 'Köln', '50667', true, 0, 4.79, 138, '2026-08-12T14:00:00Z'::timestamptz),
    ('c0000000-0000-4000-8000-000000000029'::uuid, 'werk-und-wohn', 'spielzeug', 'Holzbausteine Regenbogen', 'holzbausteine-regenbogen', 'Handgeschliffene Bausteine aus zertifiziertem Holz mit ungiftigen Farben auf Wasserbasis.', 'new', 5900, null, 25, 'WW-BLOCKS-R', 'Köln', '50667', false, 499, 4.94, 176, '2026-08-11T14:00:00Z'::timestamptz),
    ('c0000000-0000-4000-8000-000000000030'::uuid, 'werk-und-wohn', 'babyausstattung', 'Babydecke Bio-Baumwolle', 'babydecke-bio-baumwolle', 'Weiche doppellagige Babydecke aus GOTS-zertifizierter Bio-Baumwolle.', 'new', 4900, 5900, 32, 'WW-BABY-B', 'Köln', '50667', false, 399, 4.92, 119, '2026-08-11T08:00:00Z'::timestamptz)
)
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
  currency,
  vat_rate,
  price_includes_vat,
  quantity,
  sku,
  specifications,
  city,
  postal_code,
  ships_to,
  shipping_cost_cents,
  free_shipping,
  rating_average,
  rating_count,
  published_at,
  created_at
)
select
  seed.id,
  seller.id,
  category.id,
  seed.title,
  seed.slug,
  seed.description,
  seed.condition::public.product_condition,
  'active'::public.product_status,
  seed.price_cents,
  seed.compare_at_price_cents,
  'EUR',
  19.00,
  true,
  seed.quantity,
  seed.sku,
  jsonb_build_object('demo', true),
  seed.city,
  seed.postal_code,
  array['DE']::text[],
  seed.shipping_cost_cents,
  seed.free_shipping,
  seed.rating_average,
  seed.rating_count,
  seed.published_at,
  seed.published_at
from product_seed as seed
join public.sellers as seller on seller.slug = seed.seller_slug
join public.categories as category on category.slug = seed.category_slug
on conflict (slug) do update set
  seller_id = excluded.seller_id,
  category_id = excluded.category_id,
  title = excluded.title,
  description = excluded.description,
  condition = excluded.condition,
  status = excluded.status,
  price_cents = excluded.price_cents,
  compare_at_price_cents = excluded.compare_at_price_cents,
  currency = excluded.currency,
  vat_rate = excluded.vat_rate,
  price_includes_vat = excluded.price_includes_vat,
  quantity = excluded.quantity,
  sku = excluded.sku,
  specifications = excluded.specifications,
  city = excluded.city,
  postal_code = excluded.postal_code,
  ships_to = excluded.ships_to,
  shipping_cost_cents = excluded.shipping_cost_cents,
  free_shipping = excluded.free_shipping,
  rating_average = excluded.rating_average,
  rating_count = excluded.rating_count,
  published_at = excluded.published_at;

with image_seed (product_slug, image_url, alt_text) as (
  values
    ('wireless-kopfhoerer-nova-x', 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=900&h=900&q=86', 'Kabelloser Kopfhörer Nova X'),
    ('refurbished-smartphone-pro-128', 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=900&h=900&q=86', 'Refurbished Smartphone'),
    ('ultrabook-air-14-zoll', 'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?auto=format&fit=crop&w=900&h=900&q=86', 'Ultrabook Air'),
    ('bluetooth-speaker-fjord', 'https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?auto=format&fit=crop&w=900&h=900&q=86', 'Bluetooth Lautsprecher'),
    ('gaming-controller-elite', 'https://images.unsplash.com/photo-1592840496694-26d035b52b48?auto=format&fit=crop&w=900&h=900&q=86', 'Gaming Controller'),
    ('usb-c-dock-12-in-1', 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?auto=format&fit=crop&w=900&h=900&q=86', 'USB-C Dock'),
    ('smartwatch-pulse', 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&w=900&h=900&q=86', 'Smartwatch Pulse'),
    ('dashcam-roadview-4k', 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=900&h=900&q=86', 'Dashcam Roadview'),
    ('noise-cancelling-earbuds', 'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?auto=format&fit=crop&w=900&h=900&q=86', 'Noise Cancelling Earbuds'),
    ('mechanische-tastatur-compact', 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?auto=format&fit=crop&w=900&h=900&q=86', 'Mechanische Tastatur'),
    ('leinenblazer-mira', 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?auto=format&fit=crop&w=900&h=900&q=86', 'Leinenblazer Mira'),
    ('lederhandtasche-mira', 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?auto=format&fit=crop&w=900&h=900&q=86', 'Lederhandtasche Mira'),
    ('sneaker-studio-01', 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=900&h=900&q=86', 'Sneaker Studio 01'),
    ('kaschmirschal-noa', 'https://images.unsplash.com/photo-1520903920243-00d872a2d1c9?auto=format&fit=crop&w=900&h=900&q=86', 'Kaschmirschal Noa'),
    ('eau-de-parfum-sera', 'https://images.unsplash.com/photo-1541643600914-78b084683601?auto=format&fit=crop&w=900&h=900&q=86', 'Eau de Parfum Sera'),
    ('pflege-set-botanica', 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&w=900&h=900&q=86', 'Pflege-Set Botanica'),
    ('herren-overshirt-oslo', 'https://images.unsplash.com/photo-1617137968427-85924c800a22?auto=format&fit=crop&w=900&h=900&q=86', 'Herren Overshirt Oslo'),
    ('chronograph-atlas', 'https://images.unsplash.com/photo-1523170335258-f5ed11844a49?auto=format&fit=crop&w=900&h=900&q=86', 'Chronograph Atlas'),
    ('lederguertel-klassik', 'https://images.unsplash.com/photo-1624222247344-550fb60583dc?auto=format&fit=crop&w=900&h=900&q=86', 'Ledergürtel Klassik'),
    ('make-up-pinselset-pro', 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?auto=format&fit=crop&w=900&h=900&q=86', 'Make-up Pinselset'),
    ('gusseisen-pfannenset', 'https://images.unsplash.com/photo-1584990347449-a6d4f8009a3f?auto=format&fit=crop&w=900&h=900&q=86', 'Gusseisen Pfannenset'),
    ('kuechenmaschine-compact', 'https://images.unsplash.com/photo-1556911220-bff31c812dba?auto=format&fit=crop&w=900&h=900&q=86', 'Küchenmaschine Compact'),
    ('stehleuchte-luma', 'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?auto=format&fit=crop&w=900&h=900&q=86', 'Stehleuchte Luma'),
    ('beistelltisch-eiche', 'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&w=900&h=900&q=86', 'Beistelltisch Eiche'),
    ('akkuschrauber-18v', 'https://images.unsplash.com/photo-1572981779307-38b8cabb2407?auto=format&fit=crop&w=900&h=900&q=86', 'Akkuschrauber 18V'),
    ('werkzeugkoffer-108-teilig', 'https://images.unsplash.com/photo-1530124566582-a618bc2615dc?auto=format&fit=crop&w=900&h=900&q=86', 'Werkzeugkoffer'),
    ('yoga-set-balance', 'https://images.unsplash.com/photo-1599447421416-3414500d18a5?auto=format&fit=crop&w=900&h=900&q=86', 'Yoga Set Balance'),
    ('trekking-rucksack-35l', 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?auto=format&fit=crop&w=900&h=900&q=86', 'Trekking Rucksack'),
    ('holzbausteine-regenbogen', 'https://images.unsplash.com/photo-1598880940080-ff9a29891b85?auto=format&fit=crop&w=900&h=900&q=86', 'Holzbausteine'),
    ('babydecke-bio-baumwolle', 'https://images.unsplash.com/photo-1516627145497-ae6968895b74?auto=format&fit=crop&w=900&h=900&q=86', 'Babydecke aus Bio-Baumwolle')
)
insert into public.product_images (
  product_id,
  storage_path,
  image_url,
  alt_text,
  sort_order,
  width,
  height
)
select
  product.id,
  'demo/' || product.slug || '/primary.webp',
  seed.image_url,
  seed.alt_text,
  0,
  900,
  900
from image_seed as seed
join public.products as product on product.slug = seed.product_slug
on conflict (product_id, sort_order) do update set
  storage_path = excluded.storage_path,
  image_url = excluded.image_url,
  alt_text = excluded.alt_text,
  width = excluded.width,
  height = excluded.height;

comment on table public.ad_campaigns is
  'Scheduled branded placements rendered in the marketplace Home carousel.';

commit;
