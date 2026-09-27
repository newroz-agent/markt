import 'package:zerin_marketplace/features/chat/domain/chat.dart';

abstract interface class ChatRepository {
  Future<List<ChatConversation>> fetchConversations();
  Future<ChatConversation> fetchConversation(String chatId);
  Stream<List<ChatConversation>> watchConversations();
  Future<List<ChatMessage>> fetchMessages(String chatId, {ChatMessage? before});
  Stream<List<ChatMessage>> watchMessages(String chatId);
  Future<ChatConversation> openChatWithProduct({
    required String sellerId,
    required String productId,
  });
  Future<ChatConversation> openChatWithSeller(String sellerId);
  Future<ChatMessage> sendTextMessage({
    required String chatId,
    required String body,
  });
  Future<int> markChatRead(String chatId);
}
