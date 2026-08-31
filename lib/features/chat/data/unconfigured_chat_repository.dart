import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:zerin_marketplace/core/errors/app_exception.dart';
import 'package:zerin_marketplace/features/chat/domain/chat.dart';

class UnconfiguredChatRepository {
  const UnconfiguredChatRepository();

  Never _unconfigured() =>
      throw const AppException(AppFailureCode.backendNotConfigured);

  Future<List<ChatConversation>> fetchConversations() => _unconfigured();

  Future<List<ChatMessage>> fetchMessages(String chatId) => _unconfigured();

  Future<ChatConversation> openChatWithProduct({
    required String sellerId,
    required String productId,
  }) =>
      _unconfigured();

  Future<ChatMessage> sendTextMessage({
    required String chatId,
    required String body,
  }) =>
      _unconfigured();

  Stream<ChatMessage> subscribeMessages(String chatId) =>
      Stream<ChatMessage>.error(const AppException(
        AppFailureCode.backendNotConfigured,
      ));

  Future<int> markChatRead(String chatId) => _unconfigured();
}
