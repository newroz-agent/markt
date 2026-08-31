import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:zerin_marketplace/core/providers/infrastructure_providers.dart';
import 'package:zerin_marketplace/features/chat/data/supabase_chat_repository.dart';
import 'package:zerin_marketplace/features/chat/data/unconfigured_chat_repository.dart';
import 'package:zerin_marketplace/features/chat/domain/chat.dart';

part 'chat_controller.g.dart';

@Riverpod(keepAlive: true)
dynamic chatRepository(ChatRepositoryRef ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? const UnconfiguredChatRepository()
      : SupabaseChatRepository(client);
}

SupabaseChatRepository _supabaseChatRepository(dynamic repository) =>
    repository as SupabaseChatRepository;

/// Inbox: all conversations of the current user, newest first.
@riverpod
Future<List<ChatConversation>> chatInbox(ChatInboxRef ref) =>
    _supabaseChatRepository(ref.watch(chatRepositoryProvider))
        .fetchConversations();

/// Unread badge total across all conversations.
@riverpod
Future<int> unreadChatCount(UnreadChatCountRef ref) async {
  final inbox = await ref.watch(chatInboxProvider.future);
  return inbox.fold<int>(0, (sum, c) => sum + c.unreadCount);
}

/// Open (or create) the chat for a product; returns the conversation.
@riverpod
Future<ChatConversation> openChat(
  OpenChatRef ref, {
  required String sellerId,
  required String productId,
}) async {
  final conversation = await _supabaseChatRepository(ref.watch(chatRepositoryProvider))
      .openChatWithProduct(sellerId: sellerId, productId: productId);
  ref.invalidate(chatInboxProvider);
  return conversation;
}

/// One realtime conversation: initial history from PostgREST, then live
/// INSERTs pushed over Supabase Realtime. No polling.
@riverpod
class Conversation extends _$Conversation {
  StreamSubscription<ChatMessage>? _sub;
  final _seen = <String>{};
  String? _chatId;

  @override
  FutureOr<List<ChatMessage>> build({required String chatId}) {
    final repository = _supabaseChatRepository(ref.watch(chatRepositoryProvider));
    _chatId = chatId;
    ref.onDispose(() {
      _sub?.cancel();
      _sub = null;
    });

    // Opening a conversation marks it read and refreshes the badge.
    unawaited(
      repository.markChatRead(chatId).then(
            (_) => ref.invalidate(unreadChatCountProvider),
            onError: (_) {},
          ),
    );

    _sub ??= repository.subscribeMessages(chatId).listen(
          _append,
          onError: (Object error, StackTrace stackTrace) {
            if (!state.hasValue) state = AsyncError(error, stackTrace);
          },
        );

    return _loadInitial(repository, chatId);
  }

  Future<List<ChatMessage>> _loadInitial(
    SupabaseChatRepository repository,
    String chatId,
  ) async {
    final messages = await repository.fetchMessages(chatId);
    _seen
      ..clear()
      ..addAll(messages.map((m) => m.id));
    return messages;
  }

  void _append(ChatMessage message) {
    if (_seen.contains(message.id)) return;
    _seen.add(message.id);
    final current = state.value ?? const <ChatMessage>[];
    state = AsyncData(<ChatMessage>[...current, message]);
  }

  Future<void> send(String body) async {
    final chatId = _chatId;
    if (chatId == null) return;
    final repository = _supabaseChatRepository(ref.read(chatRepositoryProvider));
    await repository.sendTextMessage(chatId: chatId, body: body);
    // Own message comes back through the realtime subscription; refresh
    // the inbox preview in the background.
    ref.invalidate(chatInboxProvider);
  }
}
