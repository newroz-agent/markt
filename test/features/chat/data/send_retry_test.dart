import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
// Use Supabase's existing HTTP dependency to exercise real PostgREST requests.
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerin_marketplace/features/chat/data/supabase_chat_repository.dart';

class _Client extends Mock implements SupabaseClient {}

class _Auth extends Mock implements GoTrueClient {}

User _user(String id) => User(
  id: id,
  appMetadata: const {},
  userMetadata: const {},
  aud: 'authenticated',
  createdAt: '',
);

Map<String, dynamic> _payload(http.Request request) =>
    jsonDecode(request.body) as Map<String, dynamic>;

Map<String, dynamic> _message(http.Request request) => {
  ..._payload(request),
  'created_at': '2026-09-07T12:00:00Z',
  'read_at': '2026-09-07T12:01:00Z',
};

http.Response _json(Object? body, {int status = 200}) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

http.Response _conflict() => _json({
  'code': '23505',
  'message': 'duplicate key value violates unique constraint',
}, status: 409);

void main() {
  late _Auth auth;
  late SupabaseChatRepository repository;
  late List<http.Request> requests;
  late FutureOr<http.Response> Function(http.Request) respond;

  setUp(() {
    requests = [];
    respond = (request) => _json(_message(request));
    final transport = SupabaseClient(
      'https://chat.test',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        requests.add(request);
        expect(request.url.path, '/rest/v1/messages');
        expect(request.method, anyOf('POST', 'GET'));
        expect(request.headers['prefer'] ?? '', isNot(contains('resolution=')));
        expect(request.url.queryParameters, isNot(contains('on_conflict')));
        final response = await respond(request);
        return http.Response.bytes(
          response.bodyBytes,
          response.statusCode,
          headers: response.headers,
          request: request,
        );
      }),
    );
    addTearDown(transport.dispose);
    final client = _Client();
    auth = _Auth();
    when(() => client.auth).thenReturn(auth);
    when(() => auth.currentUser).thenReturn(_user('buyer'));
    when(() => client.from(any())).thenAnswer(
      (call) => transport.from(call.positionalArguments.single as String),
    );
    repository = SupabaseChatRepository(client);
  });

  test(
    'successful identical sends receive distinct UUID v4 primary keys',
    () async {
      final first = await repository.sendTextMessage(
        chatId: 'chat',
        body: ' Hello ',
      );
      final second = await repository.sendTextMessage(
        chatId: 'chat',
        body: 'Hello',
      );
      final uuid = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );
      expect(first.id, matches(uuid));
      expect(second.id, matches(uuid));
      expect(second.id, isNot(first.id));
      expect(_payload(requests.first), {
        'id': first.id,
        'chat_id': 'chat',
        'sender_id': 'buyer',
        'kind': 'text',
        'body': 'Hello',
      });
      expect(requests.map((r) => r.method), ['POST', 'POST']);
    },
  );

  test(
    'lost insert acknowledgement retries its ID and returns the stored row',
    () async {
      late Map<String, dynamic> committed;
      respond = (request) {
        if (requests.length == 1) {
          committed = _message(request);
          throw http.ClientException('Response lost after commit');
        }
        if (request.method == 'POST') {
          expect(_payload(request)['id'], committed['id']);
          return _conflict();
        }
        expect(request.url.queryParameters, {
          'select':
              'id,chat_id,sender_id,kind,body,product_id,read_at,created_at,'
              'product:products(id,title,price_cents,currency)',
          'id': 'eq.${committed['id']}',
          'sender_id': 'eq.buyer',
          'chat_id': 'eq.chat',
          'body': 'eq.Hello, (again) & goodbye',
          'kind': 'eq.text',
        });
        return _json([committed]);
      };
      await expectLater(
        repository.sendTextMessage(
          chatId: 'chat',
          body: ' Hello, (again) & goodbye ',
        ),
        throwsA(isA<http.ClientException>()),
      );
      final recovered = await repository.sendTextMessage(
        chatId: 'chat',
        body: 'Hello, (again) & goodbye',
      );
      expect(recovered.id, committed['id']);
      expect(recovered.createdAt, DateTime.utc(2026, 9, 7, 12));
      expect(recovered.readAt, DateTime.utc(2026, 9, 7, 12, 1));
      expect(requests.map((r) => r.method), ['POST', 'POST', 'GET']);

      respond = (request) => _json(_message(request));
      final next = await repository.sendTextMessage(
        chatId: 'chat',
        body: 'Hello, (again) & goodbye',
      );
      expect(next.id, isNot(recovered.id));
    },
  );

  test(
    'non-unique errors propagate without lookup and retain the retry ID',
    () async {
      respond = (_) =>
          _json({'code': '42501', 'message': 'denied'}, status: 403);
      for (var attempt = 0; attempt < 2; attempt++) {
        await expectLater(
          repository.sendTextMessage(chatId: 'chat', body: 'Hello'),
          throwsA(
            isA<PostgrestException>().having((e) => e.code, 'code', '42501'),
          ),
        );
      }
      respond = (request) => _json(_message(request));
      final sent = await repository.sendTextMessage(
        chatId: 'chat',
        body: 'Hello',
      );
      expect(requests.map((r) => r.method), ['POST', 'POST', 'POST']);
      expect(requests.map((r) => _payload(r)['id']), everyElement(sent.id));
    },
  );

  test('pending IDs are isolated by user, chat and trimmed body', () async {
    respond = (_) => throw http.ClientException('offline');
    for (final (uid, chat, body) in [
      ('buyer', 'chat', 'Hello'),
      ('other', 'chat', 'Hello'),
      ('buyer', 'other-chat', 'Hello'),
      ('buyer', 'chat', 'Other body'),
      ('buyer', 'chat', '  Hello\n'),
    ]) {
      when(() => auth.currentUser).thenReturn(_user(uid));
      await expectLater(
        repository.sendTextMessage(chatId: chat, body: body),
        throwsA(isA<http.ClientException>()),
      );
    }
    final ids = requests.map((r) => _payload(r)['id']).toList();
    expect(ids.take(4).toSet(), hasLength(4));
    expect(ids.last, ids.first);
    expect(_payload(requests[1])['sender_id'], 'other');
  });

  for (final mismatch in ['id', 'sender_id', 'chat_id', 'body', 'kind']) {
    test(
      'a duplicate with mismatched $mismatch is not accepted as success',
      () async {
        respond = (request) {
          if (request.method == 'POST') return _conflict();
          final stored = {..._message(requests.first), mismatch: 'different'};
          final query = request.url.queryParameters;
          final matches = ['id', 'sender_id', 'chat_id', 'body', 'kind'].every(
            (column) =>
                query[column] == null ||
                query[column] == 'eq.${stored[column]}',
          );
          return _json(matches ? [stored] : []);
        };
        await expectLater(
          repository.sendTextMessage(chatId: 'chat', body: 'Hello'),
          throwsA(
            isA<PostgrestException>().having((e) => e.code, 'code', '23505'),
          ),
        );
        respond = (request) => _json(_message(request));
        final sent = await repository.sendTextMessage(
          chatId: 'chat',
          body: 'Hello',
        );
        expect(sent.id, _payload(requests.first)['id']);
        expect(requests.map((r) => r.method), ['POST', 'GET', 'POST']);
      },
    );
  }

  test('a failed duplicate lookup retains its ID for another retry', () async {
    respond = (request) {
      if (request.method == 'POST') return _conflict();
      throw http.ClientException('Lookup response lost');
    };
    await expectLater(
      repository.sendTextMessage(chatId: 'chat', body: 'Hello'),
      throwsA(isA<http.ClientException>()),
    );
    respond = (request) => request.method == 'POST'
        ? _conflict()
        : _json([_message(requests.first)]);
    final recovered = await repository.sendTextMessage(
      chatId: 'chat',
      body: 'Hello',
    );
    expect(recovered.id, _payload(requests.first)['id']);
    final inserts = requests.where((request) => request.method == 'POST');
    expect(inserts, hasLength(2));
    expect(inserts.map((r) => _payload(r)['id']), everyElement(recovered.id));
    // PostgREST also retries failed GET requests internally.
    expect(requests.last.method, 'GET');
  });

  test(
    'an overlapping old success does not clear a newer pending send',
    () async {
      final delayed = Completer<http.Response>();
      final started = Completer<void>();
      respond = (request) {
        if (requests.length == 1) {
          started.complete();
          return delayed.future;
        }
        return _json(_message(request));
      };
      final first = repository.sendTextMessage(chatId: 'chat', body: 'Hello');
      await started.future;
      final overlap = await repository.sendTextMessage(
        chatId: 'chat',
        body: 'Hello',
      );
      expect(overlap.id, _payload(requests.first)['id']);

      respond = (_) => throw http.ClientException('offline');
      await expectLater(
        repository.sendTextMessage(chatId: 'chat', body: 'Hello'),
        throwsA(isA<http.ClientException>()),
      );
      final pendingId = _payload(requests.last)['id'];
      expect(pendingId, isNot(overlap.id));
      delayed.complete(_json(_message(requests.first)));
      await first;

      respond = (request) => _json(_message(request));
      final retried = await repository.sendTextMessage(
        chatId: 'chat',
        body: 'Hello',
      );
      expect(retried.id, pendingId);
    },
  );
}
