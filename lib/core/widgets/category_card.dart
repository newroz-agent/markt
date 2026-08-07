import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/app_skeleton.dart';
import 'package:zerin_marketplace/core/widgets/press_scale.dart';

/// Category tile that works with a network image, an icon, or both.
class CategoryCard extends StatelessWidget {
  const CategoryCard({
    required this.title,
    this.imageUrl,
    this.icon,
    this.subtitle,
    this.semanticLabel,
    this.onTap,
    this.imageHeight = AppSizes.categoryImageHeight,
    super.key,
  });

  final String title;
  final String? imageUrl;
  final IconData? icon;
  final String? subtitle;
  final String? semanticLabel;
  final VoidCallback? onTap;
  final double imageHeight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final card = Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            height: imageHeight,
            child: _CategoryVisual(
              imageUrl: imageUrl,
              icon: icon,
              semanticLabel: semanticLabel,
            ),
          ),
          Padding(
            padding: AppSpacing.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall,
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return Semantics(
      container: true,
      label: semanticLabel ?? title,
      child: PressScale(
        onTap: onTap,
        semanticLabel: semanticLabel ?? title,
        child: card,
      ),
    );
  }
}

class _CategoryVisual extends StatelessWidget {
  const _CategoryVisual({
    required this.imageUrl,
    required this.icon,
    required this.semanticLabel,
  });

  final String? imageUrl;
  final IconData? icon;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        placeholder: (_, _) =>
            const AppSkeletonBox(borderRadius: BorderRadius.zero),
        errorWidget: (_, _, _) => _IconVisual(
          icon: icon ?? Icons.category_outlined,
          semanticLabel: semanticLabel,
        ),
      );
    }
    return _IconVisual(
      icon: icon ?? Icons.category_outlined,
      semanticLabel: semanticLabel,
    );
  }
}

class _IconVisual extends StatelessWidget {
  const _IconVisual({required this.icon, required this.semanticLabel});

  final IconData icon;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.primaryContainer,
      child: Center(
        child: Icon(
          icon,
          size: AppSizes.iconState,
          color: scheme.onPrimaryContainer,
          semanticLabel: semanticLabel,
        ),
      ),
    );
  }
}
