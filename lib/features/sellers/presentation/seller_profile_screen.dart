import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/features/home/domain/home_feed.dart';
import 'package:zerin_marketplace/features/home/presentation/controllers/home_controller.dart';
import 'package:zerin_marketplace/features/products/presentation/product_rail.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

/// Public seller profile. Business and private sellers share one surface;
/// only public information is ever rendered (city-level location).
class SellerProfileScreen extends ConsumerWidget {
  const SellerProfileScreen({required this.sellerId, super.key});

  final String sellerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seller = ref.watch(sellerProfileProvider(sellerId: sellerId));

    return Scaffold(
      appBar: AppBar(),
      body: switch (seller) {
        AsyncData<MarketplaceStore?>(value: final value?) => _SellerProfile(
          seller: value,
        ),
        AsyncData<MarketplaceStore?>() => AppEmptyState(
          title: context.l10n.sellerProfileLoadFailed,
          message: context.l10n.stateErrorMessage,
          icon: Icons.storefront_outlined,
        ),
        AsyncError<MarketplaceStore?>() => AppErrorState(
          title: context.l10n.sellerProfileLoadFailed,
          message: context.l10n.stateErrorMessage,
          retryLabel: context.l10n.actionRetry,
          onRetry: () =>
              ref.invalidate(sellerProfileProvider(sellerId: sellerId)),
        ),
        _ => const _SellerProfileSkeleton(),
      },
    );
  }
}

class _SellerProfile extends StatelessWidget {
  const _SellerProfile({required this.seller});

  final MarketplaceStore seller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: AppSizes.homeStoreAvatar,
                    backgroundColor: scheme.primaryContainer,
                    backgroundImage: seller.avatarUrl == null
                        ? null
                        : CachedNetworkImageProvider(seller.avatarUrl!),
                    child: seller.avatarUrl == null
                        ? Icon(
                            seller.isBusiness
                                ? Icons.storefront_rounded
                                : Icons.person_rounded,
                            color: scheme.onPrimaryContainer,
                          )
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          seller.shopName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: <Widget>[
                            _SellerKindBadge(seller: seller),
                            if (seller.verified == true)
                              AppChip(
                                label: l10n.sellerVerified,
                                leading: const Icon(
                                  Icons.verified_rounded,
                                  size: AppSizes.iconSmall,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: <Widget>[
                  if (seller.city != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.location_on_outlined,
                          size: AppSizes.iconSmall,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          seller.city!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  if (seller.ratingCount > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.star_rounded,
                          size: AppSizes.iconSmall,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          '${seller.ratingAverage.toStringAsFixed(1)} '
                          '(${seller.ratingCount})',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.sellerProfileAbout,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    seller.bio?.isNotEmpty == true
                        ? seller.bio!
                        : l10n.sellerProfileNoBio,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                l10n.sellerProfileListingsTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            _SellerListingsSection(
              key: ValueKey(seller.id),
              sellerId: seller.id,
            ),
          ],
        ),
      ),
    );
  }
}

class _SellerKindBadge extends StatelessWidget {
  const _SellerKindBadge({required this.seller});

  final MarketplaceStore seller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = switch (seller.sellerKind) {
      'private' => l10n.sellerTypePrivate,
      'business' => l10n.sellerTypeBusiness,
      _ => null,
    };
    if (label == null) return const SizedBox.shrink();
    return AppChip(label: label);
  }
}

class _SellerListingsSection extends ConsumerStatefulWidget {
  const _SellerListingsSection({required this.sellerId, super.key});

  final String sellerId;

  @override
  ConsumerState<_SellerListingsSection> createState() =>
      _SellerListingsSectionState();
}

class _SellerListingsSectionState
    extends ConsumerState<_SellerListingsSection> {
  int _pages = 1;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final products = <String, HomeProduct>{};
    Widget? footer;
    for (var page = 0; page < _pages; page++) {
      final provider = sellerProductsProvider(
        sellerId: widget.sellerId,
        offset: page * 24,
      );
      final result = ref.watch(provider);
      if (result.hasError) {
        footer = AppErrorState(
          title: l10n.stateErrorTitle,
          message: l10n.stateErrorMessage,
          retryLabel: l10n.actionRetry,
          onRetry: () => ref.invalidate(provider),
        );
        break;
      }
      final items = result.asData?.value;
      if (items == null) {
        footer = const Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: AppSkeletonBox(height: 180),
        );
        break;
      }
      for (final product in items) {
        products[product.id] = product;
      }
      if (items.length < 24) break;
      if (page == _pages - 1) {
        footer = Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: AppButton.secondary(
            label: l10n.categoryProductsLoadMore,
            onPressed: () => setState(() => _pages++),
          ),
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (products.isNotEmpty)
          ProductRail(products: products.values.toList()),
        if (products.isEmpty && footer == null)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(l10n.sellerProfileEmptyListings),
          ),
        ?footer,
      ],
    );
  }
}

class _SellerProfileSkeleton extends StatelessWidget {
  const _SellerProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                AppSkeletonBox(
                  width: AppSizes.homeStoreAvatar * 2,
                  height: AppSizes.homeStoreAvatar * 2,
                  borderRadius: AppRadius.pill,
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppSkeletonBox(height: AppSizes.pageIndicatorSelected),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.lg),
            AppSkeletonBox(height: AppSizes.productDetailBodySkeletonHeight),
          ],
        ),
      ),
    );
  }
}
