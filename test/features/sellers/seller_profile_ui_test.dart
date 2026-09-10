import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/features/home/domain/home_feed.dart';
import 'package:zerin_marketplace/features/home/domain/home_repository.dart';
import 'package:zerin_marketplace/features/home/presentation/controllers/home_controller.dart';
import 'package:zerin_marketplace/features/products/presentation/product_rail.dart';
import 'package:zerin_marketplace/features/sellers/presentation/seller_profile_screen.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

MarketplaceStore _seller({bool verified = true, String kind = 'private'}) =>
    MarketplaceStore.fromJson({
      'id': 'seller',
      'slug': 'seller',
      'shop_name': 'Public Seller',
      'city': 'Hamburg',
      'kind': kind,
      'verified': verified,
      'email': 'secret@example.test',
      'phone': '+49123456789',
      'address': 'Private street 10',
      'user_id': 'private-user-id',
    });

HomeProduct _product(int index) => HomeProduct.fromJson({
  'id': 'p$index',
  'slug': 'p$index',
  'title': 'Listing $index',
  'description': '',
  'condition': 'new',
  'price_cents': 1200,
  'currency': 'EUR',
  'published_at': '2026-09-01T10:00:00Z',
});

class _Repository implements HomeRepository {
  MarketplaceStore? seller = _seller();
  bool failSeller = false;
  bool failPage = false;
  bool empty = false;
  Completer<MarketplaceStore?>? pendingSeller;
  Completer<List<HomeProduct>>? pendingPage;
  final offsets = <int>[];
  int sellerLoads = 0;

  @override
  Future<MarketplaceStore?> fetchSeller(String sellerId) async {
    sellerLoads++;
    if (failSeller) throw StateError('offline');
    return pendingSeller == null ? seller : pendingSeller!.future;
  }

  @override
  Future<List<HomeProduct>> fetchSellerProducts(
    String sellerId, {
    int offset = 0,
    int limit = 24,
    String? excludeProductId,
  }) async {
    offsets.add(offset);
    expect(limit, 24);
    if (failPage) throw StateError('page failed');
    if (pendingPage != null) return pendingPage!.future;
    if (empty) return [];
    return offset == 0
        ? List.generate(24, _product)
        : [_product(23), _product(24)];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(
  WidgetTester tester,
  _Repository repository, {
  Locale locale = const Locale('en'),
  bool dark = false,
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const SellerProfileScreen(sellerId: 'seller'),
      ),
      GoRoute(
        path: '/products/:productId',
        builder: (_, state) => Scaffold(
          body: Text('Product ${state.pathParameters['productId']}'),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [homeRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(
        routerConfig: router,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocale.localizationsDelegates,
        theme: dark ? AppTheme.dark : AppTheme.light,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

Future<void> _show(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump();
}

void main() {
  testWidgets(
    'profile exposes only public seller fields and navigable listings',
    (tester) async {
      await _pump(tester, _Repository());
      expect(find.text('Public Seller'), findsOneWidget);
      expect(find.text('Hamburg'), findsOneWidget);
      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
      expect(find.textContaining('secret@'), findsNothing);
      expect(find.textContaining('Private street'), findsNothing);
      expect(find.textContaining('+491234'), findsNothing);
      expect(find.textContaining('private-user-id'), findsNothing);
      await _show(tester, find.byType(ProductRail));
      expect(
        tester.getSize(find.byType(ProductCard).first).width,
        AppSizes.homeProductCardWidth,
      );
      expect(
        tester.widget<ProductCard>(find.byType(ProductCard).first).heroTag,
        isNull,
      );
      await tester.tap(find.text('Listing 0'));
      await tester.pumpAndSettle();
      expect(find.text('Product p0'), findsOneWidget);
    },
  );

  testWidgets(
    'pagination retains first page on failure and retries offset 24',
    (tester) async {
      final repository = _Repository();
      await _pump(tester, repository);
      await _show(tester, find.text('Load more'));
      repository.failPage = true;
      await tester.tap(find.text('Load more'));
      await tester.pump();
      await tester.pump();
      expect(repository.offsets, [0, 24]);
      expect(
        tester.widget<ProductRail>(find.byType(ProductRail)).products,
        hasLength(24),
      );
      await _show(tester, find.text('Try again'));
      repository.failPage = false;
      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.pump();
      expect(repository.offsets, [0, 24, 24]);
      final products = tester
          .widget<ProductRail>(find.byType(ProductRail))
          .products;
      expect(products, hasLength(25));
      expect(products.map((p) => p.id).toSet(), hasLength(25));
      expect(find.text('Load more'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('seller loading, retry, missing and empty listing states', (
    tester,
  ) async {
    final repository = _Repository()
      ..pendingSeller = Completer<MarketplaceStore?>();
    await _pump(tester, repository);
    expect(find.byType(AppSkeletonBox), findsWidgets);
    repository.pendingSeller!.completeError(StateError('offline'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(AppErrorState), findsOneWidget);
    repository.pendingSeller = null;
    repository.seller = null;
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();
    expect(repository.sellerLoads, 2);
    expect(find.byType(AppEmptyState), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await _pump(tester, _Repository()..empty = true);
    await _show(tester, find.text('No listings available right now.'));
    expect(find.byType(ProductRail), findsNothing);
  });

  testWidgets(
    'listing loading resolves to retryable error without blank section',
    (tester) async {
      final repository = _Repository()
        ..pendingPage = Completer<List<HomeProduct>>();
      await _pump(tester, repository);
      await _show(tester, find.byType(AppSkeletonBox));
      repository.pendingPage!.completeError(StateError('offline'));
      await tester.pump();
      await tester.pump();
      expect(find.byType(AppErrorState), findsOneWidget);
      repository.pendingPage = null;
      repository.empty = true;
      await _show(tester, find.text('Try again'));
      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.pump();
      expect(repository.offsets, [0, 0]);
      expect(find.byType(AppErrorState), findsNothing);
    },
  );

  for (final locale in AppLocalizations.supportedLocales) {
    for (final kind in ['private', 'business']) {
      testWidgets(
        '${locale.languageCode} $kind profile renders in dark mobile layout',
        (tester) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await _pump(
            tester,
            _Repository()..seller = _seller(kind: kind, verified: false),
            locale: locale,
            dark: true,
          );
          expect(find.byIcon(Icons.verified_rounded), findsNothing);
          await _show(tester, find.byType(ProductRail));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
