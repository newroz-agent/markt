import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
// The HTTP transport is supplied by Supabase's existing dependency.
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerin_marketplace/features/categories/data/supabase_category_products_repository.dart';
import 'package:zerin_marketplace/features/categories/domain/category_products_repository.dart';

late http.Response Function(http.Request request) _respond;

SupabaseClient _clientWithRecorder(List<http.Request> requests) {
  return SupabaseClient(
    'https://test.supabase.co',
    'anon-key',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
    httpClient: MockClient((request) async {
      requests.add(request);
      return _respond(request);
    }),
  );
}

http.Response _ok(http.Request request, List<Map<String, dynamic>> rows) =>
    http.Response(
      jsonEncode(rows),
      200,
      request: request,
      headers: const {'content-type': 'application/json'},
    );

Map<String, dynamic> _productRow(String id, {String? city}) => {
  'id': id,
  'slug': 'slug-$id',
  'title': 'Produkt $id',
  'description': 'Beschreibung',
  'condition': 'new',
  'price_cents': 1250,
  'compare_at_price_cents': null,
  'currency': 'EUR',
  'vat_rate': 19,
  'price_includes_vat': true,
  'free_shipping': false,
  'shipping_cost_cents': 0,
  'rating_average': 0,
  'rating_count': 0,
  'city': city,
  'published_at': '2026-09-01T10:00:00Z',
  'seller': {
    'id': 'seller-1',
    'slug': 'nordlicht',
    'shop_name': 'Nordlicht Technik',
    'bio': null,
    'avatar_url': null,
    'banner_url': null,
    'city': 'Hamburg',
    'rating_average': 0,
    'rating_count': 0,
    'response_time_minutes': null,
  },
  'images': <Map<String, dynamic>>[
    {
      'image_url': 'https://img.example/1.jpg',
      'storage_path': 'p',
      'sort_order': 0,
    },
  ],
};

void main() {
  late List<http.Request> requests;
  late SupabaseCategoryProductsRepository repository;

  void givenResponses(List<Map<String, dynamic>> rows) {
    _respond = (request) => _ok(request, rows);
  }

  setUp(() {
    requests = <http.Request>[];
  });

  test(
    'queries the subtree, applies German city and seller kind filters',
    () async {
      givenResponses([_productRow('a', city: 'Halle (Saale)')]);
      final client = _clientWithRecorder(requests);
      repository = SupabaseCategoryProductsRepository(client);

      final products = await repository.fetchCategoryProducts(
        const CategoryProductsQuery(
          categoryIds: ['root', 'child'],
          condition: CategoryProductConditionFilter.isNew,
          sellerKind: CategoryProductSellerKindFilter.private,
          city: 'Halle (Saale)',
        ),
      );

      expect(products, hasLength(1));
      expect(products.single.id, 'a');
      expect(products.single.city, 'Halle (Saale)');
      final url = requests.single.url;
      expect(url.queryParameters['category_id'], 'in.("root","child")');
      expect(url.queryParameters['status'], 'eq.active');
      expect(url.queryParameters['condition'], 'eq.new');
      expect(url.queryParameters['seller.kind'], 'eq.private');
      expect(url.queryParameters['city'], 'eq.Halle (Saale)');
      expect(url.queryParameters['order'], contains('published_at'));
    },
  );

  test(
    'in-category search narrows titles and pagination uses a range',
    () async {
      givenResponses([_productRow('b')]);
      final client = _clientWithRecorder(requests);
      repository = SupabaseCategoryProductsRepository(client);

      await repository.fetchCategoryProducts(
        const CategoryProductsQuery(
          categoryIds: ['root'],
          query: '  fahrrad  ',
          sort: CategoryProductSort.priceAscending,
          offset: 48,
        ),
      );

      final url = requests.single.url;
      expect(url.queryParameters['title'], 'ilike.%fahrrad%');
      expect(url.queryParameters['order'], contains('price_cents.asc'));
      expect(url.queryParameters['offset'], '48');
      expect(url.queryParameters['limit'], '24');
    },
  );

  test(
    'whitespace-only search is ignored and empty subtree skips the call',
    () async {
      givenResponses(const []);
      final client = _clientWithRecorder(requests);
      repository = SupabaseCategoryProductsRepository(client);

      await repository.fetchCategoryProducts(
        const CategoryProductsQuery(categoryIds: ['root'], query: '   '),
      );
      expect(requests.single.url.queryParameters.containsKey('title'), isFalse);

      final empty = await repository.fetchCategoryProducts(
        const CategoryProductsQuery(categoryIds: []),
      );
      expect(empty, isEmpty);
      expect(requests, hasLength(1));
    },
  );

  test('unconfigured repository returns an empty page', () async {
    final products = await const UnconfiguredCategoryProductsRepository()
        .fetchCategoryProducts(const CategoryProductsQuery(categoryIds: ['x']));
    expect(products, isEmpty);
  });
}
