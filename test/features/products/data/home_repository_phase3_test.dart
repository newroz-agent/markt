import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
// Supabase's existing HTTP dependency is used to exercise real query builders.
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerin_marketplace/core/errors/app_exception.dart';
import 'package:zerin_marketplace/features/home/data/supabase_home_repository.dart';
import 'package:zerin_marketplace/features/home/domain/home_feed.dart';

const _uid = 'f1000000-0000-0000-0000-000000000001';

Map<String, dynamic> _productRow(String id) => {
  'id': id,
  'slug': 'slug-$id',
  'title': 'Product $id',
  'description': 'Description',
  'condition': 'new',
  'price_cents': 1250,
  'currency': 'EUR',
  'city': 'Hamburg',
  'country_code': 'DE',
  'category_id': 'category-1',
  'brand': {'name': 'Real Brand'},
  'specifications': {
    'color': 'red',
    'weight': 12,
    'sizes': ['M', 'L'],
  },
  'published_at': '2026-09-01T10:00:00Z',
  'seller': _sellerRow,
  'images': [
    {'image_url': 'https://img.example/2.jpg', 'sort_order': 2},
    {'image_url': '', 'sort_order': 1},
    {'image_url': 'https://img.example/0.jpg', 'sort_order': 0},
  ],
};

const _sellerRow = {
  'id': 'seller-1',
  'slug': 'shop',
  'shop_name': 'Test Shop',
  'city': 'Hamburg',
  'country_code': 'DE',
  'kind': 'business',
};

