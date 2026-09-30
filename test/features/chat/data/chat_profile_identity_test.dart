import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerin_marketplace/features/chat/data/supabase_chat_repository.dart';

class _Client extends Mock implements SupabaseClient {}

class _Auth extends Mock implements GoTrueClient {}

void main() {
  late _Client client;
  late _Auth auth;
  late SupabaseClient transport;
  late SupabaseChatRepository repository;
  late List<http.Request> requests;
  late Object Function(http.Request) respond;

  setUp(() {
    requests = [];
    respond = (_) => <Object>[];
    transport = SupabaseClient(
      'https://chat.test',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode(respond(request)),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(transport.dispose);
    client = _Client();
    auth = _Auth();
    when(() => client.auth).thenReturn(auth);
    when(() => auth.currentUser).thenReturn(
      const User(
        id: 'buyer',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '',
      ),
    );
    when(() => client.storage).thenReturn(transport.storage);
    when(
      () => client.rpc<List<dynamic>>(any(), params: any(named: 'params')),
    ).thenAnswer(
      (call) => transport.rpc<List<dynamic>>(
        call.positionalArguments.single as String,
        params: call.namedArguments[#params] as Map<String, dynamic>?,
      ),
    );
    when(
      () =>
          client.rpc<Map<String, dynamic>>(any(), params: any(named: 'params')),
    ).thenAnswer(
      (call) => transport.rpc<Map<String, dynamic>>(
        call.positionalArguments.single as String,
        params: call.namedArguments[#params] as Map<String, dynamic>?,
      ),
    );
    repository = SupabaseChatRepository(client);
  });

  test(
    'openChatWithSeller uses get_or_create_chat with only the seller',
    () async {
      respond = (request) => switch (request.url.path) {
        '/rest/v1/rpc/get_or_create_chat' => {'id': 'chat'},
        '/rest/v1/rpc/get_chat_inbox' => [
          {'id': 'chat', 'seller_id': 'seller-1', 'unread_count': 0},
        ],
        _ => throw StateError('Unexpected ${request.url}'),
      };
      final chat = await repository.openChatWithSeller('seller-1');
      expect(chat.chatId, 'chat');
      expect(requests.map((r) => r.url.path), [
        '/rest/v1/rpc/get_or_create_chat',
        '/rest/v1/rpc/get_chat_inbox',
      ]);
      // Productless profile chat sends only the seller id.
      expect(jsonDecode(requests.first.body), {'p_seller_id': 'seller-1'});
    },
  );

  test('inbox resolves opaque avatar object paths to public URLs', () async {
    respond = (_) => [
      {
        'id': 'chat',
        'seller_id': 'seller-1',
        'shop_name': 'Alice Public',
        'shop_profile_username': 'alice_name',
        'shop_avatar_url': 'key/object.webp',
        'buyer_avatar_url': 'buyer-key/b.webp',
        'viewer_identity_avatar_url': 'viewer-key/v.webp',
        'seller_identity_avatar_url': 'seller-key/s.webp',
        'unread_count': 0,
      },
    ];
    final conversations = await repository.fetchConversations();
    final conversation = conversations.single;
    expect(conversation.shopProfileUsername, 'alice_name');
    expect(
      conversation.shopAvatarUrl,
      contains('/storage/v1/object/public/avatars/key/object.webp'),
    );
    expect(
      conversation.buyerAvatarUrl,
      contains('/storage/v1/object/public/avatars/buyer-key/b.webp'),
    );
    expect(
      conversation.viewerIdentityAvatarUrl,
      contains('/storage/v1/object/public/avatars/viewer-key/v.webp'),
    );
    expect(
      conversation.sellerIdentityAvatarUrl,
      contains('/storage/v1/object/public/avatars/seller-key/s.webp'),
    );
  });

  test(
    'inbox passes through absolute business avatar URLs unchanged',
    () async {
      respond = (_) => [
        {
          'id': 'chat',
          'seller_id': 'seller-2',
          'shop_name': 'Trusted Store',
          'shop_profile_username': null,
          'shop_avatar_url': 'https://cdn.example/store.png',
          'viewer_identity_avatar_url': 'https://cdn.example/viewer.png',
          'seller_identity_avatar_url':
              'https://cdn.example/store-identity.png',
          'unread_count': 0,
        },
      ];
      final conversation = (await repository.fetchConversations()).single;
      expect(conversation.shopAvatarUrl, 'https://cdn.example/store.png');
      expect(
        conversation.viewerIdentityAvatarUrl,
        'https://cdn.example/viewer.png',
      );
      expect(
        conversation.sellerIdentityAvatarUrl,
        'https://cdn.example/store-identity.png',
      );
      expect(conversation.shopProfileUsername, isNull);
    },
  );
}
