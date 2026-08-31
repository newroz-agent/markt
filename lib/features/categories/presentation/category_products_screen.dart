import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zerin_marketplace/app/router/app_router.dart';
import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/features/categories/domain/category_products_repository.dart';
import 'package:zerin_marketplace/features/categories/presentation/controllers/category_products_controller.dart';
import 'package:zerin_marketplace/features/home/domain/home_feed.dart';
import 'package:zerin_marketplace/features/home/presentation/home_formatters.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

class CategoryProductsScreen extends ConsumerWidget {
  const CategoryProductsScreen({required this.categoryId, super.key});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final category = ref.watch(categoryByIdProvider(categoryId));
    final locale = Localizations.localeOf(context);
    final appBarTitle = category.maybeWhen(
      data: (value) =>
          value?.nameForLanguage(locale.languageCode) ?? l10n.categoriesTitle,
      orElse: () => l10n.categoriesTitle,
    );

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(categoryProductsProvider(categoryId));
              await ref.read(categoryProductsProvider(categoryId).future);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: <Widget>[
                _SubcategoryRail(categoryId: categoryId),
                _FilterBar(categoryId: categoryId),
                _ProductGrid(categoryId: categoryId),
                const SliverPadding(
                  padding: EdgeInsets.only(bottom: AppSpacing.xxl),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SubcategoryRail extends ConsumerWidget {
  const _SubcategoryRail({required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final children = ref.watch(categoryChildrenProvider(categoryId));
    final filter = ref.watch(categoryProductsFilterProvider(categoryId));

    return children.maybeWhen(
      orElse: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (value) => value.isEmpty
          ? const SliverToBoxAdapter(child: SizedBox.shrink())
          : SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  0,
                ),
                child: SizedBox(
                  height: AppSizes.chipHeight,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: value.length + 1,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _FilterChip(
                          label: l10n.categoryProductsAll,
                          selected: filter.subcategoryId == null,
                          onTap: () => ref
                              .read(
                                categoryProductsFilterProvider(
                                  categoryId,
                                ).notifier,
                              )
                              .selectSubcategory(null),
                        );
                      }
                      final child = value[index - 1];
                      return _FilterChip(
                        label: child.nameForLanguage(locale.languageCode),
                        selected: filter.subcategoryId == child.id,
                        onTap: () => ref
                            .read(
                              categoryProductsFilterProvider(
                                categoryId,
                              ).notifier,
                            )
                            .selectSubcategory(child.id),
                      );
                    },
                  ),
                ),
              ),
            ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final filter = ref.watch(categoryProductsFilterProvider(categoryId));
    final filterNotifier = ref.read(
      categoryProductsFilterProvider(categoryId).notifier,
    );

    final conditionOptions = <(CategoryProductConditionFilter, String)>[
      (CategoryProductConditionFilter.all, l10n.filterConditionAll),
      (CategoryProductConditionFilter.isNew, l10n.productConditionNew),
      (CategoryProductConditionFilter.isUsed, l10n.productConditionUsed),
    ];
    final sortLabel = switch (filter.sort) {
      CategoryProductSort.newest => l10n.filterSortNewest,
      CategoryProductSort.priceAscending => l10n.filterSortPriceAsc,
      CategoryProductSort.priceDescending => l10n.filterSortPriceDesc,
    };

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: <Widget>[
            Expanded(
              child: SizedBox(
                height: AppSizes.chipHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: conditionOptions.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final (value, label) = conditionOptions[index];
                    return _FilterChip(
                      label: label,
                      selected: filter.condition == value,
                      onTap: () => filterNotifier.setCondition(value),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            PopupMenuButton<CategoryProductSort>(
              tooltip: l10n.filterSortLabel,
              onSelected: filterNotifier.setSort,
              initialValue: filter.sort,
              itemBuilder: (context) => <PopupMenuEntry<CategoryProductSort>>[
                PopupMenuItem(
                  value: CategoryProductSort.newest,
                  child: Text(l10n.filterSortNewest),
                ),
                PopupMenuItem(
                  value: CategoryProductSort.priceAscending,
                  child: Text(l10n.filterSortPriceAsc),
                ),
                PopupMenuItem(
                  value: CategoryProductSort.priceDescending,
                  child: Text(l10n.filterSortPriceDesc),
                ),
              ],
              child: Container(
                height: AppSizes.chipHeight,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.pill,
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.sort_rounded,
                      size: AppSizes.iconSmall,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      sortLabel,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pill,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: selected ? scheme.primaryContainer : null,
            borderRadius: AppRadius.pill,
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductGrid extends ConsumerWidget {
  const _ProductGrid({required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final products = ref.watch(categoryProductsProvider(categoryId));

    return switch (products) {
      AsyncData<List<HomeProduct>>(:final value) when value.isNotEmpty =>
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.md),
          sliver: SliverLayoutBuilder(
            builder: (context, constraints) {
              final columnCount =
                  constraints.crossAxisExtent >= AppSizes.compactBreakpoint
                  ? 3
                  : 2;
              return SliverGrid.builder(
                itemCount: value.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columnCount,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  mainAxisExtent: AppSizes.categoryProductCardHeight,
                ),
                itemBuilder: (context, index) {
                  final product = value[index];
                  return _CategoryProductCard(product: product);
                },
              );
            },
          ),
        ),
      AsyncData<List<HomeProduct>>() => SliverFillRemaining(
        hasScrollBody: false,
        child: AppEmptyState(
          title: l10n.categoryProductsEmptyTitle,
          message: l10n.categoryProductsEmptyBody,
          icon: Icons.inventory_2_outlined,
        ),
      ),
      AsyncError<List<HomeProduct>>() => SliverFillRemaining(
        hasScrollBody: false,
        child: AppErrorState(
          title: l10n.stateErrorTitle,
          message: l10n.stateErrorMessage,
          retryLabel: l10n.actionRetry,
          onRetry: () => ref.invalidate(categoryProductsProvider(categoryId)),
        ),
      ),
      _ => const SliverPadding(
        padding: EdgeInsets.all(AppSpacing.md),
        sliver: _ProductGridSkeleton(),
      ),
    };
  }
}

class _CategoryProductCard extends StatelessWidget {
  const _CategoryProductCard({required this.product});

  final HomeProduct product;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final price = formatMarketplacePrice(
      locale,
      product.priceCents,
      product.currency,
    );
    final conditionLabel = product.condition == 'new'
        ? l10n.productConditionNew
        : l10n.productConditionUsed;

    return ProductCard(
      title: product.title,
      priceLabel: price,
      imageUrl: product.imageUrls.firstOrNull,
      heroTag: 'category-${product.id}',
      conditionLabel: conditionLabel,
      sellerLabel: product.store?.shopName,
      aspectRatio: AppRatios.widescreen,
      semanticLabel: '${product.title}, $price',
      onTap: () => ProductDetailRoute(
        productId: product.id,
        heroTag: 'category-${product.id}',
      ).push<void>(context),
    );
  }
}

class _ProductGridSkeleton extends StatelessWidget {
  const _ProductGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final columnCount =
            constraints.crossAxisExtent >= AppSizes.compactBreakpoint ? 3 : 2;
        return SliverGrid.builder(
          itemCount: 6,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            mainAxisExtent: AppSizes.categoryProductCardHeight,
          ),
          itemBuilder: (_, _) =>
              const AppSkeletonBox(borderRadius: AppRadius.large),
        );
      },
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
