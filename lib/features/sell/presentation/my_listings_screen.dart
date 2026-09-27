import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerin_marketplace/app/router/app_router.dart';
import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/features/home/presentation/home_formatters.dart';
import 'package:zerin_marketplace/features/sell/domain/sell_models.dart';
import 'package:zerin_marketplace/features/sell/presentation/controllers/sell_controller.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(myListingsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.myListingsTitle)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
          child: RefreshIndicator(
            onRefresh: () => ref.refresh(myListingsProvider.future),
            child: listings.when(
              loading: () => ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: 4,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, _) =>
                    const AppSkeletonBox(height: AppSizes.stateIllustration),
              ),
              error: (_, _) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: <Widget>[
                  AppErrorState(
                    title: context.l10n.stateErrorTitle,
                    message: context.l10n.stateErrorMessage,
                    retryLabel: context.l10n.actionRetry,
                    onRetry: () => ref.invalidate(myListingsProvider),
                  ),
                ],
              ),
              data: (items) => items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: <Widget>[
                        AppEmptyState(
                          icon: Icons.inventory_2_outlined,
                          title: context.l10n.myListingsEmptyTitle,
                          message: context.l10n.myListingsEmptyBody,
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.xxl,
                      ),
                      itemCount: items.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) =>
                          _MyListingCard(listing: items[index]),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MyListingCard extends StatelessWidget {
  const _MyListingCard({required this.listing});

  final MyListing listing;

  @override
  Widget build(BuildContext context) {
    final status = _statusLabel(context, listing.status);
    return Card(
      child: InkWell(
        borderRadius: AppRadius.large,
        onTap: listing.status == ListingStatus.active
            ? () =>
                  ProductDetailRoute(productId: listing.id).push<void>(context)
            : null,
        child: Padding(
          padding: AppSpacing.card,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClipRRect(
                borderRadius: AppRadius.medium,
                child: SizedBox.square(
                  dimension: AppSizes.stateIllustration,
                  child: listing.imageUrls.isEmpty
                      ? const ColoredBox(
                          color: Colors.transparent,
                          child: Icon(Icons.image_outlined),
                        )
                      : CachedNetworkImage(
                          imageUrl: listing.imageUrls.first,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => const AppSkeletonBox(
                            borderRadius: BorderRadius.zero,
                          ),
                          errorWidget: (_, _, _) =>
                              const Icon(Icons.broken_image_outlined),
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: <Widget>[
                        Chip(label: Text(status)),
                        Text(
                          formatMarketplacePrice(
                            context.appLocale,
                            listing.priceCents,
                            listing.currency,
                          ),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      listing.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      listing.city,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (listing.moderationReason?.isNotEmpty ==
                        true) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '${context.l10n.listingModerationReason}: '
                        '${listing.moderationReason}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(BuildContext context, ListingStatus status) =>
      switch (status) {
        ListingStatus.pendingReview => context.l10n.listingStatusPending,
        ListingStatus.active => context.l10n.listingStatusActive,
        ListingStatus.rejected => context.l10n.listingStatusRejected,
        ListingStatus.draft => context.l10n.listingStatusDraft,
        ListingStatus.sold => context.l10n.listingStatusSold,
        ListingStatus.blocked => context.l10n.listingStatusBlocked,
      };
}
