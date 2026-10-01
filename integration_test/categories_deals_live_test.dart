import 'dart:io';

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
import 'package:zerin_marketplace/features/categories/presentation/categories_foundation_screen.dart';
import 'package:zerin_marketplace/features/home/presentation/home_foundation_screen.dart';
import 'package:zerin_marketplace/features/settings/presentation/controllers/app_settings_controller.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late SupabaseClient client;
  late SharedPreferences preferences;
  late ProviderContainer container;
  late GoRouter router;
  late int rootCount;
  late int dealsCount;
  final checks = <String, String>{};

  Future<void> until(
    WidgetTester tester,
    bool Function() condition,
    String reason,
  ) async {
    final deadline = DateTime.now().add(const Duration(seconds: 60));
    while (!condition() && DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(condition(), isTrue, reason: reason);
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> screenshot(WidgetTester tester, String name) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    final bytes = await binding.takeScreenshot('categories_deals_$name');
    expect(bytes.length, greaterThan(1000));
    checks[name] = 'PASS';
  }

  setUpAll(() async {
    expect(AppEnvironment.isSupabaseConfigured, isTrue);
    expect(
      <String>['localhost', '127.0.0.1', '::1'],
      contains(Uri.parse(AppEnvironment.supabaseUrl).host),
      reason:
          'Categories acceptance is intentionally restricted to local Supabase',
    );
    client = SupabaseClient(
      AppEnvironment.supabaseUrl,
      AppEnvironment.supabaseAnonKey,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    preferences = await SharedPreferences.getInstance();
    await preferences.setBool(SettingsStorageKeys.onboardingComplete, true);

    final roots = await client
        .from('categories')
        .select('id, slug')
        .isFilter('parent_id', null)
        .eq('is_active', true);
    rootCount = (roots as List).length;
    expect(rootCount, greaterThanOrEqualTo(13));

    final deals = await client
        .from('products')
        .select('id')
        .eq('status', 'active')
        .not('compare_at_price_cents', 'is', null)
        .limit(10);
    dealsCount = (deals as List).length;
    expect(dealsCount, greaterThan(0));

    for (final slug in <String>[
      'musikinstrumente',
      'goldschmuck',
      'silberschmuck',
      'eheringe',
      'antiker-schmuck',
      'anzuege',
      'frische-lebensmittel',
      'gewuerze-importwaren',
    ]) {
      final row = await client
          .from('categories')
          .select('id')
          .eq('slug', slug)
          .eq('is_active', true)
          .maybeSingle();
      expect(row, isNotNull, reason: 'category $slug must be active');
    }
  });

  tearDownAll(() async {
    binding.reportData ??= <String, dynamic>{};
    binding.reportData!['checks'] = checks;
    binding.reportData!['tests'] = <String, String>{
      for (final entry in binding.results.entries)
        entry.key: entry.value == 'success' ? 'PASS' : 'FAIL',
    };
    binding.reportData!['runtime'] = <String, String>{
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'device': const String.fromEnvironment(
        'CATEGORIES_DEALS_DEVICE',
        defaultValue: 'unknown',
      ),
    };
    binding.reportData!['evidence'] = <String, Object>{
      'root_count': rootCount,
      'deals_count': dealsCount,
    };
    await client.dispose();
  });

  testWidgets('real iOS category grid and Home deals section', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(preferences),
          supabaseClientProvider.overrideWithValue(client),
        ],
        child: const ZerinApp(),
      ),
    );
    await tester.pump();
    container = ProviderScope.containerOf(
      tester.element(find.byType(ZerinApp)),
    );
    await container
        .read(appSettingsControllerProvider.notifier)
        .setLocale('de');
    router = container.read(appRouterProvider);

    router.go(const MarketplaceRoute(tab: 1).location);
    await until(
      tester,
      () =>
          find.byType(CategoriesFoundationScreen).evaluate().isNotEmpty &&
          find.text('Musikinstrumente').evaluate().isNotEmpty,
      'Category grid shows the new Musikinstrumente top-level',
    );
    await screenshot(tester, 'category_grid');

    router.go(const MarketplaceRoute().location);
    await until(
      tester,
      () =>
          find.byType(HomeFoundationScreen).evaluate().isNotEmpty &&
          find.text('Angebote').evaluate().isNotEmpty,
      'Home feed shows the Angebote deals section',
    );
    await screenshot(tester, 'home_deals');

    expect(checks, hasLength(2));
  });
}
