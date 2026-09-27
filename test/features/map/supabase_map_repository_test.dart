import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
// Supabase's existing HTTP dependency drives real query/RPC builders.
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerin_marketplace/features/map/data/supabase_map_repository.dart';
import 'package:zerin_marketplace/features/map/domain/map_models.dart';

void main() {
  late SupabaseClient client;
  late SupabaseMapRepository repository;
  late List<http.Request> requests;
  late Object? Function(http.Request request) respond;

  setUp(() {
    requests = <http.Request>[];
    respond = (_) => <Object>[];
    client = SupabaseClient(
      'https://map.test',
      'anon-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode(respond(request)),
          200,
          request: request,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.dispose);
    repository = SupabaseMapRepository(client);
  });

  test('cities come from the one ordered server-owned source', () async {
    respond = (_) => <Object>[
      <String, Object>{
        'name': 'Berlin',
        'latitude': '52.520008',
        'longitude': 13.404954,
      },
      <String, Object>{
        'name': 'Hamburg',
        'latitude': 53.551086,
        'longitude': '9.993682',
      },
      <String, Object?>{'name': 'Broken', 'latitude': null, 'longitude': null},
    ];

    final cities = await repository.fetchGermanCities();

    expect(cities.map((city) => city.name), <String>['Berlin', 'Hamburg']);
    expect(requests.single.method, 'GET');
    expect(requests.single.url.path, '/rest/v1/german_cities');
    expect(requests.single.url.queryParameters['order'], 'name.asc.nullslast');
  });

  test(
    'radius and discovery filters are sent only to the server RPC',
    () async {
      respond = (_) => <Object>[
        _row(id: 'private-1', precise: false, address: 'must never survive'),
        _row(id: 'private-1', precise: false),
        _row(id: 'precise-1', precise: true, address: 'Store Street 1'),
        _row(id: 'broken', precise: false, latitude: 120),
      ];

      final result = await repository.fetchListings(
        const MapQuery(
          center: MapPoint(latitude: 52.52, longitude: 13.405),
          radius: MapRadius.km20,
          filters: MapFilters(
            query: '  fahrrad  ',
            categoryId: '  category-1 ',
            condition: MapListingCondition.used,
            sellerKind: MapSellerKind.privateSeller,
            minPriceCents: 1000,
            maxPriceCents: 5000,
            sort: MapSort.priceAscending,
          ),
          limit: 24,
          offset: 7,
        ),
      );

      expect(requests, hasLength(1));
      final request = requests.single;
      expect(request.method, 'POST');
      expect(request.url.path, '/rest/v1/rpc/listings_within_radius');
      expect(jsonDecode(request.body), <String, Object?>{
        'center_lat': 52.52,
        'center_lng': 13.405,
        'radius_km': 20,
        'p_query': 'fahrrad',
        'p_category_id': 'category-1',
        'p_condition': 'used',
        'p_seller_kind': 'private',
        'p_min_price_cents': 1000,
        'p_max_price_cents': 5000,
        'p_sort': 'price_asc',
        'p_limit': 24,
        'p_offset': 7,
      });
      expect(result.listings.map((listing) => listing.productId), <String>[
        'private-1',
        'precise-1',
      ]);
      expect(
        result.listings.first.publicAddress,
        isNull,
        reason: 'private pins may never carry an exact address',
      );
      expect(result.listings.last.publicAddress, 'Store Street 1');
      expect(result.totalCount, 4);
      expect(result.nextOffset, 11);
    },
  );

  test('Alle sends null radius and never writes viewer coordinates', () async {
    respond = (_) => <Object>[_row(id: 'all-1', precise: false)];

    await repository.fetchListings(
      const MapQuery(
        center: MapPoint(latitude: 48.135125, longitude: 11.581981),
        radius: MapRadius.all,
      ),
    );

    expect(requests, hasLength(1));
    expect(requests.single.url.path, '/rest/v1/rpc/listings_within_radius');
    expect(requests.single.method, 'POST');
    final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
    expect(body['radius_km'], isNull);
    expect(body['center_lat'], 48.135125);
    expect(body['center_lng'], 11.581981);
    expect(
      requests.any(
        (request) =>
            request.method == 'PATCH' ||
            request.method == 'PUT' ||
            request.url.path.contains('/profiles') ||
            request.url.path.contains('/products'),
      ),
      isFalse,
    );
  });
}

Map<String, Object?> _row({
  required String id,
  required bool precise,
  double latitude = 52.519,
  String longitude = '13.406',
  String? address,
}) => <String, Object?>{
  'product_id': id,
  'title': 'Listing $id',
  'price_cents': '2500',
  'currency': 'EUR',
  'product_condition': 'used',
  'city': 'Berlin',
  'seller_id': 'seller-$id',
  'seller_name': 'Seller',
  'seller_kind': precise ? 'business' : 'private',
  'category_id': 'category-1',
  'primary_image_path': null,
  'primary_image_url': 'https://example.invalid/$id.webp',
  'marker_latitude': latitude,
  'marker_longitude': longitude,
  'distance_km': '1.25',
  'is_precise_business': precise,
  'public_address': address,
  'total_count': 4,
};
