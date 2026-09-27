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

import 'support/harness_cleanup.dart';

const _ownerEmail = 'step-b-ios-owner@example.invalid';
const _adminEmail = 'step-b-ios-admin@example.invalid';
const _password = 'ZerinStepB!2026';
const _templateTitle = 'Wireless Kopfhörer Nova X';
const _imagesBucket = 'product-images';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late SupabaseClient client;
  late SharedPreferences preferences;
  late ProviderContainer container;
  late GoRouter router;
  late String categoryId;
  late String listingTitle;
  late Map<String, int> beforeCounts;
  Map<String, int>? afterCounts;
  final checks = <String, String>{};
  var runStarted = false;
  Map<String, Object?>? cleanup;

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

  Future<Map<String, int>> captureCounts() async {
    final listings = await client.from('products').select('id');
    final imageRows = await client.from('product_images').select('id');
    final storageObjects = await countStorageObjects(
      client,
      bucket: _imagesBucket,
    );
    return <String, int>{
      'listings': listings.length,
      'image_rows': imageRows.length,
      'storage_objects': storageObjects,
    };
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

    await signIn(_adminEmail);
    beforeCounts = await captureCounts();
  });

  tearDownAll(() async {
    // Runs whether the test passed or failed: the run's listing (unique title)
    // and every photo it uploaded are removed, so nothing accumulates.
    if (runStarted) {
      await signIn(_adminEmail);
      final rows = await client
          .from('products')
          .select('id, images:product_images(storage_path)')
          .eq('title', listingTitle);
      final ids = [for (final row in rows) row['id']! as String];
      final paths = <String>[
        for (final row in rows)
          for (final image in row['images']! as List)
            (image as Map)['storage_path']! as String,
      ];
      // Photos first: product-images objects are only visible (and therefore
      // removable) while their listing row exists, even for admins.
      final removed = await removeUploadedObjects(
        client,
        bucket: _imagesBucket,
        paths: paths,
      );
      if (ids.isNotEmpty) {
        await client.from('products').delete().inFilter('id', ids);
      }
      cleanup = <String, Object?>{
        'deleted_listings': ids.length,
        'removed_objects': removed.length,
        'removed_paths': removed,
      };
    } else {
      await signIn(_adminEmail);
    }

    afterCounts = await captureCounts();
    final countsMatch =
        beforeCounts.length == afterCounts!.length &&
        beforeCounts.entries.every(
          (entry) => afterCounts![entry.key] == entry.value,
        );
    binding.reportData ??= <String, dynamic>{};
    binding.reportData!['cleanup'] = cleanup;
    binding.reportData!['counts'] = <String, Object?>{
      'before': beforeCounts,
      'after': afterCounts,
      'matched': countsMatch,
    };
    binding.reportData!['checks'] = checks;
    binding.reportData!['tests'] = <String, String>{
      for (final entry in binding.results.entries)
        entry.key: entry.value == 'success' ? 'PASS' : 'FAIL',
    };
    await client.auth.signOut();
    await client.dispose();
    expect(
      countsMatch,
      isTrue,
      reason: 'Step B listing, image-row, and Storage counts must be restored',
    );
  });

  testWidgets('real iOS unified Sell and moderation publication flow', (
    tester,
  ) async {
    runStarted = true;
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

    // The details list is built lazily and has grown since Step B (compare-at
    // price), so scroll the button into existence instead of assuming it is built.
    final detailsNext = find.byKey(const ValueKey('sell-details-next'));
    final detailsList = find.descendant(
      of: find.byKey(const ValueKey('sell-details-step')),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      detailsNext,
      300,
      scrollable: detailsList.first,
    );
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
    // Since the admin expansion, /moderation opens on the overview tab; the
    // approve action lives on the listings tab.
    await tester.tap(
      find
          .descendant(
            of: find.byType(ModerationScreen),
            matching: find.byType(ChoiceChip),
          )
          .at(1),
    );
    final approve = find.byKey(ValueKey('moderation-approve-$productId'));
    await until(
      tester,
      () => approve.evaluate().isNotEmpty,
      'Listings tab shows the pending listing with its approve action',
    );
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
    final hitTestableApprove = approve.hitTestable();
    expect(hitTestableApprove, findsOneWidget);
    await tester.tap(hitTestableApprove);
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
