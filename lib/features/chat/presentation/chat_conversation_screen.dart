import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/features/chat/domain/chat.dart';
import 'package:zerin_marketplace/features/chat/presentation/controllers/chat_controller.dart';
import 'package:zerin_marketplace/features/home/presentation/home_formatters.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

/// One conversation: product card on top (kind: product), system notices
/// centered, text bubbles aligned by sender. Messages arrive via Supabase
/// Realtime (no polling).
class ChatConversationScreen extends ConsumerStatefulWidget {
  const ChatConversationScreen({required this.chatId, super.key});

  final String chatId;

  @override
  ConsumerState<ChatConversationScreen> createState() =>
      _ChatConversationScreenState();
}

class _ChatConversationScreenState extends ConsumerState<ChatConversationScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    await ref
        .read(conversationProvider(chatId: widget.chatId).notifier)
        .send(text);
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(conversationProvider(chatId: widget.chatId));
    _scrollToBottom();

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.chatTitle)),
      body: switch (messages) {
        AsyncData(:final value?) => Column(
            children: <Widget>[
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: value.length,
                  itemBuilder: (context, index) =>
                      _MessageBubble(message: value[index]),
                ),
              ),
              SafeArea(child: _Composer(controller: _input, onSend: _send)),
            ],
          ),
        AsyncError() => AppErrorState(
            title: context.l10n.stateErrorTitle,
            message: context.l10n.stateErrorMessage,
            retryLabel: context.l10n.actionRetry,
            onRetry: () =>
                ref.invalidate(conversationProvider(chatId: widget.chatId)),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (message.kind) {
      MessageKind.system => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: scheme.surfaceVariant,
                borderRadius: AppRadius.medium,
              ),
              child: Text(
                message.body ?? '',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
        ),
      MessageKind.product => Align(
          alignment: Alignment.centerLeft,
          child: _ProductCard(
            title: message.productTitle ?? context.l10n.chatProductCard,
            priceCents: message.productPriceCents,
            currency: message.productCurrency,
          ),
        ),
      _ => Align(
          alignment: message.isMine
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            constraints: const BoxConstraints(
              maxWidth: AppSizes.contentMaxWidth * 0.75,
            ),
            decoration: BoxDecoration(
              color: message.isMine ? scheme.primary : scheme.surfaceVariant,
              borderRadius: AppRadius.medium,
            ),
            child: Text(
              message.body ?? '',
              style: TextStyle(
                color: message.isMine ? scheme.onPrimary : scheme.onSurface,
              ),
            ),
          ),
        ),
    };
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.title,
    required this.priceCents,
    required this.currency,
  });

  final String? title;
  final int priceCents;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final price = formatMarketplacePrice(
      Localizations.localeOf(context),
      priceCents,
      currency,
    );
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      padding: AppSpacing.card,
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: scheme.surfaceRaised,
        borderRadius: AppRadius.medium,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.inventory_2_outlined, color: scheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  price,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: context.l10n.chatInputHint,
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send_rounded),
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}
