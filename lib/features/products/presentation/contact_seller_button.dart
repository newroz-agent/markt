import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/app/router/app_router.dart';
import 'package:zerin_marketplace/features/chat/presentation/controllers/chat_controller.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

/// "Verkäufer kontaktieren" — opens (or creates) the chat for this product
/// and navigates to the conversation. The chat is seeded with the
/// anti-circumvention system message and a product card.
class ContactSellerButton extends ConsumerWidget {
  const ContactSellerButton({
    required this.sellerId,
    required this.productId,
    super.key,
  });

  final String sellerId;
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = ref.watch(
      openChatProvider(sellerId: sellerId, productId: productId),
    );
    return AppButton(
      label: context.l10n.productContactSeller,
      icon: Icons.chat_bubble_outline_rounded,
      loading: open.isLoading,
      expand: true,
      onPressed: open.value == null
          ? null
          : () => ChatConversationRoute(chatId: open.value!.chatId)
              .push<void>(context),
    );
  }
}
