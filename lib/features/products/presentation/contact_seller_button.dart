import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zerin_marketplace/app/router/app_router.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/features/auth/presentation/controllers/auth_controller.dart';
import 'package:zerin_marketplace/features/chat/presentation/controllers/chat_controller.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

/// Opens a server-seeded conversation only after an explicit tap.
class ContactSellerButton extends ConsumerStatefulWidget {
  const ContactSellerButton({
    required this.sellerId,
    required this.productId,
    super.key,
  });

  final String sellerId;
  final String productId;

  @override
  ConsumerState<ContactSellerButton> createState() =>
      _ContactSellerButtonState();
}

class _ContactSellerButtonState extends ConsumerState<ContactSellerButton> {
  bool _opening = false;

  Future<void> _open() async {
    if (_opening) return;
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      await AuthRoute(
        redirectTo: ProductDetailRoute(productId: widget.productId).location,
      ).push<void>(context);
      return;
    }
    setState(() => _opening = true);
    try {
      final conversation = await ref
          .read(chatRepositoryProvider)
          .openChatWithProduct(
            sellerId: widget.sellerId,
            productId: widget.productId,
          );
      if (!mounted ||
          ref.read(authRepositoryProvider).currentUser?.id != user.id) {
        return;
      }
      ref.invalidate(chatInboxProvider);
      await ChatConversationRoute(
        chatId: conversation.chatId,
      ).push<void>(context);
    } catch (_) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: context.l10n.stateErrorMessage,
          variant: AppSnackBarVariant.error,
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: context.l10n.productContactSeller,
      leading: const Icon(Icons.chat_bubble_outline_rounded),
      loading: _opening,
      expand: true,
      onPressed: _opening ? null : _open,
    );
  }
}
