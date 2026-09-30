import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
// Supabase's existing HTTP dependency drives the real RPC builder.
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerin_marketplace/features/business/data/supabase_business_repository.dart';
import 'package:zerin_marketplace/features/business/domain/business_models.dart';

const _uid = 'a1000000-0000-4000-8000-000000000001';
const _sellerId = '11111111-1111-4111-8111-111111111111';
const _privateSellerId = '22222222-2222-4222-8222-222222222222';

Map<String, Object?> _onboarding() => <String, Object?>{
  'seller': <String, Object?>{
    'id': _sellerId,
    'kind': 'business',
    'status': 'pending',
    'shop_name': 'Zagros Grill',
    'city': 'Berlin',
    'directory_type': 'restaurant',
  },
  'is_verified': false,
  'required_document_kinds': <String>['identity', 'business_registration'],
  'documents': <Object?>[],
  'profile': null,
  'hours': <Object?>[],
  'menu': <Object?>[],
};

void main() {
  late SupabaseClient client;
  late SupabaseBusinessRepository repository;
  late List<http.Request> requests;

  setUp(() {
    requests = <http.Request>[];
    client = SupabaseClient(
      'https://business.test',
      'anon-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        if (request.url.path == '/auth/v1/token') {
          return http.Response(
            jsonEncode(<String, Object?>{
              'access_token': 'token',
              'refresh_token': 'refresh',
              'token_type': 'bearer',
              'expires_in': 3600,
              'user': <String, Object?>{
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
            headers: const <String, String>{'content-type': 'application/json'},
          );
        }
        requests.add(request);
        final isListResponse =
            request.url.path.endsWith('/owner_replace_directory_hours') ||
            request.url.path.endsWith('/owner_replace_directory_menu');
        return http.Response(
          jsonEncode(isListResponse ? <Object?>[] : _onboarding()),
          200,
          request: request,
          headers: const <String, String>{'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.dispose);
    repository = SupabaseBusinessRepository(client);
  });

  Future<void> signIn() => client.auth.signInWithPassword(
    email: 'owner@example.invalid',
    password: 'password',
  );

  Map<String, dynamic> body(String rpc) => Map<String, dynamic>.from(
    jsonDecode(
          requests
              .singleWhere((request) => request.url.path.endsWith('/$rpc'))
              .body,
        )
        as Map,
  );

  test('every owner RPC sends the explicit business seller id', () async {
    await signIn();
    await repository.fetchOnboarding(sellerId: _sellerId);
    await repository.setDirectoryType(
      sellerId: _sellerId,
      type: DirectoryType.restaurant,
    );
    await repository.saveProfile(
      sellerId: _sellerId,
      profile: const DirectoryProfile(
        type: DirectoryType.restaurant,
        description: 'A valid directory profile description.',
        phone: '030 1234567',
        languages: <SpokenLanguage>{SpokenLanguage.german},
        cuisines: <DirectoryCuisine>{DirectoryCuisine.kurdish},
        priceLevel: 2,
      ),
    );
    await repository.saveHours(
      sellerId: _sellerId,
      intervals: const <OpeningInterval>[],
    );
    await repository.saveMenu(
      sellerId: _sellerId,
      sections: const <MenuSectionDraft>[],
    );

    expect(body('get_my_directory_onboarding')['p_seller_id'], _sellerId);
    expect(body('owner_set_directory_type')['p_seller_id'], _sellerId);
    expect(body('owner_upsert_directory_profile')['p_seller_id'], _sellerId);
    expect(body('owner_replace_directory_hours')['p_seller_id'], _sellerId);
    expect(body('owner_replace_directory_menu')['p_seller_id'], _sellerId);
  });

  test('business start always selects the UUID-first overload', () async {
    await signIn();
    await repository.createBusiness(
      existingPrivateSellerId: null,
      type: DirectoryType.restaurant,
      shopName: 'Zagros Grill',
      city: 'Berlin',
    );
    final personOnly = body('owner_start_directory');
    expect(personOnly, containsPair('p_existing_private_seller_id', null));

    requests.clear();
    await repository.createBusiness(
      existingPrivateSellerId: _privateSellerId,
      type: DirectoryType.restaurant,
      shopName: 'Zagros Grill',
      city: 'Berlin',
    );
    expect(
      body('owner_start_directory')['p_existing_private_seller_id'],
      _privateSellerId,
    );
  });
}
