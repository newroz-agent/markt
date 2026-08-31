import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zerin_marketplace/app/router/app_router.dart';
import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/features/auth/presentation/controllers/auth_controller.dart';
import 'package:zerin_marketplace/features/categories/domain/marketplace_category.dart';
import 'package:zerin_marketplace/features/categories/presentation/controllers/category_controller.dart';
import 'package:zerin_marketplace/features/home/domain/home_feed.dart';
import 'package:zerin_marketplace/features/home/presentation/controllers/home_controller.dart';
import 'package:zerin_marketplace/features/home/presentation/widgets/home_campaign_carousel.dart';
import 'package:zerin_marketplace/features/home/presentation/widgets/home_rails.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

class HomeFoundationScreen extends ConsumerStatefulWidget {
  const HomeFoundationScreen({super.key});

  @override
  ConsumerState<HomeFoundationScreen> createState() =>
      _HomeFoundationScreenState();
}

class _HomeFoundationScreenState extends ConsumerState<HomeFoundationScreen> {
  final Set<String> _favoriteProductIds = <String>{};

  Future<void> _refresh() async {
    ref.invalidate(homeFeedProvider);
    ref.invalidate(activeCategoriesProvider);
    await Future.wait<Object?>(<Future<Object?>>[
      ref.read(homeFeedProvider.future),
      ref.read(activeCategoriesProvider.future),
    ]);
  }

  void _openCategories() => const MarketplaceRoute(tab: 1).go(context);

  void _openProduct(HomeProduct product, String heroTag) => ProductDetailRoute(
    productId: product.id,
    heroTag: heroTag,
  ).push<void>(context);

  void _toggleFavorite(HomeProduct product) {
    setState(() {
      if (!_favoriteProductIds.add(product.id)) {
        _favoriteProductIds.remove(product.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final categories = ref.watch(rootCategoriesProvider);
    final feed = ref.watch(homeFeedProvider);
    final user = ref.watch(authStateProvider).valueOrNull;
    final displayName = user?.displayName?.trim();
    final greeting = displayName == null || displayName.isEmpty
        ? l10n.homeGreeting
        : l10n.homeGreetingNamed(name: displayName.split(RegExp(r'\s+')).first);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.contentMaxWidth,
              ),
              child: ListView(
                key: const PageStorageKey<String>('home-feed'),
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(
                  bottom: AppSizes.bottomBarHeight + AppSpacing.xxl,
                ),
                children: <Widget>[
                  _HomeHeader(
                    greeting: greeting,
                    searchHint: l10n.homeSearchHint,
                    notificationTooltip: l10n.notificationsTitle,
                    onSearchPressed: _openCategories,
                    onNotificationsPressed: () =>
                        const NotificationSettingsRoute().push<void>(context),
                  ),
                  Padding(
                    padding: AppSpacing.page,
                    child: switch (feed) {
                      AsyncData<HomeFeed>(:final value)
                          when value.campaigns.isNotEmpty =>
                        HomeCampaignCarousel(campaigns: value.campaigns),
                      AsyncData<HomeFeed>() => const SizedBox.shrink(),
                      AsyncError<HomeFeed>() => _InlineFeedError(
                        onRetry: () => ref.invalidate(homeFeedProvider),
                      ),
                      _ => const HomeCampaignSkeleton(),
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  HomeSectionTitle(l10n.homeCategoriesTitle),
                  const SizedBox(height: AppSpacing.sm),
                  switch (categories) {
                    AsyncData<List<MarketplaceCategory>>(:final value)
                        when value.isNotEmpty =>
                      HomeCategoryRail(
                        categories: value,
                        allLabel: l10n.homeAllCategoriesLabel,
                        onCategoryPressed: (_) => _openCategories(),
                        onAllPressed: _openCategories,
                      ),
                    AsyncData<List<MarketplaceCategory>>() => Padding(
                      padding: AppSpacing.page,
                      child: AppEmptyState(
                        title: l10n.categoriesEmptyTitle,
                        message: l10n.categoriesEmptyBody,
                        icon: Icons.category_outlined,
                      ),
                    ),
                    AsyncError<List<MarketplaceCategory>>() => Padding(
                      padding: AppSpacing.page,
                      child: AppErrorState(
                        title: l10n.stateErrorTitle,
                        message: l10n.stateErrorMessage,
                        retryLabel: l10n.actionRetry,
                        onRetry: () => ref.invalidate(activeCategoriesProvider),
                      ),
                    ),
                    _ => const HomeCategoryRailSkeleton(),
                  },
                  const SizedBox(height: AppSpacing.xl),
                  switch (feed) {
                    AsyncData<HomeFeed>(:final value) => _FeedSections(
                      feed: value,
                      favoriteProductIds: _favoriteProductIds,
                      onProductPressed: _openProduct,
                      onFavoriteToggle: _toggleFavorite,
                    ),
                    AsyncError<HomeFeed>() => const SizedBox.shrink(),
                    _ => const _FeedSectionsSkeleton(),
                  },
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.greeting,
    required this.searchHint,
    required this.notificationTooltip,
    required this.onSearchPressed,
    required this.onNotificationsPressed,
  });

  final String greeting;
  final String searchHint;
  final String notificationTooltip;
  final VoidCallback onSearchPressed;
  final VoidCallback onNotificationsPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const _BrandMonogram(),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'zêrîn',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontFamily: AppTypography.displayFamily,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                            height: 1,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      greeting,
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
              const SizedBox(width: AppSpacing.sm),
              IconButton.outlined(
                onPressed: onNotificationsPressed,
                tooltip: notificationTooltip,
                style: IconButton.styleFrom(
                  foregroundColor: scheme.primary,
                  backgroundColor: context.semanticColors.surfaceRaised,
                  side: BorderSide(color: scheme.outlineVariant),
                ),
                icon: const Icon(Icons.notifications_none_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _SearchSurface(hint: searchHint, onTap: onSearchPressed),
        ],
      ),
    );
  }
}

class _BrandMonogram extends StatelessWidget {
  const _BrandMonogram();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.controlMedium,
      height: AppSizes.controlMedium,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.petrol800,
        borderRadius: AppRadius.medium,
      ),
      child: Text(
        'Ẑ',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: AppColors.gold400,
          fontFamily: AppTypography.displayFamily,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          height: 1,
        ),
      ),
    );
  }
}

