import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zerin_marketplace/app/router/app_router.dart';
import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/features/categories/domain/marketplace_category.dart';
import 'package:zerin_marketplace/features/categories/presentation/controllers/category_controller.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

class CategoriesFoundationScreen extends ConsumerWidget {
  const CategoriesFoundationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final categories = ref.watch(rootCategoriesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.categoriesTitle),
        actions: <Widget>[
          IconButton(
            key: const ValueKey('categories-map-action'),
            tooltip: l10n.mapOpenTooltip,
            onPressed: () => const MapRoute().push<void>(context),
            icon: const Icon(Icons.map_outlined),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
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
                0,
                AppSpacing.md,
                AppSizes.bottomBarHeight + AppSpacing.xxl,
              ),
              children: <Widget>[
                AppTextField(
                  hint: l10n.categoriesSearchHint,
                  prefix: const Icon(Icons.search_rounded),
                  readOnly: true,
                ),
                const SizedBox(height: AppSpacing.lg),
                switch (categories) {
                  AsyncData<List<MarketplaceCategory>>(:final value)
                      when value.isNotEmpty =>
                    _CategoryGrid(categories: value),
                  AsyncData<List<MarketplaceCategory>>() => AppEmptyState(
                    title: l10n.categoriesEmptyTitle,
                    message: l10n.categoriesEmptyBody,
                    icon: Icons.category_outlined,
                  ),
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
        final columnCount = constraints.maxWidth >= AppSizes.compactBreakpoint
            ? 4
            : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            mainAxisExtent: AppSizes.categoryCardHeight,
          ),
          itemBuilder: (context, index) {
            final category = categories[index];
            return CategoryCard(
              title: category.nameForLanguage(
                Localizations.localeOf(context).languageCode,
              ),
              imageUrl: category.imageUrl,
              icon: Icons.category_rounded,
              onTap: () => CategoryProductsRoute(
                categoryId: category.id,
              ).push<void>(context),
            );
          },
        );
      },
    );
  }
}

class _CategoryGridSkeleton extends StatelessWidget {
  const _CategoryGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        mainAxisExtent: AppSizes.categoryCardHeight,
      ),
      itemBuilder: (_, _) =>
          const AppSkeletonBox(borderRadius: AppRadius.large),
    );
  }
}
