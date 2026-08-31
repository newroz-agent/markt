import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/features/home/domain/home_feed.dart';
import 'package:zerin_marketplace/features/home/presentation/controllers/home_controller.dart';
import 'package:zerin_marketplace/features/home/presentation/home_formatters.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({required this.productId, this.heroTag, super.key});

  final String productId;
  final String? heroTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(homeProductProvider(productId: productId));
    return Scaffold(
      appBar: AppBar(),
      body: switch (product) {
        AsyncData<HomeProduct?>(value: final value?) => _ProductDetail(
          product: value,
          heroTag: heroTag ?? 'product-${value.id}',
        ),
        AsyncData<HomeProduct?>() => AppEmptyState(
          title: context.l10n.stateErrorTitle,
          message: context.l10n.stateErrorMessage,
          icon: Icons.inventory_2_outlined,
        ),
        AsyncError<HomeProduct?>() => AppErrorState(
          title: context.l10n.stateErrorTitle,
          message: context.l10n.stateErrorMessage,
          retryLabel: context.l10n.actionRetry,
          onRetry: () =>
              ref.invalidate(homeProductProvider(productId: productId)),
        ),
        _ => const _ProductDetailSkeleton(),
      },
    );
  }
}

class _ProductDetail extends StatelessWidget {
  const _ProductDetail({required this.product, required this.heroTag});

  final HomeProduct product;
  final String heroTag;

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
    final condition = product.condition == 'new'
        ? l10n.productConditionNew
        : l10n.productConditionUsed;
    final imageUrl = product.imageUrls.firstOrNull;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          children: <Widget>[
            AspectRatio(
              aspectRatio: AppRatios.square,
              child: Hero(
                tag: heroTag,
                child: imageUrl == null
                    ? const _ProductImageFallback()
                    : CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => const AppSkeletonBox(
                          borderRadius: BorderRadius.zero,
                        ),
                        errorWidget: (_, _, _) => const _ProductImageFallback(),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    product.title,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(letterSpacing: 0),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.productVatIncluded(price: price),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontFamily: AppTypography.displayFamily,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: <Widget>[
                      AppChip(label: condition),
                      if (product.freeShipping)
                        AppChip(label: l10n.productFreeShipping),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    product.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 0,
                    ),
                  ),
                  if (product.store != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.xl),
                    _StoreIdentity(store: product.store!),
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

class _StoreIdentity extends StatelessWidget {
  const _StoreIdentity({required this.store});

  final MarketplaceStore store;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.semanticColors.surfaceRaised,
        borderRadius: AppRadius.large,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: AppSpacing.card,
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: AppSizes.homeStoreAvatar / 2,
              backgroundColor: scheme.primaryContainer,
              backgroundImage: store.avatarUrl == null
                  ? null
                  : CachedNetworkImageProvider(store.avatarUrl!),
              child: store.avatarUrl == null
                  ? Icon(
                      Icons.storefront_rounded,
                      color: scheme.onPrimaryContainer,
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    store.shopName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    <String>[
                      if (store.city != null) store.city!,
                      if (store.ratingCount > 0)
                        '${store.ratingAverage.toStringAsFixed(1)} (${store.ratingCount})',
                    ].join('  |  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductImageFallback extends StatelessWidget {
  const _ProductImageFallback();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.semanticColors.surfaceMuted,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: AppSizes.iconState,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ProductDetailSkeleton extends StatelessWidget {
  const _ProductDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
        child: ListView(
          children: <Widget>[
            const AspectRatio(
              aspectRatio: AppRatios.square,
              child: AppSkeletonBox(borderRadius: BorderRadius.zero),
            ),
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AppSkeletonBox(height: AppSizes.pageIndicatorSelected),
                  SizedBox(height: AppSpacing.sm),
                  AppSkeletonBox(
                    width: AppSizes.productDetailPriceSkeletonWidth,
                    height: AppSizes.iconLarge,
                  ),
                  SizedBox(height: AppSpacing.lg),
                  AppSkeletonBox(
                    height: AppSizes.productDetailBodySkeletonHeight,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on List<String> {
  String? get firstOrNull => isEmpty ? null : first;
}
