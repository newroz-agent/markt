import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
// Supabase's existing HTTP dependency drives the real RPC/query/storage builders.
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerin_marketplace/features/identity/domain/identity.dart';
import 'package:zerin_marketplace/features/sell/data/supabase_sell_repository.dart';
import 'package:zerin_marketplace/features/sell/domain/sell_models.dart';

const _uid = 'a1000000-0000-4000-8000-000000000001';
const _privateSellerId = '11111111-1111-4111-8111-111111111111';
const _businessSellerId = '22222222-2222-4222-8222-222222222222';
const _productId = '33333333-3333-4333-8333-333333333333';
const _person = MarketplaceIdentity(
  type: MarketplaceIdentityType.person,
  sellerId: null,
  sellerKind: 'private',
  sellerStatus: null,
  label: 'Alice Person',
  avatarUrl: null,
  username: 'alice',
);
const _business = MarketplaceIdentity(
  type: MarketplaceIdentityType.business,
  sellerId: _businessSellerId,
  sellerKind: 'business',
  sellerStatus: 'approved',
  label: 'Alice Store',
  avatarUrl: null,
  username: null,
);

Map<String, Object?> _listing(String sellerId, String id, String title) => {
  'id': id,
  'seller_id': sellerId,
  'title': title,
  'price_cents': 2500,
  'currency': 'EUR',
  'city': 'Berlin',
  'condition': 'used',
  'status': 'pending_review',
  'moderation_reason': null,
  'created_at': '2026-09-30T12:00:00Z',
  'images': <Object?>[],
};

void main() {
  late SupabaseClient client;
  late SupabaseSellRepository repository;
  late List<http.Request> requests;
  late String preparedSellerId;
  late String preparedKind;

  setUp(() {
    requests = <http.Request>[];
    preparedSellerId = _privateSellerId;
    preparedKind = 'private';
    client = SupabaseClient(
      'https://sell.test',
      'anon-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        if (request.url.path == '/auth/v1/token') {
          return http.Response(
            jsonEncode({
              'access_token': 'token',
              'refresh_token': 'refresh',
              'token_type': 'bearer',
              'expires_in': 3600,
              'user': {
                'id': _uid,
                'aud': 'authenticated',
                'role': 'authenticated',
                'email': 'owner@example.invalid',
                'app_metadata': <String, Object?>{},
                'user_metadata': <String, Object?>{},
                'created_at': '2026-01-01T00:00:00Z',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        requests.add(request);
        final Object response = switch (request.url.path) {
          '/rest/v1/rpc/prepare_listing_submission' => {
            'product_id': _productId,
            'seller_id': preparedSellerId,
            'seller_kind': preparedKind,
            'seller_name': preparedKind == 'business'
                ? 'Alice Store'
                : 'Alice Person',
          },
          '/rest/v1/rpc/submit_listing' => <String, Object?>{},
          '/rest/v1/products'
              when request.url.queryParameters.containsKey('id') =>
            _listing(preparedSellerId, _productId, 'Submitted listing'),
          '/rest/v1/products' => <Object?>[
            _listing(_privateSellerId, 'private-product', 'Private listing'),
            _listing(_businessSellerId, 'business-product', 'Business listing'),
          ],
          final path
              when path.startsWith('/storage/v1/object/product-images/') =>
            {'Key': path},
          _ => throw StateError('Unexpected ${request.url}'),
        };
        return http.Response(
          jsonEncode(response),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.dispose);
    repository = SupabaseSellRepository(client);
  });

  Future<void> signIn() => client.auth.signInWithPassword(
    email: 'owner@example.invalid',
    password: 'password',
  );

  SellListingDraft draft(MarketplaceIdentity identity) => SellListingDraft(
    identity: identity,
    title: 'Submitted listing',
    priceCents: 2500,
    city: 'Berlin',
    categoryId: 'category',
    condition: SellCondition.used,
    description: 'A complete listing description.',
    photos: <SellPhoto>[
      SellPhoto(bytes: Uint8List.fromList(<int>[1, 2, 3]), name: 'one.webp'),
    ],
  );

  http.Request requestFor(String suffix) =>
      requests.singleWhere((request) => request.url.path.endsWith(suffix));

  test(
    'person with no seller uses explicit null UUID and returned private id',
    () async {
      await signIn();
      final listing = await repository.submitListing(draft(_person));

      final prepare = Map<String, dynamic>.from(
        jsonDecode(requestFor('/prepare_listing_submission').body) as Map,
      );
      expect(prepare, {
        'p_seller_id': null,
        'p_seller_kind': 'private',
        'p_seller_name': 'Alice Person',
        'p_city': 'Berlin',
      });
      final submit = Map<String, dynamic>.from(
        jsonDecode(requestFor('/submit_listing').body) as Map,
      );
      expect(submit['p_seller_id'], _privateSellerId);
      expect(
        requests.any(
          (request) => request.url.path.contains(
            '/product-images/$_privateSellerId/$_productId/',
          ),
        ),
        isTrue,
      );
      expect(listing.identity.sellerId, _privateSellerId);
      expect(listing.identity.isPerson, isTrue);
    },
  );

  test(
    'business draft keeps its exact UUID through prepare and submit',
    () async {
      await signIn();
      preparedSellerId = _businessSellerId;
      preparedKind = 'business';

      final listing = await repository.submitListing(draft(_business));

      final prepare =
          jsonDecode(requestFor('/prepare_listing_submission').body)
              as Map<String, dynamic>;
      final submit =
          jsonDecode(requestFor('/submit_listing').body)
              as Map<String, dynamic>;
      expect(prepare['p_seller_id'], _businessSellerId);
      expect(prepare['p_seller_kind'], 'business');
      expect(submit['p_seller_id'], _businessSellerId);
      expect(listing.identity.selectionKey, _business.selectionKey);
    },
  );

  test(
    'My Listings queries all catalog seller ids and maps each identity',
    () async {
      await signIn();
      final personWithSeller = _person.withSellerId(_privateSellerId);

      final listings = await repository.fetchMyListings(
        IdentityCatalog(<MarketplaceIdentity>[personWithSeller, _business]),
      );

      final request = requestFor('/products');
      expect(
        request.url.queryParameters['seller_id'],
        contains(_privateSellerId),
      );
      expect(
        request.url.queryParameters['seller_id'],
        contains(_businessSellerId),
      );
      expect(listings, hasLength(2));
      expect(
        listings
            .singleWhere((listing) => listing.id == 'private-product')
            .identity,
        same(personWithSeller),
      );
      expect(
        listings
            .singleWhere((listing) => listing.id == 'business-product')
            .identity,
        same(_business),
      );
    },
  );
}
