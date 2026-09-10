import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
// The HTTP transport is supplied by Supabase's existing dependency.
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerin_marketplace/core/errors/app_exception.dart';
import 'package:zerin_marketplace/features/chat/data/supabase_chat_repository.dart';
import 'package:zerin_marketplace/features/chat/domain/chat.dart';

class _Client extends Mock implements SupabaseClient {}

class _Auth extends Mock implements GoTrueClient {}

class _Channel extends Fake implements RealtimeChannel {
  final callbacks = <String, void Function(PostgresChangePayload)>{};
  final filters = <String, PostgresChangeFilter?>{};
  void Function(RealtimeSubscribeStatus, Object?)? status;

  @override
  RealtimeChannel onPostgresChanges({
    required PostgresChangeEvent event,
    String? schema,
    String? table,
    PostgresChangeFilter? filter,
    List<PostgresChangeFilter>? filters,
    List<String>? select,
    required void Function(PostgresChangePayload) callback,
  }) {
    expect(event, PostgresChangeEvent.all);
    expect(schema, 'public');
    callbacks[table!] = callback;
    this.filters[table] = filter;
    return this;
  }

  @override
  RealtimeChannel subscribe([
    void Function(RealtimeSubscribeStatus, Object?)? callback,
    Duration? timeout,
  ]) {
    status = callback;
    return this;
  }

  void change(String table) => callbacks[table]!(
    PostgresChangePayload(
      schema: 'public',
      table: table,
      commitTimestamp: DateTime.utc(2026),
      eventType: PostgresChangeEvent.update,
      newRecord: const {},
      oldRecord: const {},
      errors: null,
    ),
  );
}

Map<String, dynamic> _message(String id, {String? readAt}) => {
  'id': id,
  'chat_id': 'chat',
  'sender_id': 'buyer',
  'kind': 'text',
  'body': 'Hello',
  'created_at': '2026-09-07T12:00:00Z',
  'read_at': readAt,
};

