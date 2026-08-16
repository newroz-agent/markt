import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/features/categories/domain/marketplace_category.dart';
import 'package:zerin_marketplace/features/categories/presentation/controllers/category_controller.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

class HomeFoundationScreen extends ConsumerWidget {
  const HomeFoundationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final categories = ref.watch(rootCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appName)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeCategoriesProvider);
          await ref.read(rootCategoriesProvider.future);
        },
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.contentMaxWidth,
            ),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSizes.bottomBarHeight + AppSpacing.xxl,
              ),
              children: <Widget>[
                Text(
                  l10n.homeGreeting,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.homeCategoriesTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                switch (categories) {
                  AsyncData<List<MarketplaceCategory>>(:final value)
                      when value.isEmpty =>
                    AppEmptyState(
                      title: l10n.categoriesEmptyTitle,
                      message: l10n.categoriesEmptyBody,
                      icon: Icons.category_outlined,
                    ),
                  AsyncData<List<MarketplaceCategory>>(:final value) =>
                    _CategoryGrid(categories: value),
                  AsyncError<List<MarketplaceCategory>>() => AppErrorState(
                    title: l10n.stateErrorTitle,
                    message: l10n.stateErrorMessage,
                    retryLabel: l10n.actionRetry,
                    onRetry: () => ref.invalidate(activeCategoriesProvider),
                  ),
                  _ => const _CategoryGridSkeleton(),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.categories});

  final List<MarketplaceCategory> categories;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = constraints.maxWidth >= 600 ? 6 : 4;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.68,
          ),
          itemBuilder: (context, index) => _CategoryShortcut(
            category: categories[index],
            languageCode: context.appLocale.languageCode,
          ),
        );
      },
    );
  }
}

class _CategoryShortcut extends StatelessWidget {
  const _CategoryShortcut({required this.category, required this.languageCode});

  final MarketplaceCategory category;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final name = category.nameForLanguage(languageCode);
    return Semantics(
      container: true,
      label: name,
      child: Column(
        children: <Widget>[
          AspectRatio(
            aspectRatio: AppRatios.square,
            child: ClipRRect(
              borderRadius: AppRadius.medium,
              child: category.imageUrl.isEmpty
                  ? _CategoryFallback(icon: _iconForCategory(category.iconKey))
                  : CachedNetworkImage(
                      imageUrl: category.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, _) =>
                          const AppSkeletonBox(borderRadius: BorderRadius.zero),
                      errorWidget: (_, _, _) => _CategoryFallback(
                        icon: _iconForCategory(category.iconKey),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _CategoryFallback extends StatelessWidget {
  const _CategoryFallback({required this.icon});

  final IconData icon;

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
        ),
      ),
    );
  }
}

class _CategoryGridSkeleton extends StatelessWidget {
  const _CategoryGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = constraints.maxWidth >= 600 ? 6 : 4;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: columnCount * 2,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.68,
          ),
          itemBuilder: (_, _) => const Column(
            children: <Widget>[
              AspectRatio(
                aspectRatio: AppRatios.square,
                child: AppSkeletonBox(),
              ),
              SizedBox(height: AppSpacing.xs),
              AppSkeletonBox(height: AppSizes.iconSmall),
            ],
          ),
        );
      },
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
