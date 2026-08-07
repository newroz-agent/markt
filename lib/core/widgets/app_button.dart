import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:zerin_marketplace/core/theme/theme.dart';

enum AppButtonVariant { primary, secondary, ghost, destructive }

enum AppButtonSize { small, medium, large }

/// Tokenized button with four visual variants and a built-in loading state.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.leading,
    this.loading = false,
    this.expand = false,
    this.enableHaptics = true,
    this.semanticLabel,
    this.style,
    super.key,
  });

  const AppButton.primary({
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.medium,
    this.leading,
    this.loading = false,
    this.expand = false,
    this.enableHaptics = true,
    this.semanticLabel,
    this.style,
    super.key,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.medium,
    this.leading,
    this.loading = false,
    this.expand = false,
    this.enableHaptics = true,
    this.semanticLabel,
    this.style,
    super.key,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.ghost({
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.medium,
    this.leading,
    this.loading = false,
    this.expand = false,
    this.enableHaptics = true,
    this.semanticLabel,
    this.style,
    super.key,
  }) : variant = AppButtonVariant.ghost;

  const AppButton.destructive({
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.medium,
    this.leading,
    this.loading = false,
    this.expand = false,
    this.enableHaptics = true,
    this.semanticLabel,
    this.style,
    super.key,
  }) : variant = AppButtonVariant.destructive;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final Widget? leading;
  final bool loading;
  final bool expand;
  final bool enableHaptics;
  final String? semanticLabel;
  final ButtonStyle? style;

  double get _height => switch (size) {
    AppButtonSize.small => AppSizes.controlSmall,
    AppButtonSize.medium => AppSizes.controlMedium,
    AppButtonSize.large => AppSizes.controlLarge,
  };

  EdgeInsetsGeometry get _padding => switch (size) {
    AppButtonSize.small => const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
    ),
    AppButtonSize.medium => AppSpacing.button,
    AppButtonSize.large => const EdgeInsets.symmetric(
      horizontal: AppSpacing.xl,
    ),
  };

  VoidCallback? _effectiveCallback() {
    if (loading || onPressed == null) return null;
    return () {
      if (enableHaptics) HapticFeedback.lightImpact();
      onPressed!();
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final callback = _effectiveCallback();
    final customStyle = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        Size(AppSizes.minimumTouchTarget, _height),
      ),
      padding: WidgetStatePropertyAll(_padding),
    ).merge(style);
    final indicator = SizedBox.square(
      dimension: AppSizes.iconMedium,
      child: CircularProgressIndicator(
        strokeWidth: AppStrokes.progress,
        color:
            variant == AppButtonVariant.secondary ||
                variant == AppButtonVariant.ghost
            ? scheme.primary
            : variant == AppButtonVariant.destructive
            ? scheme.onError
            : scheme.onPrimary,
      ),
    );
    final icon = loading ? indicator : leading;
    final button = switch (variant) {
      AppButtonVariant.primary => _elevated(callback, icon, customStyle),
      AppButtonVariant.secondary => _outlined(callback, icon, customStyle),
      AppButtonVariant.ghost => _text(callback, icon, customStyle),
      AppButtonVariant.destructive => _elevated(
        callback,
        icon,
        ElevatedButton.styleFrom(
          backgroundColor: scheme.error,
          foregroundColor: scheme.onError,
          disabledBackgroundColor: scheme.error.withValues(
            alpha: AppOpacity.destructiveDisabledSurface,
          ),
          disabledForegroundColor: scheme.error.withValues(
            alpha: AppOpacity.half,
          ),
        ).merge(customStyle),
      ),
    };

    return Semantics(
      button: true,
      enabled: callback != null,
      label: semanticLabel ?? label,
      child: SizedBox(width: expand ? double.infinity : null, child: button),
    );
  }

  Widget _elevated(VoidCallback? callback, Widget? icon, ButtonStyle style) {
    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: callback,
        style: style,
        icon: icon,
        label: Text(label),
      );
    }
    return ElevatedButton(
      onPressed: callback,
      style: style,
      child: Text(label),
    );
  }

  Widget _outlined(VoidCallback? callback, Widget? icon, ButtonStyle style) {
    if (icon != null) {
      return OutlinedButton.icon(
        onPressed: callback,
        style: style,
        icon: icon,
        label: Text(label),
      );
    }
    return OutlinedButton(
      onPressed: callback,
      style: style,
      child: Text(label),
    );
  }

  Widget _text(VoidCallback? callback, Widget? icon, ButtonStyle style) {
    if (icon != null) {
      return TextButton.icon(
        onPressed: callback,
        style: style,
        icon: icon,
        label: Text(label),
      );
    }
    return TextButton(onPressed: callback, style: style, child: Text(label));
  }
}
