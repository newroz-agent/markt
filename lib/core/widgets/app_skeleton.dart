import 'package:flutter/material.dart';

import 'package:zerin_marketplace/core/theme/theme.dart';

/// Applies a theme-aware shimmer to a subtree of skeleton shapes.
class AppSkeletonLoader extends StatefulWidget {
  const AppSkeletonLoader({
    required this.child,
    this.enabled = true,
    super.key,
  });

  final Widget child;
  final bool enabled;

  @override
  State<AppSkeletonLoader> createState() => _AppSkeletonLoaderState();
}

class _AppSkeletonLoaderState extends State<AppSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.skeleton,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final semantic = context.semanticColors;
    if (!widget.enabled || disableAnimations) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final travel = (_controller.value * 4) - 2;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(travel - 1, 0),
              end: Alignment(travel + 1, 0),
              colors: <Color>[
                semantic.surfaceMuted,
                semantic.surfaceRaised,
                semantic.surfaceMuted,
              ],
              stops: const <double>[0.15, 0.5, 0.85],
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

/// A single rounded skeleton shape.
class AppSkeletonBox extends StatelessWidget {
  const AppSkeletonBox({
    this.width,
    this.height,
    this.borderRadius = AppRadius.medium,
    this.animate = true,
    super.key,
  });

  final double? width;
  final double? height;
  final BorderRadiusGeometry borderRadius;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final shape = DecoratedBox(
      decoration: BoxDecoration(
        color: context.semanticColors.surfaceMuted,
        borderRadius: borderRadius,
      ),
      child: SizedBox(width: width, height: height),
    );
    return animate ? AppSkeletonLoader(child: shape) : shape;
  }
}

typedef SkeletonLoader = AppSkeletonLoader;
