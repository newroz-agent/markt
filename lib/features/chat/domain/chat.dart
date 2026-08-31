import 'package:flutter/foundation.dart';

enum MessageKind { text, image, product, system }

@immutable
class ChatConversation {
  const ChatConversation({
    required this.chatId,
    required this.buyerId,
    required this.sellerId,
    required this.sellerUserId,
    required this.shopName,
    required this.shopSlug,
    required this.shopAvatarUrl,
    required this.productId,
    required this.productTitle,
    required this.productImageUrl,
    required this.productPriceCents,
    required this.productCurrency,
    required this.lastMessageAt,
    required this.lastMessagePreview,
    required this.unreadCount,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final product = _mapOrNull(json['product'] ?? json['products']);
    return ChatConversation(
      chatId: json['id']! as String,
      buyerId: json['buyer_id'] as String?,
      sellerId: json['seller_id']! as String,
      sellerUserId: json['seller_user_id'] as String?,
      shopName: json['shop_name'] as String? ?? 'Seller',
      shopSlug: json['shop_slug'] as String? ?? '',
      shopAvatarUrl: json['shop_avatar_url'] as String?,
      productId: product != null ? product['id'] as String? : null,
      productTitle: product != null ? product['title'] as String? : null,
      productImageUrl: product != null
          ? (product['image_url'] as String?)
          : null,
      productPriceCents:
          (product?['price_cents'] as num?)?.toInt() ?? 0,
      productCurrency: product?['currency'] as String? ?? 'EUR',
      lastMessageAt: DateTime.tryParse(json['last_message_at'] as String? ?? ''),
      lastMessagePreview: json['last_message_preview'] as String?,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    );
  }

  final String chatId;
  final String? buyerId;
  final String sellerId;
  final String? sellerUserId;
  final String shopName;
  final String shopSlug;
  final String? shopAvatarUrl;
  final String? productId;
  final String? productTitle;
  final String? productImageUrl;
  final int productPriceCents;
  final String productCurrency;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;
  final int unreadCount;
}

@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.kind,
    required this.body,
    required this.productId,
    required this.productTitle,
    required this.productPriceCents,
    required this.productCurrency,
    required this.readAt,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final product = _mapOrNull(json['product'] ?? json['products']);
    return ChatMessage(
      id: json['id']! as String,
      chatId: json['chat_id']! as String,
      senderId: json['sender_id'] as String?,
      kind: _kindFromName(json['kind'] as String? ?? 'text'),
      body: json['body'] as String?,
      productId: json['product_id'] as String? ?? product?['id'] as String?,
      productTitle: product?['title'] as String?,
      productPriceCents: (product?['price_cents'] as num?)?.toInt() ?? 0,
      productCurrency: product?['currency'] as String? ?? 'EUR',
      readAt: DateTime.tryParse(json['read_at'] as String? ?? ''),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final String id;
  final String chatId;
  final String? senderId;
  final MessageKind kind;
  final String? body;
  final String? productId;
  final String? productTitle;
  final int productPriceCents;
  final String productCurrency;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isMine => senderId != null;

  static MessageKind _kindFromName(String name) => switch (name) {
        'image' => MessageKind.image,
        'product' => MessageKind.product,
        'system' => MessageKind.system,
        _ => MessageKind.text,
      };
}

Map<String, dynamic>? _mapOrNull(Object? value) =>
    value is Map<String, dynamic> ? value : null;
