import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/features/auth/domain/auth_repository.dart';
import 'package:zerin_marketplace/features/auth/domain/auth_user.dart';
import 'package:zerin_marketplace/features/auth/presentation/controllers/auth_controller.dart';
import 'package:zerin_marketplace/features/categories/domain/marketplace_category.dart';
import 'package:zerin_marketplace/features/categories/presentation/controllers/category_products_controller.dart';
import 'package:zerin_marketplace/features/home/domain/home_feed.dart';
import 'package:zerin_marketplace/features/home/domain/home_repository.dart';
import 'package:zerin_marketplace/features/home/presentation/controllers/home_controller.dart';
import 'package:zerin_marketplace/features/products/presentation/contact_seller_button.dart';
import 'package:zerin_marketplace/features/products/presentation/product_detail_screen.dart';
import 'package:zerin_marketplace/features/products/presentation/product_rail.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

class _Auth extends Mock implements AuthRepository {}

class _Repository extends Mock implements HomeRepository {}

final _seller = MarketplaceStore.fromJson({
  'id': 'seller',
  'slug': 'seller',
  'shop_name': 'Public Seller',
  'kind': 'private',
  'city': 'Hamburg',
  'verified': true,
});

HomeProduct _product({
  String id = 'current',
  List<String> images = const [],
  bool seller = false,
  bool category = false,
  bool details = false,
}) => HomeProduct.fromJson({
  'id': id,
  'slug': id,
  'title': 'Listing $id',
  'description': 'Description of the listing',
  'condition': 'used',
  'price_cents': 1250,
  'currency': 'EUR',
  'published_at': '2026-09-01T10:00:00Z',
  if (seller)
    'seller': {
      'id': 'seller',
      'slug': 'seller',
      'shop_name': 'Public Seller',
      'kind': 'private',
    },
  if (category) 'category_id': 'category',
  if (details) 'brand': {'name': 'Acme'},
  if (details) 'specifications': {'Material': 'Wood', 'Weight': 3, 'Blank': ''},
  'images': [
    for (final url in images) {'image_url': url},
  ],
});

const _category = MarketplaceCategory(
  id: 'category',
  parentId: null,
  slug: 'category',
  nameDe: 'Kategorie',
  nameEn: 'Category name',
  nameAr: 'Category',
  nameTr: 'Category',
  iconKey: 'devices',
  imageUrl: '',
  sortOrder: 0,
);

Future<void> _pump(
  WidgetTester tester, {
  HomeProduct? product,
  Future<HomeProduct?> Function()? load,
  _Repository? repository,
  bool guest = false,
  Locale locale = const Locale('en'),
  bool dark = false,
  List<HomeProduct> listings = const [],
  Future<List<HomeProduct>> Function()? sellerListings,
}) async {
  final auth = _Auth();
  when(() => auth.currentUser).thenReturn(
    guest ? null : const AuthUser(id: 'buyer', email: 'buyer@example.test'),
  );
  final home = repository ?? _Repository();
  when(() => home.fetchFavoriteState(any())).thenAnswer((_) async => false);
  when(() => home.recordProductView(any())).thenAnswer((_) async {});
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const ProductDetailScreen(productId: 'current'),
      ),
      GoRoute(
        path: '/auth',
        builder: (_, _) => const Scaffold(body: Text('Auth destination')),
      ),
      GoRoute(
        path: '/sellers/:sellerId',
        builder: (_, state) =>
            Scaffold(body: Text('Seller ${state.pathParameters['sellerId']}')),
      ),
      GoRoute(
        path: '/categories/:categoryId',
        builder: (_, state) => Scaffold(
          body: Text('Category ${state.pathParameters['categoryId']}'),
        ),
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
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        homeRepositoryProvider.overrideWithValue(home),
        homeProductProvider(productId: 'current').overrideWith(
          (ref) => load == null ? Future.value(product ?? _product()) : load(),
        ),
        sellerProfileProvider(
          sellerId: 'seller',
        ).overrideWith((ref) async => _seller),
        sellerProductsProvider(
          sellerId: 'seller',
          excludeProductId: 'current',
        ).overrideWith(
          (ref) => sellerListings == null
              ? Future.value(listings)
              : sellerListings(),
        ),
        similarProductsProvider(
          productId: 'current',
          categoryId: 'category',
        ).overrideWith((ref) async => listings),
        categoryByIdProvider('category').overrideWith((ref) async => _category),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: locale,
        localizationsDelegates: AppLocale.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: dark ? AppTheme.dark : AppTheme.light,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

Future<void> _openReport(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.flag_outlined));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Report listing').last);
  await tester.pumpAndSettle();
}

