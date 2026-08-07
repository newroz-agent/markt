import 'package:flutter/material.dart';

import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/app_button.dart';

/// Empty-content treatment shared by lists and detail views.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.iconSemanticLabel,
    this.actionLabel,
    this.onAction,
    this.action,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    super.key,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? iconSemanticLabel;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _AppStateLayout(
      title: title,
      message: message,
      padding: padding,
      visual: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: SizedBox.square(
          dimension: AppSizes.stateIllustration,
          child: Icon(
            icon,
            size: AppSizes.iconState,
            color: scheme.onPrimaryContainer,
            semanticLabel: iconSemanticLabel,
          ),
        ),
      ),
      action:
          action ??
          (actionLabel != null && onAction != null
              ? AppButton.secondary(label: actionLabel!, onPressed: onAction)
              : null),
    );
  }
}

/// Error treatment with an optional localized retry action.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    required this.title,
    this.message,
    this.icon = Icons.error_outline_rounded,
    this.iconSemanticLabel,
    this.retryLabel,
    this.onRetry,
    this.action,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    super.key,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? iconSemanticLabel;
  final String? retryLabel;
  final VoidCallback? onRetry;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _AppStateLayout(
      title: title,
      message: message,
      padding: padding,
      visual: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          shape: BoxShape.circle,
        ),
        child: SizedBox.square(
          dimension: AppSizes.stateIllustration,
          child: Icon(
            icon,
            size: AppSizes.iconState,
            color: scheme.onErrorContainer,
            semanticLabel: iconSemanticLabel,
          ),
        ),
      ),
      action:
          action ??
          (retryLabel != null && onRetry != null
              ? AppButton.secondary(label: retryLabel!, onPressed: onRetry)
              : null),
    );
  }
}

class _AppStateLayout extends StatelessWidget {
  const _AppStateLayout({
    required this.title,
    required this.message,
    required this.visual,
    required this.action,
    required this.padding,
  });

  final String title;
  final String? message;
  final Widget visual;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: padding,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.dialogMaxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              visual,
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              if (message != null) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (action != null) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

typedef EmptyState = AppEmptyState;
typedef ErrorState = AppErrorState;
