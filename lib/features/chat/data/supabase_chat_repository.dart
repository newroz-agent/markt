import 'dart:async';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerin_marketplace/core/errors/app_exception.dart';
import 'package:zerin_marketplace/core/storage/avatar_url_resolver.dart';
import 'package:zerin_marketplace/features/chat/domain/chat.dart';
import 'package:zerin_marketplace/features/chat/domain/chat_repository.dart';

class SupabaseChatRepository implements ChatRepository {
  SupabaseChatRepository(this._client)
    : _avatarUrls = AvatarUrlResolver(_client);

  final SupabaseClient _client;
  final AvatarUrlResolver _avatarUrls;
  final _pendingSendIds = <(String, String, String), String>{};
  int _channelSerial = 0;
  final _historyStart = <String, ChatMessage>{};
  static const _messageColumns =
      'id, chat_id, sender_id, kind, body, product_id, read_at, created_at, '
      'product:products(id, title, price_cents, currency)';

  @override
  Future<List<ChatConversation>> fetchConversations() => _inbox();

  Future<List<ChatConversation>> _inbox({String? chatId}) async {
    _currentUserId();
    final rows = await _client.rpc<List<dynamic>>(
      'get_chat_inbox',
      params: {'p_chat_id': chatId},
    );
    return rows.map((row) {
      final map = Map<String, dynamic>.from(row as Map);
      // Inbox RPC returns opaque avatar object paths; resolve to public URLs
      // so the UI only ever renders resolved delivery URLs.
      map['shop_avatar_url'] = _avatarUrls.resolve(
        map['shop_avatar_url'] as String?,
      );
      map['buyer_avatar_url'] = _avatarUrls.resolve(
        map['buyer_avatar_url'] as String?,
      );
      return ChatConversation.fromJson(map);
    }).toList();
  }

  @override
  Future<ChatConversation> fetchConversation(String chatId) async {
    final rows = await _inbox(chatId: chatId);
    if (rows.isEmpty) throw const AppException(AppFailureCode.unknown);
    return rows.single;
  }

  @override
  Future<ChatConversation> openChatWithProduct({
    required String sellerId,
    required String productId,
  }) async {
    _currentUserId();
    // The RPC atomically seeds system/product messages. Triggers own previews.
    final row = await _client.rpc<Map<String, dynamic>>(
      'get_or_create_chat',
      params: {'p_seller_id': sellerId, 'p_product_id': productId},
    );
    return fetchConversation(row['id']! as String);
  }

  @override
  Future<ChatConversation> openChatWithSeller(String sellerId) async {
    _currentUserId();
    // Productless profile chat reuses get_or_create_chat with only the seller.
    final row = await _client.rpc<Map<String, dynamic>>(
      'get_or_create_chat',
      params: {'p_seller_id': sellerId},
    );
    return fetchConversation(row['id']! as String);
  }

  @override
  Future<List<ChatMessage>> fetchMessages(
    String chatId, {
    ChatMessage? before,
  }) async {
    final historyKey = '${_currentUserId()}/$chatId';
    var query = _client
        .from('messages')
        .select(_messageColumns)
        .eq('chat_id', chatId);
    if (before != null) {
      final time = before.createdAt.toUtc().toIso8601String();
      query = query.or(
        'created_at.lt.$time,and(created_at.eq.$time,id.lt.${before.id})',
      );
    }
    final rows = await query
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .limit(100);
    final messages = rows.map(ChatMessage.fromJson).toList().reversed.toList();
    if (messages.isNotEmpty &&
        (_historyStart[historyKey] == null ||
            _compare(messages.first, _historyStart[historyKey]!) < 0)) {
      _historyStart[historyKey] = messages.first;
    }
    return messages;
  }

