import 'package:flutter_test/flutter_test.dart';
import 'package:zerin_marketplace/core/errors/app_exception.dart';
import 'package:zerin_marketplace/features/chat/data/unconfigured_chat_repository.dart';
import 'package:zerin_marketplace/features/chat/domain/chat.dart';
import 'package:zerin_marketplace/features/chat/domain/chat_repository.dart';

void main() {
  for (final relation in ['product', 'products']) {
    test('conversation parses inbox fields and $relation relation', () {
      final chat = ChatConversation.fromJson({
        'id': 'chat',
        'buyer_id': 'buyer',
        'seller_id': 'seller',
        'seller_user_id': 'owner',
        'shop_name': 'Shop',
        'shop_slug': 'shop',
        'shop_avatar_url': 'shop.png',
        'buyer_name': 'Buyer',
        'buyer_avatar_url': 'buyer.png',
        'last_message_at': '2026-09-07T12:00:00Z',
        'last_message_preview': 'Hello',
        'unread_count': 3.0,
        relation: {
          'id': 'product',
          'title': 'Chair',
          'image_url': 'chair.png',
          'price_cents': 2500.0,
          'currency': 'USD',
        },
      });

      expect(chat.chatId, 'chat');
      expect(chat.buyerId, 'buyer');
      expect(chat.sellerId, 'seller');
      expect(chat.sellerUserId, 'owner');
      expect(chat.shopName, 'Shop');
      expect(chat.shopSlug, 'shop');
      expect(chat.shopAvatarUrl, 'shop.png');
      expect(chat.buyerName, 'Buyer');
      expect(chat.buyerAvatarUrl, 'buyer.png');
      expect(chat.lastMessageAt, DateTime.utc(2026, 9, 7, 12));
      expect(chat.lastMessagePreview, 'Hello');
      expect(chat.unreadCount, 3);
      expect(chat.productId, 'product');
      expect(chat.productTitle, 'Chair');
      expect(chat.productImageUrl, 'chair.png');
      expect(chat.productPriceCents, 2500);
      expect(chat.productCurrency, 'USD');
    });

    test('message parses $relation and read receipt', () {
      final message = ChatMessage.fromJson({
        'id': 'message',
        'chat_id': 'chat',
        'sender_id': 'buyer',
        'kind': 'product',
        'body': 'Chair',
        'created_at': '2026-09-07T14:00:00+02:00',
        'read_at': '2026-09-07T12:01:00Z',
        relation: {
          'id': 'product',
          'title': 'Chair',
          'price_cents': 2500.0,
          'currency': 'USD',
        },
      });
      expect(message.id, 'message');
      expect(message.chatId, 'chat');
      expect(message.senderId, 'buyer');
      expect(message.kind, MessageKind.product);
      expect(message.body, 'Chair');
      expect(message.productId, 'product');
      expect(message.productTitle, 'Chair');
      expect(message.productPriceCents, 2500);
      expect(message.productCurrency, 'USD');
      expect(message.createdAt, DateTime.utc(2026, 9, 7, 12));
      expect(message.readAt, DateTime.utc(2026, 9, 7, 12, 1));
    });
  }

  test('missing optional conversation data has safe defaults', () {
    final chat = ChatConversation.fromJson({
      'id': 'chat',
      'seller_id': 'seller',
      'last_message_at': 'invalid',
      'product': <Object>[],
    });
    expect(chat.shopName, 'Seller');
    expect(chat.shopSlug, '');
    expect(chat.buyerId, isNull);
    expect(chat.buyerName, isNull);
    expect(chat.sellerUserId, isNull);
    expect(chat.productId, isNull);
    expect(chat.productPriceCents, 0);
    expect(chat.productCurrency, 'EUR');
    expect(chat.lastMessageAt, isNull);
    expect(chat.unreadCount, 0);
  });

  for (final kind in ['text', 'image', 'product', 'system', 'future-kind']) {
    test('message kind $kind and absent optional fields', () {
      final message = ChatMessage.fromJson({
        'id': 'message',
        'chat_id': 'chat',
        'kind': kind,
        'created_at': 'invalid',
        'read_at': 'invalid',
      });
      expect(
        message.kind,
        kind == 'future-kind'
            ? MessageKind.text
            : MessageKind.values.byName(kind),
      );
      expect(message.senderId, isNull);
      expect(message.body, isNull);
      expect(message.productPriceCents, 0);
      expect(message.productCurrency, 'EUR');
      expect(message.readAt, isNull);
      expect(message.createdAt.millisecondsSinceEpoch, 0);
    });
  }

  test('explicit product id wins over relation id', () {
    final message = ChatMessage.fromJson({
      'id': 'message',
      'chat_id': 'chat',
      'product_id': 'explicit',
      'product': {'id': 'nested'},
    });
    expect(message.productId, 'explicit');
    expect(message.kind, MessageKind.text);
  });

  test('unconfigured implementation fails every interface operation', () async {
    const ChatRepository repository = UnconfiguredChatRepository();
    final error = isA<AppException>().having(
      (e) => e.code,
      'code',
      AppFailureCode.backendNotConfigured,
    );
    for (final call in <Future<Object?> Function()>[
      repository.fetchConversations,
      () => repository.fetchConversation('chat'),
      () => repository.fetchMessages('chat'),
      () => repository.openChatWithProduct(
        sellerId: 'seller',
        productId: 'product',
      ),
      () => repository.sendTextMessage(chatId: 'chat', body: 'Hello'),
      () => repository.markChatRead('chat'),
    ]) {
      await expectLater(call(), throwsA(error));
    }
    await expectLater(repository.watchConversations(), emitsError(error));
    await expectLater(repository.watchMessages('chat'), emitsError(error));
  });
}