Future<void> _show(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    250,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump();
}

void main() {
  testWidgets('empty gallery has a fallback and price has no VAT claim', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    expect(find.byType(PageView), findsNothing);
    await _show(tester, find.text('Listing current'));
    expect(find.textContaining('VAT'), findsNothing);
    expect(find.textContaining('12.50'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('gallery contains images and announces current position', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pump(
        tester,
        product: _product(
          images: ['https://example.test/1', 'https://example.test/2'],
        ),
      );
      expect(
        tester
            .widget<CachedNetworkImage>(find.byType(CachedNetworkImage).first)
            .fit,
        BoxFit.contain,
      );
      expect(find.text('1 / 2'), findsOneWidget);
      expect(
        tester
            .getSemantics(
              find.byKey(const ValueKey('product-gallery-position')),
            )
            .value,
        'Image 1 of 2',
      );
      await tester.drag(find.byType(PageView), const Offset(-650, 0));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('2 / 2'), findsOneWidget);
      expect(
        tester
            .getSemantics(
              find.byKey(const ValueKey('product-gallery-position')),
            )
            .value,
        'Image 2 of 2',
      );
      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage).last,
      );
      final fallback = image.errorWidget!(
        tester.element(find.byType(CachedNetworkImage).last),
        '',
        StateError('image'),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocale.localizationsDelegates,
          supportedLocales: AppLocale.supportedLocales,
          home: fallback,
        ),
      );
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'seller uses public verification and city before description and navigates',
    (tester) async {
      await _pump(tester, product: _product(seller: true));
      await _show(tester, find.text('Hamburg'));
      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Public Seller')).dy,
        lessThan(tester.getTopLeft(find.text('Description of the listing')).dy),
      );
      expect(find.byType(ContactSellerButton), findsOneWidget);
      await tester.ensureVisible(find.text('Public Seller'));
      await tester.pump();
      expect(find.text('Public Seller').hitTestable(), findsOneWidget);
      await tester.tap(find.text('Public Seller'));
      await tester.pumpAndSettle();
      expect(find.text('Seller seller'), findsOneWidget);
    },
  );

  testWidgets('category links and optional structured details are rendered', (
    tester,
  ) async {
    await _pump(tester, product: _product(category: true, details: true));
    await _show(tester, find.text('Material'));
    expect(find.text('Acme'), findsOneWidget);
    expect(find.text('Wood'), findsOneWidget);
    expect(find.text('Blank'), findsNothing);
    await tester.ensureVisible(find.text('Category: Category name'));
    await tester.pump();
    expect(find.text('Category: Category name').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Category: Category name'));
    await tester.pumpAndSettle();
    expect(find.text('Category category'), findsOneWidget);
  });

  testWidgets(
    'rails exclude current listing and have bounded cards without heroes',
    (tester) async {
      final current = _product(seller: true, category: true);
      await _pump(
        tester,
        product: current,
        listings: [
          current,
          _product(id: 'other'),
        ],
      );
      await _show(tester, find.byType(ProductRail));
      final firstRail = tester.widget<ProductRail>(
        find.byType(ProductRail).first,
      );
      expect(firstRail.products.map((p) => p.id), ['other']);
      for (final card in tester.widgetList<ProductCard>(
        find.byType(ProductCard),
      )) {
        expect(card.heroTag, isNull);
      }
      expect(
        tester.getSize(find.byType(ProductCard).first).width,
        AppSizes.homeProductCardWidth,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Listing other').first);
      await tester.pumpAndSettle();
      expect(find.text('Product other'), findsOneWidget);
    },
  );

  testWidgets('product loading, error retry and missing states are real', (
    tester,
  ) async {
    final pending = Completer<HomeProduct?>();
    var calls = 0;
    await _pump(
      tester,
      load: () {
        calls++;
        return pending.future;
      },
    );
    expect(find.byType(AppSkeletonBox), findsWidgets);
    pending.completeError(StateError('offline'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(AppErrorState), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(calls, 2);
    await tester.pumpWidget(const SizedBox());
    await _pump(tester, load: () async => null);
    expect(find.byType(AppEmptyState), findsOneWidget);
  });

  testWidgets('report redirects guests before presenting the form', (
    tester,
  ) async {
    await _pump(tester, guest: true);
    await _openReport(tester);
    expect(find.text('Auth destination'), findsOneWidget);
    expect(find.byType(AppTextField), findsNothing);
  });

  testWidgets('report stays keyboard safe and can be dismissed and reopened', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await _pump(tester);
    await _openReport(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pump();
    await tester.ensureVisible(find.byType(AppTextField));
    await tester.enterText(find.byType(TextFormField), 'x' * 3100);
    expect(
      tester
          .widget<AppTextField>(find.byType(AppTextField))
          .controller!
          .text
          .length,
      3000,
    );
    await tester.ensureVisible(find.text('Send report'));
    expect(tester.takeException(), isNull);
    Navigator.of(tester.element(find.byType(AppTextField))).pop();
    await tester.pumpAndSettle();
    tester.view.resetViewInsets();
    await _openReport(tester);
    expect(
      tester.widget<AppTextField>(find.byType(AppTextField)).controller!.text,
      isEmpty,
    );
    expect(
      tester
          .widget<RadioGroup<String>>(find.byType(RadioGroup<String>))
          .groupValue,
      isNull,
    );
  });

  testWidgets('late report completion after disposal does not navigate', (
    tester,
  ) async {
    final repository = _Repository();
    final pending = Completer<void>();
    when(
      () => repository.reportProduct(
        productId: 'current',
        reason: 'spam',
        details: '',
      ),
    ).thenAnswer((_) => pending.future);
    await _pump(tester, repository: repository);
    await _openReport(tester);
    await tester.tap(find.text('Spam'));
    await tester.ensureVisible(find.text('Send report'));
    await tester.tap(find.text('Send report'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    pending.complete();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'seller rail retries failed loading and shows genuine empty state',
    (tester) async {
      var calls = 0;
      await _pump(
        tester,
        product: _product(seller: true),
        sellerListings: () async {
          calls++;
          if (calls == 1) throw StateError('offline');
          return [];
        },
      );
      await _show(tester, find.text('Try again'));
      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.pump();
      expect(calls, 2);
      expect(find.text('No listings available right now.'), findsOneWidget);
      expect(find.byType(ProductRail), findsNothing);
    },
  );

  testWidgets(
    'report requires reason, limits text and retains failure for retry',
    (tester) async {
      final repository = _Repository();
      var calls = 0;
      var pending = Completer<void>();
      when(
        () => repository.reportProduct(
          productId: 'current',
          reason: 'spam',
          details: any(named: 'details'),
        ),
      ).thenAnswer((_) {
        calls++;
        return pending.future;
      });
      await _pump(tester, repository: repository);
      await _openReport(tester);
      AppButton submit() => tester.widget<AppButton>(
        find.byWidgetPredicate(
          (w) => w is AppButton && w.label == 'Send report',
        ),
      );
      expect(submit().onPressed, isNull);
      expect(
        tester
            .widget<RadioGroup<String>>(find.byType(RadioGroup<String>))
            .groupValue,
        isNull,
      );
      expect(
        tester.widget<AppTextField>(find.byType(AppTextField)).maxLength,
        3000,
      );
      await tester.tap(find.text('Spam'));
      await tester.ensureVisible(find.byType(AppTextField));
      await tester.enterText(find.byType(TextFormField), 'Evidence');
      await tester.ensureVisible(find.text('Send report'));
      await tester.tap(find.text('Send report'));
      await tester.pump();
      expect(submit().loading, isTrue);
      expect(submit().onPressed, isNull);
      expect(calls, 1);
      pending.completeError(StateError('offline'));
      await tester.pump();
      expect(
        tester.widget<AppTextField>(find.byType(AppTextField)).controller!.text,
        'Evidence',
      );
      expect(find.text('Please try again in a moment.'), findsOneWidget);
      pending = Completer<void>();
      await tester.ensureVisible(find.text('Send report'));
      await tester.tap(find.text('Send report'));
      await tester.pump();
      pending.complete();
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.byType(AppTextField), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('share sends only text with registered URI and popover origin', (
    tester,
  ) async {
    MethodCall? shared;
    const channel = MethodChannel('dev.fluttercommunity.plus/share');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      shared = call;
      return '';
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    await _pump(tester);
    await tester.tap(find.byIcon(Icons.share_outlined));
    await tester.pumpAndSettle();
    expect(shared, isNotNull);
    final args = shared!.arguments as Map;
    expect(args['text'], contains('de.zerin.marketplace:///products/current'));
    expect(args['uri'], isNull);
    expect(args['originWidth'], greaterThan(0));
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (_) async => throw PlatformException(code: 'failed'),
    );
    await tester.tap(find.byIcon(Icons.share_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
  });

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets(
      'detail renders ${locale.languageCode} in dark mode on mobile',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await _pump(
          tester,
          product: _product(seller: true),
          locale: locale,
          dark: true,
        );
        await _show(tester, find.text('Hamburg'));
        expect(find.byType(ContactSellerButton), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
