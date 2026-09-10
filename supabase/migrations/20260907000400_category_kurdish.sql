-- Kurdish is a first-class app language (master spec §42). Categories gain a
-- Kurmanji name column; rows without a reviewed translation fall back to
-- German at the client. app_language gains 'ku' so profile/notification
-- locale columns can store it natively.
begin;

alter table public.categories add column name_ku text;

update public.categories as category
set name_ku = mapping.name_ku
from (values
  -- roots
  ('elektronik', 'Elektronîk'),
  ('mode-damen', 'Moda Jinan'),
  ('mode-herren', 'Moda Mêran'),
  ('beauty-pflege', 'Bedewî & Parastin'),
  ('haushalt-kueche', 'Mal & Aşxane'),
  ('moebel-deko', 'Mobîlya & Dekorasyon'),
  ('auto-zubehoer', 'Otomobîl & Aksesuar'),
  ('uhren-schmuck', 'Demjimêr & Zîver'),
  ('sport-freizeit', 'Werziş & Valatî'),
  ('kinder-baby', 'Zarok & Pitik'),
  ('werkzeug-industrie', 'Amûr & Pîşesazî'),
  ('lebensmittel-suesses', 'Xurek & Şîrînî'),
  -- elektronik
  ('smartphones', 'Telefonên Jîr'),
  ('laptops-tablets', 'Kompyuterên Berbang & Tablet'),
  ('audio', 'Deng'),
  ('elektronik-zubehoer', 'Aksesuar'),
  ('konsolen-gaming', 'Konsol & Lîstin'),
  -- mode-damen
  ('damen-kleidung', 'Kincên Jinan'),
  ('damen-schuhe', 'Kincên Lingan ên Jinan'),
  ('damen-taschen', 'Çanteyên Jinan'),
  ('damen-accessoires', 'Aksesuarên Jinan'),
  -- mode-herren
  ('herren-kleidung', 'Kincên Mêran'),
  ('herren-schuhe', 'Kincên Lingan ên Mêran'),
  ('herren-uhren', 'Demjimêrên Mêran'),
  ('herren-accessoires', 'Aksesuarên Mêran'),
  -- beauty-pflege
  ('parfuem', 'Bomê'),
  ('make-up', 'Rûmak'),
  ('haarpflege', 'Parastina Poran'),
  ('pflegegeraete', 'Amûrên Parastinê'),
  -- haushalt-kueche
  ('kochgeschirr', 'Kesan û Tewan'),
  ('kuechengeraete', 'Amûrên Aşxaneyê'),
  ('aufbewahrung', 'Kefzên Depokirinê'),
  -- moebel-deko
  ('moebel', 'Mobîlya'),
  ('beleuchtung', 'Ronakbîrî'),
  ('wohnaccessoires', 'Aksesuarên Malê'),
  -- auto-zubehoer
  ('innenausstattung', 'Cihê Hundir'),
  ('autopflege', 'Parastina Otomobîlê'),
  ('ersatzteile', 'Perçeyên Guhertinê'),
  ('auto-elektronik', 'Elektronîka Otomobîlê'),
  -- uhren-schmuck
  ('uhren', 'Demjimêr'),
  ('schmuck', 'Zîver'),
  -- sport-freizeit
  ('fitness', 'Werzişa Awaţê'),
  ('outdoor', 'Dervazî'),
  ('fahrraeder', 'Bisîklet'),
  ('teamsport', 'Werzişa Tîmî'),
  -- kinder-baby
  ('babybekleidung', 'Kincên Pitikan'),
  ('spielzeug', 'Lîstik'),
  ('kinderwagen', 'Waginê Zarokan'),
  ('babyausstattung', 'Cihazên Pitikan'),
  -- werkzeug-industrie
  ('handwerkzeuge', 'Amûrên Destan'),
  ('elektrowerkzeuge', 'Amûrên Elektrîkî'),
  ('betriebsausstattung', 'Cihazên Karsaziyê'),
  -- lebensmittel-suesses
  ('restaurants', 'Xwarinxane'),
  ('suesswaren', 'Şîrînî'),
  ('getraenke', 'Vexwarin')
) as mapping(slug, name_ku)
where category.slug = mapping.slug
  and category.name_ku is null;

-- app_language enum gains 'ku' (idempotent). Handlers that map requested
-- languages keep their else-branches; 'ku' values now persist natively.
alter type public.app_language add value if not exists 'ku';

commit;
