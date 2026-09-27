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
import 'package:zerin_marketplace/features/moderation/presentation/moderation_screen.dart';
import 'package:zerin_marketplace/features/settings/presentation/controllers/app_settings_controller.dart';

const _adminEmail = 'step-b-ios-admin@example.invalid';
const _adminPassword = 'ZerinStepB!2026';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late SupabaseClient client;
  late SharedPreferences preferences;
  late ProviderContainer container;
  late GoRouter router;
  late int pendingListings;
  late int pendingDocs;
  late int openReports;
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
    final bytes = await binding.takeScreenshot('admin_expansion_$name');
    expect(bytes.length, greaterThan(1000));
    checks[name] = 'PASS';
  }

  Future<void> signIn() async {
    await client.auth.signOut();
    final response = await client.auth.signInWithPassword(
      email: _adminEmail,
      password: _adminPassword,
    );
    expect(response.session, isNotNull);
  }

  setUpAll(() async {
    expect(AppEnvironment.isSupabaseConfigured, isTrue);
    expect(
      <String>['localhost', '127.0.0.1', '::1'],
      contains(Uri.parse(AppEnvironment.supabaseUrl).host),
      reason:
          'Admin expansion acceptance is intentionally restricted to local Supabase',
    );
    client = SupabaseClient(
      AppEnvironment.supabaseUrl,
      AppEnvironment.supabaseAnonKey,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    preferences = await SharedPreferences.getInstance();
    await preferences.setBool(SettingsStorageKeys.onboardingComplete, true);

    await signIn();
    final isAdmin = await client.rpc<bool>('is_admin');
    expect(isAdmin, isTrue);

    final dashboard = await client.rpc<Map<String, dynamic>>(
      'get_moderation_dashboard',
      params: const {'p_limit': 50},
    );
    final verification = await client.rpc<Map<String, dynamic>>(
      'get_admin_verification_queue',
      params: const {'p_limit': 50},
    );
    final reports = await client.rpc<Map<String, dynamic>>(
      'get_admin_reports',
      params: const {'p_limit': 50},
    );
    pendingListings = ((dashboard['counts'] as Map)['pending'] as num).toInt();
    pendingDocs = (verification['pending'] as num).toInt();
    openReports = (reports['open'] as num).toInt();
    expect(pendingListings, greaterThan(0));
    expect(pendingDocs, greaterThan(0));
    expect(openReports, greaterThan(0));
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
        'ADMIN_EXPANSION_DEVICE',
        defaultValue: 'unknown',
      ),
    };
    binding.reportData!['evidence'] = <String, Object>{
      'pending_listings': pendingListings,
      'pending_docs': pendingDocs,
      'open_reports': openReports,
    };
    await client.auth.signOut();
    await client.dispose();
  });

  testWidgets('real iOS admin overview, verification queue, and reports', (
    tester,
  ) async {
    await signIn();
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
    router.go(const ModerationRoute().location);
    await until(
      tester,
      () =>
          find.byType(ModerationScreen).evaluate().isNotEmpty &&
          find.text('Offene Angebote').evaluate().isNotEmpty &&
          find.text('Offene Verkäuferdokumente').evaluate().isNotEmpty &&
          find.text('Offene Meldungen').evaluate().isNotEmpty,
      'Admin overview shows pending counts for all three queues',
    );
    await screenshot(tester, 'overview');

    await tester.tap(find.byType(ChoiceChip).at(2));
    await until(
      tester,
      () =>
          find.text('Demo Manufaktur Berlin').evaluate().isNotEmpty &&
          find.text('Freigeben').evaluate().isNotEmpty,
      'Seller verification queue shows the pending document group',
    );
    await screenshot(tester, 'seller_verification');

    await tester.tap(find.byType(ChoiceChip).at(3));
    await until(
      tester,
      () =>
          find.text('Verwerfen').evaluate().isNotEmpty &&
          find.text('Angebot sperren').evaluate().isNotEmpty,
      'Reports queue shows the dismiss and block-listing actions',
    );
    await screenshot(tester, 'reports_queue');

    expect(checks, hasLength(3));
  });
}
