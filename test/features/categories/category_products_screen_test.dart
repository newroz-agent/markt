import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/features/categories/domain/category_products_repository.dart';
import 'package:zerin_marketplace/features/categories/domain/marketplace_category.dart';
import 'package:zerin_marketplace/features/categories/presentation/category_products_screen.dart';
import 'package:zerin_marketplace/features/categories/presentation/controllers/category_controller.dart';
import 'package:zerin_marketplace/features/categories/presentation/controllers/category_products_controller.dart';
import 'package:zerin_marketplace/features/home/domain/home_feed.dart';
import 'package:zerin_marketplace/l10n/app_localizations.dart';

const _root = MarketplaceCategory(
  id: 'root-id',
  parentId: null,
  slug: 'elektronik',
  nameDe: 'Elektronik',
  nameEn: 'Electronics',
  nameAr: 'إلكترونيات',
  nameTr: 'Elektronik',
  nameKu: 'Elektronîk',
  iconKey: 'devices',
  imageUrl: '',
  sortOrder: 10,
);

const _child = MarketplaceCategory(
  id: 'child-id',
  parentId: 'root-id',
  slug: 'smartphones',
  nameDe: 'Smartphones',
  nameEn: 'Smartphones',
  nameAr: 'هواتف',
  nameTr: 'Telefonlar',
  nameKu: 'Telefonên Jîr',
  iconKey: 'smartphone',
  imageUrl: '',
  sortOrder: 10,
);

HomeProduct _product(String id) => HomeProduct.fromJson(<String, dynamic>{
  'id': id,
  'slug': 'slug-$id',
  'title': 'Produkt $id',
  'description': 'Beschreibung',
  'condition': 'new',
  'price_cents': 1250,
  'currency': 'EUR',
  'city': 'Berlin',
  'published_at': '2026-09-01T10:00:00Z',
  'seller': null,
  'images': <Map<String, dynamic>>[
    {'image_url': '', 'sort_order': 0},
  ],
});

class _FakeRepository implements CategoryProductsRepository {
  _FakeRepository();

  final queries = <CategoryProductsQuery>[];
  int page = 0;

  @override
  Future<List<HomeProduct>> fetchCategoryProducts(
    CategoryProductsQuery query,
  ) async {
    queries.add(query);
    if (query.offset > 0) {
      return <HomeProduct>[_product('p-${query.offset}')];
    }
    return List.generate(query.limit, (index) => _product('p$index'));
  }
}

Widget _app(Widget child) => MaterialApp(
  locale: const Locale('de'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  theme: AppTheme.light,
  home: child,
);

/// The skeleton shimmer repeats forever while loading, so tests pump fixed
/// durations instead of waiting for the frame clock to go idle.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _pumpScreen(
  WidgetTester tester,
  _FakeRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        categoryProductsRepositoryProvider.overrideWithValue(repository),
        activeCategoriesProvider.overrideWith(
          (ref) async => const [_root, _child],
        ),
      ],
      child: _app(const CategoryProductsScreen(categoryId: 'root-id')),
    ),
  );
  await _settle(tester);
}

void main() {
  test('Kurdish category names come from the database column', () {
    expect(_root.nameForLanguage('ku'), 'Elektronîk');
    expect(_child.nameForLanguage('ku'), 'Telefonên Jîr');
    final withoutKu = MarketplaceCategory(
      id: 'x',
      parentId: null,
      slug: 's',
      nameDe: 'Deutsch',
      nameEn: 'English',
      nameAr: 'عربي',
      nameTr: 'Türkçe',
      iconKey: 'i',
      imageUrl: '',
      sortOrder: 0,
    );
    // Unreviewed rows fall back to German instead of showing a blank label.
    expect(withoutKu.nameForLanguage('ku'), 'Deutsch');
  });

  testWidgets('grid/list toggle switches the results view', (tester) async {
    final repository = _FakeRepository();
    await _pumpScreen(tester, repository);

    expect(find.byType(SliverGrid), findsOneWidget);
    await tester.tap(find.byIcon(Icons.view_list_rounded));
    await _settle(tester);
    expect(find.byType(SliverGrid), findsNothing);

    // The toggle state persists inside the filter provider.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CategoryProductsScreen)),
    );
    expect(
      container.read(categoryProductsFilterProvider('root-id')).viewMode,
      CategoryProductViewMode.list,
    );
  });

  testWidgets('city sheet offers German cities only and applies the filter', (
    tester,
  ) async {
    final repository = _FakeRepository();
    await _pumpScreen(tester, repository);

    await tester.tap(find.byKey(const ValueKey('city-chip')));
    await _settle(tester);
    expect(find.text('Stadt wählen'), findsOneWidget);
    // Germany-only catalog: German cities only, no other markets.
    expect(find.text('Berlin'), findsOneWidget);
    expect(find.text('Wien'), findsNothing);
    expect(find.text('Zürich'), findsNothing);

    await tester.tap(find.text('Berlin'));
    await _settle(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(CategoryProductsScreen)),
    );
    expect(
      container.read(categoryProductsFilterProvider('root-id')).city,
      'Berlin',
    );
    expect(
      repository.queries.last.city,
      'Berlin',
      reason: 'the city filter must reach the repository query',
    );
  });

  testWidgets('seller kind sheet filters private listings', (tester) async {
    final repository = _FakeRepository();
    await _pumpScreen(tester, repository);

    // Row order: [Alle, Neu, Gebraucht] condition chips, then the keyed
    // seller chip.
    await tester.tap(find.byKey(const ValueKey('seller-kind-chip')));
    await _settle(tester);
    await tester.tap(find.text('Privat'));
    await _settle(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(CategoryProductsScreen)),
    );
    expect(
      container.read(categoryProductsFilterProvider('root-id')).sellerKind,
      CategoryProductSellerKindFilter.private,
    );
  });

  testWidgets('in-category search feeds the query state', (tester) async {
    final repository = _FakeRepository();
    await _pumpScreen(tester, repository);

    await tester.enterText(find.byType(TextField), 'fahrrad');
    await _settle(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(CategoryProductsScreen)),
    );
    expect(
      container.read(categoryProductsFilterProvider('root-id')).searchQuery,
      'fahrrad',
    );
  });

  testWidgets('load more appends a page without duplicates', (tester) async {
    final repository = _FakeRepository();
    await _pumpScreen(tester, repository);

    await tester.scrollUntilVisible(
      find.text('Mehr laden'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Mehr laden'));
    await _settle(tester);

    expect(repository.queries.last.offset, greaterThan(0));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CategoryProductsScreen)),
    );
    final loaded = container
        .read(categoryProductsProvider('root-id'))
        .requireValue;
    expect(loaded, hasLength(25));
    expect(loaded.map((p) => p.id), contains('p-24'));
  });
}