void main() {
  late SupabaseClient client;
  late SupabaseHomeRepository repository;
  late List<http.Request> requests;
  late Object? Function(http.Request) respond;
  late int status;

  setUp(() {
    requests = [];
    respond = (_) => [];
    status = 200;
    client = SupabaseClient(
      'https://test.supabase.co',
      'anon-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        if (request.url.path == '/auth/v1/token') {
          return http.Response(
            jsonEncode({
              'access_token': 'test-token',
              'refresh_token': 'refresh-token',
              'token_type': 'bearer',
              'expires_in': 3600,
              'user': {
                'id': _uid,
                'aud': 'authenticated',
                'role': 'authenticated',
                'email': 'one@example.invalid',
                'app_metadata': <String, dynamic>{},
                'user_metadata': <String, dynamic>{},
                'created_at': '2026-01-01T00:00:00Z',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        requests.add(request);
        return http.Response(
          jsonEncode(respond(request)),
          status,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    repository = SupabaseHomeRepository(client);
  });

  tearDown(() async => client.dispose());

  Future<void> signIn() => client.auth.signInWithPassword(
    email: 'one@example.invalid',
    password: 'test-password',
  );

  void expectPublicScope(http.Request request) {
    final params = request.url.queryParameters;
    expect(params['status'], 'eq.active');
    expect(params['seller.status'], 'eq.approved');
    expect(params['seller.phase3_in_germany'], 'eq.true');
    expect(params['country_code'], 'eq.DE');
    expect(params['ships_to'], isNull);
    expect(params['quantity'], 'gt.0');
    expect(params['select'], contains('seller:sellers!inner('));
    expect(params['select'], contains('brand:brands(name)'));
    expect(params['select'], contains('specifications'));
    expect('country_code'.allMatches(params['select']!).length, 2);
  }

  test('home newest, deals and stores keep unknown-country entries', () async {
    final unknownSeller = {..._sellerRow, 'country_code': null};
    final unknownProduct = {
      ..._productRow('legacy'),
      'country_code': null,
      'seller': unknownSeller,
    };
    respond = (request) => switch (request.url.path) {
      '/rest/v1/products' => [unknownProduct],
      '/rest/v1/sellers' => [unknownSeller],
      _ => [],
    };
    final feed = await repository.fetchHomeFeed(limit: 6);
    expect(feed.newArrivals.single.id, 'legacy');
    expect(feed.deals.single.id, 'legacy');
    expect(feed.popularStores.single.id, 'seller-1');
    expect(feed.newArrivals.single.countryCode, isNull);
    expect(feed.popularStores.single.countryCode, isNull);
    expect(requests, hasLength(4));
    for (final request in requests) {
      final params = request.url.queryParameters;
      expect(params.keys, isNot(contains('country_code')));
      expect(params.keys, isNot(contains('phase3_in_germany')));
      expect(params.keys, isNot(contains('seller.phase3_in_germany')));
      expect(params.keys, isNot(contains('ships_to')));
      if (request.url.path.endsWith('/products')) {
        expect(params['status'], 'eq.active');
        expect(params['quantity'], 'gt.0');
        expect(params['seller.status'], isNull);
        expect(params['order'], 'published_at.desc.nullslast');
        expect(params['limit'], '6');
      }
    }
    expect(
      requests.where(
        (r) => r.url.queryParameters['compare_at_price_cents'] == 'not.is.null',
      ),
      hasLength(1),
    );
    final stores = requests.singleWhere((r) => r.url.path.endsWith('/sellers'));
    expect(stores.url.queryParameters['status'], 'eq.approved');
    expect(stores.url.queryParameters['limit'], '8');
  });

  test(
    'detail enforces public scope even with an owner/admin session',
    () async {
      await signIn();
      respond = (_) => _productRow('p1');
      expect((await repository.fetchProduct('p1'))!.id, 'p1');
      expectPublicScope(requests.single);
      expect(requests.single.url.queryParameters['id'], 'eq.p1');
    },
  );

  test('unavailable public detail returns null', () async {
    respond = (_) => null;
    expect(await repository.fetchProduct('hidden'), isNull);
    expectPublicScope(requests.single);
  });

  test(
    'seller and similar lists share projection and exclude before paging',
    () async {
      respond = (_) => [_productRow('other')];
      expect(
        (await repository.fetchSimilarProducts(
          productId: 'current',
          categoryId: 'category-1',
        )).single.id,
        'other',
      );
      final similar = requests.last.url.queryParameters;
      expectPublicScope(requests.last);
      expect(similar['category_id'], 'eq.category-1');
      expect(similar['id'], 'neq.current');
      expect(similar['limit'], '8');

      await repository.fetchSellerProducts(
        'seller-1',
        offset: 24,
        limit: 12,
        excludeProductId: 'current',
      );
      final seller = requests.last.url.queryParameters;
      expectPublicScope(requests.last);
      expect(seller['seller_id'], 'eq.seller-1');
      expect(seller['id'], 'neq.current');
      expect(seller['offset'], '24');
      expect(seller['limit'], '12');
      expect(seller['order'], 'published_at.desc.nullslast,id.asc.nullslast');
      expect(seller['select'], similar['select']);

      await repository.fetchSellerProducts('seller-1');
      expect(requests.last.url.queryParameters['limit'], '24');
      expect(requests.last.url.queryParameters['offset'], '0');
      expect(requests.last.url.queryParameters['id'], isNull);
    },
  );

  test('invalid pagination makes no network requests', () async {
    await expectLater(
      repository.fetchSellerProducts('s', offset: -1),
      throwsArgumentError,
    );
    await expectLater(
      repository.fetchSellerProducts('s', limit: 0),
      throwsArgumentError,
    );
    await expectLater(
      repository.fetchSellerProducts('s', limit: 101),
      throwsArgumentError,
    );
    expect(requests, isEmpty);
  });

  test(
    'model sorts images without mutating rows and keeps real schema fields',
    () {
      final row = _productRow('p1');
      final product = HomeProduct.fromJson(row);
      expect(product.countryCode, 'DE');
      expect(product.store!.countryCode, 'DE');
      expect(product.categoryId, 'category-1');
      expect(product.brandName, 'Real Brand');
      expect(product.specifications['weight'], 12);
      expect(product.specifications['sizes'], ['M', 'L']);
      expect(product.imageUrls, [
        'https://img.example/0.jpg',
        'https://img.example/2.jpg',
      ]);
      expect((row['images'] as List).first['sort_order'], 2);
      expect(
        () => product.specifications['new'] = true,
        throwsUnsupportedError,
      );
      expect(
        HomeProduct.fromJson({
          ...row,
          'brand': null,
          'specifications': null,
        }).brandName,
        isNull,
      );
    },
  );

  test(
    'country models preserve null and missing values without city inference',
    () {
      for (final country in [
        <String, dynamic>{},
        {'country_code': null},
      ]) {
        final seller = {..._sellerRow}..remove('country_code');
        final product = {..._productRow('p1')}..remove('country_code');
        expect(
          MarketplaceStore.fromJson({...seller, ...country}).countryCode,
          isNull,
        );
        expect(
          HomeProduct.fromJson({...product, ...country}).countryCode,
          isNull,
        );
      }
    },
  );

  test(
    'seller fetch uses a separate boolean RPC, never document rows',
    () async {
      respond = (request) =>
          request.url.path.endsWith('/rpc/is_verified_seller')
          ? true
          : _sellerRow;
      final seller = await repository.fetchSeller('seller-1');
      expect(seller!.isBusiness, isTrue);
      expect(seller.verified, isTrue);
      expect(seller.countryCode, 'DE');
      final profile = requests.singleWhere(
        (r) => r.url.path.endsWith('/sellers'),
      );
      expect(profile.url.queryParameters['status'], 'eq.approved');
      expect(profile.url.queryParameters['phase3_in_germany'], 'eq.true');
      expect(profile.url.queryParameters['select'], contains('country_code'));
      final rpc = requests.singleWhere((r) => r.url.path.contains('/rpc/'));
      expect(jsonDecode(rpc.body), {'target_seller_id': 'seller-1'});
      expect(
        requests.any((r) => r.url.path.contains('seller_documents')),
        isFalse,
      );
    },
  );

  test('approval alone never produces a verified badge', () async {
    respond = (request) =>
        request.url.path.contains('/rpc/') ? false : _sellerRow;
    expect((await repository.fetchSeller('seller-1'))!.verified, isFalse);
    expect(MarketplaceStore.fromJson(_sellerRow).verified, isNull);
  });

  test(
    'favorites insert explicit uid and ignore conflicts, reads/deletes scoped',
    () async {
      await signIn();
      expect(await repository.fetchFavoriteState('p1'), isFalse);
      final read = requests.last;
      expect(read.method, 'GET');
      expect(read.url.queryParameters['user_id'], 'eq.$_uid');
      expect(read.url.queryParameters['product_id'], 'eq.p1');

      await repository.setFavorite(productId: 'p1', favorite: true);
      final insert = requests.last;
      expect(insert.method, 'POST');
      expect(jsonDecode(insert.body), {'user_id': _uid, 'product_id': 'p1'});
      expect(insert.url.queryParameters['on_conflict'], 'user_id,product_id');
      expect(
        insert.headers['Prefer'],
        contains('resolution=ignore-duplicates'),
      );

      await repository.setFavorite(productId: 'p1', favorite: false);
      final delete = requests.last;
      expect(delete.method, 'DELETE');
      expect(delete.url.queryParameters['user_id'], 'eq.$_uid');
      expect(delete.url.queryParameters['product_id'], 'eq.p1');
    },
  );

  test('anonymous favorite/report operations never reach PostgREST', () async {
    final unauthenticated = throwsA(
      isA<AppException>().having(
        (e) => e.code,
        'code',
        AppFailureCode.notAuthenticated,
      ),
    );
    await expectLater(repository.fetchFavoriteState('p1'), unauthenticated);
    await expectLater(
      repository.setFavorite(productId: 'p1', favorite: true),
      unauthenticated,
    );
    await expectLater(
      repository.reportProduct(productId: 'p1', reason: 'counterfeit'),
      unauthenticated,
    );
    expect(requests, isEmpty);
  });

  test(
    'report includes real session uid and trims details; status is server-owned',
    () async {
      await signIn();
      await repository.reportProduct(
        productId: 'p1',
        reason: 'counterfeit',
        details: '  suspicious  ',
      );
      expect(requests.single.method, 'POST');
      expect(jsonDecode(requests.single.body), {
        'product_id': 'p1',
        'reporter_id': _uid,
        'reason': 'counterfeit',
        'details': 'suspicious',
      });
    },
  );

  test('PostgREST failures map to AppException', () async {
    status = 403;
    respond = (_) => {'code': '42501', 'message': 'denied'};
    await expectLater(
      repository.fetchProduct('p1'),
      throwsA(isA<AppException>()),
    );
  });
}
