import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zerin_marketplace/core/errors/app_exception.dart';
import 'package:zerin_marketplace/features/auth/domain/auth_repository.dart';
import 'package:zerin_marketplace/features/auth/domain/auth_user.dart';
import 'package:zerin_marketplace/features/auth/presentation/controllers/auth_controller.dart';
import 'package:zerin_marketplace/features/chat/domain/chat.dart';
import 'package:zerin_marketplace/features/chat/domain/chat_repository.dart';
import 'package:zerin_marketplace/features/chat/presentation/controllers/chat_controller.dart';
import 'package:zerin_marketplace/features/identity/presentation/controllers/identity_controller.dart';

class _Auth extends Mock implements AuthRepository {}

class _Repository extends Fake implements ChatRepository {
  final streams = <StreamController<List<ChatMessage>>>[];
  final inboxes = <StreamController<List<ChatConversation>>>[];
  final cursors = <ChatMessage?>[];
  final sends = <({String chatId, String body})>[];
  final reads = <String>[];
  final details = <String>[];
  int cancelled = 0;
  int inboxCancelled = 0;
  Future<ChatMessage> Function()? onSend;
  Future<List<ChatMessage>> Function()? onFetch;
  Future<int> Function()? onRead;
  Future<ChatConversation> Function()? onDetails;

  @override
  Stream<List<ChatMessage>> watchMessages(String chatId) {
    expect(chatId, 'chat');
    final stream = StreamController<List<ChatMessage>>(
      onCancel: () => cancelled++,
    );
    streams.add(stream);
    return stream.stream;
  }

  @override
  Stream<List<ChatConversation>> watchConversations() {
    final stream = StreamController<List<ChatConversation>>(
      onCancel: () => inboxCancelled++,
    );
    inboxes.add(stream);
    return stream.stream;
  }

  @override
  Future<ChatMessage> sendTextMessage({
    required String chatId,
    required String body,
  }) {
    sends.add((chatId: chatId, body: body));
    return onSend!();
  }

  @override
  Future<List<ChatMessage>> fetchMessages(
    String chatId, {
    ChatMessage? before,
  }) {
    expect(chatId, 'chat');
    cursors.add(before);
    return onFetch!();
  }

  @override
  Future<int> markChatRead(String chatId) {
    reads.add(chatId);
    return onRead?.call() ?? Future.value(1);
  }

  @override
  Future<ChatConversation> fetchConversation(String chatId) async {
    details.add(chatId);
    return onDetails?.call() ?? _chat(chatId, 0);
  }

  Future<void> close() async {
    for (final stream in streams) {
      await stream.close();
    }
    for (final stream in inboxes) {
      await stream.close();
    }
  }
}

ChatMessage _message(String id, {int minute = 0, bool read = false}) =>
    ChatMessage.fromJson({
      'id': id,
      'chat_id': 'chat',
      'sender_id': 'buyer',
      'body': id,
      'created_at': DateTime.utc(2026, 9, 7, 12, minute).toIso8601String(),
      'read_at': read ? '2026-09-07T13:00:00Z' : null,
    });

ChatConversation _chat(String id, int unread) => ChatConversation.fromJson({
  'id': id,
  'seller_id': 'seller',
  'unread_count': unread,
});

