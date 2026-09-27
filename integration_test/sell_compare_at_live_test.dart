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
import 'package:zerin_marketplace/features/sell/presentation/sell_foundation_screen.dart';
import 'package:zerin_marketplace/features/settings/presentation/controllers/app_settings_controller.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late SupabaseClient client;
  late SharedPreferences preferences;
  late ProviderContainer container;
  late GoRouter router;
  late int compareAtCount;
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
    final bytes = await binding.takeScreenshot('sell_compare_at_$name');
    expect(bytes.length, greaterThan(1000));
    checks[name] = 'PASS';
  }

  setUpAll(() async {
    expect(AppEnvironment.isSupabaseConfigured, isTrue);
    expect(
      <String>['localhost', '127.0.0.1', '::1'],
      contains(Uri.parse(AppEnvironment.supabaseUrl).host),
      reason:
          'Sell compare-at acceptance is intentionally restricted to local Supabase',
    );
    client = SupabaseClient(
      AppEnvironment.supabaseUrl,
      AppEnvironment.supabaseAnonKey,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    preferences = await SharedPreferences.getInstance();
    await preferences.setBool(SettingsStorageKeys.onboardingComplete, true);

    final deals = await client
        .from('products')
        .select('id')
        .eq('status', 'active')
        .not('compare_at_price_cents', 'is', null);
    compareAtCount = (deals as List).length;
    expect(compareAtCount, greaterThan(0));

    final signature = await client.rpc<List<dynamic>>(
      'submit_listing',
      params: const <String, dynamic>{},
    ).catchError((Object error) => <dynamic>[]);
    expect(signature, isA<List<dynamic>>());
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
        'SELL_COMPARE_AT_DEVICE',
        defaultValue: 'unknown',
      ),
    };
    binding.reportData!['evidence'] = <String, Object>{
      'compare_at_products': compareAtCount,
    };
    await client.dispose();
  });

  testWidgets('real iOS Sell flow exposes the Originalpreis field', (
    tester,
  ) async {
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
    router.go(const MarketplaceRoute(tab: 2).location);
    await until(
      tester,
      () =>
          find.byType(SellFoundationScreen).evaluate().isNotEmpty &&
          find.byKey(const ValueKey('sell-free-form')).evaluate().isNotEmpty,
      'Sell flow loads the free-form entry action',
    );

    await tester.tap(find.byKey(const ValueKey('sell-free-form')));
    await until(
      tester,
      () =>
          find.byKey(const ValueKey('sell-details-step')).evaluate().isNotEmpty &&
          find
              .byKey(const ValueKey('sell-compare-at-price-field'))
              .evaluate()
              .isNotEmpty,
      'Details step shows the Originalpreis field',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('sell-compare-at-price-field')),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Originalpreis in Euro (optional)'), findsOneWidget);
    expect(
      find.text('Durchgestrichener Preis neben deinem Preis'),
      findsOneWidget,
    );
    await screenshot(tester, 'sell_originalpreis_field');
    expect(checks, hasLength(1));
  });
}
