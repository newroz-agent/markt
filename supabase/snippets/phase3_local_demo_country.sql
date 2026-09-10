-- LOCAL DEV ONLY, opt-in fixture, never a deployment migration or global backfill.
-- psql postgresql://postgres:postgres@127.0.0.1:54322/postgres -X \
--   -v ON_ERROR_STOP=1 -v phase3_local_demo=true -f supabase/snippets/phase3_local_demo_country.sql
-- These fixed IDs identify the German Hamburg/Berlin/Cologne demo catalog in
-- 20260817000100_home_demo_catalog.sql. City labels are NOT country inference.
\if :{?phase3_local_demo}
\else
  \quit 3
\endif
\if :phase3_local_demo
\else
  \quit 3
\endif

begin;
create temp table phase3_demo_sellers (id uuid primary key, slug text) on commit drop;
insert into phase3_demo_sellers values
  ('b0000000-0000-4000-8000-000000000001', 'nordlicht-technik'),
  ('b0000000-0000-4000-8000-000000000002', 'atelier-lale'),
  ('b0000000-0000-4000-8000-000000000003', 'werk-und-wohn');

update public.sellers s set country_code = 'DE'
from phase3_demo_sellers seed
where s.id = seed.id and s.slug = seed.slug and s.user_id is null
  and s.country_code is null;

with demo_products (id, slug) as (values
  ('c0000000-0000-4000-8000-000000000001'::uuid, 'wireless-kopfhoerer-nova-x'),
  ('c0000000-0000-4000-8000-000000000002'::uuid, 'refurbished-smartphone-pro-128'),
  ('c0000000-0000-4000-8000-000000000003'::uuid, 'ultrabook-air-14-zoll'),
  ('c0000000-0000-4000-8000-000000000004'::uuid, 'bluetooth-speaker-fjord'),
  ('c0000000-0000-4000-8000-000000000005'::uuid, 'gaming-controller-elite'),
  ('c0000000-0000-4000-8000-000000000006'::uuid, 'usb-c-dock-12-in-1'),
  ('c0000000-0000-4000-8000-000000000007'::uuid, 'smartwatch-pulse'),
  ('c0000000-0000-4000-8000-000000000008'::uuid, 'dashcam-roadview-4k'),
  ('c0000000-0000-4000-8000-000000000009'::uuid, 'noise-cancelling-earbuds'),
  ('c0000000-0000-4000-8000-000000000010'::uuid, 'mechanische-tastatur-compact'),
  ('c0000000-0000-4000-8000-000000000011'::uuid, 'leinenblazer-mira'),
  ('c0000000-0000-4000-8000-000000000012'::uuid, 'lederhandtasche-mira'),
  ('c0000000-0000-4000-8000-000000000013'::uuid, 'sneaker-studio-01'),
  ('c0000000-0000-4000-8000-000000000014'::uuid, 'kaschmirschal-noa'),
  ('c0000000-0000-4000-8000-000000000015'::uuid, 'eau-de-parfum-sera'),
  ('c0000000-0000-4000-8000-000000000016'::uuid, 'pflege-set-botanica'),
  ('c0000000-0000-4000-8000-000000000017'::uuid, 'herren-overshirt-oslo'),
  ('c0000000-0000-4000-8000-000000000018'::uuid, 'chronograph-atlas'),
  ('c0000000-0000-4000-8000-000000000019'::uuid, 'lederguertel-klassik'),
  ('c0000000-0000-4000-8000-000000000020'::uuid, 'make-up-pinselset-pro'),
  ('c0000000-0000-4000-8000-000000000021'::uuid, 'gusseisen-pfannenset'),
  ('c0000000-0000-4000-8000-000000000022'::uuid, 'kuechenmaschine-compact'),
  ('c0000000-0000-4000-8000-000000000023'::uuid, 'stehleuchte-luma'),
  ('c0000000-0000-4000-8000-000000000024'::uuid, 'beistelltisch-eiche'),
  ('c0000000-0000-4000-8000-000000000025'::uuid, 'akkuschrauber-18v'),
  ('c0000000-0000-4000-8000-000000000026'::uuid, 'werkzeugkoffer-108-teilig'),
  ('c0000000-0000-4000-8000-000000000027'::uuid, 'yoga-set-balance'),
  ('c0000000-0000-4000-8000-000000000028'::uuid, 'trekking-rucksack-35l'),
  ('c0000000-0000-4000-8000-000000000029'::uuid, 'holzbausteine-regenbogen'),
  ('c0000000-0000-4000-8000-000000000030'::uuid, 'babydecke-bio-baumwolle')
)
update public.products p set country_code = 'DE'
from demo_products seed, phase3_demo_sellers seller_seed, public.sellers s
where p.id = seed.id and p.slug = seed.slug and p.seller_id = seller_seed.id
  and s.id = seller_seed.id and s.slug = seller_seed.slug and s.user_id is null
  and s.country_code = 'DE' and p.specifications @> '{"demo":true}'::jsonb
  and p.country_code is null;
commit;
