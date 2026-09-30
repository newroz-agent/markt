import 'package:flutter/widgets.dart';
import 'package:zerin_marketplace/features/chat/domain/chat.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

String chatCounterpartName(
  BuildContext context,
  ChatConversation conversation,
) {
  final name = conversation.counterpartName.trim();
  return name.isEmpty ? context.l10n.chatTitle : name;
}

String? chatOwnedIdentityLabel(
  BuildContext context,
  ChatConversation conversation,
) {
  final name = conversation.ownedIdentityName?.trim();
  if (name == null || name.isEmpty) return null;
  return context.l10n.chatIdentityContext(name: name);
}
