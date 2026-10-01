import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zerin_marketplace/app/router/app_router.dart';
import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/features/auth/presentation/controllers/auth_controller.dart';
import 'package:zerin_marketplace/features/chat/domain/chat.dart';
import 'package:zerin_marketplace/features/chat/presentation/chat_identity_label.dart';
import 'package:zerin_marketplace/features/chat/presentation/controllers/chat_controller.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

/// Inbox: all conversations of the current user with the last message
/// preview and an unread badge.
class ChatInboxScreen extends ConsumerWidget {
  const ChatInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authStateProvider);
    if (ref.watch(authRepositoryProvider).currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.chatInboxTitle)),
        body: AppEmptyState(
          title: context.l10n.authRequiredTitle,
          message: context.l10n.authRequiredMessage,
        ),
      );
    }
    final inbox = ref.watch(chatInboxProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.chatInboxTitle)),
      body: switch (inbox) {
        AsyncData(:final value) =>
          value.isEmpty
              ? AppEmptyState(
                  title: context.l10n.chatInboxEmptyTitle,
                  message: context.l10n.chatInboxEmptyBody,
                  icon: Icons.forum_outlined,
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(chatInboxProvider);
                    try {
                      await ref.read(chatInboxProvider.future);
                    } catch (_) {
                      // The provider renders the retry state.
                    }
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
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

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation});

  final ChatConversation conversation;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final avatarUrl = conversation.counterpartAvatarUrl;
    final title = chatCounterpartName(context, conversation);
    final identityLabel = chatOwnedIdentityLabel(context, conversation);
    final preview =
        conversation.lastMessagePreview ?? context.l10n.chatNoMessagesYet;
    final previewStyle = TextStyle(
      color: conversation.unreadCount > 0
          ? scheme.onSurface
          : scheme.onSurfaceVariant,
      fontWeight: conversation.unreadCount > 0
          ? FontWeight.w600
          : FontWeight.w400,
    );
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: scheme.primaryContainer,
        backgroundImage: avatarUrl == null ? null : NetworkImage(avatarUrl),
        child: avatarUrl == null
            ? Icon(
                conversation.isSellerViewer ||
                        conversation.sellerKind != 'business'
                    ? Icons.person_outline
                    : Icons.storefront_rounded,
                color: scheme.onPrimaryContainer,
              )
            : null,
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      isThreeLine: identityLabel != null,
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (identityLabel != null)
            Text(
              identityLabel,
              key: ValueKey('chat-identity-${conversation.chatId}'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          Text(
            preview,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: previewStyle,
          ),
        ],
      ),
      trailing: conversation.unreadCount > 0
          ? Badge(
              label: Text('${conversation.unreadCount}'),
              backgroundColor: scheme.primary,
              textColor: scheme.onPrimary,
            )
          : null,
      onTap: () => ChatConversationRoute(
        chatId: conversation.chatId,
      ).push<void>(context),
    );
  }
}
