import 'package:flutter/material.dart';

import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/features/chat/domain/chat.dart';
import 'package:zerin_marketplace/features/chat/presentation/controllers/chat_controller.dart';
import 'package:zerin_marketplace/features/home/presentation/home_formatters.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

/// Inbox: all conversations of the current user with the last message
/// preview and an unread badge.
class ChatInboxScreen extends ConsumerWidget {
  const ChatInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inbox = ref.watch(chatInboxProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.chatInboxTitle)),
      body: switch (inbox) {
        AsyncData(:final value?) => value.isEmpty
            ? AppEmptyState(
                title: context.l10n.chatInboxEmptyTitle,
                message: context.l10n.chatInboxEmptyBody,
                icon: Icons.forum_outlined,
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(chatInboxProvider),
                child: ListView.separated(
                  itemCount: value.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 0),
                  itemBuilder: (context, index) =>
                      _ConversationTile(conversation: value[index]),
                ),
              ),
        AsyncError() => AppErrorState(
            title: context.l10n.stateErrorTitle,
            message: context.l10n.stateErrorMessage,
            retryLabel: context.l10n.actionRetry,
            onRetry: () => ref.invalidate(chatInboxProvider),
          ),
        _ => ListView.builder(
            itemCount: 6,
            itemBuilder: (context, index) => const ListTile(
              title: AppSkeletonBox(height: AppSpacing.md),
              subtitle: AppSkeletonBox(height: AppSpacing.sm),
            ),
          ),
      },
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  const _ConversationTile({required this.conversation});

  final ChatConversation conversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = conversation.lastMessagePreview ??
        context.l10n.chatNoMessagesYet;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: scheme.primaryContainer,
        backgroundImage: conversation.shopAvatarUrl == null
            ? null
            : NetworkImage(conversation.shopAvatarUrl!),
        child: conversation.shopAvatarUrl == null
            ? Icon(Icons.storefront_rounded, color: scheme.onPrimaryContainer)
            : null,
      ),
      title: Text(
        conversation.shopName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: conversation.unreadCount > 0
              ? scheme.onSurface
              : scheme.onSurfaceVariant,
          fontWeight: conversation.unreadCount > 0
              ? FontWeight.w600
              : FontWeight.w400,
        ),
      ),
      trailing: conversation.unreadCount > 0
          ? Badge(
              label: Text('${conversation.unreadCount}'),
              backgroundColor: scheme.primary,
              textColor: scheme.onPrimary,
            )
          : null,
      onTap: () => ChatConversationRoute(chatId: conversation.chatId)
          .push<void>(context),
    );
  }
}

// price formatting kept for the conversation header card.
// ignore: unused_element
String _formatPrice(BuildContext context, ChatConversation c) =>
    formatMarketplacePrice(
      Localizations.localeOf(context),
      c.productPriceCents,
      c.productCurrency,
    );