class _SearchSurface extends StatelessWidget {
  const _SearchSurface({required this.hint, required this.onTap});

  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PressScale(
      onTap: onTap,
      semanticLabel: hint,
      child: Container(
        height: AppSizes.controlLarge,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: context.semanticColors.surfaceRaised,
          borderRadius: AppRadius.medium,
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.search_rounded, color: scheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedSections extends StatelessWidget {
  const _FeedSections({
    required this.feed,
    required this.favoriteProductIds,
    required this.onProductPressed,
    required this.onFavoriteToggle,
  });

  final HomeFeed feed;
  final Set<String> favoriteProductIds;
  final void Function(HomeProduct product, String heroTag) onProductPressed;
  final ValueChanged<HomeProduct> onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (feed.newArrivals.isNotEmpty) ...<Widget>[
          HomeSectionTitle(l10n.homeNewArrivalsTitle),
          const SizedBox(height: AppSpacing.sm),
          HomeProductRail(
            products: feed.newArrivals,
            favoriteIds: favoriteProductIds,
            heroPrefix: 'home-new',
            onProductPressed: onProductPressed,
            onFavoriteToggle: onFavoriteToggle,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        if (feed.deals.isNotEmpty) ...<Widget>[
          HomeSectionTitle(l10n.homeDealsTitle),
          const SizedBox(height: AppSpacing.sm),
          HomeProductRail(
            products: feed.deals,
            favoriteIds: favoriteProductIds,
            heroPrefix: 'home-deals',
            onProductPressed: onProductPressed,
            onFavoriteToggle: onFavoriteToggle,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        if (feed.popularStores.isNotEmpty) ...<Widget>[
          HomeSectionTitle(l10n.homePopularStoresTitle),
          const SizedBox(height: AppSpacing.sm),
          HomeStoreRail(stores: feed.popularStores),
        ],
      ],
    );
  }
}

class _FeedSectionsSkeleton extends StatelessWidget {
  const _FeedSectionsSkeleton();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        HomeSectionTitle(l10n.homeNewArrivalsTitle),
        const SizedBox(height: AppSpacing.sm),
        const HomeProductRailSkeleton(),
        const SizedBox(height: AppSpacing.xl),
        HomeSectionTitle(l10n.homeDealsTitle),
        const SizedBox(height: AppSpacing.sm),
        const HomeProductRailSkeleton(),
        const SizedBox(height: AppSpacing.xl),
        HomeSectionTitle(l10n.homePopularStoresTitle),
        const SizedBox(height: AppSpacing.sm),
        const HomeStoreRailSkeleton(),
      ],
    );
  }
}

class _InlineFeedError extends StatelessWidget {
  const _InlineFeedError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppErrorState(
      title: l10n.stateErrorTitle,
      message: l10n.stateErrorMessage,
      retryLabel: l10n.actionRetry,
      onRetry: onRetry,
    );
  }
}
