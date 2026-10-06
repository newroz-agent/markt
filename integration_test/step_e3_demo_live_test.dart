import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerin_marketplace/app/app.dart';
import 'package:zerin_marketplace/app/router/app_router.dart';
import 'package:zerin_marketplace/core/config/app_environment.dart';
import 'package:zerin_marketplace/core/providers/infrastructure_providers.dart';
import 'package:zerin_marketplace/core/widgets/app_skeleton.dart';
import 'package:zerin_marketplace/features/categories/presentation/category_products_screen.dart';
import 'package:zerin_marketplace/features/home/presentation/home_foundation_screen.dart';
import 'package:zerin_marketplace/features/map/domain/device_location_service.dart';
import 'package:zerin_marketplace/features/map/presentation/controllers/map_controller.dart';
import 'package:zerin_marketplace/features/map/presentation/map_screen.dart';
import 'package:zerin_marketplace/features/products/presentation/product_detail_screen.dart';
import 'package:zerin_marketplace/features/settings/presentation/controllers/app_settings_controller.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late SupabaseClient client;
  late SharedPreferences preferences;
  late ProviderContainer container;
  late GoRouter router;
  final checks = <String, String>{};
  final categoryIds = <String, String>{};
  final demoTitles = <String, List<String>>{};
  final demoProductIds = <String>[];
  final demoImageUrls = <String>[];
  final failedImageUrls = <String>[];
  // Newest demo deal; Home Angebote orders by published_at, so it renders first.
  const homeDealTitle = 'Schwarzer Business-Anzug, Größe 52';
  const slugs = <String>[
    'anzuege',
    'goldschmuck',
    'silberschmuck',
    'eheringe',
    'saiteninstrumente',
    'schlaginstrumente',
    'gewuerze-importwaren',
    'suesswaren',
  ];

  Future<void> until(
    WidgetTester tester,
    bool Function() condition,
    String reason,
  ) async {
    final deadline = DateTime.now().add(const Duration(seconds: 60));
    while (!condition() && DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(condition(), isTrue, reason: reason);
    await tester.pump(const Duration(seconds: 2));
  }

  bool anyText(Iterable<String> titles) =>
      titles.any((title) => find.text(title).evaluate().isNotEmpty);

  Future<void> shot(WidgetTester tester, String name) async {
    await until(
      tester,
      () => find.byType(AppSkeletonBox).evaluate().isEmpty,
      '$name has no visible loading placeholders',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    final bytes = await binding.takeScreenshot('step_e3_demo_$name');
    expect(bytes.length, greaterThan(1000));
    checks[name] = 'PASS';
  }

  setUpAll(() async {
    expect(AppEnvironment.isSupabaseConfigured, isTrue);
    expect(
      Uri.parse(AppEnvironment.supabaseUrl).host,
      isIn(<String>['localhost', '127.0.0.1', '::1']),
      reason: 'E3.0 evidence must use local Supabase only',
    );
    client = SupabaseClient(
      AppEnvironment.supabaseUrl,
      AppEnvironment.supabaseAnonKey,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    expect(
      client.auth.currentUser,
      isNull,
      reason: 'Anonymous detail views make this capture database read-only',
    );
    preferences = await SharedPreferences.getInstance();
    await preferences.setBool(SettingsStorageKeys.onboardingComplete, true);
    for (final slug in slugs) {
      final category = await client
          .from('categories')
          .select('id')
          .eq('slug', slug)
          .single();
      categoryIds[slug] = category['id']! as String;
      final products = await client
          .from('products')
          .select('id, title')
          .eq('category_id', categoryIds[slug]!)
          .eq('status', 'active');
      demoTitles[slug] = <String>[
        for (final row in products)
          if ((row['id'] as String).startsWith('e3d0')) row['title'] as String,
      ];
      demoProductIds.addAll(<String>[
        for (final row in products)
          if ((row['id'] as String).startsWith('e3d0')) row['id'] as String,
      ]);
      expect(
        demoTitles[slug],
        isNotEmpty,
        reason: 'E3.0 $slug must have local demo rows',
      );
    }
    final images = await client
        .from('product_images')
        .select('image_url')
        .inFilter('product_id', demoProductIds);
    demoImageUrls.addAll(<String>[
      for (final row in images) row['image_url'] as String,
    ]);
    expect(demoProductIds, hasLength(20));
    expect(demoImageUrls, hasLength(20));
  });

  tearDownAll(() async {
    binding.reportData ??= <String, dynamic>{};
    binding.reportData!['checks'] = checks;
    binding.reportData!['demo_images'] = <String, Object>{
      'source': 'hotlinked images.pexels.com URLs',
      'precached': demoImageUrls.length - failedImageUrls.length,
      'failed': failedImageUrls,
    };
    binding.reportData!['tests'] = <String, String>{
      for (final entry in binding.results.entries)
        entry.key: entry.value == 'success' ? 'PASS' : 'FAIL',
    };
    binding.reportData!['runtime'] = <String, String>{
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
    };
    await client.dispose();
  });

  testWidgets('E3.0 local demo screenshots', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(preferences),
          supabaseClientProvider.overrideWithValue(client),
          // No location prompt: a system alert makes the app inactive and every
          // capture blank. The map then uses its Berlin fallback.
          deviceLocationServiceProvider.overrideWithValue(
            const _NoDeviceLocation(),
          ),
        ],
        child: const ZerinApp(),
      ),
    );
    await tester.pump();
    container = ProviderScope.containerOf(
      tester.element(find.byType(ZerinApp)),
    );
    router = container.read(appRouterProvider);
    await container
        .read(appSettingsControllerProvider.notifier)
        .setLocale('de');

    // Demo photos are hotlinked from Pexels. Load them into the same image-cache
    // entries the cards use so no capture races a network download.
    final appContext = tester.element(find.byType(ZerinApp));
    await Future.wait(<Future<void>>[
      for (final url in demoImageUrls)
        precacheImage(
          CachedNetworkImageProvider(url),
          appContext,
          onError: (_, _) => failedImageUrls.add(url),
        ),
    ]);
    expect(failedImageUrls, isEmpty, reason: 'Every demo image must load');

    router.go(const MarketplaceRoute().location);
    await until(
      tester,
      () =>
          find.byType(HomeFoundationScreen).evaluate().isNotEmpty &&
          find.text('Angebote').evaluate().isNotEmpty &&
          anyText(<String>[homeDealTitle]),
      'German Home shows demo Angebote',
    );
    // The Angebote title is onstage behind the floating bottom bar, so
    // ensureVisible does not move it; scroll the feed so it sits near the top.
    final feed = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byKey(const PageStorageKey<String>('home-feed')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    final viewHeight = tester.getSize(find.byType(HomeFoundationScreen)).height;
    final dealsTop = tester.getTopLeft(find.text('Angebote')).dy;
    feed.position.jumpTo(
      (feed.position.pixels + dealsTop - viewHeight / 4).clamp(
        0.0,
        feed.position.maxScrollExtent,
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      tester.getTopLeft(find.text('Angebote')).dy,
      lessThan(viewHeight / 2),
      reason: 'Angebote title is in the upper half of German Home',
    );
    await shot(tester, 'home_angebote');

    for (final slug in slugs) {
      router.go(CategoryProductsRoute(categoryId: categoryIds[slug]!).location);
      await until(
        tester,
        () =>
            find.byType(CategoryProductsScreen).evaluate().isNotEmpty &&
            anyText(demoTitles[slug]!),
        '$slug category shows its demo listings',
      );
      await shot(tester, 'category_$slug');
    }

    const productId = 'e3d00000-0000-4000-8002-000000000017';
    router.go(const ProductDetailRoute(productId: productId).location);
    await until(
      tester,
      () =>
          find.byType(ProductDetailScreen).evaluate().isNotEmpty &&
          find.textContaining('Pistazien-Baklava').evaluate().isNotEmpty,
      'E3.0 listing detail loaded',
    );
    await shot(tester, 'listing_detail');

    router.go(const MapRoute().location);
    await until(tester, () {
      final map = container.read(mapControllerProvider);
      return find.byType(MapScreen).evaluate().isNotEmpty &&
          map.hasInitialized &&
          map.listings.any((item) => item.productId.startsWith('e3d0'));
    }, 'Map shows demo listing pins');
    await shot(tester, 'map');

    for (final language in <String>['ku', 'ar']) {
      await container
          .read(appSettingsControllerProvider.notifier)
          .setLocale(language);
      router.go(const MarketplaceRoute().location);
      await until(
        tester,
        () =>
            find.byType(HomeFoundationScreen).evaluate().isNotEmpty &&
            Localizations.localeOf(
                  tester.element(find.byType(HomeFoundationScreen)),
                ).languageCode ==
                language &&
            anyText(<String>[homeDealTitle]),
        '$language Home shows demo listings',
      );
      await shot(tester, 'home_$language');
    }
    expect(checks.length, 13);
  });
}

class _NoDeviceLocation implements DeviceLocationService {
  const _NoDeviceLocation();

  @override
  Future<DeviceLocationResult> getCurrentLocation() async =>
      const DeviceLocationResult.unavailable();
}
