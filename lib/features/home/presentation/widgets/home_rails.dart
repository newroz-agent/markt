import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/features/categories/domain/marketplace_category.dart';
import 'package:zerin_marketplace/features/home/domain/home_feed.dart';
import 'package:zerin_marketplace/features/home/presentation/home_formatters.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

class HomeSectionTitle extends StatelessWidget {
  const HomeSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.page,
      child: Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontFamily: AppTypography.displayFamily,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class HomeCategoryRail extends StatelessWidget {
  const HomeCategoryRail({
    required this.categories,
    required this.allLabel,
    required this.onCategoryPressed,
    required this.onAllPressed,
    super.key,
  });

  final List<MarketplaceCategory> categories;
  final String allLabel;
  final ValueChanged<MarketplaceCategory> onCategoryPressed;
  final VoidCallback onAllPressed;

  @override
  Widget build(BuildContext context) {
    final visibleCategories = categories.take(6).toList(growable: false);
    return SizedBox(
      height: AppSizes.homeCategoryRailHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.page,
        itemCount: visibleCategories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == visibleCategories.length) {
            return _AllCategoriesTile(label: allLabel, onTap: onAllPressed);
          }
          final category = visibleCategories[index];
          return _DelayedReveal(
            delay: AppDurations.staggered(index),
            child: _CategoryTile(
              category: category,
              onTap: () => onCategoryPressed(category),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});

  final MarketplaceCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = category.nameForLanguage(
      Localizations.localeOf(context).languageCode,
    );
    return SizedBox(
      width: AppSizes.homeCategoryTileWidth,
      child: PressScale(
        onTap: onTap,
        semanticLabel: label,
        child: ClipRRect(
          borderRadius: AppRadius.large,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              if (category.imageUrl.isEmpty)
                _CategoryFallback(icon: _iconForCategory(category.iconKey))
              else
                CachedNetworkImage(
                  imageUrl: category.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, _) =>
                      const AppSkeletonBox(borderRadius: BorderRadius.zero),
                  errorWidget: (_, _, _) => _CategoryFallback(
                    icon: _iconForCategory(category.iconKey),
                  ),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: <Color>[
                      AppColors.petrol950,
                      AppColors.petrol950.withValues(alpha: AppOpacity.muted),
                      AppColors.petrol950.withValues(
                        alpha: AppOpacity.transparent,
                      ),
                    ],
                    stops: <double>[0, 0.46, 1],
                  ),
                ),
              ),
              PositionedDirectional(
                start: AppSpacing.sm,
                end: AppSpacing.sm,
                bottom: AppSpacing.sm,
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.berf0,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AllCategoriesTile extends StatelessWidget {
  const _AllCategoriesTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSizes.homeCategoryTileWidth,
      child: PressScale(
        onTap: onTap,
        semanticLabel: label,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.petrol800,
            borderRadius: AppRadius.large,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(
                  Icons.apps_rounded,
                  size: AppSizes.iconState,
                  color: AppColors.berf100,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.berf0,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryFallback extends StatelessWidget {
  const _CategoryFallback({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.petrol700,
      child: Center(
        child: Icon(icon, color: AppColors.berf100, size: AppSizes.iconState),
      ),
    );
  }
}

class HomeProductRail extends StatelessWidget {
  const HomeProductRail({
    required this.products,
    required this.favoriteIds,
    required this.heroPrefix,
    required this.onProductPressed,
    required this.onFavoriteToggle,
    super.key,
  });

  final List<HomeProduct> products;
  final Set<String> favoriteIds;

  /// Disambiguates hero tags when the same product renders in multiple rails.
  final String heroPrefix;
  final void Function(HomeProduct product, String heroTag) onProductPressed;
  final ValueChanged<HomeProduct> onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.homeProductRailHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.page,
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final product = products[index];
          final heroTag = '$heroPrefix-${product.id}';
          return _DelayedReveal(
            delay: AppDurations.staggered(index),
            child: _HomeProductCard(
              product: product,
              isFavorite: favoriteIds.contains(product.id),
              heroTag: heroTag,
              onTap: () => onProductPressed(product, heroTag),
              onFavoriteToggle: () => onFavoriteToggle(product),
            ),
          );
        },
      ),
    );
  }
}

class _HomeProductCard extends StatelessWidget {
  const _HomeProductCard({
    required this.product,
    required this.isFavorite,
    required this.heroTag,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  final HomeProduct product;
  final bool isFavorite;
  final String heroTag;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context);
    final price = formatMarketplacePrice(
      locale,
      product.priceCents,
      product.currency,
    );
    final comparePrice = product.compareAtPriceCents == null
        ? null
        : formatMarketplacePrice(
            locale,
            product.compareAtPriceCents!,
            product.currency,
          );
    final imageUrl = product.imageUrls.firstOrNull;

    return SizedBox(
      width: AppSizes.homeProductCardWidth,
      child: PressScale(
        onTap: onTap,
        semanticLabel: '${product.title}, $price',
        child: Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                height: AppSizes.homeProductImageHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Hero(
                      tag: heroTag,
                      child: imageUrl == null
                          ? const _ProductFallback()
                          : CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => const AppSkeletonBox(
                                borderRadius: BorderRadius.zero,
                              ),
                              errorWidget: (_, _, _) =>
                                  const _ProductFallback(),
                            ),
                    ),
                    if (product.isDiscounted)
                      PositionedDirectional(
                        start: AppSpacing.xs,
                        top: AppSpacing.xs,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.error,
                            borderRadius: AppRadius.pill,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: AppSpacing.xxs,
                            ),
                            child: Text(
                              '-${product.discountPercent}%',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: scheme.onError,
                                    letterSpacing: 0,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    PositionedDirectional(
                      end: AppSpacing.xs,
                      top: AppSpacing.xs,
                      child: Material(
                        color: context.semanticColors.surfaceRaised.withValues(
                          alpha: AppOpacity.raised,
                        ),
                        shape: const CircleBorder(),
                        child: IconButton(
                          onPressed: onFavoriteToggle,
                          tooltip: isFavorite
                              ? l10n.favoriteRemove
                              : l10n.favoriteAdd,
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
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              price,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontFamily: AppTypography.displayFamily,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0,
                                  ),
                            ),
                          ),
                          if (comparePrice != null) ...<Widget>[
                            const SizedBox(width: AppSpacing.xxs),
                            Text(
                              comparePrice,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    decoration: TextDecoration.lineThrough,
                                    letterSpacing: 0,
                                  ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        l10n.cartVatIncluded,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              product.store?.shopName ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    letterSpacing: 0,
                                  ),
                            ),
                          ),
                          if (product.ratingCount > 0) ...<Widget>[
                            const SizedBox(width: AppSpacing.xs),
                            Icon(
                              Icons.star_rounded,
                              size: AppSizes.iconSmall,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: AppSpacing.xxs),
                            Text(
                              product.ratingAverage.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductFallback extends StatelessWidget {
  const _ProductFallback();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.semanticColors.surfaceMuted,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: AppSizes.iconState,
        ),
      ),
    );
  }
}

class HomeStoreRail extends StatelessWidget {
  const HomeStoreRail({required this.stores, this.onStorePressed, super.key});

  final List<MarketplaceStore> stores;
  final ValueChanged<MarketplaceStore>? onStorePressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.homeStoreRailHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.page,
        itemCount: stores.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final store = stores[index];
          return _DelayedReveal(
            delay: AppDurations.staggered(index),
            child: _StoreCard(
              store: store,
              onTap: onStorePressed == null
                  ? null
                  : () => onStorePressed!(store),
            ),
          );
        },
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({required this.store, required this.onTap});

  final MarketplaceStore store;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: AppSizes.homeStoreCardWidth,
      child: PressScale(
        onTap: onTap,
        semanticLabel: store.shopName,
        child: Card(
          child: Stack(
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(
                    height: AppSizes.homeStoreBannerHeight,
                    child: store.bannerUrl == null
                        ? const _StoreBannerFallback()
                        : CachedNetworkImage(
                            imageUrl: store.bannerUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => const AppSkeletonBox(
                              borderRadius: BorderRadius.zero,
                            ),
                            errorWidget: (_, _, _) =>
                                const _StoreBannerFallback(),
                          ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        72,
                        AppSpacing.sm,
                        AppSpacing.sm,
                        AppSpacing.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            store.shopName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Row(
                            children: <Widget>[
                              if (store.city != null) ...<Widget>[
                                Flexible(
                                  child: Text(
                                    store.city!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                          letterSpacing: 0,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                              ],
                              Icon(
                                Icons.star_rounded,
                                size: AppSizes.iconSmall,
                                color: scheme.primary,
                              ),
                              const SizedBox(width: AppSpacing.xxs),
                              Text(
                                store.ratingAverage.toStringAsFixed(1),
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              PositionedDirectional(
                start: AppSpacing.sm,
                top: 72,
                child: Container(
                  width: AppSizes.homeStoreAvatar,
                  height: AppSizes.homeStoreAvatar,
                  decoration: BoxDecoration(
                    color: context.semanticColors.surfaceRaised,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.semanticColors.surfaceRaised,
                      width: AppStrokes.heavy,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: store.avatarUrl == null
                      ? const _StoreAvatarFallback()
                      : CachedNetworkImage(
                          imageUrl: store.avatarUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => const AppSkeletonBox(
                            borderRadius: BorderRadius.zero,
                          ),
                          errorWidget: (_, _, _) =>
                              const _StoreAvatarFallback(),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreBannerFallback extends StatelessWidget {
  const _StoreBannerFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: AppColors.petrol700);
  }
}

class _StoreAvatarFallback extends StatelessWidget {
  const _StoreAvatarFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.petrol800,
      child: Icon(Icons.storefront_rounded, color: AppColors.berf100),
    );
  }
}

class HomeCategoryRailSkeleton extends StatelessWidget {
  const HomeCategoryRailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.homeCategoryRailHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.page,
        itemCount: 5,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, _) => const SizedBox(
          width: AppSizes.homeCategoryTileWidth,
          child: AppSkeletonBox(borderRadius: AppRadius.large),
        ),
      ),
    );
  }
}

class HomeProductRailSkeleton extends StatelessWidget {
  const HomeProductRailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.homeProductRailHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.page,
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, _) => const SizedBox(
          width: AppSizes.homeProductCardWidth,
          child: AppSkeletonBox(borderRadius: AppRadius.large),
        ),
      ),
    );
  }
}

class HomeStoreRailSkeleton extends StatelessWidget {
  const HomeStoreRailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.homeStoreRailHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.page,
        itemCount: 2,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, _) => const SizedBox(
          width: AppSizes.homeStoreCardWidth,
          child: AppSkeletonBox(borderRadius: AppRadius.large),
        ),
      ),
    );
  }
}

class _DelayedReveal extends StatefulWidget {
  const _DelayedReveal({required this.delay, required this.child});

  final Duration delay;
  final Widget child;

  @override
  State<_DelayedReveal> createState() => _DelayedRevealState();
}

class _DelayedRevealState extends State<_DelayedReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.emphasized,
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.standardCurve,
  );
  late final Animation<Offset> _offset = Tween<Offset>(
    begin: const Offset(0.06, 0),
    end: Offset.zero,
  ).animate(_opacity);
  Timer? _timer;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }
    _timer = Timer(widget.delay, _controller.forward);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

IconData _iconForCategory(String key) => switch (key) {
  'devices' => Icons.devices_rounded,
  'checkroom' => Icons.checkroom_rounded,
  'styler' => Icons.man_rounded,
  'spa' => Icons.spa_rounded,
  'countertops' => Icons.kitchen_rounded,
  'chair' => Icons.chair_rounded,
  'directions_car' => Icons.directions_car_rounded,
  'watch' => Icons.watch_rounded,
  'sports_soccer' => Icons.sports_soccer_rounded,
  'child_friendly' => Icons.child_friendly_rounded,
  'construction' => Icons.construction_rounded,
  'restaurant' => Icons.restaurant_rounded,
  _ => Icons.category_rounded,
};

extension on List<String> {
  String? get firstOrNull => isEmpty ? null : first;
}