  @override
  Future<ChatMessage> sendTextMessage({
    required String chatId,
    required String body,
  }) async {
    final text = body.trim();
    if (text.isEmpty || text.runes.length > 5000) {
      throw const AppException(AppFailureCode.unknown);
    }
    final uid = _currentUserId();
    final key = (uid, chatId, text);
    // A failed response may hide a committed insert. Reuse its primary key.
    final id = _pendingSendIds.putIfAbsent(key, _messageId);
    Map<String, dynamic> row;
    try {
      row = await _client
          .from('messages')
          .insert({
            'id': id,
            'chat_id': chatId,
            'sender_id': uid,
            'kind': 'text',
            'body': text,
          })
          .select(_messageColumns)
          .single();
    } on PostgrestException catch (error) {
      if (error.code != '23505') rethrow;
      final existing = await _client
          .from('messages')
          .select(_messageColumns)
          .eq('id', id)
          .eq('sender_id', uid)
          .eq('chat_id', chatId)
          .eq('body', text)
          .eq('kind', 'text')
          .maybeSingle();
      if (existing == null) rethrow;
      row = existing;
    }
    final message = ChatMessage.fromJson(row);
    // An overlapping retry must not clear a newer send's key.
    if (_pendingSendIds[key] == id) _pendingSendIds.remove(key);
    return message;
  }

  @override
  Future<int> markChatRead(String chatId) =>
      _client.rpc<int>('mark_chat_read', params: {'p_chat_id': chatId});

  @override
  Stream<List<ChatConversation>> watchConversations() =>
      _watch(tables: const ['chats', 'messages'], load: fetchConversations);

  @override
  Stream<List<ChatMessage>> watchMessages(String chatId) {
    final historyKey = '${_currentUserId()}/$chatId';
    _historyStart.remove(historyKey);
    return _watch(
      tables: const ['messages'],
      chatId: chatId,
      onCancel: () => _historyStart.remove(historyKey),
      load: () async {
        final oldest = _historyStart[historyKey];
        var page = await fetchMessages(chatId);
        final result = [...page];
        // Refresh the loaded range, including read receipts on older pages and
        // messages missed while disconnected. Older history stays on demand.
        while (oldest != null &&
            page.length == 100 &&
            _compare(page.first, oldest) > 0) {
          page = await fetchMessages(chatId, before: page.first);
          result.insertAll(0, page);
        }
        return result;
      },
    );
  }

  // Subscribe before loading; serialize event-driven refreshes so stale requests
  // cannot overwrite newer data. No timer or polling is used.
  Stream<T> _watch<T>({
    required List<String> tables,
    required Future<T> Function() load,
    String? chatId,
    void Function()? onCancel,
  }) {
    late final StreamController<T> controller;
    RealtimeChannel? channel;
    var cancelled = false;
    var loading = false;
    var dirty = false;
    var ready = false;
    Future<void> refresh() async {
      dirty = true;
      if (loading || !ready || cancelled) return;
      loading = true;
      try {
        while (dirty && !cancelled && ready) {
          dirty = false;
          try {
            final value = await load();
            if (!cancelled) controller.add(value);
          } catch (error, stack) {
            if (!cancelled) controller.addError(error, stack);
          }
        }
      } finally {
        loading = false;
      }
    }

    controller = StreamController<T>(
      onListen: () {
        channel = _client.channel(
          'phase1-${_currentUserId()}-${_channelSerial++}',
        );
        for (final table in tables) {
          channel!.onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: table,
            filter: chatId == null
                ? null
                : PostgresChangeFilter(
                    type: PostgresChangeFilterType.eq,
                    column: 'chat_id',
                    value: chatId,
                  ),
            callback: (_) => unawaited(refresh()),
          );
        }
        channel!.subscribe((status, error) {
          if (cancelled) return;
          ready = status == RealtimeSubscribeStatus.subscribed;
          if (ready) {
            unawaited(refresh());
          } else if (status == RealtimeSubscribeStatus.channelError ||
              status == RealtimeSubscribeStatus.timedOut ||
              status == RealtimeSubscribeStatus.closed) {
            controller.addError(
              AppException(AppFailureCode.network, cause: error),
            );
          }
        });
      },
      onCancel: () async {
        cancelled = true;
        onCancel?.call();
        if (channel != null) await _client.removeChannel(channel!);
      },
    );
    return controller.stream;
  }

  String _currentUserId() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw const AppException(AppFailureCode.notAuthenticated);
    return uid;
  }
}

String _messageId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

int _compare(ChatMessage a, ChatMessage b) {
  final time = a.createdAt.compareTo(b.createdAt);
  return time == 0 ? a.id.compareTo(b.id) : time;
}
