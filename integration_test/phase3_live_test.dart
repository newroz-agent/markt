import 'dart:math';

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
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/features/auth/presentation/auth_screen.dart';
import 'package:zerin_marketplace/features/auth/presentation/controllers/auth_controller.dart';
import 'package:zerin_marketplace/features/chat/presentation/chat_conversation_screen.dart';
import 'package:zerin_marketplace/features/home/data/supabase_home_repository.dart';
import 'package:zerin_marketplace/features/home/domain/home_feed.dart';
import 'package:zerin_marketplace/features/home/presentation/controllers/home_controller.dart';
import 'package:zerin_marketplace/features/products/presentation/product_detail_screen.dart';
import 'package:zerin_marketplace/features/sellers/presentation/seller_profile_screen.dart';
import 'package:zerin_marketplace/features/settings/domain/app_settings.dart';
import 'package:zerin_marketplace/features/settings/presentation/controllers/app_settings_controller.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late SupabaseClient client;
  late SharedPreferences preferences;
  late HomeProduct product;
  late ProviderContainer container;
  late GoRouter router;
  final originalPreferences = <String, Object?>{};
  final proof = <String, dynamic>{};
  final runId = DateTime.now().microsecondsSinceEpoch.toString();
  String? buyerId;

  void passed(String checkpoint) {
    proof[checkpoint] = 'PASS';
    binding.reportData ??= <String, dynamic>{};
    binding.reportData!['assertions'] = proof;
    debugPrint('PHASE3 PASS: $checkpoint');
  }

  Future<void> until(
    WidgetTester tester,
    bool Function() condition,
    String reason,
  ) async {
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (!condition() && DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 150));
    }
    expect(condition(), isTrue, reason: reason);
    await tester.pump(const Duration(milliseconds: 350));
  }

  Future<void> screenshot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 30),
    );
    expect(tester.takeException(), isNull);
    final bytes = await binding.takeScreenshot('phase3_$name');
    expect(bytes.length, greaterThan(1000));
  }

  AppLocalizations labels(WidgetTester tester) =>
      tester.element(find.byType(Scaffold).first).l10n;

  Future<void> openProduct(WidgetTester tester) async {
    router.go(ProductDetailRoute(productId: product.id).location);
    await tester.pumpAndSettle();
    await until(
      tester,
      () =>
          find.byType(ProductDetailScreen).evaluate().isNotEmpty &&
          find
              .descendant(
                of: find.byType(ProductDetailScreen),
                matching: find.byType(PageView),
              )
              .evaluate()
              .isNotEmpty,
      'Live product gallery loaded',
    );
    expect(
      tester
          .widget<ProductDetailScreen>(find.byType(ProductDetailScreen))
          .productId,
      product.id,
    );
  }

  Future<void> openSeller(WidgetTester tester) async {
    final card = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          widget.properties.label == labels(tester).viewSellerProfile,
    );
    await tester.scrollUntilVisible(
      card,
      240,
      scrollable: find
          .descendant(
            of: find.byType(ProductDetailScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(card);
    await tester.tap(card);
    await until(
      tester,
      () =>
          find.byType(SellerProfileScreen).evaluate().isNotEmpty &&
          find.byType(ProductCard).evaluate().isNotEmpty,
      'Live seller profile and listings loaded',
    );
    expect(
      GoRouterState.of(
        tester.element(find.byType(SellerProfileScreen)),
      ).uri.path,
      '/sellers/${product.store!.id}',
    );
    expect(find.text(product.store!.shopName), findsWidgets);
  }

  Future<void> openReport(WidgetTester tester) async {
    final l10n = labels(tester);
    await tester.tap(find.byTooltip(l10n.productReport));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.productReport));
    await tester.pumpAndSettle();
  }

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    // These are the same two real infrastructure dependencies as bootstrap().
    // A fresh in-memory Auth client leaves existing persisted sessions alone.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
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
    expect(
      container.read(homeRepositoryProvider),
      isA<SupabaseHomeRepository>(),
    );
    await container
        .read(appSettingsControllerProvider.notifier)
        .setLocale('de');
    await container
        .read(appSettingsControllerProvider.notifier)
        .setTheme(AppThemePreference.light);
    router = container.read(appRouterProvider);
    await openProduct(tester);
  }

  Future<void> authenticate(WidgetTester tester) async {
    if (buyerId == null) {
      final password =
          'P3!${List.generate(32, (_) => Random.secure().nextInt(36).toRadixString(36)).join()}';
      final response = await client.auth.signUp(
        email: 'phase3-$runId@example.com',
        password: password,
        data: {'display_name': 'Phase3 validation $runId'},
      );
      expect(
        response.session != null,
        isTrue,
        reason:
            'Local normal Auth signup must issue a session; no admin bypass',
      );
      buyerId = response.user!.id;
      proof['dedicated_buyer_id'] = buyerId;
    }
    await until(
      tester,
      () => container.read(authRepositoryProvider).currentUser?.id == buyerId,
      'Production auth provider sees dedicated buyer',
    );
  }

  setUpAll(() async {
    expect(
      AppEnvironment.isSupabaseConfigured,
      isTrue,
      reason: 'Pass the actual runtime dart_defines.json',
    );
    expect(
      ['localhost', '127.0.0.1', '::1'],
      contains(Uri.parse(AppEnvironment.supabaseUrl).host),
      reason: 'This mutating validation is restricted to local Supabase',
    );
    client = SupabaseClient(
      AppEnvironment.supabaseUrl,
      AppEnvironment.supabaseAnonKey,
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );
    preferences = await SharedPreferences.getInstance();
    for (final key in [
      SettingsStorageKeys.locale,
      SettingsStorageKeys.theme,
      SettingsStorageKeys.onboardingComplete,
    ]) {
      originalPreferences[key] = preferences.get(key);
    }
    await preferences.setBool(SettingsStorageKeys.onboardingComplete, true);
    final repository = SupabaseHomeRepository(client);
    final sellers = await client
        .from('sellers')
        .select('id')
        .eq('status', 'approved')
        .eq('country_code', 'DE');
    final candidates = <HomeProduct>[];
    for (final seller in sellers) {
      candidates.addAll(
        await repository.fetchSellerProducts(seller['id'] as String),
      );
    }
    expect(
      candidates,
      isNotEmpty,
      reason: 'Actual DE fixture must be queryable',
    );
    product = candidates.firstWhere(
      (item) => item.imageUrls.length > 1,
      orElse: () => candidates.firstWhere((item) => item.imageUrls.isNotEmpty),
    );
    expect(product.countryCode, 'DE');
    expect(product.store!.countryCode, 'DE');
    proof['product_id'] = product.id;
    proof['seller_id'] = product.store!.id;
    proof['live_de_products'] = candidates.length;
    proof['live_de_sellers'] = sellers.length;
    proof['product_image_count'] = product.imageUrls.length;
    if (product.imageUrls.length < 2) {
      proof['gallery_gap'] = 'No multi-image product in the live DE fixture';
    }
    passed('live_DE_fixture');
  });

  tearDownAll(() async {
    binding.reportData ??= <String, dynamic>{};
    binding.reportData!['tests'] = {
      for (final entry in binding.results.entries)
        entry.key: entry.value == 'success' ? 'PASS' : 'FAIL',
    };
    for (final entry in originalPreferences.entries) {
      final value = entry.value;
      if (value == null) {
        await preferences.remove(entry.key);
      } else if (value is bool) {
        await preferences.setBool(entry.key, value);
      } else if (value is String) {
        await preferences.setString(entry.key, value);
      }
    }
    await client.dispose();
  });

  testWidgets('Phase3 live product seller product navigation', (tester) async {
    await mount(tester);
    await screenshot(tester, 'product_de_light');
    await openSeller(tester);
    await screenshot(tester, 'seller_de_light');
    final firstCard = find.byType(ProductCard).first;
    final cardTitle = tester.widget<ProductCard>(firstCard).title;
    await tester.ensureVisible(firstCard);
    await tester.tap(firstCard);
    await until(
      tester,
      () => find.byType(ProductDetailScreen).evaluate().isNotEmpty,
      'Seller listing navigates back to a real product',
    );
    final openedId = tester
        .widget<ProductDetailScreen>(find.byType(ProductDetailScreen))
        .productId;
    final opened = await container.read(
      homeProductProvider(productId: openedId).future,
    );
    expect(opened!.title, cardTitle);
    expect(opened.store!.id, product.store!.id);
    passed('ProductDetail_to_sellerProfile_to_product');
  });

  testWidgets('Phase3 live multi-image gallery swipe', (tester) async {
    await mount(tester);
    await tester.drag(find.byType(PageView), const Offset(-320, 0));
    await tester.pumpAndSettle();
    await screenshot(tester, 'gallery_de_light');
    expect(
      product.imageUrls.length,
      greaterThan(1),
      reason: 'Live fixture needs multiple images to prove page advancement',
    );
    expect(tester.widget<PageView>(find.byType(PageView)).controller!.page, 1);
    expect(
      tester
          .widget<Semantics>(
            find.byKey(const ValueKey('product-gallery-position')),
          )
          .properties
          .value,
      '2 / ${product.imageUrls.length}',
    );
    passed('gallery_swipe_page_and_semantic_counter');
  });

  testWidgets('Phase3 guest favorite report contact require authentication', (
    tester,
  ) async {
    await mount(tester);
    expect(client.auth.currentUser, isNull);
    for (final action in ['favorite', 'report', 'contact']) {
      final l10n = labels(tester);
      if (action == 'favorite') {
        await tester.tap(find.byTooltip(l10n.favoriteAdd));
      } else if (action == 'report') {
        await openReport(tester);
      } else {
        await tester.tap(find.text(l10n.productContactSeller));
      }
      await until(
        tester,
        () => find.byType(AuthScreen).evaluate().isNotEmpty,
        'Guest $action must reach AuthScreen',
      );
      final auth = tester.widget<AuthScreen>(find.byType(AuthScreen));
      expect(auth.redirectLocation, '/products/${product.id}');
      expect(client.auth.currentUser, isNull);
      expect(find.byType(ChatConversationScreen), findsNothing);
      expect(find.byType(RadioGroup<String>), findsNothing);
      passed('guest_${action}_auth_guard_and_return_location');
      await screenshot(tester, 'guest_${action}_auth');
      router.pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Phase3 authenticated favorite persists and removes', (
    tester,
  ) async {
    await mount(tester);
    await authenticate(tester);
    final repository = container.read(homeRepositoryProvider);
    expect(await repository.fetchFavoriteState(product.id), isFalse);
    await tester.tap(find.byTooltip(labels(tester).favoriteAdd));
    await until(
      tester,
      () => find.byTooltip(labels(tester).favoriteRemove).evaluate().isNotEmpty,
      'Favorite UI must update after real write',
    );
    expect(await repository.fetchFavoriteState(product.id), isTrue);
    passed('authenticated_favorite_UI_and_database_insert');
    await screenshot(tester, 'favorite_authenticated');
    await tester.tap(find.byTooltip(labels(tester).favoriteRemove));
    await until(
      tester,
      () => find.byTooltip(labels(tester).favoriteAdd).evaluate().isNotEmpty,
      'Favorite UI must update after real removal',
    );
    expect(await repository.fetchFavoriteState(product.id), isFalse);
    passed('authenticated_favorite_UI_and_database_remove');
  });

  testWidgets(
    'Phase3 dark de ku ar product seller gallery report and real submission',
    (tester) async {
      await mount(tester);
      await authenticate(tester);
      for (final locale in ['de', 'ku', 'ar']) {
        final settings = container.read(appSettingsControllerProvider.notifier);
        await settings.setLocale(locale);
        await settings.setTheme(AppThemePreference.dark);
        await openProduct(tester);
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(PageView));
        expect(Localizations.localeOf(context).languageCode, locale);
        expect(Theme.of(context).brightness, Brightness.dark);
        expect(
          Directionality.of(context),
          locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
        await screenshot(tester, 'product_${locale}_dark');
        final pageView = tester.widget<PageView>(find.byType(PageView));
        final initial = pageView.controller!.page!.round();
        await tester.drag(
          find.byType(PageView),
          Offset(locale == 'ar' ? 320 : -320, 0),
        );
        await tester.pumpAndSettle();
        expect(
          pageView.controller!.page!.round(),
          product.imageUrls.length > 1 ? initial + 1 : 0,
        );
        if (product.imageUrls.length > 1)
          expect(
            tester
                .widget<Semantics>(
                  find.byKey(const ValueKey('product-gallery-position')),
                )
                .properties
                .value,
            '${initial + 2} / ${product.imageUrls.length}',
          );
        await screenshot(tester, 'gallery_${locale}_dark');
        await openSeller(tester);
        expect(find.text(labels(tester).sellerProfileAbout), findsOneWidget);
        await screenshot(tester, 'seller_${locale}_dark');
        router.pop();
        await tester.pumpAndSettle();
        await openReport(tester);
        final l10n = labels(tester);
        expect(find.text(l10n.productReportTitle), findsOneWidget);
        expect(find.byType(RadioListTile<String>), findsNWidgets(7));
        final submit = find.widgetWithText(AppButton, l10n.productReportSubmit);
        expect(tester.widget<AppButton>(submit).onPressed, isNull);
        await tester.tap(find.text(l10n.reportReasonOther));
        await tester.pumpAndSettle();
        expect(tester.widget<AppButton>(submit).onPressed, isNotNull);
        await screenshot(tester, 'report_${locale}_dark');
        passed(
          'dark_${locale}_locale_direction_gallery_seller_report_validation',
        );
        if (locale == 'ar') {
          final details =
              'Phase3 integration validation $runId; local fixture only.';
          await tester.enterText(find.byType(TextField), details);
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
          await tester.ensureVisible(submit);
          await tester.tap(submit);
          await until(
            tester,
            () => find.byType(RadioGroup<String>).evaluate().isEmpty,
            'Successful real report must dismiss sheet',
          );
          expect(find.text(l10n.productReportSubmitted), findsOneWidget);
          final reports = await client
              .from('reports')
              .select('product_id,reason,details')
              .eq('reporter_id', buyerId!)
              .eq('details', details);
          expect(reports, hasLength(1));
          expect(reports.single['product_id'], product.id);
          expect(reports.single['reason'], 'other');
          passed('authenticated_report_UI_confirmation_and_database_row');
        } else {
          Navigator.of(tester.element(submit)).pop();
          await tester.pumpAndSettle();
        }
      }
    },
  );

  testWidgets('Phase3 authenticated contact opens real seeded chat and sends', (
    tester,
  ) async {
    await mount(tester);
    await authenticate(tester);
    await tester.tap(find.text(labels(tester).productContactSeller));
    await until(
      tester,
      () =>
          find.byType(ChatConversationScreen).evaluate().isNotEmpty &&
          find.byType(TextField).evaluate().isNotEmpty,
      'Authenticated contact must load real chat',
    );
    final chatId = tester
        .widget<ChatConversationScreen>(find.byType(ChatConversationScreen))
        .chatId;
    final chat = await client
        .from('chats')
        .select('buyer_id,seller_id,product_id')
        .eq('id', chatId)
        .single();
    expect(chat['buyer_id'], buyerId);
    expect(chat['seller_id'], product.store!.id);
    expect(chat['product_id'], product.id);
    final seeded = await client
        .from('messages')
        .select('kind,product_id')
        .eq('chat_id', chatId);
    expect(
      seeded.where(
        (row) => row['kind'] == 'product' && row['product_id'] == product.id,
      ),
      hasLength(1),
    );
    expect(seeded.where((row) => row['kind'] == 'system'), isNotEmpty);
    passed('authenticated_contact_chat_identity_and_server_seeded_messages');
    final message = 'Phase3 local integration validation $runId';
    await tester.enterText(find.byType(TextField), message);
    await tester.tap(find.byTooltip(labels(tester).chatSend));
    await until(
      tester,
      () =>
          tester
              .widget<TextField>(find.byType(TextField))
              .controller!
              .text
              .isEmpty &&
          find.text(message).evaluate().isNotEmpty,
      'Sent message clears composer and appears in conversation',
    );
    final messages = await client
        .from('messages')
        .select('sender_id,body')
        .eq('chat_id', chatId)
        .eq('body', message);
    expect(messages, hasLength(1));
    expect(messages.single['sender_id'], buyerId);
    FocusManager.instance.primaryFocus?.unfocus();
    passed('authenticated_chat_send_UI_and_database_row');
    await screenshot(tester, 'chat_authenticated');
  });
}
