import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zerin_marketplace/core/errors/app_exception.dart';
import 'package:zerin_marketplace/core/providers/infrastructure_providers.dart';
import 'package:zerin_marketplace/features/auth/presentation/controllers/auth_controller.dart';
import 'package:zerin_marketplace/features/chat/data/supabase_chat_repository.dart';
import 'package:zerin_marketplace/features/chat/data/unconfigured_chat_repository.dart';
import 'package:zerin_marketplace/features/chat/domain/chat.dart';
import 'package:zerin_marketplace/features/chat/domain/chat_repository.dart';
import 'package:zerin_marketplace/features/identity/presentation/controllers/identity_controller.dart';

part 'chat_controller.g.dart';

@Riverpod(keepAlive: true)
ChatRepository chatRepository(ChatRepositoryRef ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? const UnconfiguredChatRepository()
      : SupabaseChatRepository(client);
}

@riverpod
Stream<List<ChatConversation>> chatInbox(ChatInboxRef ref) {
  ref.watch(authStateProvider.select((state) => state.valueOrNull?.id));
  ref.watch(identityCatalogRevisionProvider);
  ref.state = const AsyncData([]);
  if (ref.read(authRepositoryProvider).currentUser == null) {
    return Stream.value([]);
  }
  return ref.watch(chatRepositoryProvider).watchConversations();
}

@riverpod
Future<int> unreadChatCount(UnreadChatCountRef ref) async {
  final inbox = await ref.watch(chatInboxProvider.future);
  return inbox.fold<int>(0, (sum, c) => sum + c.unreadCount);
}

@riverpod
Future<ChatConversation?> chatDetails(
  ChatDetailsRef ref, {
  required String chatId,
}) {
  ref.watch(authStateProvider.select((state) => state.valueOrNull?.id));
  ref.watch(identityCatalogRevisionProvider);
  ref.state = const AsyncData(null);
  if (ref.read(authRepositoryProvider).currentUser == null) {
    throw const AppException(AppFailureCode.notAuthenticated);
  }
  return ref.watch(chatRepositoryProvider).fetchConversation(chatId);
}

@riverpod
class Conversation extends _$Conversation {
  final _messages = <String, ChatMessage>{};
  bool hasOlder = true;
  bool _loadingOlder = false;
  bool _sending = false;
  bool _markingRead = false;
  bool _readAgain = false;
  int _generation = 0;

  @override
  Stream<List<ChatMessage>> build({required String chatId}) {
    ref.watch(authStateProvider.select((state) => state.valueOrNull?.id));
    final repository = ref.watch(chatRepositoryProvider);
    final generation = ++_generation;
    ref.onDispose(() => _generation++);
    // Riverpod retains previous data during loading/errors. Replace private
    // data with an empty value before switching the authenticated stream.
    state = const AsyncData([]);
    _messages.clear();
    _sending = false;
    _loadingOlder = false;
    _markingRead = false;
    _readAgain = false;
    hasOlder = true;
    if (ref.read(authRepositoryProvider).currentUser == null) {
      return Stream.error(const AppException(AppFailureCode.notAuthenticated));
    }
    var initial = true;
    return repository.watchMessages(chatId).map((messages) {
      if (generation != _generation) return <ChatMessage>[];
      if (initial) {
        hasOlder = messages.length >= 100;
        initial = false;
      }
      return _merge(messages);
    });
  }

  List<ChatMessage> _merge(List<ChatMessage> messages) {
    for (final message in messages) {
      final previous = _messages[message.id];
      // An older in-flight send response must not undo a realtime read receipt.
      if (previous?.readAt != null && message.readAt == null) continue;
      _messages[message.id] = message;
    }
    return _messages.values.toList()..sort((a, b) {
      final time = a.createdAt.compareTo(b.createdAt);
      return time == 0 ? a.id.compareTo(b.id) : time;
    });
  }

  Future<void> send(String body) async {
    if (_sending) return;
    _sending = true;
    final generation = _generation;
    try {
      final message = await ref
          .read(chatRepositoryProvider)
          .sendTextMessage(chatId: chatId, body: body);
      if (generation == _generation) state = AsyncData(_merge([message]));
    } finally {
      if (generation == _generation) _sending = false;
    }
  }

  Future<void> loadOlder() async {
    if (_loadingOlder || !hasOlder || _messages.isEmpty) return;
    _loadingOlder = true;
    final generation = _generation;
    try {
      final page = await ref
          .read(chatRepositoryProvider)
          .fetchMessages(chatId, before: _merge([]).first);
      if (generation != _generation) return;
      hasOlder = page.length == 100;
      state = AsyncData(_merge(page));
    } finally {
      if (generation == _generation) _loadingOlder = false;
    }
  }

  Future<void> markRead() async {
    _readAgain = true;
    if (_markingRead) return;
    _markingRead = true;
    final generation = _generation;
    final repository = ref.read(chatRepositoryProvider);
    try {
      while (_readAgain && generation == _generation) {
        _readAgain = false;
        await repository.markChatRead(chatId);
      }
    } finally {
      if (generation == _generation) _markingRead = false;
    }
  }
}
