import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:zerin_marketplace/core/errors/app_exception.dart';
import 'package:zerin_marketplace/features/chat/domain/chat.dart';

/// System message inserted as the very first message of every chat.
///
/// This is the marketplace's anti-circumvention line: all contact and
/// payment must stay inside the app. Keep in sync with l10n copy.
const chatSystemNotice = '请尽量在应用内沟通和交易，以保障你的权益与安全。';

class SupabaseChatRepository {
  SupabaseChatRepository(this._client);

  static const _sellerJoin =
      'seller:sellers!inner(id, user_id, slug, shop_name, avatar_url)';

  static const _conversationColumns =
      'id, buyer_id, seller_id, last_message_at, last_message_preview, '
      '$_sellerJoin, '
      'product:products(id, title, price_cents, currency)';

  static const _messageColumns =
      'id, chat_id, sender_id, kind, body, product_id, read_at, created_at, '
      'product:products(id, title, price_cents, currency)';

  final SupabaseClient _client;

  /// Inbox: every chat where the current user is buyer or seller,
  /// newest activity first.
  Future<List<ChatConversation>> fetchConversations() async {
    try {
      final uid = _currentUserId();
      final rows = await _client
          .from('chats')
          .select(_conversationColumns)
          .or('buyer_id.eq.$uid,sellers.user_id.eq.$uid')
          .order('last_message_at', ascending: false, nullsFirst: false)
          .order('created_at', ascending: false)
          .limit(200);
      return <ChatConversation>[
        for (final row in (rows as List<dynamic>))
          ChatConversation.fromJson(row as Map<String, dynamic>),
      ];
    } on PostgrestException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        AppException(AppFailureCode.unknown, cause: error),
        stackTrace,
      );
    }
  }

  /// Historical messages of one chat (oldest last).
  Future<List<ChatMessage>> fetchMessages(String chatId) async {
    try {
      final rows = await _client
          .from('messages')
          .select(_messageColumns)
          .eq('chat_id', chatId)
          .order('created_at', ascending: true)
          .limit(500);
      return <ChatMessage>[
        for (final row in (rows as List<dynamic>))
          ChatMessage.fromJson(row as Map<String, dynamic>),
      ];
    } on PostgrestException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        AppException(AppFailureCode.unknown, cause: error),
        stackTrace,
      );
    }
  }

  /// Opens (or returns the existing) chat for a product and, on first
  /// creation, seeds the anti-circumvention system message plus a
  /// product card message (kind: product).
  Future<ChatConversation> openChatWithProduct({
    required String sellerId,
    required String productId,
  }) async {
    late final Map<String, dynamic> chatRow;
    try {
      chatRow = await _client.rpc('get_or_create_chat', params: {
        'p_seller_id': sellerId,
        'p_product_id': productId,
      });
    } on FunctionException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        AppException(AppFailureCode.unknown, cause: error),
        stackTrace,
      );
    }

    final chatId = chatRow['id']! as String;
    final seeded = await _seedFirstMessages(chatId, productId);

    try {
      final conversations = await fetchConversations();
      return conversations.firstWhere(
        (c) => c.chatId == chatId,
        orElse: () => _minimalConversation(chatRow),
      );
    } on AppException {
      // Inbox refresh failed but the chat exists — return the minimal form.
      return _minimalConversation(chatRow);
    }
  }

  /// Sends a text message and bumps the chat's activity columns.
  Future<ChatMessage> sendTextMessage({
    required String chatId,
    required String body,
  }) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      throw const AppException(AppFailureCode.unknown);
    }
    try {
      final row = await _client
          .from('messages')
          .insert({
            'chat_id': chatId,
            'sender_id': _currentUserId(),
            'kind': 'text',
            'body': trimmed,
          })
          .select(_messageColumns)
          .single();
      await _touchChat(chatId, trimmed);
      return ChatMessage.fromJson(row);
    } on PostgrestException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        AppException(AppFailureCode.unknown, cause: error),
        stackTrace,
      );
    }
  }

  /// Realtime message stream for one chat: initial history followed by
  /// every INSERT pushed via Supabase Realtime (no polling).
  ///
  /// The returned stream never completes on its own; cancel the
  /// subscription (or dispose the listener) to stop it.
  Stream<ChatMessage> subscribeMessages(String chatId) async* {
    // Initial history first.
    for (final message in await fetchMessages(chatId)) {
      yield message;
    }

    final controller = StreamController<ChatMessage>();
    late final RealtimeChannel channel;
    channel = _client
        .channel('chat-messages-$chatId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: chatId,
          ),
          callback: (payload) {
            final row = payload.newRecord;
            if (row.isNotEmpty) {
              controller.add(ChatMessage.fromJson(row));
            }
          },
        )
        .subscribe();

    await controller.stream
        .map<ChatMessage>((m) => m)
        .forEach(controller.add);
  }

  Future<int> markChatRead(String chatId) async {
    try {
      final count = await _client.rpc('mark_chat_read', params: {
        'p_chat_id': chatId,
      });
      return (count as num?)?.toInt() ?? 0;
    } on FunctionException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        AppException(AppFailureCode.unknown, cause: error),
        stackTrace,
      );
    }
  }

  /// Inserts the anti-circumvention system message (and product card)
  /// exactly once, keyed on the chat having no prior messages.
  Future<bool> _seedFirstMessages(String chatId, String productId) async {
    try {
      final existing = await _client
          .from('messages')
          .select('id')
          .eq('chat_id', chatId)
          .limit(1);
      if ((existing as List<dynamic>).isNotEmpty) return false;

      await _client.from('messages').insert(<Map<String, dynamic>>[
        {
          'chat_id': chatId,
          'sender_id': null,
          'kind': 'system',
          'body': chatSystemNotice,
        },
        {
          'chat_id': chatId,
          'sender_id': _currentUserId(),
          'kind': 'product',
          'product_id': productId,
        },
      ]);
      await _touchChat(chatId, chatSystemNotice);
      return true;
    } on PostgrestException {
      // A concurrent session may have seeded first; the chat still works.
      return false;
    }
  }

  Future<void> _touchChat(String chatId, String preview) async {
    await _client.from('chats').update({
      'last_message_at': DateTime.now().toUtc().toIso8601String(),
      'last_message_preview': preview,
    }).eq('id', chatId);
  }

  ChatConversation _minimalConversation(Map<String, dynamic> chatRow) {
    final seller = _mapOrNull(chatRow['seller'] ?? chatRow['sellers']);
    final product = _mapOrNull(chatRow['product'] ?? chatRow['products']);
    return ChatConversation(
      chatId: chatRow['id']! as String,
      buyerId: chatRow['buyer_id'] as String?,
      sellerId: chatRow['seller_id']! as String,
      sellerUserId: seller?['user_id'] as String?,
      shopName: seller?['shop_name'] as String? ?? 'Seller',
      shopSlug: seller?['slug'] as String? ?? '',
      shopAvatarUrl: seller?['avatar_url'] as String?,
      productId: product?['id'] as String?,
      productTitle: product?['title'] as String?,
      productImageUrl: null,
      productPriceCents: (product?['price_cents'] as num?)?.toInt() ?? 0,
      productCurrency: product?['currency'] as String? ?? 'EUR',
      lastMessageAt: null,
      lastMessagePreview: null,
      unreadCount: 0,
    );
  }

  String _currentUserId() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw const AppException(AppFailureCode.notAuthenticated);
    }
    return uid;
  }
}

Map<String, dynamic>? _mapOrNull(Object? value) =>
    value is Map<String, dynamic> ? value : null;