void main() {
  const buyer = AuthUser(id: 'buyer', email: 'buyer@example.com');
  const other = AuthUser(id: 'other', email: 'other@example.com');
  final provider = conversationProvider(chatId: 'chat');
  late _Auth auth;
  late _Repository repository;
  late StreamController<AuthUser?> authEvents;
  late ProviderContainer container;

  setUp(() async {
    auth = _Auth();
    repository = _Repository();
    authEvents = StreamController<AuthUser?>();
    when(() => auth.currentUser).thenReturn(buyer);
    when(() => auth.authStateChanges).thenAnswer((_) => authEvents.stream);
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        chatRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await repository.close();
      await authEvents.close();
    });
    container.listen(authStateProvider, (_, _) {});
    authEvents.add(buyer);
    await container.read(authStateProvider.future);
  });

  Future<void> emit(List<ChatMessage> messages) async {
    repository.streams.last.add(messages);
    await Future<void>.delayed(Duration.zero);
    await container.pump();
  }

  Future<void> changeUser(AuthUser? user) async {
    when(() => auth.currentUser).thenReturn(user);
    authEvents.add(user);
    await Future<void>.delayed(Duration.zero);
    await container.pump();
    await Future<void>.delayed(Duration.zero);
  }

  test(
    'live snapshots deduplicate, sort ties and update read receipts',
    () async {
      container.listen(provider, (_, _) {});
      await emit([_message('b'), _message('a'), _message('c', minute: 1)]);
      expect(container.read(provider).requireValue.map((m) => m.id), [
        'a',
        'b',
        'c',
      ]);
      await emit([_message('b', read: true), _message('b', read: true)]);
      final messages = container.read(provider).requireValue;
      expect(messages.map((m) => m.id), ['a', 'b', 'c']);
      expect(messages[1].readAt, isNotNull);
      expect(container.read(provider.notifier).hasOlder, isFalse);
    },
  );

  for (final liveFirst in [true, false]) {
    test(
      'send/live dedup when ${liveFirst ? 'live' : 'send'} arrives first',
      () async {
        container.listen(provider, (_, _) {});
        await emit([]);
        final response = Completer<ChatMessage>();
        repository.onSend = () => response.future;
        final notifier = container.read(provider.notifier);
        final sending = notifier.send('Hello');
        await notifier.send('duplicate tap');
        expect(repository.sends, [(chatId: 'chat', body: 'Hello')]);
        if (liveFirst) await emit([_message('sent', read: true)]);
        response.complete(_message('sent'));
        await sending;
        if (!liveFirst) await emit([_message('sent', read: true)]);
        final messages = container.read(provider).requireValue;
        expect(messages, hasLength(1));
        expect(messages.single.id, 'sent');
        expect(messages.single.readAt, isNotNull);
      },
    );
  }

  test(
    'send failure preserves history and releases send guard for retry',
    () async {
      container.listen(provider, (_, _) {});
      await emit([_message('existing')]);
      repository.onSend = () => Future.error(StateError('send failed'));
      final notifier = container.read(provider.notifier);
      await expectLater(notifier.send('Hello'), throwsStateError);
      expect(container.read(provider).requireValue.single.id, 'existing');
      repository.onSend = () async => _message('sent', minute: 1);
      await notifier.send('retry');
      expect(repository.sends, hasLength(2));
      expect(container.read(provider).requireValue.map((m) => m.id), [
        'existing',
        'sent',
      ]);
    },
  );

  test(
    'older history uses oldest cursor, blocks overlap and survives live refresh',
    () async {
      container.listen(provider, (_, _) {});
      await emit(List.generate(100, (i) => _message('m$i', minute: i + 1)));
      final notifier = container.read(provider.notifier);
      expect(notifier.hasOlder, isTrue);
      final older = Completer<List<ChatMessage>>();
      repository.onFetch = () => older.future;
      final loading = notifier.loadOlder();
      await notifier.loadOlder();
      expect(repository.cursors, hasLength(1));
      expect(repository.cursors.single?.id, 'm0');
      older.complete([_message('old'), _message('m0', minute: 1)]);
      await loading;
      expect(notifier.hasOlder, isFalse);
      await emit([_message('new', minute: 101)]);
      expect(container.read(provider).requireValue, hasLength(102));
      expect(container.read(provider).requireValue.first.id, 'old');
      expect(container.read(provider).requireValue.last.id, 'new');
      await notifier.loadOlder();
      expect(repository.cursors, hasLength(1));
    },
  );

  test(
    'read requests during a read are coalesced into another server update',
    () async {
      container.listen(provider, (_, _) {});
      await emit([_message('a')]);
      final first = Completer<int>();
      repository.onRead = () =>
          repository.reads.length == 1 ? first.future : Future.value(1);
      final notifier = container.read(provider.notifier);
      final marking = notifier.markRead();
      await notifier.markRead();
      await notifier.markRead();
      expect(repository.reads, ['chat']);
      first.complete(1);
      await marking;
      expect(repository.reads, ['chat', 'chat']);
    },
  );

  test(
    'auto disposal cancels stream and late send cannot populate new provider',
    () async {
      final subscription = container.listen(provider, (_, _) {});
      await emit([_message('old-user')]);
      final response = Completer<ChatMessage>();
      repository.onSend = () => response.future;
      final sending = container.read(provider.notifier).send('Hello');
      subscription.close();
      await container.pump();
      expect(repository.cancelled, 1);
      response.complete(_message('late'));
      await sending;
      container.listen(provider, (_, _) {});
      await emit([_message('fresh')]);
      expect(container.read(provider).requireValue.single.id, 'fresh');
    },
  );

  test(
    'auth switch cancels old stream and ignores pending send and history',
    () async {
      container.listen(provider, (_, _) {});
      await emit(List.generate(100, (i) => _message('old$i', minute: i)));
      final response = Completer<ChatMessage>();
      final history = Completer<List<ChatMessage>>();
      repository.onSend = () => response.future;
      repository.onFetch = () => history.future;
      final notifier = container.read(provider.notifier);
      final sending = notifier.send('old account');
      final loading = notifier.loadOlder();
      await changeUser(other);
      expect(repository.cancelled, 1);
      expect(repository.streams, hasLength(2));
      await emit([_message('other-user')]);
      response.complete(_message('old-send'));
      history.complete([_message('old-history')]);
      await Future.wait([sending, loading]);
      expect(container.read(provider).requireValue.single.id, 'other-user');
      expect(container.read(provider.notifier).hasOlder, isFalse);
    },
  );

  test(
    'sign out clears conversation and does not subscribe anonymously',
    () async {
      container.listen(provider, (_, _) {});
      await emit([_message('private')]);
      await changeUser(null);
      expect(
        container.read(provider).error,
        isA<AppException>().having(
          (e) => e.code,
          'code',
          AppFailureCode.notAuthenticated,
        ),
      );
      expect(repository.cancelled, 1);
      expect(repository.streams, hasLength(1));
      expect(container.read(provider).valueOrNull, isEmpty);
    },
  );

  test('inbox unread count updates, auth isolation and disposal', () async {
    final inbox = container.listen(chatInboxProvider, (_, _) {});
    final count = container.listen(unreadChatCountProvider, (_, _) {});
    repository.inboxes.last.add([_chat('a', 2), _chat('b', 3)]);
    await Future<void>.delayed(Duration.zero);
    expect(await container.read(unreadChatCountProvider.future), 5);
    repository.inboxes.last.add([_chat('a', 0), _chat('b', 1)]);
    await Future<void>.delayed(Duration.zero);
    expect(await container.read(unreadChatCountProvider.future), 1);
    await changeUser(null);
    expect(await container.read(chatInboxProvider.future), isEmpty);
    expect(await container.read(unreadChatCountProvider.future), 0);
    expect(repository.inboxCancelled, 1);
    expect(repository.inboxes, hasLength(1));
    await changeUser(other);
    expect(repository.inboxes, hasLength(2));
    repository.inboxes.last.add([_chat('other', 4)]);
    await Future<void>.delayed(Duration.zero);
    expect(await container.read(unreadChatCountProvider.future), 4);
    inbox.close();
    count.close();
    await container.pump();
    expect(repository.inboxCancelled, 2);
  });

  test('details are keyed by chat and refetched after auth change', () async {
    final details = chatDetailsProvider(chatId: 'detail');
    container.listen(details, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    expect((await container.read(details.future))?.chatId, 'detail');
    await changeUser(other);
    expect((await container.read(details.future))?.chatId, 'detail');
    expect(repository.details, ['detail', 'detail']);
  });

  test('identity catalog revision refetches inbox and chat details', () async {
    final inbox = container.listen(chatInboxProvider, (_, _) {});
    final detailsProvider = chatDetailsProvider(chatId: 'detail');
    final details = container.listen(detailsProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    expect(repository.inboxes, hasLength(1));
    expect(repository.details, ['detail']);

    container.read(identityCatalogRevisionProvider.notifier).bump();
    await container.pump();
    await Future<void>.delayed(Duration.zero);

    expect(repository.inboxCancelled, 1);
    expect(repository.inboxes, hasLength(2));
    expect(repository.details, ['detail', 'detail']);
    inbox.close();
    details.close();
  });

  for (final fail in [false, true]) {
    test(
      'auth switch clears private data while new requests ${fail ? 'fail' : 'wait'}',
      () async {
        final details = chatDetailsProvider(chatId: 'detail');
        container.listen(provider, (_, _) {});
        container.listen(chatInboxProvider, (_, _) {});
        container.listen(unreadChatCountProvider, (_, _) {});
        container.listen(details, (_, _) {});
        await emit([_message('private')]);
        repository.inboxes.last.add([_chat('private', 7)]);
        await Future<void>.delayed(Duration.zero);
        expect((await container.read(details.future))?.chatId, 'detail');
        expect(await container.read(unreadChatCountProvider.future), 7);

        final newDetails = Completer<ChatConversation>();
        repository.onDetails = () => newDetails.future;
        await changeUser(other);
        expect(repository.cancelled, 1);
        expect(repository.inboxCancelled, 1);
        expect(container.read(provider).valueOrNull, isEmpty);
        expect(container.read(chatInboxProvider).valueOrNull, isEmpty);
        expect(container.read(details).valueOrNull, isNull);
        expect(container.read(unreadChatCountProvider).valueOrNull, isNot(7));

        if (fail) {
          final error = StateError('new account request failed');
          repository.streams.last.addError(error);
          repository.inboxes.last.addError(error);
          newDetails.completeError(error);
          await Future<void>.delayed(Duration.zero);
          await container.pump();
          expect(container.read(provider).hasError, isTrue);
          expect(container.read(chatInboxProvider).hasError, isTrue);
          expect(container.read(details).hasError, isTrue);
          expect(container.read(provider).valueOrNull, isEmpty);
          expect(container.read(chatInboxProvider).valueOrNull, isEmpty);
          expect(container.read(details).valueOrNull, isNull);
          expect(container.read(unreadChatCountProvider).valueOrNull, isNot(7));
        } else {
          newDetails.complete(_chat('other-detail', 0));
          repository.inboxes.last.add([_chat('other-inbox', 2)]);
          await emit([_message('other-message')]);
          expect(
            container.read(provider).requireValue.single.id,
            'other-message',
          );
          expect(
            container.read(chatInboxProvider).requireValue.single.chatId,
            'other-inbox',
          );
          expect(
            (await container.read(details.future))?.chatId,
            'other-detail',
          );
          expect(await container.read(unreadChatCountProvider.future), 2);
        }
      },
    );
  }

  test(
    'late previous-account details cannot replace current details',
    () async {
      final oldResult = Completer<ChatConversation>();
      final newResult = Completer<ChatConversation>();
      repository.onDetails = () =>
          repository.details.length == 1 ? oldResult.future : newResult.future;
      final details = chatDetailsProvider(chatId: 'detail');
      container.listen(details, (_, _) {});
      await changeUser(other);
      newResult.complete(_chat('other-detail', 0));
      await Future<void>.delayed(Duration.zero);
      oldResult.complete(_chat('private-detail', 0));
      await Future<void>.delayed(Duration.zero);
      expect(container.read(details).requireValue?.chatId, 'other-detail');
      await changeUser(null);
      expect(container.read(details).valueOrNull, isNull);
      expect(
        container.read(details).error,
        isA<AppException>().having(
          (e) => e.code,
          'code',
          AppFailureCode.notAuthenticated,
        ),
      );
      expect(repository.details, hasLength(2));
    },
  );

  for (final failOld in [false, true]) {
    test(
      'auth resets guards and old ${failOld ? 'failed' : 'completed'} operations cannot release new guards',
      () async {
        container.listen(provider, (_, _) {});
        await emit(List.generate(100, (i) => _message('old$i', minute: i)));
        final oldSend = Completer<ChatMessage>();
        final oldHistory = Completer<List<ChatMessage>>();
        final oldRead = Completer<int>();
        final newSend = Completer<ChatMessage>();
        final newHistory = Completer<List<ChatMessage>>();
        final newRead = Completer<int>();
        repository.onSend = () =>
            repository.sends.length == 1 ? oldSend.future : newSend.future;
        repository.onFetch = () => repository.cursors.length == 1
            ? oldHistory.future
            : newHistory.future;
        repository.onRead = () => switch (repository.reads.length) {
          1 => oldRead.future,
          2 => newRead.future,
          _ => Future.value(1),
        };
        final notifier = container.read(provider.notifier);
        final oldOperations = [
          notifier.send('old'),
          notifier.loadOlder(),
          notifier.markRead(),
        ];
        final oldChecks = [
          for (final operation in oldOperations)
            expectLater(operation, failOld ? throwsStateError : completes),
        ];
        await notifier.markRead();
        await changeUser(other);
        await emit(List.generate(100, (i) => _message('new$i', minute: i)));
        final newOperations = [
          notifier.send('new'),
          notifier.loadOlder(),
          notifier.markRead(),
        ];
        expect(repository.sends, hasLength(2));
        expect(repository.cursors, hasLength(2));
        expect(repository.reads, hasLength(2));
        expect(repository.cursors.last?.id, 'new0');
        if (failOld) {
          oldSend.completeError(StateError('old send'));
          oldHistory.completeError(StateError('old history'));
          oldRead.completeError(StateError('old read'));
        } else {
          oldSend.complete(_message('private-send'));
          oldHistory.complete([_message('private-history')]);
          oldRead.complete(1);
        }
        await Future.wait(oldChecks);
        await notifier.send('duplicate');
        await notifier.loadOlder();
        await notifier.markRead();
        expect(repository.sends, hasLength(2));
        expect(repository.cursors, hasLength(2));
        expect(repository.reads, hasLength(2));
        expect(
          container
              .read(provider)
              .requireValue
              .every((m) => m.id.startsWith('new')),
          isTrue,
        );
        newSend.complete(_message('new-send', minute: 101));
        newHistory.complete([_message('new-history', minute: -1)]);
        newRead.complete(1);
        await Future.wait(newOperations);
        expect(repository.reads, hasLength(3));
        expect(container.read(provider).requireValue, hasLength(102));
        expect(notifier.hasOlder, isFalse);
      },
    );
  }
}
