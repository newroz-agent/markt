import 'package:zerin_marketplace/core/errors/app_exception.dart';
import 'package:zerin_marketplace/features/chat/domain/chat.dart';
import 'package:zerin_marketplace/features/chat/domain/chat_repository.dart';

class UnconfiguredChatRepository implements ChatRepository {
  const UnconfiguredChatRepository();
  Never _unconfigured() =>
      throw const AppException(AppFailureCode.backendNotConfigured);
  @override
  Future<List<ChatConversation>> fetchConversations() async => _unconfigured();
  @override
  Future<ChatConversation> fetchConversation(String chatId) async =>
      _unconfigured();
  @override
  Future<List<ChatMessage>> fetchMessages(
    String chatId, {
    ChatMessage? before,
  }) async => _unconfigured();
  @override
  Future<ChatConversation> openChatWithProduct({
    required String sellerId,
    required String productId,
  }) async => _unconfigured();
  @override
  Future<ChatConversation> openChatWithSeller(String sellerId) async =>
      _unconfigured();
  @override
  Future<ChatMessage> sendTextMessage({
    required String chatId,
    required String body,
  }) async => _unconfigured();
  @override
  Stream<List<ChatMessage>> watchMessages(String chatId) =>
      Stream.error(const AppException(AppFailureCode.backendNotConfigured));
  @override
  Stream<List<ChatConversation>> watchConversations() =>
      Stream.error(const AppException(AppFailureCode.backendNotConfigured));
  @override
  Future<int> markChatRead(String chatId) async => _unconfigured();
}
