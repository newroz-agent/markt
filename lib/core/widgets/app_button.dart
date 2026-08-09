import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:zerin_marketplace/core/theme/theme.dart';

/// Button intents.
///
/// [accent] is the gold call to action. Gold is an accent, not a surface
/// colour: a screen gets **at most one** [accent] button, and in debug builds
/// mounting a second one trips an assertion. Everything else that needs
/// emphasis uses [primary].
enum AppButtonVariant { primary, accent, secondary, ghost, destructive }

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

  /// The gold call to action. At most one per screen — see [AppButtonVariant].
  const AppButton.accent({
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
  }) : variant = AppButtonVariant.accent;

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

  /// The label, carrying [semanticLabel] itself.
  ///
  /// Deliberately not wrapped in an outer [Semantics]: that would add a second
  /// node next to the one the button already publishes, and assistive tech
  /// would announce the control twice — once with the override label and no
  /// tap action, once with the visible label.
  Widget get _label => Text(label, semanticsLabel: semanticLabel);

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
    final semantic = context.semanticColors;
    final indicator = SizedBox.square(
      dimension: AppSizes.iconMedium,
      child: CircularProgressIndicator(
        strokeWidth: AppStrokes.progress,
        color: switch (variant) {
          AppButtonVariant.secondary ||
          AppButtonVariant.ghost => scheme.primary,
          AppButtonVariant.destructive => scheme.onError,
          AppButtonVariant.accent => semantic.onAccent,
          AppButtonVariant.primary => scheme.onPrimary,
        },
      ),
    );
    final icon = loading ? indicator : leading;
    final button = switch (variant) {
      AppButtonVariant.primary => _elevated(callback, icon, customStyle),
      AppButtonVariant.accent => _AccentButton(
        enabled: callback != null,
        gradient: semantic.accentGradient,
        disabledSurface: semantic.accentDisabled,
        child: _elevated(
          callback,
          icon,
          ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: semantic.onAccent,
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor: semantic.onAccent.withValues(
              alpha: AppOpacity.half,
            ),
            shadowColor: Colors.transparent,
            elevation: AppElevation.none,
          ).merge(customStyle),
        ),
      ),
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

    return SizedBox(width: expand ? double.infinity : null, child: button);
  }

  Widget _elevated(VoidCallback? callback, Widget? icon, ButtonStyle style) {
    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: callback,
        style: style,
        icon: icon,
        label: _label,
      );
    }
    return ElevatedButton(onPressed: callback, style: style, child: _label);
  }

  Widget _outlined(VoidCallback? callback, Widget? icon, ButtonStyle style) {
    if (icon != null) {
      return OutlinedButton.icon(
        onPressed: callback,
        style: style,
        icon: icon,
        label: _label,
      );
    }
    return OutlinedButton(onPressed: callback, style: style, child: _label);
  }

  Widget _text(VoidCallback? callback, Widget? icon, ButtonStyle style) {
    if (icon != null) {
      return TextButton.icon(
        onPressed: callback,
        style: style,
        icon: icon,
        label: _label,
      );
    }
    return TextButton(onPressed: callback, style: style, child: _label);
  }
}

/// Paints the gold gradient behind an accent button and, in debug builds,
/// enforces the one-gold-CTA-per-screen rule.
class _AccentButton extends StatefulWidget {
  const _AccentButton({
    required this.enabled,
    required this.gradient,
    required this.disabledSurface,
    required this.child,
  });

  final bool enabled;
  final Gradient gradient;
  final Color disabledSurface;
  final Widget child;

  /// Accent buttons currently mounted, per enclosing route. Debug-only.
  ///
  /// Keyed by route rather than counted globally: during a push transition the
  /// outgoing and incoming screens are both mounted, and a global counter would
  /// flag every navigation between two screens that each legitimately own one
  /// gold call to action.
  static final Map<Object, int> _debugMountedPerScope = <Object, int>{};

  /// Bucket for accent buttons outside any [ModalRoute].
  static final Object _debugRootScope = Object();

  @override
  State<_AccentButton> createState() => _AccentButtonState();
}

class _AccentButtonState extends State<_AccentButton> {
  Object? _scope;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    assert(() {
      final scope = ModalRoute.of(context) ?? _AccentButton._debugRootScope;
      if (identical(scope, _scope)) return true;
      _releaseScope();
      _scope = scope;
      final count = (_AccentButton._debugMountedPerScope[scope] ?? 0) + 1;
      _AccentButton._debugMountedPerScope[scope] = count;
      if (count > 1) {
        // Reported rather than thrown: throwing here would abort the mount
        // half-way and strand this counter, so every later gold button on the
        // route would be flagged too.
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: FlutterError.fromParts(<DiagnosticsNode>[
              ErrorSummary(
                'This screen mounts $count AppButtonVariant.accent buttons.',
              ),
              ErrorDescription(
                'Gold is an accent colour: a screen gets at most one gold '
                'call to action so it stays the single clearest next step.',
              ),
              ErrorHint(
                'Demote the others to AppButtonVariant.primary, or move them '
                'to a route of their own.',
              ),
            ]),
            library: 'zerin marketplace',
            context: ErrorDescription('while mounting a gold call to action'),
          ),
        );
      }
      return true;
    }());
  }

  /// Gives this button's slot back to its route, if it holds one.
  void _releaseScope() {
    final scope = _scope;
    if (scope == null) return;
    final remaining = (_AccentButton._debugMountedPerScope[scope] ?? 1) - 1;
    if (remaining > 0) {
      _AccentButton._debugMountedPerScope[scope] = remaining;
    } else {
      // Dropped, not left at zero: the map must not retain dead routes.
      _AccentButton._debugMountedPerScope.remove(scope);
    }
    _scope = null;
  }

  @override
  void dispose() {
    assert(() {
      _releaseScope();
      return true;
    }());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: widget.enabled ? widget.gradient : null,
        color: widget.enabled ? null : widget.disabledSurface,
        borderRadius: AppRadius.medium,
      ),
      child: widget.child,
    );
  }
}
