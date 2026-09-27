import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/features/auth/domain/auth_user.dart';
import 'package:zerin_marketplace/features/auth/presentation/controllers/auth_controller.dart';
import 'package:zerin_marketplace/features/categories/domain/marketplace_category.dart';
import 'package:zerin_marketplace/features/categories/presentation/categories_foundation_screen.dart';
import 'package:zerin_marketplace/features/categories/presentation/category_products_screen.dart';
import 'package:zerin_marketplace/features/categories/presentation/controllers/category_controller.dart';
import 'package:zerin_marketplace/features/home/domain/home_feed.dart';
import 'package:zerin_marketplace/features/home/presentation/controllers/home_controller.dart';
import 'package:zerin_marketplace/features/home/presentation/home_foundation_screen.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

const _category = MarketplaceCategory(
  id: 'category-1',
  parentId: null,
  slug: 'category',
  nameDe: 'Kategorie',
  nameEn: 'Category',
  nameAr: 'فئة',
  nameTr: 'Kategori',
  nameKu: 'Kategorî',
  iconKey: 'category',
  imageUrl: '',
  sortOrder: 1,
);

void main() {
  testWidgets('Home map icon is separate from the Categories search action', (
    tester,
  ) async {
    final router = await _pumpEntry(
      tester,
      const HomeFoundationScreen(),
      overrides: <Override>[
        authStateProvider.overrideWith((ref) => Stream<AuthUser?>.value(null)),
        homeFeedProvider.overrideWith(
          (ref) async => const HomeFeed(
            campaigns: <AdCampaign>[],
            newArrivals: <HomeProduct>[],
            deals: <HomeProduct>[],
            popularStores: <MarketplaceStore>[],
          ),
        ),
        rootCategoriesProvider.overrideWith(
          (ref) async => const <MarketplaceCategory>[],
        ),
      ],
    );
    addTearDown(router.dispose);

    expect(find.byKey(const ValueKey('home-map-action')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('home-map-action')));
    await tester.pumpAndSettle();
    expect(find.text('map destination'), findsOneWidget);
  });

  testWidgets('root Categories app bar opens the dedicated Map route', (
    tester,
  ) async {
    final router = await _pumpEntry(
      tester,
      const CategoriesFoundationScreen(),
      overrides: <Override>[
        rootCategoriesProvider.overrideWith(
          (ref) async => const <MarketplaceCategory>[_category],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.tap(find.byKey(const ValueKey('categories-map-action')));
    await tester.pumpAndSettle();
    expect(find.text('map destination'), findsOneWidget);
  });

  testWidgets('category results pass category context to the Map route', (
    tester,
  ) async {
    final router = await _pumpEntry(
      tester,
      const CategoryProductsScreen(categoryId: 'category-1'),
      overrides: <Override>[
        activeCategoriesProvider.overrideWith(
          (ref) async => const <MarketplaceCategory>[_category],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.tap(find.byKey(const ValueKey('category-results-map-action')));
    await tester.pumpAndSettle();
    expect(find.text('map destination category-1'), findsOneWidget);
  });
}

Future<GoRouter> _pumpEntry(
  WidgetTester tester,
  Widget origin, {
  List<Override> overrides = const <Override>[],
}) async {
  final router = GoRouter(
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (_, _) => origin),
      GoRoute(
        path: '/map',
        builder: (_, state) {
          final category = state.uri.queryParameters['category-id'];
          return Scaffold(
            body: Text(
              category == null
                  ? 'map destination'
                  : 'map destination $category',
            ),
          );
        },
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        routerConfig: router,
        locale: AppLocale.english,
        supportedLocales: AppLocale.supportedLocales,
        localizationsDelegates: AppLocale.localizationsDelegates,
        theme: AppTheme.light,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  return router;
}
