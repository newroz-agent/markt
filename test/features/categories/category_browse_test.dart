import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/features/categories/domain/category_repository.dart';
import 'package:zerin_marketplace/features/categories/domain/marketplace_category.dart';
import 'package:zerin_marketplace/features/categories/presentation/controllers/category_controller.dart';
import 'package:zerin_marketplace/features/home/presentation/home_foundation_screen.dart';
import 'package:zerin_marketplace/l10n/app_localizations.dart';

const _rootCategory = MarketplaceCategory(
  id: 'root-id',
  parentId: null,
  slug: 'elektronik',
  nameDe: 'Elektronik',
  nameEn: 'Electronics',
  nameAr: 'Electronics AR',
  nameTr: 'Elektronik TR',
  iconKey: 'devices',
  imageUrl: '',
  sortOrder: 10,
);

const _childCategory = MarketplaceCategory(
  id: 'child-id',
  parentId: 'root-id',
  slug: 'smartphones',
  nameDe: 'Smartphones',
  nameEn: 'Smartphones',
  nameAr: 'Smartphones AR',
  nameTr: 'Akilli Telefonlar',
  iconKey: 'smartphone',
  imageUrl: '',
  sortOrder: 10,
);

class _CategoryRepository implements CategoryRepository {
  const _CategoryRepository(this.categories);

  final List<MarketplaceCategory> categories;

  @override
  Future<List<MarketplaceCategory>> fetchActiveCategories() async => categories;
}

void main() {
  test('maps the Supabase category row and localizes its name', () {
    final category = MarketplaceCategory.fromJson(const <String, dynamic>{
      'id': 'category-id',
      'parent_id': null,
      'slug': 'mode-damen',
      'name_de': 'Mode Damen',
      'name_en': "Women's Fashion",
      'name_ar': 'Arabic name',
      'name_tr': 'Kadin Modasi',
      'icon_key': 'checkroom',
      'image_url': 'https://example.com/category.jpg',
      'sort_order': 20,
    });

    expect(category.isRoot, isTrue);
    expect(category.nameForLanguage('de'), 'Mode Damen');
    expect(category.nameForLanguage('en'), "Women's Fashion");
    expect(category.nameForLanguage('ar'), 'Arabic name');
    expect(category.nameForLanguage('tr'), 'Kadin Modasi');
    expect(category.nameForLanguage('ku'), 'Mode Damen');
  });

  test('root category provider excludes second-level categories', () async {
    final container = ProviderContainer(
      overrides: <Override>[
        categoryRepositoryProvider.overrideWithValue(
          const _CategoryRepository(<MarketplaceCategory>[
            _rootCategory,
            _childCategory,
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    final categories = await container.read(rootCategoriesProvider.future);

    expect(categories, <MarketplaceCategory>[_rootCategory]);
  });

  testWidgets('Home renders categories supplied by the browse provider', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          rootCategoriesProvider.overrideWith(
            (ref) async => const <MarketplaceCategory>[
              _rootCategory,
              MarketplaceCategory(
                id: 'fashion-id',
                parentId: null,
                slug: 'mode-damen',
                nameDe: 'Mode Damen',
                nameEn: "Women's Fashion",
                nameAr: 'Fashion AR',
                nameTr: 'Kadin Modasi',
                iconKey: 'checkroom',
                imageUrl: '',
                sortOrder: 20,
              ),
            ],
          ),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.light,
          home: const HomeFoundationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Elektronik'), findsOneWidget);
    expect(find.text('Mode Damen'), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome_rounded), findsNothing);
  });
}
