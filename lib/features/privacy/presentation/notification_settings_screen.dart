import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/features/auth/presentation/controllers/auth_controller.dart';
import 'package:zerin_marketplace/features/privacy/domain/notification_preferences.dart';
import 'package:zerin_marketplace/features/privacy/domain/privacy_overview.dart';
import 'package:zerin_marketplace/features/privacy/presentation/controllers/privacy_controller.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

/// Per-channel notification opt-in, backed by
/// `profiles.notification_preferences`.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isSignedIn = ref.watch(authStateProvider).valueOrNull != null;
    final async = ref.watch(privacyControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationsTitle)),
      body: SafeArea(
        child: switch (async) {
          // Guarded like the privacy screen: without a session every write is
          // rejected, so editable switches would promise a save that fails.
          _ when !isSignedIn => AppEmptyState(
            title: l10n.notificationsSignedOutTitle,
            message: l10n.notificationsSignedOutBody,
            icon: Icons.lock_outline_rounded,
          ),
          AsyncError<PrivacyOverview>() => AppErrorState(
            title: l10n.stateErrorTitle,
            message: l10n.stateErrorMessage,
            retryLabel: l10n.actionRetry,
            onRetry: () => ref.invalidate(privacyControllerProvider),
          ),
          AsyncData<PrivacyOverview>(:final value) => _ChannelList(
            preferences: value.settings.notifications,
          ),
          _ => const _NotificationSkeleton(),
        },
      ),
    );
  }
}

class _ChannelList extends ConsumerWidget {
  const _ChannelList({required this.preferences});

  final NotificationPreferences preferences;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: <Widget>[
            Text(
              l10n.notificationsBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Card(
              child: Column(
                children: <Widget>[
                  for (final (index, channel)
                      in NotificationChannel.values.indexed) ...<Widget>[
                    if (index > 0) const Divider(height: 0),
                    _ChannelTile(
                      channel: channel,
                      enabled: preferences.isEnabled(channel),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChannelTile extends ConsumerWidget {
  const _ChannelTile({required this.channel, required this.enabled});

  final NotificationChannel channel;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final (title, body) = _copy(l10n, channel);

    return SwitchListTile.adaptive(
      title: Text(title),
      subtitle: Text(body),
      value: enabled,
      onChanged: (next) => _toggle(context, ref, next: next),
    );
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref, {
    required bool next,
  }) async {
    final l10n = context.l10n;
    try {
      await ref
          .read(privacyControllerProvider.notifier)
          .setNotificationChannel(channel, enabled: next);
    } catch (_) {
      // The controller already rolled the switch back; all that is left is to
      // say so, because a switch that silently snaps back looks like a bug.
      if (context.mounted) {
        AppSnackBar.show(
          context,
          message: l10n.notificationsSaveFailed,
          variant: AppSnackBarVariant.error,
        );
      }
    }
  }

  static (String, String) _copy(
    AppLocalizations l10n,
    NotificationChannel channel,
  ) => switch (channel) {
    NotificationChannel.orders => (
      l10n.notificationsOrders,
      l10n.notificationsOrdersBody,
    ),
    NotificationChannel.chat => (
      l10n.notificationsChat,
      l10n.notificationsChatBody,
    ),
    NotificationChannel.offers => (
      l10n.notificationsOffers,
      l10n.notificationsOffersBody,
    ),
    NotificationChannel.priceDrops => (
      l10n.notificationsPriceDrops,
      l10n.notificationsPriceDropsBody,
    ),
    NotificationChannel.system => (
      l10n.notificationsSystem,
      l10n.notificationsSystemBody,
    ),
  };
}

class _NotificationSkeleton extends StatelessWidget {
  const _NotificationSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: <Widget>[
        for (var index = 0;
            index < NotificationChannel.values.length;
            index++) ...<Widget>[
          const AppSkeletonBox(height: AppSizes.controlLarge),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}
