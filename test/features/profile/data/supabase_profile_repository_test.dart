import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
// Supabase's existing HTTP dependency drives real RPC/query builders.
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerin_marketplace/features/profile/data/supabase_profile_repository.dart';
import 'package:zerin_marketplace/features/profile/domain/profile_errors.dart';

const _uid = 'a1000000-0000-0000-0000-000000000001';

void main() {
  late SupabaseClient client;
  late SupabaseProfileRepository repository;
  late List<http.Request> requests;
  late Object? Function(http.Request) respond;
  late int status;

  setUp(() {
    requests = [];
    respond = (_) => <Object>[];
    status = 200;
    client = SupabaseClient(
      'https://profile.test',
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
    addTearDown(client.dispose);
    repository = SupabaseProfileRepository(client);
  });

  Future<void> signIn() => client.auth.signInWithPassword(
    email: 'owner@example.invalid',
    password: 'password',
  );

  test('get_my_profile resolves avatar object to a public URL', () async {
    await signIn();
    respond = (_) => {
      'display_name': 'Alice Public',
      'username': 'alice_name',
      'city': 'Berlin',
      'bio': 'Hallo',
      'avatar_object': 'key/object.webp',
      'listing_count': 3,
      'seller': {
        'id': 'seller-1',
        'kind': 'private',
        'status': 'approved',
        'store_name': null,
        'verified': false,
      },
    };
    final profile = await repository.fetchMyProfile();
    expect(requests.single.url.path, '/rest/v1/rpc/get_my_profile');
    expect(profile.displayName, 'Alice Public');
    expect(profile.username, 'alice_name');
    expect(profile.listingCount, 3);
    // Domain layer never sees a raw object path; only a resolved public URL.
    expect(profile.avatarUrl, contains('/storage/v1/object/public/avatars/'));
    expect(profile.avatarUrl, contains('key/object.webp'));
    expect(profile.seller?.id, 'seller-1');
    expect(profile.seller?.isApproved, isTrue);
  });

  test('get_public_profile returns null for a missing username', () async {
    respond = (_) => null;
    final profile = await repository.fetchPublicProfile('missing');
    expect(profile, isNull);
    expect(requests.single.url.path, '/rest/v1/rpc/get_public_profile');
    expect(jsonDecode(requests.single.body), {'p_username': 'missing'});
  });

  test('check_profile_username maps server states', () async {
    await signIn();
    for (final entry in <String, UsernameAvailability>{
      'available': UsernameAvailability.available,
      'taken': UsernameAvailability.taken,
      'reserved': UsernameAvailability.reserved,
      'invalid': UsernameAvailability.invalid,
    }.entries) {
      respond = (_) => entry.key;
      expect(await repository.checkUsername('candidate'), entry.value);
    }
  });

  test('update_my_profile maps 23505 to a taken username', () async {
    await signIn();
    status = 409;
    respond = (_) => {
      'code': '23505',
      'message': 'Username is already taken',
      'details': null,
      'hint': null,
    };
    await expectLater(
      repository.updateMyProfile(
        displayName: 'Alice',
        username: 'taken_name',
        city: 'Berlin',
      ),
      throwsA(
        isA<ProfileException>().having(
          (e) => e.reason,
          'reason',
          ProfileFailureReason.usernameTaken,
        ),
      ),
    );
    expect(jsonDecode(requests.single.body), {
      'p_display_name': 'Alice',
      'p_username': 'taken_name',
      'p_city': 'Berlin',
      'p_bio': null,
    });
  });

  test(
    'update_my_profile maps 22023 reserved/city/invalid by message',
    () async {
      await signIn();
      status = 400;
      Future<void> expectReason(String message, ProfileFailureReason reason) {
        respond = (_) => {
          'code': '22023',
          'message': message,
          'details': null,
          'hint': null,
        };
        return expectLater(
          repository.updateMyProfile(
            displayName: 'Alice',
            username: 'name',
            city: 'Berlin',
          ),
          throwsA(
            isA<ProfileException>().having((e) => e.reason, 'reason', reason),
          ),
        );
      }

      await expectReason(
        'Username is reserved',
        ProfileFailureReason.usernameReserved,
      );
      await expectReason(
        'Choose a supported German city',
        ProfileFailureReason.unsupportedCity,
      );
      await expectReason(
        'Username format is invalid',
        ProfileFailureReason.usernameInvalid,
      );
    },
  );

  test(
    'avatar upload prepares, uploads, commits and re-reads profile',
    () async {
      await signIn();
      respond = (request) {
        final path = request.url.path;
        if (path == '/rest/v1/rpc/prepare_profile_avatar_upload') {
          return {'avatar_object': 'key/new.webp'};
        }
        if (path.startsWith('/storage/v1/object/avatars/')) {
          return {'Key': 'avatars/key/new.webp'};
        }
        if (path == '/rest/v1/rpc/commit_profile_avatar') {
          return {
            'avatar_object': 'key/new.webp',
            'previous_avatar_object': null,
          };
        }
        if (path == '/rest/v1/rpc/get_my_profile') {
          return {
            'display_name': 'Alice',
            'username': 'alice_name',
            'city': 'Berlin',
            'bio': null,
            'avatar_object': 'key/new.webp',
            'listing_count': 0,
            'seller': null,
          };
        }
        return <Object>[];
      };
      final profile = await repository.uploadAvatar(
        Uint8List.fromList(<int>[1, 2, 3]),
      );
      final paths = requests.map((r) => r.url.path).toList();
      expect(paths, contains('/rest/v1/rpc/prepare_profile_avatar_upload'));
      expect(paths, contains('/rest/v1/rpc/commit_profile_avatar'));
      expect(paths.last, '/rest/v1/rpc/get_my_profile');
      expect(profile.avatarUrl, contains('avatars/key/new.webp'));
    },
  );

  test('failed avatar commit cleans the staged object', () async {
    await signIn();
    respond = (request) {
      final path = request.url.path;
      if (path == '/rest/v1/rpc/prepare_profile_avatar_upload') {
        return {'avatar_object': 'key/staged.webp'};
      }
      if (path.startsWith('/storage/v1/object/avatars/') &&
          request.method == 'POST') {
        return {'Key': 'avatars/key/staged.webp'};
      }
      if (path == '/rest/v1/rpc/commit_profile_avatar') {
        status = 400;
        return {
          'code': '22023',
          'message': 'Avatar upload is unavailable',
          'details': null,
          'hint': null,
        };
      }
      if (request.method == 'DELETE') {
        status = 200;
        return <Object>[];
      }
      return <Object>[];
    };

    await expectLater(
      repository.uploadAvatar(Uint8List.fromList(<int>[1, 2, 3])),
      throwsA(isA<ProfileException>()),
    );
    expect(
      requests.any(
        (request) =>
            request.method == 'DELETE' &&
            request.url.path == '/storage/v1/object/avatars',
      ),
      isTrue,
    );
  });

  test('summaries resolve avatars and drop rows without a seller id', () async {
    respond = (_) => [
      {
        'seller_id': 'seller-1',
        'display_name': 'Alice Public',
        'username': 'alice_name',
        'city': 'Berlin',
        'avatar_object': 'key/object.webp',
      },
      {
        'seller_id': null,
        'display_name': 'No Id',
        'username': null,
        'city': null,
        'avatar_object': null,
      },
    ];
    final summaries = await repository.fetchPublicProfileSummaries([
      'seller-1',
      'seller-1',
    ]);
    expect(jsonDecode(requests.single.body), {
      'p_seller_ids': ['seller-1'],
    });
    expect(summaries.keys, ['seller-1']);
    final summary = summaries['seller-1']!;
    expect(summary.displayName, 'Alice Public');
    expect(summary.username, 'alice_name');
    expect(summary.avatarUrl, contains('avatars/key/object.webp'));
  });

  test('empty seller id list never calls the RPC', () async {
    final summaries = await repository.fetchPublicProfileSummaries(const []);
    expect(summaries, isEmpty);
    expect(requests, isEmpty);
  });
}
