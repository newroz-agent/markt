-- Localized, admin-editable two-level category tree for the German launch.

begin;

create temporary table marketplace_category_seed (
  parent_slug text,
  slug text primary key,
  name_de text,
  name_en text,
  name_ar text,
  name_tr text,
  icon_key text,
  image_url text,
  sort_order integer,
  is_active boolean
) on commit drop;

insert into marketplace_category_seed (
  parent_slug,
  slug,
  name_de,
  name_en,
  name_ar,
  name_tr,
  icon_key,
  image_url,
  sort_order,
  is_active
)
values
  (null, 'elektronik', 'Elektronik', 'Electronics', 'إلكترونيات', 'Elektronik', 'devices', 'https://images.unsplash.com/photo-1498049794561-7780e7231661?auto=format&fit=crop&w=1200&q=80', 10, true),
  (null, 'mode-damen', 'Mode Damen', 'Women''s Fashion', 'أزياء نسائية', 'Kadın Modası', 'checkroom', 'https://images.unsplash.com/photo-1445205170230-053b83016050?auto=format&fit=crop&w=1200&q=80', 20, true),
  (null, 'mode-herren', 'Mode Herren', 'Men''s Fashion', 'أزياء رجالية', 'Erkek Modası', 'styler', 'https://images.unsplash.com/photo-1617137968427-85924c800a22?auto=format&fit=crop&w=1200&q=80', 30, true),
  (null, 'beauty-pflege', 'Beauty & Pflege', 'Beauty & Care', 'الجمال والعناية', 'Güzellik ve Bakım', 'spa', 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?auto=format&fit=crop&w=1200&q=80', 40, true),
  (null, 'haushalt-kueche', 'Haushalt & Küche', 'Home & Kitchen', 'المنزل والمطبخ', 'Ev ve Mutfak', 'countertops', 'https://images.unsplash.com/photo-1556911220-bff31c812dba?auto=format&fit=crop&w=1200&q=80', 50, true),
  (null, 'moebel-deko', 'Möbel & Deko', 'Furniture & Decor', 'الأثاث والديكور', 'Mobilya ve Dekorasyon', 'chair', 'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&w=1200&q=80', 60, true),
  (null, 'auto-zubehoer', 'Auto & Zubehör', 'Automotive', 'السيارات وملحقاتها', 'Otomotiv', 'directions_car', 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=1200&q=80', 70, true),
  (null, 'uhren-schmuck', 'Uhren & Schmuck', 'Watches & Jewelry', 'الساعات والمجوهرات', 'Saat ve Takı', 'watch', 'https://images.unsplash.com/photo-1523170335258-f5ed11844a49?auto=format&fit=crop&w=1200&q=80', 80, true),
  (null, 'sport-freizeit', 'Sport & Freizeit', 'Sports & Leisure', 'الرياضة والترفيه', 'Spor ve Eğlence', 'sports_soccer', 'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?auto=format&fit=crop&w=1200&q=80', 90, true),
  (null, 'kinder-baby', 'Kinder & Baby', 'Kids & Baby', 'الأطفال والرضع', 'Çocuk ve Bebek', 'child_friendly', 'https://images.unsplash.com/photo-1516627145497-ae6968895b74?auto=format&fit=crop&w=1200&q=80', 100, true),
  (null, 'werkzeug-industrie', 'Werkzeug & Industrie', 'Tools & Industry', 'الأدوات والصناعة', 'Aletler ve Endüstri', 'construction', 'https://images.unsplash.com/photo-1530124566582-a618bc2615dc?auto=format&fit=crop&w=1200&q=80', 110, true),
  (null, 'lebensmittel-suesses', 'Lebensmittel & Süßes', 'Food & Sweets', 'الأطعمة والحلويات', 'Gıda ve Tatlı', 'restaurant', 'https://images.unsplash.com/photo-1606312619070-d48b4c652a52?auto=format&fit=crop&w=1200&q=80', 120, false),

  ('elektronik', 'smartphones', 'Smartphones', 'Smartphones', 'هواتف ذكية', 'Akıllı Telefonlar', 'smartphone', 'https://images.unsplash.com/photo-1498049794561-7780e7231661?auto=format&fit=crop&w=1200&q=80', 10, true),
  ('elektronik', 'laptops-tablets', 'Laptops & Tablets', 'Laptops & Tablets', 'حواسيب محمولة وأجهزة لوحية', 'Dizüstü Bilgisayarlar ve Tabletler', 'laptop_mac', 'https://images.unsplash.com/photo-1498049794561-7780e7231661?auto=format&fit=crop&w=1200&q=80', 20, true),
  ('elektronik', 'audio', 'Audio', 'Audio', 'صوتيات', 'Ses Sistemleri', 'headphones', 'https://images.unsplash.com/photo-1498049794561-7780e7231661?auto=format&fit=crop&w=1200&q=80', 30, true),
  ('elektronik', 'elektronik-zubehoer', 'Zubehör', 'Accessories', 'ملحقات', 'Aksesuarlar', 'cable', 'https://images.unsplash.com/photo-1498049794561-7780e7231661?auto=format&fit=crop&w=1200&q=80', 40, true),
  ('elektronik', 'konsolen-gaming', 'Konsolen & Gaming', 'Consoles & Gaming', 'أجهزة وألعاب الفيديو', 'Konsol ve Oyun', 'sports_esports', 'https://images.unsplash.com/photo-1498049794561-7780e7231661?auto=format&fit=crop&w=1200&q=80', 50, true),

  ('mode-damen', 'damen-kleidung', 'Kleidung', 'Clothing', 'ملابس', 'Giyim', 'checkroom', 'https://images.unsplash.com/photo-1445205170230-053b83016050?auto=format&fit=crop&w=1200&q=80', 10, true),
  ('mode-damen', 'damen-schuhe', 'Schuhe', 'Shoes', 'أحذية', 'Ayakkabı', 'steps', 'https://images.unsplash.com/photo-1445205170230-053b83016050?auto=format&fit=crop&w=1200&q=80', 20, true),
  ('mode-damen', 'damen-taschen', 'Taschen', 'Bags', 'حقائب', 'Çantalar', 'shopping_bag', 'https://images.unsplash.com/photo-1445205170230-053b83016050?auto=format&fit=crop&w=1200&q=80', 30, true),
  ('mode-damen', 'damen-accessoires', 'Accessoires', 'Accessories', 'إكسسوارات', 'Aksesuarlar', 'diamond', 'https://images.unsplash.com/photo-1445205170230-053b83016050?auto=format&fit=crop&w=1200&q=80', 40, true),

  ('mode-herren', 'herren-kleidung', 'Kleidung', 'Clothing', 'ملابس', 'Giyim', 'checkroom', 'https://images.unsplash.com/photo-1617137968427-85924c800a22?auto=format&fit=crop&w=1200&q=80', 10, true),
  ('mode-herren', 'herren-schuhe', 'Schuhe', 'Shoes', 'أحذية', 'Ayakkabı', 'steps', 'https://images.unsplash.com/photo-1617137968427-85924c800a22?auto=format&fit=crop&w=1200&q=80', 20, true),
  ('mode-herren', 'herren-uhren', 'Uhren', 'Watches', 'ساعات', 'Saatler', 'watch', 'https://images.unsplash.com/photo-1617137968427-85924c800a22?auto=format&fit=crop&w=1200&q=80', 30, true),
  ('mode-herren', 'herren-accessoires', 'Accessoires', 'Accessories', 'إكسسوارات', 'Aksesuarlar', 'styler', 'https://images.unsplash.com/photo-1617137968427-85924c800a22?auto=format&fit=crop&w=1200&q=80', 40, true),

  ('beauty-pflege', 'parfuem', 'Parfüm', 'Perfume', 'عطور', 'Parfüm', 'air', 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?auto=format&fit=crop&w=1200&q=80', 10, true),
  ('beauty-pflege', 'make-up', 'Make-up', 'Makeup', 'مكياج', 'Makyaj', 'brush', 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?auto=format&fit=crop&w=1200&q=80', 20, true),
  ('beauty-pflege', 'haarpflege', 'Haarpflege', 'Hair Care', 'العناية بالشعر', 'Saç Bakımı', 'content_cut', 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?auto=format&fit=crop&w=1200&q=80', 30, true),
  ('beauty-pflege', 'pflegegeraete', 'Pflegegeräte', 'Beauty Devices', 'أجهزة العناية', 'Bakım Cihazları', 'health_and_beauty', 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?auto=format&fit=crop&w=1200&q=80', 40, true),

  ('haushalt-kueche', 'kochgeschirr', 'Kochgeschirr', 'Cookware', 'أدوات الطبخ', 'Pişirme Gereçleri', 'skillet', 'https://images.unsplash.com/photo-1556911220-bff31c812dba?auto=format&fit=crop&w=1200&q=80', 10, true),
  ('haushalt-kueche', 'kuechengeraete', 'Küchengeräte', 'Kitchen Appliances', 'أجهزة المطبخ', 'Mutfak Aletleri', 'blender', 'https://images.unsplash.com/photo-1556911220-bff31c812dba?auto=format&fit=crop&w=1200&q=80', 20, true),
  ('haushalt-kueche', 'aufbewahrung', 'Aufbewahrung', 'Storage', 'التخزين', 'Saklama', 'inventory_2', 'https://images.unsplash.com/photo-1556911220-bff31c812dba?auto=format&fit=crop&w=1200&q=80', 30, true),

  ('moebel-deko', 'moebel', 'Möbel', 'Furniture', 'أثاث', 'Mobilya', 'chair', 'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&w=1200&q=80', 10, true),
  ('moebel-deko', 'beleuchtung', 'Beleuchtung', 'Lighting', 'إضاءة', 'Aydınlatma', 'light', 'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&w=1200&q=80', 20, true),
  ('moebel-deko', 'wohnaccessoires', 'Wohnaccessoires', 'Home Accessories', 'إكسسوارات منزلية', 'Ev Aksesuarları', 'home', 'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&w=1200&q=80', 30, true),

  ('auto-zubehoer', 'innenausstattung', 'Innenausstattung', 'Interior', 'تجهيزات داخلية', 'İç Donanım', 'airline_seat_recline_normal', 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=1200&q=80', 10, true),
  ('auto-zubehoer', 'autopflege', 'Pflege', 'Car Care', 'العناية بالسيارة', 'Araç Bakımı', 'cleaning_services', 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=1200&q=80', 20, true),
  ('auto-zubehoer', 'ersatzteile', 'Ersatzteile', 'Spare Parts', 'قطع غيار', 'Yedek Parçalar', 'car_repair', 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=1200&q=80', 30, true),
  ('auto-zubehoer', 'auto-elektronik', 'Elektronik', 'Electronics', 'إلكترونيات السيارة', 'Araç Elektroniği', 'memory', 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=1200&q=80', 40, true),

  ('uhren-schmuck', 'uhren', 'Uhren', 'Watches', 'ساعات', 'Saatler', 'watch', 'https://images.unsplash.com/photo-1523170335258-f5ed11844a49?auto=format&fit=crop&w=1200&q=80', 10, true),
  ('uhren-schmuck', 'schmuck', 'Schmuck', 'Jewelry', 'مجوهرات', 'Takı', 'diamond', 'https://images.unsplash.com/photo-1523170335258-f5ed11844a49?auto=format&fit=crop&w=1200&q=80', 20, true),

  ('sport-freizeit', 'fitness', 'Fitness', 'Fitness', 'لياقة بدنية', 'Fitness', 'fitness_center', 'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?auto=format&fit=crop&w=1200&q=80', 10, true),
  ('sport-freizeit', 'outdoor', 'Outdoor', 'Outdoor', 'أنشطة خارجية', 'Outdoor', 'hiking', 'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?auto=format&fit=crop&w=1200&q=80', 20, true),
  ('sport-freizeit', 'fahrraeder', 'Fahrräder', 'Bicycles', 'دراجات', 'Bisikletler', 'pedal_bike', 'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?auto=format&fit=crop&w=1200&q=80', 30, true),
  ('sport-freizeit', 'teamsport', 'Teamsport', 'Team Sports', 'رياضات جماعية', 'Takım Sporları', 'sports_handball', 'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?auto=format&fit=crop&w=1200&q=80', 40, true),

  ('kinder-baby', 'babybekleidung', 'Babybekleidung', 'Baby Clothing', 'ملابس الرضع', 'Bebek Giyimi', 'checkroom', 'https://images.unsplash.com/photo-1516627145497-ae6968895b74?auto=format&fit=crop&w=1200&q=80', 10, true),
  ('kinder-baby', 'spielzeug', 'Spielzeug', 'Toys', 'ألعاب', 'Oyuncaklar', 'toys', 'https://images.unsplash.com/photo-1516627145497-ae6968895b74?auto=format&fit=crop&w=1200&q=80', 20, true),
  ('kinder-baby', 'kinderwagen', 'Kinderwagen', 'Strollers', 'عربات أطفال', 'Bebek Arabaları', 'baby_changing_station', 'https://images.unsplash.com/photo-1516627145497-ae6968895b74?auto=format&fit=crop&w=1200&q=80', 30, true),
  ('kinder-baby', 'babyausstattung', 'Babyausstattung', 'Baby Equipment', 'مستلزمات الرضع', 'Bebek Ekipmanları', 'child_friendly', 'https://images.unsplash.com/photo-1516627145497-ae6968895b74?auto=format&fit=crop&w=1200&q=80', 40, true),

  ('werkzeug-industrie', 'handwerkzeuge', 'Handwerkzeuge', 'Hand Tools', 'أدوات يدوية', 'El Aletleri', 'handyman', 'https://images.unsplash.com/photo-1530124566582-a618bc2615dc?auto=format&fit=crop&w=1200&q=80', 10, true),
  ('werkzeug-industrie', 'elektrowerkzeuge', 'Elektrowerkzeuge', 'Power Tools', 'أدوات كهربائية', 'Elektrikli Aletler', 'power', 'https://images.unsplash.com/photo-1530124566582-a618bc2615dc?auto=format&fit=crop&w=1200&q=80', 20, true),
  ('werkzeug-industrie', 'betriebsausstattung', 'Betriebsausstattung', 'Industrial Equipment', 'معدات صناعية', 'Endüstriyel Ekipman', 'factory', 'https://images.unsplash.com/photo-1530124566582-a618bc2615dc?auto=format&fit=crop&w=1200&q=80', 30, true),

  ('lebensmittel-suesses', 'restaurants', 'Restaurants', 'Restaurants', 'مطاعم', 'Restoranlar', 'restaurant', 'https://images.unsplash.com/photo-1606312619070-d48b4c652a52?auto=format&fit=crop&w=1200&q=80', 10, false),
  ('lebensmittel-suesses', 'suesswaren', 'Süßwaren', 'Sweets', 'حلويات', 'Tatlılar', 'cake', 'https://images.unsplash.com/photo-1606312619070-d48b4c652a52?auto=format&fit=crop&w=1200&q=80', 20, false),
  ('lebensmittel-suesses', 'getraenke', 'Getränke', 'Drinks', 'مشروبات', 'İçecekler', 'local_drink', 'https://images.unsplash.com/photo-1606312619070-d48b4c652a52?auto=format&fit=crop&w=1200&q=80', 30, false);

insert into public.categories (
  parent_id,
  slug,
  name_de,
  name_en,
  name_ar,
  name_tr,
  icon_key,
  image_url,
  sort_order,
  is_active
)
select
  null,
  seed.slug,
  seed.name_de,
  seed.name_en,
  seed.name_ar,
  seed.name_tr,
  seed.icon_key,
  seed.image_url,
  seed.sort_order,
  seed.is_active
from marketplace_category_seed as seed
where seed.parent_slug is null
on conflict (slug) do update set
  parent_id = null,
  name_de = excluded.name_de,
  name_en = excluded.name_en,
  name_ar = excluded.name_ar,
  name_tr = excluded.name_tr,
  icon_key = excluded.icon_key,
  image_url = excluded.image_url,
  sort_order = excluded.sort_order,
  is_active = excluded.is_active;

insert into public.categories (
  parent_id,
  slug,
  name_de,
  name_en,
  name_ar,
  name_tr,
  icon_key,
  image_url,
  sort_order,
  is_active
)
select
  parent.id,
  seed.slug,
  seed.name_de,
  seed.name_en,
  seed.name_ar,
  seed.name_tr,
  seed.icon_key,
  seed.image_url,
  seed.sort_order,
  seed.is_active
from marketplace_category_seed as seed
join public.categories as parent on parent.slug = seed.parent_slug
where seed.parent_slug is not null
on conflict (slug) do update set
  parent_id = excluded.parent_id,
  name_de = excluded.name_de,
  name_en = excluded.name_en,
  name_ar = excluded.name_ar,
  name_tr = excluded.name_tr,
  icon_key = excluded.icon_key,
  image_url = excluded.image_url,
  sort_order = excluded.sort_order,
  is_active = excluded.is_active;

commit;
