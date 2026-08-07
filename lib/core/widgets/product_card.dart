import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/app_skeleton.dart';
import 'package:zerin_marketplace/core/widgets/press_scale.dart';

/// Reusable marketplace product tile.
///
/// Formatting and localized labels are deliberately supplied by the caller.
class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.title,
    required this.priceLabel,
    this.imageUrl,
    this.heroTag,
    this.conditionLabel,
    this.shippingLabel,
    this.sellerLabel,
    this.ratingLabel,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.favoriteSemanticLabel,
    this.imageSemanticLabel,
    this.semanticLabel,
    this.onTap,
    this.imagePlaceholder,
    this.imageError,
    this.aspectRatio = AppRatios.square,
    super.key,
  });

  final String title;
  final String priceLabel;
  final String? imageUrl;
  final Object? heroTag;
  final String? conditionLabel;
  final String? shippingLabel;
  final String? sellerLabel;
  final String? ratingLabel;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final String? favoriteSemanticLabel;
  final String? imageSemanticLabel;
  final String? semanticLabel;
  final VoidCallback? onTap;
  final Widget? imagePlaceholder;
  final Widget? imageError;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final content = Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AspectRatio(
            aspectRatio: aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                _ProductImage(
                  imageUrl: imageUrl,
                  heroTag: heroTag,
                  semanticLabel: imageSemanticLabel,
                  placeholder: imagePlaceholder,
                  error: imageError,
                ),
                if (onFavoriteToggle != null || isFavorite)
                  PositionedDirectional(
                    top: AppSpacing.xs,
                    end: AppSpacing.xs,
                    child: Material(
                      color: context.semanticColors.surfaceRaised.withValues(
                        alpha: AppOpacity.raised,
                      ),
                      shape: const CircleBorder(),
                      child: IconButton(
                        onPressed: onFavoriteToggle == null
                            ? null
                            : () {
                                HapticFeedback.selectionClick();
                                onFavoriteToggle!();
                              },
                        tooltip: favoriteSemanticLabel,
                        icon: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFavorite ? scheme.error : scheme.onSurface,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: AppSpacing.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (conditionLabel != null ||
                    shippingLabel != null) ...<Widget>[
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: <Widget>[
                      if (conditionLabel != null)
                        _ProductBadge(
                          label: conditionLabel!,
                          foreground: scheme.onPrimaryContainer,
                          background: scheme.primaryContainer,
                        ),
                      if (shippingLabel != null)
                        _ProductBadge(
                          label: shippingLabel!,
                          foreground: context.semanticColors.onSuccessContainer,
                          background: context.semanticColors.successContainer,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  priceLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (sellerLabel != null || ratingLabel != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: <Widget>[
                      if (sellerLabel != null)
                        Expanded(
                          child: Text(
                            sellerLabel!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                      if (ratingLabel != null) ...<Widget>[
                        const SizedBox(width: AppSpacing.xs),
                        Icon(
                          Icons.star_rounded,
                          size: AppSizes.iconSmall,
                          color: scheme.secondary,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(ratingLabel!, style: textTheme.labelSmall),
                      ],
                    ],
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
      label: semanticLabel,
      child: PressScale(
        onTap: onTap,
        semanticLabel: semanticLabel,
        child: content,
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({
    required this.imageUrl,
    required this.heroTag,
    required this.semanticLabel,
    required this.placeholder,
    required this.error,
  });

  final String? imageUrl;
  final Object? heroTag;
  final String? semanticLabel;
  final Widget? placeholder;
  final Widget? error;

  @override
  Widget build(BuildContext context) {
    final child = imageUrl == null || imageUrl!.isEmpty
        ? placeholder ?? const AppSkeletonBox(borderRadius: BorderRadius.zero)
        : CachedNetworkImage(
            imageUrl: imageUrl!,
            fit: BoxFit.cover,
            placeholder: (_, _) =>
                placeholder ??
                const AppSkeletonBox(borderRadius: BorderRadius.zero),
            errorWidget: (_, _, _) =>
                error ??
                ColoredBox(
                  color: context.semanticColors.surfaceMuted,
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      semanticLabel: semanticLabel,
                    ),
                  ),
                ),
          );
    final semanticImage = Semantics(
      image: semanticLabel != null,
      label: semanticLabel,
      child: child,
    );
    if (heroTag == null) return semanticImage;
    return Hero(tag: heroTag!, child: semanticImage);
  }
}

class _ProductBadge extends StatelessWidget {
  const _ProductBadge({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.pill,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: foreground),
        ),
      ),
    );
  }
}
