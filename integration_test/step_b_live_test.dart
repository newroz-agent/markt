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
import 'package:zerin_marketplace/features/categories/presentation/category_products_screen.dart';
import 'package:zerin_marketplace/features/categories/presentation/controllers/category_products_controller.dart';
import 'package:zerin_marketplace/features/moderation/presentation/controllers/moderation_controller.dart';
import 'package:zerin_marketplace/features/moderation/presentation/moderation_screen.dart';
import 'package:zerin_marketplace/features/sell/presentation/controllers/sell_controller.dart';
import 'package:zerin_marketplace/features/sell/presentation/sell_foundation_screen.dart';
import 'package:zerin_marketplace/features/settings/presentation/controllers/app_settings_controller.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

const _ownerEmail = 'step-b-ios-owner@example.invalid';
const _adminEmail = 'step-b-ios-admin@example.invalid';
const _password = 'ZerinStepB!2026';
const _templateTitle = 'Wireless Kopfhörer Nova X';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late SupabaseClient client;
  late SharedPreferences preferences;
  late ProviderContainer container;
  late GoRouter router;
  late String categoryId;
  late String listingTitle;
  final checks = <String, String>{};

  Future<void> until(
    WidgetTester tester,
    bool Function() condition,
    String reason,
  ) async {
    final deadline = DateTime.now().add(const Duration(seconds: 45));
    while (!condition() && DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(condition(), isTrue, reason: reason);
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> screenshot(WidgetTester tester, String name) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 30),
    );
    expect(tester.takeException(), isNull);
    final bytes = await binding.takeScreenshot('step_b_$name');
    expect(bytes.length, greaterThan(1000));
    checks[name] = 'PASS';
  }

  AppLocalizations labels(WidgetTester tester) =>
      tester.element(find.byType(Scaffold).first).l10n;

  Future<void> signIn(String email) async {
    await client.auth.signOut();
    final response = await client.auth.signInWithPassword(
      email: email,
      password: _password,
    );
    expect(response.session, isNotNull);
  }

  setUpAll(() async {
    expect(AppEnvironment.isSupabaseConfigured, isTrue);
    expect(
      <String>['localhost', '127.0.0.1', '::1'],
      contains(Uri.parse(AppEnvironment.supabaseUrl).host),
      reason: 'Step B acceptance is intentionally restricted to local Supabase',
    );
    client = SupabaseClient(
      AppEnvironment.supabaseUrl,
      AppEnvironment.supabaseAnonKey,
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );
    preferences = await SharedPreferences.getInstance();
    await preferences.setBool(SettingsStorageKeys.onboardingComplete, true);
    final template = await client
        .from('products')
        .select('category_id')
        .eq('title', _templateTitle)
        .eq('status', 'active')
        .single();
    categoryId = template['category_id'] as String;
    listingTitle = 'Zêrîn Prüfangebot ${DateTime.now().millisecondsSinceEpoch}';
  });

  tearDownAll(() async {
    binding.reportData ??= <String, dynamic>{};
    binding.reportData!['checks'] = checks;
    binding.reportData!['tests'] = <String, String>{
      for (final entry in binding.results.entries)
        entry.key: entry.value == 'success' ? 'PASS' : 'FAIL',
    };
    await client.auth.signOut();
    await client.dispose();
  });

  testWidgets('real iOS unified Sell and moderation publication flow', (
    tester,
  ) async {
    await signIn(_ownerEmail);
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
      () => find.byType(SellFoundationScreen).evaluate().isNotEmpty,
      'Sell tab opens',
    );

    final catalogSearch = find.descendant(
      of: find.byKey(const ValueKey('sell-catalog-step')),
      matching: find.byType(EditableText),
    );
    await tester.enterText(catalogSearch, 'Nova X');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await until(
      tester,
      () => find.text(_templateTitle).evaluate().isNotEmpty,
      'Catalog template search returns a real active listing',
    );
    await screenshot(tester, 'catalog_template_search');

    await tester.tap(find.text(labels(tester).sellCatalogUseTemplate).first);
    await until(
      tester,
      () =>
          find.byKey(const ValueKey('sell-details-step')).evaluate().isNotEmpty,
      'Template opens unified details',
    );
    await until(
      tester,
      () =>
          find.text(labels(tester).sellTemplateImported).evaluate().isNotEmpty,
      'Real template image is downloaded and compressed',
    );
    await tester.tap(find.byTooltip(labels(tester).actionBack));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sell-free-form')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('sell-title-field')),
        matching: find.byType(EditableText),
      ),
      listingTitle,
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('sell-price-field')),
        matching: find.byType(EditableText),
      ),
      '179,90',
    );
    final cityField = find.byKey(const ValueKey('sell-city-null'));
    await tester.ensureVisible(cityField);
    await tester.tap(cityField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Berlin').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('sell-description-field')),
        matching: find.byType(EditableText),
      ),
      'Vollständiges freies iOS Prüfangebot mit echtem Foto-Upload.',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.drag(
      find.byKey(const ValueKey('sell-details-step')),
      const Offset(0, 900),
    );
    await tester.pumpAndSettle();
    await screenshot(tester, 'free_form_details');

    final detailsNext = find.byKey(const ValueKey('sell-details-next'));
    await tester.ensureVisible(detailsNext);
    await tester.drag(
      find.byKey(const ValueKey('sell-details-step')),
      const Offset(0, -220),
    );
    await tester.pumpAndSettle();
    expect(tester.getCenter(detailsNext).dy, lessThan(820));
    await tester.tap(detailsNext);
    await until(
      tester,
      () =>
          find.byKey(const ValueKey('sell-photos-step')).evaluate().isNotEmpty,
      'Validated details continue to photos',
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('sell-photos-step')),
        matching: find.byType(Image),
      ),
      findsWidgets,
      reason: 'Template import supplies a compressed in-memory photo',
    );
    await screenshot(tester, 'photo_upload');

    await tester.tap(find.byKey(const ValueKey('sell-photos-next')));
    await tester.pumpAndSettle();
    final submit = find.byKey(const ValueKey('sell-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await until(
      tester,
      () =>
          find.byKey(const ValueKey('sell-confirmation')).evaluate().isNotEmpty,
      'Protected upload and atomic pending submission complete',
    );
    final submitted = container
        .read(sellSubmissionControllerProvider)
        .requireValue!;
    expect(submitted.status.name, 'pendingReview');
    final productId = submitted.id;
    final pendingRow = await client
        .from('products')
        .select('status')
        .eq('id', productId)
        .single();
    expect(pendingRow['status'], 'pending_review');
    await screenshot(tester, 'pending_confirmation');

    await client.auth.signOut();
    await until(
      tester,
      () => client.auth.currentUser == null,
      'Owner signs out before public visibility check',
    );
    final hiddenRows = await client
        .from('products')
        .select('id')
        .eq('id', productId);
    expect(hiddenRows, isEmpty);
    router.go(CategoryProductsRoute(categoryId: categoryId).location);
    await until(
      tester,
      () => find.byType(CategoryProductsScreen).evaluate().isNotEmpty,
      'Public category screen opens',
    );
    await tester.enterText(find.byType(EditableText).first, listingTitle);
    await tester.pump(const Duration(seconds: 1));
    await until(tester, () {
      final state = container.read(categoryProductsProvider(categoryId));
      return state.hasValue && state.requireValue.isEmpty;
    }, 'Public category search is empty before approval');
    await screenshot(tester, 'public_before_approval');

    await signIn(_adminEmail);
    router.go(const ModerationRoute().location);
    await until(
      tester,
      () =>
          find.byType(ModerationScreen).evaluate().isNotEmpty &&
          find.text(listingTitle).evaluate().isNotEmpty,
      'Server-admin moderation queue contains pending listing',
    );
    await screenshot(tester, 'moderation_queue');
    final approve = find.byKey(ValueKey('moderation-approve-$productId'));
    final moderationScroll = find
        .descendant(
          of: find.byType(ModerationScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    for (var attempt = 0; attempt < 5; attempt++) {
      if (tester.getCenter(approve).dy < 800) break;
      await tester.drag(moderationScroll, const Offset(0, -400));
      await tester.pumpAndSettle();
    }
    expect(tester.getCenter(approve).dy, lessThan(800));
    await tester.tap(approve);
    await until(tester, () {
      final dashboard = container.read(moderationDashboardProvider);
      return dashboard.hasValue &&
          dashboard.requireValue.items.every((item) => item.id != productId);
    }, 'Approved listing leaves pending queue');
    final activeRow = await client
        .from('products')
        .select('status')
        .eq('id', productId)
        .single();
    expect(activeRow['status'], 'active');

    await client.auth.signOut();
    await until(
      tester,
      () => client.auth.currentUser == null,
      'Admin signs out before public publication check',
    );
    router.go(CategoryProductsRoute(categoryId: categoryId).location);
    await until(
      tester,
      () => find.byType(CategoryProductsScreen).evaluate().isNotEmpty,
      'Public category screen reopens after approval',
    );
    await tester.enterText(find.byType(EditableText).first, listingTitle);
    await tester.pump(const Duration(seconds: 1));
    await until(tester, () {
      final state = container.read(categoryProductsProvider(categoryId));
      return state.hasValue &&
          state.requireValue.any((product) => product.id == productId);
    }, 'Approved listing appears through public category contract');
    expect(find.text(listingTitle), findsNWidgets(2));
    await screenshot(tester, 'public_after_approval');

    expect(checks, hasLength(7));
  });
}
