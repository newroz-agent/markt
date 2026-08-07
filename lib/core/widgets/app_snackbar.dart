import 'package:flutter/material.dart';

import 'package:zerin_marketplace/core/theme/theme.dart';

enum AppSnackBarVariant { neutral, success, warning, error, info }

/// Theme-aware snackbar presenter for status feedback.
abstract final class AppSnackBar {
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show(
    BuildContext context, {
    required String message,
    AppSnackBarVariant variant = AppSnackBarVariant.neutral,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = AppDurations.snackBar,
    bool replaceCurrent = true,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    final messenger = ScaffoldMessenger.of(context);
    final (background, foreground, icon) = switch (variant) {
      AppSnackBarVariant.neutral => (
        scheme.inverseSurface,
        scheme.onInverseSurface,
        Icons.info_outline_rounded,
      ),
      AppSnackBarVariant.success => (
        semantic.success,
        semantic.onSuccess,
        Icons.check_circle_outline_rounded,
      ),
      AppSnackBarVariant.warning => (
        semantic.warning,
        semantic.onWarning,
        Icons.warning_amber_rounded,
      ),
      AppSnackBarVariant.error => (
        scheme.error,
        scheme.onError,
        Icons.error_outline_rounded,
      ),
      AppSnackBarVariant.info => (
        semantic.info,
        semantic.onInfo,
        Icons.info_outline_rounded,
      ),
    };
    if (replaceCurrent) messenger.hideCurrentSnackBar();

    return messenger.showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: background,
        content: Semantics(
          liveRegion: true,
          child: Row(
            children: <Widget>[
              Icon(icon, color: foreground, size: AppSizes.iconMedium),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: foreground),
                ),
              ),
            ],
          ),
        ),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: foreground,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }
}
