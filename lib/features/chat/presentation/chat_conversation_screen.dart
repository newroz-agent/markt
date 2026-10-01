import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zerin_marketplace/app/router/app_router.dart';
import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/features/auth/presentation/controllers/auth_controller.dart';
import 'package:zerin_marketplace/features/chat/domain/chat.dart';
import 'package:zerin_marketplace/features/chat/presentation/chat_identity_label.dart';
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

class _ChatConversationScreenState extends ConsumerState<ChatConversationScreen>
    with WidgetsBindingObserver, RouteAware {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  ModalRoute<dynamic>? _route;
  bool _sending = false;
  bool _loadingOlder = false;

  bool get _isVisible =>
      mounted &&
      (_route?.isCurrent ?? false) &&
      (WidgetsBinding.instance.lifecycleState == null ||
          WidgetsBinding.instance.lifecycleState ==
              AppLifecycleState.resumed) &&
      ref.read(authRepositoryProvider).currentUser != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (_route != route) {
      chatRouteObserver.unsubscribe(this);
      _route = route;
      if (route != null) chatRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPush() => _scheduleMarkRead();

  @override
  void didPopNext() => _scheduleMarkRead();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _scheduleMarkRead();
  }

  void _scheduleMarkRead() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isVisible) unawaited(_markRead());
    });
  }

  Future<void> _markRead() async {
    if (!_isVisible) return;
    try {
      await ref
          .read(conversationProvider(chatId: widget.chatId).notifier)
          .markRead();
    } catch (_) {
      // Read receipts are retried on the next visible update or resume.
    }
  }

  @override
  void dispose() {
    chatRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.jumpTo(0);
      }
    });
  }

  Future<void> _send() async {
    if (_sending || !_isVisible) return;
    final draft = _input.text;
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(conversationProvider(chatId: widget.chatId).notifier)
          .send(text);
      if (!mounted) return;
      if (_input.text == draft) _input.clear();
      _scrollToBottom();
    } catch (_) {
      _showError();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _loadOlder() async {
    if (_loadingOlder) return;
    setState(() => _loadingOlder = true);
    try {
      await ref
          .read(conversationProvider(chatId: widget.chatId).notifier)
          .loadOlder();
    } catch (_) {
      _showError();
    } finally {
      if (mounted) setState(() => _loadingOlder = false);
    }
  }

  void _showError() {
    if (!mounted) return;
    AppSnackBar.show(
      context,
      message: context.l10n.stateErrorMessage,
      variant: AppSnackBarVariant.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authStateProvider);
    final user = ref.watch(authRepositoryProvider).currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.chatTitle)),
        body: AppEmptyState(
          title: context.l10n.authRequiredTitle,
          message: context.l10n.authRequiredMessage,
        ),
      );
    }
    final messages = ref.watch(conversationProvider(chatId: widget.chatId));
    final details = ref.watch(chatDetailsProvider(chatId: widget.chatId));
    ref.listen(conversationProvider(chatId: widget.chatId), (previous, next) {
      final before = previous?.asData?.value;
      final after = next.asData?.value;
      if (after == null) return;
      final latestChanged =
          before == null || (before.lastOrNull?.id != after.lastOrNull?.id);
      if (latestChanged) {
        _scheduleMarkRead();
        if (!_scroll.hasClients || _scroll.position.pixels < 80) {
          _scrollToBottom();
        } else {
          final pixels = _scroll.position.pixels;
          final extent = _scroll.position.maxScrollExtent;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || !_scroll.hasClients) return;
            _scroll.jumpTo(
              (pixels + _scroll.position.maxScrollExtent - extent).clamp(
                0.0,
                _scroll.position.maxScrollExtent,
              ),
            );
          });
        }
      }
    });
    final product = details.asData?.value;
    final headerIdentity = product == null
        ? null
        : chatOwnedIdentityLabel(context, product);
    final headerTitle = product == null
        ? context.l10n.chatTitle
        : chatCounterpartName(context, product);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(headerTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (headerIdentity != null)
              Text(
                headerIdentity,
                key: const ValueKey('chat-conversation-identity'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
          ],
        ),
      ),
      body: switch (messages) {
        AsyncData(:final value) => Column(
          children: <Widget>[
            if (product?.productId != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: _ProductCard(
                  title: product!.productTitle ?? context.l10n.chatProductCard,
                  priceCents: product.productPriceCents,
                  currency: product.productCurrency,
                ),
              ),
            if (details.hasError)
              TextButton.icon(
                onPressed: () =>
                    ref.invalidate(chatDetailsProvider(chatId: widget.chatId)),
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.actionRetry),
              ),
            Expanded(
              child: value.isEmpty
                  ? Center(child: Text(context.l10n.chatNoMessagesYet))
                  : ListView.builder(
                      // Reverse layout anchors new history above the viewport.
                      reverse: true,
                      controller: _scroll,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: value.length + 1,
                      itemBuilder: (context, index) {
                        if (index == value.length) {
                          return ref
                                  .read(
                                    conversationProvider(
                                      chatId: widget.chatId,
                                    ).notifier,
                                  )
                                  .hasOlder
                              ? Center(
                                  child: TextButton.icon(
                                    onPressed: _loadingOlder
                                        ? null
                                        : _loadOlder,
                                    icon: _loadingOlder
                                        ? const SizedBox.square(
                                            dimension: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.expand_less),
                                    label: Text(context.l10n.chatLoadEarlier),
                                  ),
                                )
                              : const SizedBox.shrink();
                        }
                        final message = value[value.length - index - 1];
                        return _MessageBubble(
                          key: ValueKey(message.id),
                          message: message,
                          isMine: message.senderId == user.id,
                        );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: _Composer(
                controller: _input,
                onSend: _send,
                sending: _sending,
              ),
            ),
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
  const _MessageBubble({
    required this.message,
    required this.isMine,
    super.key,
  });

  final ChatMessage message;
  final bool isMine;

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
              color: scheme.surfaceContainerHighest,
              borderRadius: AppRadius.medium,
            ),
            child: Text(
              message.body ?? '',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
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
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
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
            color: isMine ? scheme.primary : scheme.surfaceContainerHighest,
            borderRadius: AppRadius.medium,
          ),
          child: Text(
            message.body ?? '',
            style: TextStyle(
              color: isMine ? scheme.onPrimary : scheme.onSurface,
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
        color: context.semanticColors.surfaceRaised,
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
  const _Composer({
    required this.controller,
    required this.onSend,
    required this.sending,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool sending;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: sending ? null : (_) => onSend(),
              decoration: InputDecoration(
                hintText: context.l10n.chatInputHint,
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) => IconButton(
              tooltip: context.l10n.chatSend,
              icon: sending
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              onPressed: sending || value.text.trim().isEmpty ? null : onSend,
            ),
          ),
        ],
      ),
    );
  }
}
