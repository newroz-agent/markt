import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:zerin_marketplace/core/theme/theme.dart';

/// Adds subtle press feedback without taking control of its child's visuals.
class PressScale extends StatefulWidget {
  const PressScale({
    required this.child,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
    this.enabled = true,
    this.enableHaptics = true,
    this.scale = AppMotion.pressedScale,
    this.behavior = HitTestBehavior.opaque,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticLabel;
  final bool enabled;
  final bool enableHaptics;
  final double scale;
  final HitTestBehavior behavior;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _isPressed = false;

  bool get _isEnabled {
    return widget.enabled &&
        (widget.onTap != null || widget.onLongPress != null);
  }

  void _setPressed(bool value) {
    if (_isPressed == value || !mounted) return;
    setState(() => _isPressed = value);
  }

  void _handleTap() {
    if (!_isEnabled || widget.onTap == null) return;
    if (widget.enableHaptics) HapticFeedback.selectionClick();
    widget.onTap!();
  }

  void _handleLongPress() {
    if (!_isEnabled || widget.onLongPress == null) return;
    if (widget.enableHaptics) HapticFeedback.mediumImpact();
    widget.onLongPress!();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final content = AnimatedScale(
      scale: _isPressed && !disableAnimations ? widget.scale : 1,
      duration: disableAnimations ? Duration.zero : AppDurations.quick,
      curve: AppMotion.standardCurve,
      child: widget.child,
    );

    if (!_isEnabled) return content;

    return Semantics(
      button: widget.onTap != null,
      enabled: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: widget.behavior,
        onTap: widget.onTap == null ? null : _handleTap,
        onLongPress: widget.onLongPress == null ? null : _handleLongPress,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: content,
      ),
    );
  }
}
