import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zerin_marketplace/features/auth/domain/auth_repository.dart';
import 'package:zerin_marketplace/features/auth/domain/auth_user.dart';
import 'package:zerin_marketplace/features/auth/presentation/controllers/auth_controller.dart';
import 'package:zerin_marketplace/features/home/domain/home_feed.dart';
import 'package:zerin_marketplace/features/home/domain/home_repository.dart';
import 'package:zerin_marketplace/features/home/presentation/controllers/home_controller.dart';
import 'package:zerin_marketplace/features/products/presentation/product_detail_screen.dart';
import 'package:zerin_marketplace/features/products/presentation/product_rail.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

HomeProduct _product() => HomeProduct.fromJson({
  'id': 'p1',
  'slug': 'p1',
  'title': 'Recorded Product',
  'description': 'A product',
  'condition': 'used',
  'price_cents': 1200,
  'currency': 'EUR',
  'published_at': '2026-09-01T10:00:00Z',
});

class _Home implements HomeRepository {
  final recorded = <String>[];

  @override
  Future<void> recordProductView(String productId) async =>
      recorded.add(productId);

  @override
  Future<bool> fetchFavoriteState(String productId) async => false;

  @override
  Future<List<HomeProduct>> fetchSellerProducts(
    String sellerId, {
    int offset = 0,
    int limit = 24,
    String? excludeProductId,
  }) async => const <HomeProduct>[];

  @override
  Future<List<HomeProduct>> fetchSimilarProducts({
    required String productId,
    required String categoryId,
  }) async => const <HomeProduct>[];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _StubAuth implements AuthRepository {
  _StubAuth(this._user);
  final AuthUser? _user;
  @override
  AuthUser? get currentUser => _user;
  @override
  Stream<AuthUser?> get authStateChanges => Stream<AuthUser?>.value(_user);
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

Future<void> _pumpDetail(
  WidgetTester tester,
  _Home home, {
  AuthUser? user,
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const ProductDetailScreen(productId: 'p1'),
      ),
      GoRoute(
        path: '/products/:productId',
        builder: (_, state) =>
            Scaffold(body: Text('P ${state.pathParameters['productId']}')),
      ),
      GoRoute(path: '/auth', builder: (_, _) => const Scaffold()),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_StubAuth(user)),
        authStateProvider.overrideWith((ref) => Stream<AuthUser?>.value(user)),
        homeRepositoryProvider.overrideWithValue(home),
        homeProductProvider(
          productId: 'p1',
        ).overrideWith((ref) async => _product()),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocale.localizationsDelegates,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  testWidgets('detail open records the view once for authenticated users', (
    tester,
  ) async {
    final home = _Home();
    await _pumpDetail(
      tester,
      home,
      user: const AuthUser(id: 'buyer', email: 'buyer@example.test'),
    );
    expect(home.recorded, ['p1']);
  });

  testWidgets('anonymous detail open records nothing', (tester) async {
    final home = _Home();
    await _pumpDetail(tester, home);
    expect(home.recorded, isEmpty);
  });

  testWidgets('preview rail never mounts detail and never records a view', (
    tester,
  ) async {
    final home = _Home();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) =>
              Scaffold(body: ProductRail(products: <HomeProduct>[_product()])),
        ),
        GoRoute(
          path: '/products/:productId',
          builder: (_, state) =>
              Scaffold(body: Text('P ${state.pathParameters['productId']}')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _StubAuth(const AuthUser(id: 'buyer', email: 'b@example.test')),
          ),
          homeRepositoryProvider.overrideWithValue(home),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocale.localizationsDelegates,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Recorded Product'), findsOneWidget);
    // A preview card is shown, but the detail screen never mounted.
    expect(home.recorded, isEmpty);
  });
}
