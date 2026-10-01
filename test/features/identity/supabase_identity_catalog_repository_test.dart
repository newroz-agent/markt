import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
// Supabase's existing HTTP dependency drives the real RPC builder.
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerin_marketplace/core/errors/app_exception.dart';
import 'package:zerin_marketplace/features/identity/data/supabase_identity_catalog_repository.dart';

const _uid = 'a1000000-0000-4000-8000-000000000001';

void main() {
  late SupabaseClient client;
  late SupabaseIdentityCatalogRepository repository;
  late List<http.Request> requests;
  late Object response;

  setUp(() {
    requests = <http.Request>[];
    response = <String, Object?>{};
    client = SupabaseClient(
      'https://identity.test',
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
        return http.Response(
          jsonEncode(response),
          200,
          request: request,
          headers: const <String, String>{'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.dispose);
    repository = SupabaseIdentityCatalogRepository(client);
  });

  Future<void> signIn() => client.auth.signInWithPassword(
    email: 'owner@example.invalid',
    password: 'password',
  );

  test('maps the safe person and optional business catalog', () async {
    await signIn();
    response = <String, Object?>{
      'identities': <Object?>[
        <String, Object?>{
          'identity_type': 'person',
          'seller_id': null,
          'kind': 'private',
          'status': null,
          'label': 'Alice Person',
          'avatar_url': 'opaque/avatar.webp',
          'username': 'alice',
        },
        <String, Object?>{
          'identity_type': 'business',
          'seller_id': '22222222-2222-4222-8222-222222222222',
          'kind': 'business',
          'status': 'approved',
          'label': 'Alice Store',
          'avatar_url': 'https://images.example/store.webp',
          'username': null,
        },
      ],
    };

    final catalog = await repository.fetchMyIdentityCatalog();

    expect(requests.single.url.path, '/rest/v1/rpc/get_my_identity_catalog');
    expect(jsonDecode(requests.single.body), isNull);
    expect(catalog.person?.sellerId, isNull);
    expect(
      catalog.person?.avatarUrl,
      contains('/storage/v1/object/public/avatars/'),
    );
    expect(catalog.business?.label, 'Alice Store');
    expect(catalog.business?.isVerifiedBusiness, isTrue);
    expect(catalog.business?.avatarUrl, 'https://images.example/store.webp');
  });

  test('rejects a malformed catalog without a person identity', () async {
    await signIn();
    response = <String, Object?>{'identities': <Object?>[]};

    await expectLater(
      repository.fetchMyIdentityCatalog(),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          AppFailureCode.unknown,
        ),
      ),
    );
  });
}