void main() {
  late _Client client;
  late _Auth auth;
  late _Channel channel;
  late SupabaseClient transport;
  late SupabaseChatRepository repository;
  late List<http.Request> requests;
  late FutureOr<Object> Function(http.Request) respond;

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
          jsonEncode(await respond(request)),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(transport.dispose);
    client = _Client();
    auth = _Auth();
    channel = _Channel();
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
    when(() => client.from(any())).thenAnswer(
      (call) => transport.from(call.positionalArguments.single as String),
    );
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
    when(() => client.rpc<int>(any(), params: any(named: 'params'))).thenAnswer(
      (call) => transport.rpc<int>(
        call.positionalArguments.single as String,
        params: call.namedArguments[#params] as Map<String, dynamic>?,
      ),
    );
    when(() => client.channel(any())).thenReturn(channel);
    when(() => client.removeChannel(channel)).thenAnswer((_) async => 'ok');
    repository = SupabaseChatRepository(client);
  });

  test(
    'opening uses only atomic creation and inbox RPCs, including repeats',
    () async {
      respond = (request) => switch (request.url.path) {
        '/rest/v1/rpc/get_or_create_chat' => {'id': 'chat'},
        '/rest/v1/rpc/get_chat_inbox' => [
          {'id': 'chat', 'seller_id': 'seller', 'unread_count': 2},
        ],
        _ => throw StateError(
          'Unexpected client seeding/touch: ${request.url}',
        ),
      };
      for (var i = 0; i < 2; i++) {
        final chat = await repository.openChatWithProduct(
          sellerId: 'seller',
          productId: 'product',
        );
        expect(chat.chatId, 'chat');
        expect(chat.unreadCount, 2);
      }
      expect(requests.map((r) => r.url.path), [
        '/rest/v1/rpc/get_or_create_chat',
        '/rest/v1/rpc/get_chat_inbox',
        '/rest/v1/rpc/get_or_create_chat',
        '/rest/v1/rpc/get_chat_inbox',
      ]);
      expect(requests.every((r) => r.method == 'POST'), isTrue);
      expect(jsonDecode(requests.first.body), {
        'p_seller_id': 'seller',
        'p_product_id': 'product',
      });
      expect(jsonDecode(requests[1].body), {'p_chat_id': 'chat'});
    },
  );

  test('inbox uses RPC and missing detail fails', () async {
    expect(await repository.fetchConversations(), isEmpty);
    expect(jsonDecode(requests.single.body), {'p_chat_id': null});
    await expectLater(
      repository.fetchConversation('missing'),
      throwsA(isA<AppException>()),
    );
    expect(jsonDecode(requests.last.body), {'p_chat_id': 'missing'});
  });

  test('send trims and inserts message fields without touching chats', () async {
    respond = (_) => _message('sent');
    final sent = await repository.sendTextMessage(
      chatId: 'chat',
      body: ' \n Hello \t ',
    );
    expect(sent.id, 'sent');
    expect(requests.single.url.path, '/rest/v1/messages');
    expect(requests.single.method, 'POST');
    final payload = jsonDecode(requests.single.body) as Map<String, dynamic>;
    expect(
      payload.remove('id'),
      matches(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      ),
    );
    expect(payload, {
      'chat_id': 'chat',
      'sender_id': 'buyer',
      'kind': 'text',
      'body': 'Hello',
    });
  });

  test('send limits count Unicode scalars after trimming', () async {
    respond = (_) => _message('sent');
    final scalar = String.fromCharCode(0x1f600);
    await repository.sendTextMessage(
      chatId: 'chat',
      body: '  ${scalar * 5000}  ',
    );
    expect(
      (jsonDecode(requests.single.body)['body'] as String).runes.length,
      5000,
    );
    for (final body in ['', ' \n\t ', 'a' * 5001, scalar * 5001]) {
      await expectLater(
        repository.sendTextMessage(chatId: 'chat', body: body),
        throwsA(isA<AppException>()),
      );
    }
    expect(requests, hasLength(1));
  });

  test(
    'unauthenticated fetch, open and valid send never reach transport',
    () async {
      when(() => auth.currentUser).thenReturn(null);
      final error = throwsA(
        isA<AppException>().having(
          (e) => e.code,
          'code',
          AppFailureCode.notAuthenticated,
        ),
      );
      await expectLater(repository.fetchConversations(), error);
      await expectLater(repository.fetchMessages('chat'), error);
      await expectLater(
        repository.openChatWithProduct(
          sellerId: 'seller',
          productId: 'product',
        ),
        error,
      );
      await expectLater(
        repository.sendTextMessage(chatId: 'chat', body: 'Hello'),
        error,
      );
      expect(requests, isEmpty);
    },
  );

  test(
    'history takes latest 100 with stable order and strict composite cursor',
    () async {
      respond = (_) => [_message('b'), _message('a')];
      final latest = await repository.fetchMessages('chat');
      expect(latest.map((m) => m.id), ['a', 'b']);
      final query = requests.single.url.queryParameters;
      expect(query['chat_id'], 'eq.chat');
      expect(query['order'], 'created_at.desc.nullslast,id.desc.nullslast');
      expect(query['limit'], '100');
      expect(query, isNot(contains('or')));
      final cursor = ChatMessage.fromJson({
        ..._message('a'),
        'created_at': '2026-09-07T14:00:00+02:00',
      });
      await repository.fetchMessages('chat', before: cursor);
      expect(
        requests.last.url.queryParameters['or'],
        '(created_at.lt.2026-09-07T12:00:00.000Z,and(created_at.eq.2026-09-07T12:00:00.000Z,id.lt.a))',
      );
    },
  );

  test('mark read uses server RPC and returns affected count', () async {
    respond = (_) => 4;
    expect(await repository.markChatRead('chat'), 4);
    expect(requests.single.url.path, '/rest/v1/rpc/mark_chat_read');
    expect(jsonDecode(requests.single.body), {'p_chat_id': 'chat'});
  });

  test(
    'subscribes before query; an event during fetch queues a fresh read',
    () async {
      final first = Completer<Object>();
      final started = Completer<void>();
      respond = (_) {
        if (requests.length == 1) {
          started.complete();
          return first.future;
        }
        return [_message('a', readAt: '2026-09-07T12:01:00Z')];
      };
      final stream = StreamIterator(repository.watchMessages('chat'));
      addTearDown(stream.cancel);
      final initial = stream.moveNext();
      expect(channel.status, isNotNull);
      expect(channel.callbacks.keys, ['messages']);
      expect(channel.filters['messages'].toString(), 'chat_id=eq.chat');
      await Future<void>.delayed(Duration.zero);
      expect(requests, isEmpty);
      channel.status!(RealtimeSubscribeStatus.subscribed, null);
      await started.future;
      channel.change('messages');
      channel.change('messages');
      expect(requests, hasLength(1));
      first.complete([_message('a')]);
      expect(await initial, isTrue);
      expect(stream.current.single.readAt, isNull);
      expect(await stream.moveNext(), isTrue);
      expect(stream.current.single.readAt, DateTime.utc(2026, 9, 7, 12, 1));
      expect(requests, hasLength(2));
      await stream.cancel();
      verify(() => client.removeChannel(channel)).called(1);
      channel.change('messages');
      channel.status!(RealtimeSubscribeStatus.subscribed, null);
      await Future<void>.delayed(Duration.zero);
      expect(requests, hasLength(2));
    },
  );

  test(
    'cancellation during initial fetch removes channel and drops result',
    () async {
      final result = Completer<Object>();
      final started = Completer<void>();
      respond = (_) {
        started.complete();
        return result.future;
      };
      final values = <List<ChatMessage>>[];
      final subscription = repository.watchMessages('chat').listen(values.add);
      channel.status!(RealtimeSubscribeStatus.subscribed, null);
      await started.future;
      await subscription.cancel();
      result.complete([_message('late')]);
      await Future<void>.delayed(Duration.zero);
      expect(values, isEmpty);
      verify(() => client.removeChannel(channel)).called(1);
    },
  );

  test(
    'reconnect catches up across pages to the previous oldest message',
    () async {
      Map<String, dynamic> row(int index) => {
        ..._message('m${index.toString().padLeft(3, '0')}'),
        'created_at': DateTime.utc(2026, 9, 7, 12, index).toIso8601String(),
      };
      respond = (_) => switch (requests.length) {
        1 => [row(0)],
        2 => List.generate(100, (i) => row(205 - i)),
        3 => List.generate(100, (i) => row(105 - i)),
        4 => List.generate(6, (i) => row(5 - i)),
        _ => throw StateError('Unexpected extra history fetch'),
      };
      final stream = StreamIterator(repository.watchMessages('chat'));
      addTearDown(stream.cancel);
      final initial = stream.moveNext();
      channel.status!(RealtimeSubscribeStatus.subscribed, null);
      expect(await initial, isTrue);
      expect(stream.current.single.id, 'm000');
      channel.status!(RealtimeSubscribeStatus.subscribed, null);
      expect(await stream.moveNext(), isTrue);
      expect(
        stream.current.map((m) => m.id),
        List.generate(206, (i) => 'm${i.toString().padLeft(3, '0')}'),
      );
      expect(requests, hasLength(4));
      expect(requests[1].url.queryParameters, isNot(contains('or')));
      expect(requests[2].url.queryParameters['or'], contains('id.lt.m106'));
      expect(requests[3].url.queryParameters['or'], contains('id.lt.m006'));
    },
  );

  test(
    'realtime refresh includes read receipts throughout manually loaded history',
    () async {
      Map<String, dynamic> row(int index, {bool read = false}) => {
        ..._message(
          'm${index.toString().padLeft(3, '0')}',
          readAt: read ? '2026-09-07T15:00:00Z' : null,
        ),
        'created_at': DateTime.utc(2026, 9, 7, 12, index).toIso8601String(),
      };
      respond = (_) => switch (requests.length) {
        1 => List.generate(100, (i) => row(199 - i)),
        2 => List.generate(100, (i) => row(99 - i)),
        3 => List.generate(100, (i) => row(199 - i, read: true)),
        4 => List.generate(100, (i) => row(99 - i, read: true)),
        5 => List.generate(100, (i) => row(199 - i, read: true)),
        _ => throw StateError('Fetched beyond loaded history'),
      };
      final stream = StreamIterator(repository.watchMessages('chat'));
      addTearDown(stream.cancel);
      final initial = stream.moveNext();
      channel.status!(RealtimeSubscribeStatus.subscribed, null);
      expect(await initial, isTrue);
      final older = await repository.fetchMessages(
        'chat',
        before: stream.current.first,
      );
      expect(older.first.id, 'm000');
      expect(older.first.readAt, isNull);
      channel.change('messages');
      expect(await stream.moveNext(), isTrue);
      expect(stream.current, hasLength(200));
      expect(stream.current.first.id, 'm000');
      expect(stream.current.every((m) => m.readAt != null), isTrue);
      expect(requests[3].url.queryParameters['or'], contains('id.lt.m100'));
      expect(requests, hasLength(4));
      await stream.cancel();

      final reopened = StreamIterator(repository.watchMessages('chat'));
      addTearDown(reopened.cancel);
      final reopenedInitial = reopened.moveNext();
      channel.status!(RealtimeSubscribeStatus.subscribed, null);
      expect(await reopenedInitial, isTrue);
      expect(reopened.current, hasLength(100));
      expect(reopened.current.first.id, 'm100');
      expect(requests, hasLength(5));
    },
  );

  test(
    'history fetched by another account does not widen current live range',
    () async {
      Map<String, dynamic> row(int index) => {
        ..._message('m${index.toString().padLeft(3, '0')}'),
        'created_at': DateTime.utc(2026, 9, 7, 12, index).toIso8601String(),
      };
      final buyer = auth.currentUser;
      respond = (_) => switch (requests.length) {
        1 || 3 => List.generate(100, (i) => row(199 - i)),
        2 => List.generate(100, (i) => row(99 - i)),
        _ => throw StateError('Other account history leaked into live range'),
      };
      final stream = StreamIterator(repository.watchMessages('chat'));
      addTearDown(stream.cancel);
      final initial = stream.moveNext();
      channel.status!(RealtimeSubscribeStatus.subscribed, null);
      expect(await initial, isTrue);
      when(() => auth.currentUser).thenReturn(
        const User(
          id: 'other',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '',
        ),
      );
      await repository.fetchMessages('chat', before: stream.current.first);
      when(() => auth.currentUser).thenReturn(buyer);
      channel.change('messages');
      expect(await stream.moveNext(), isTrue);
      expect(stream.current, hasLength(100));
      expect(stream.current.first.id, 'm100');
      expect(requests, hasLength(3));
    },
  );

  test('subscription errors surface and reconnect can still load', () async {
    final errors = <Object>[];
    final loaded = Completer<List<ChatMessage>>();
    respond = (_) => [_message('reconnected')];
    final subscription = repository
        .watchMessages('chat')
        .listen(loaded.complete, onError: (Object error) => errors.add(error));
    addTearDown(subscription.cancel);
    for (final status in [
      RealtimeSubscribeStatus.channelError,
      RealtimeSubscribeStatus.timedOut,
      RealtimeSubscribeStatus.closed,
    ]) {
      channel.status!(status, StateError('offline'));
    }
    await Future<void>.delayed(Duration.zero);
    expect(errors, hasLength(3));
    expect(
      errors,
      everyElement(
        isA<AppException>().having(
          (e) => e.code,
          'code',
          AppFailureCode.network,
        ),
      ),
    );
    expect(requests, isEmpty);
    channel.status!(RealtimeSubscribeStatus.subscribed, null);
    expect((await loaded.future).single.id, 'reconnected');
  });

  test(
    'inbox watches chats and messages and refreshes after reconnect',
    () async {
      respond = (_) => [
        {'id': 'chat', 'seller_id': 'seller', 'unread_count': requests.length},
      ];
      final stream = StreamIterator(repository.watchConversations());
      addTearDown(stream.cancel);
      final initial = stream.moveNext();
      expect(channel.callbacks.keys, unorderedEquals(['chats', 'messages']));
      expect(channel.filters.values, everyElement(isNull));
      channel.status!(RealtimeSubscribeStatus.subscribed, null);
      expect(await initial, isTrue);
      expect(stream.current.single.unreadCount, 1);
      channel.change('chats');
      expect(await stream.moveNext(), isTrue);
      expect(stream.current.single.unreadCount, 2);
      channel.change('messages');
      expect(await stream.moveNext(), isTrue);
      expect(stream.current.single.unreadCount, 3);
      channel.status!(RealtimeSubscribeStatus.subscribed, null);
      expect(await stream.moveNext(), isTrue);
      expect(stream.current.single.unreadCount, 4);
    },
  );
}
