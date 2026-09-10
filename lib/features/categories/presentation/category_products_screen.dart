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

/// German marketplace cities. Germany-only is a hard product requirement; the
/// catalog is intentionally local so no non-German location can be selected.
const germanMarketplaceCities = <String>[
  'Berlin',
  'Hamburg',
  'München',
  'Köln',
  'Frankfurt am Main',
  'Stuttgart',
  'Düsseldorf',
  'Leipzig',
  'Dortmund',
  'Essen',
  'Bremen',
  'Dresden',
  'Hannover',
  'Nürnberg',
  'Bonn',
  'Halle (Saale)',
  'Magdeburg',
  'Karlsruhe',
  'Mannheim',
  'Augsburg',
];

class CategoryProductsScreen extends ConsumerStatefulWidget {
  const CategoryProductsScreen({required this.categoryId, super.key});

  final String categoryId;

  @override
  ConsumerState<CategoryProductsScreen> createState() =>
      _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends ConsumerState<CategoryProductsScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final category = ref.watch(categoryByIdProvider(widget.categoryId));
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
              ref.invalidate(categoryProductsProvider(widget.categoryId));
              await ref.read(categoryProductsProvider(widget.categoryId).future);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      0,
                    ),
                    child: AppTextField(
                      controller: _searchController,
                      hint: l10n.categorySearchInCategory,
                      prefix: const Icon(Icons.search_rounded),
                      suffix: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(
                                      categoryProductsFilterProvider(
                                        widget.categoryId,
                                      ).notifier,
                                    )
                                    .setSearchQuery(null);
                              },
                            ),
                      onChanged: (value) {
                        setState(() {});
                        ref
                            .read(
                              categoryProductsFilterProvider(
                                widget.categoryId,
                              ).notifier,
                            )
                            .setSearchQuery(value);
                      },
                    ),
                  ),
                ),
                _SubcategoryRail(categoryId: widget.categoryId),
                _FilterBar(categoryId: widget.categoryId),
                _ResultsSection(categoryId: widget.categoryId),
                _LoadMoreSection(categoryId: widget.categoryId),
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
    final filter = ref.watch(categoryProductsFilterProvider(categoryId));
    final filterNotifier =
        ref.read(categoryProductsFilterProvider(categoryId).notifier);

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
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
                _ViewModeToggle(categoryId: categoryId),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: <Widget>[
                Expanded(
                  child: SizedBox(
                    height: AppSizes.chipHeight,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: <Widget>[
                        _FilterChip(
                          key: const ValueKey('seller-kind-chip'),
                          label: filter.sellerKind ==
                                  CategoryProductSellerKindFilter.all
                              ? l10n.filterSellerKindAll
                              : switch (filter.sellerKind) {
                                  CategoryProductSellerKindFilter.private =>
                                    l10n.filterSellerKindPrivate,
                                  CategoryProductSellerKindFilter.business =>
                                    l10n.filterSellerKindBusiness,
                                  CategoryProductSellerKindFilter.all =>
                                    l10n.filterSellerKindAll,
                                },
                          selected:
                              filter.sellerKind !=
                              CategoryProductSellerKindFilter.all,
                          onTap: () => _showSellerKindSheet(
                            context,
                            ref,
                            categoryId,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _FilterChip(
                          key: const ValueKey('city-chip'),
                          label: filter.city ?? l10n.filterCityAll,
                          selected: filter.city != null,
                          onTap: () =>
                              _showCitySheet(context, ref, categoryId),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _SortMenu(
                          categoryId: categoryId,
                          sortLabel: sortLabel,
                          filter: filter,
                          filterNotifier: filterNotifier,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSellerKindSheet(
    BuildContext context,
    WidgetRef ref,
    String categoryId,
  ) {
    final l10n = context.l10n;
    final filter = ref.read(categoryProductsFilterProvider(categoryId));
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                l10n.filterSellerKindLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final (value, label) in <(
              CategoryProductSellerKindFilter,
              String
            )>[
              (
                CategoryProductSellerKindFilter.all,
                l10n.filterSellerKindAll
              ),
              (
                CategoryProductSellerKindFilter.private,
                l10n.filterSellerKindPrivate
              ),
              (
                CategoryProductSellerKindFilter.business,
                l10n.filterSellerKindBusiness
              ),
            ])
              RadioGroup<CategoryProductSellerKindFilter>(
                groupValue: filter.sellerKind,
                onChanged: (selected) {
                  ref
                      .read(categoryProductsFilterProvider(categoryId).notifier)
                      .setSellerKind(
                        selected ?? CategoryProductSellerKindFilter.all,
                      );
                  Navigator.of(context).pop();
                },
                child: ListTile(
                  leading: Radio<CategoryProductSellerKindFilter>(
                    value: value,
                  ),
                  title: Text(label),
                  onTap: () {
                    ref
                        .read(
                          categoryProductsFilterProvider(
                            categoryId,
                          ).notifier,
                        )
                        .setSellerKind(value);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  void _showCitySheet(
    BuildContext context,
    WidgetRef ref,
    String categoryId,
  ) {
    final l10n = context.l10n;
    final filter = ref.read(categoryProductsFilterProvider(categoryId));
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          builder: (context, scrollController) => CustomScrollView(
            controller: scrollController,
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    l10n.filterCityTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: RadioGroup<String?>(
                  groupValue: filter.city,
                  onChanged: (selected) {
                    ref
                        .read(categoryProductsFilterProvider(categoryId).notifier)
                        .setCity(selected);
                    Navigator.of(context).pop();
                  },
                  child: ListTile(
                    leading: const Radio<String?>(value: null),
                    title: Text(l10n.filterCityAll),
                    onTap: () {
                      ref
                          .read(
                            categoryProductsFilterProvider(
                              categoryId,
                            ).notifier,
                          )
                          .setCity(null);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
              SliverList.builder(
                itemCount: germanMarketplaceCities.length,
                itemBuilder: (context, index) {
                  final city = germanMarketplaceCities[index];
                  return RadioGroup<String?>(
                    groupValue: filter.city,
                    onChanged: (selected) {
                      ref
                          .read(
                            categoryProductsFilterProvider(
                              categoryId,
                            ).notifier,
                          )
                          .setCity(selected);
                      Navigator.of(context).pop();
                    },
                    child: ListTile(
                      leading: Radio<String?>(value: city),
                      title: Text(city),
                      onTap: () {
                        ref
                            .read(
                              categoryProductsFilterProvider(
                                categoryId,
                              ).notifier,
                            )
                            .setCity(city);
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                },
              ),
              const SliverPadding(padding: EdgeInsets.all(AppSpacing.md)),
            ],
          ),
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
    super.key,
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

class _ViewModeToggle extends ConsumerWidget {
  const _ViewModeToggle({required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(categoryProductsFilterProvider(categoryId));
    final isGrid = filter.viewMode == CategoryProductViewMode.grid;

    return Semantics(
      label: isGrid ? l10n.categoryViewList : l10n.categoryViewGrid,
      button: true,
      child: IconButton(
        tooltip: isGrid ? l10n.categoryViewList : l10n.categoryViewGrid,
        onPressed: () => ref
            .read(categoryProductsFilterProvider(categoryId).notifier)
            .setViewMode(
              isGrid
                  ? CategoryProductViewMode.list
                  : CategoryProductViewMode.grid,
            ),
        icon: Icon(isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded),
      ),
    );
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({
    required this.categoryId,
    required this.sortLabel,
    required this.filter,
    required this.filterNotifier,
  });

  final String categoryId;
  final String sortLabel;
  final CategoryProductsFilterState filter;
  final CategoryProductsFilter filterNotifier;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<CategoryProductSort>(
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
    );
  }
}

class _ResultsSection extends ConsumerWidget {
  const _ResultsSection({required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(categoryProductsProvider(categoryId));
    final filter = ref.watch(categoryProductsFilterProvider(categoryId));

    return switch (products) {
      AsyncData<List<HomeProduct>>(:final value) when value.isNotEmpty =>
        filter.viewMode == CategoryProductViewMode.grid
            ? _ProductGrid(categoryId: categoryId, products: value)
            : _ProductList(products: value),
      AsyncData<List<HomeProduct>>() => const SliverFillRemaining(
        hasScrollBody: false,
        child: _ResultsEmptyState(),
      ),
      AsyncError<List<HomeProduct>>() => SliverFillRemaining(
        hasScrollBody: false,
        child: AppErrorState(
          title: context.l10n.stateErrorTitle,
          message: context.l10n.stateErrorMessage,
          retryLabel: context.l10n.actionRetry,
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

class _ResultsEmptyState extends ConsumerWidget {
  const _ResultsEmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return AppEmptyState(
      title: l10n.categoryProductsEmptyTitle,
      message: l10n.categoryProductsEmptyBody,
      icon: Icons.inventory_2_outlined,
    );
  }
}

class _LoadMoreSection extends ConsumerWidget {
  const _LoadMoreSection({required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final products = ref.watch(categoryProductsProvider(categoryId));
    final notifier = ref.read(categoryProductsProvider(categoryId).notifier);
    final data = products.asData?.value;

    return SliverToBoxAdapter(
      child: switch (products) {
        AsyncLoading<List<HomeProduct>>() when data != null =>
          const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        AsyncData<List<HomeProduct>>(:final value) when value.isNotEmpty =>
          notifier.hasMore
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Center(
                    child: AppButton(
                      label: l10n.categoryProductsLoadMore,
                      variant: AppButtonVariant.secondary,
                      onPressed: () => notifier.loadMore(),
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Center(
                    child: Text(
                      l10n.categoryProductsNoMore,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _ProductGrid extends ConsumerWidget {
  const _ProductGrid({required this.categoryId, required this.products});

  final String categoryId;
  final List<HomeProduct> products;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverPadding(
      padding: const EdgeInsets.all(AppSpacing.md),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final columnCount =
              constraints.crossAxisExtent >= AppSizes.compactBreakpoint ? 3 : 2;
          return SliverGrid.builder(
            itemCount: products.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columnCount,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              mainAxisExtent: AppSizes.categoryProductCardHeight,
            ),
            itemBuilder: (context, index) {
              final product = products[index];
              return _CategoryProductCard(
                product: product,
                grid: true,
              );
            },
          );
        },
      ),
    );
  }
}

class _ProductList extends StatelessWidget {
  const _ProductList({required this.products});

  final List<HomeProduct> products;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(AppSpacing.md),
      sliver: SliverList.separated(
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) =>
            _CategoryProductCard(product: products[index], grid: false),
      ),
    );
  }
}

class _CategoryProductCard extends StatelessWidget {
  const _CategoryProductCard({required this.product, required this.grid});

  final HomeProduct product;
  final bool grid;

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
      aspectRatio: grid ? AppRatios.widescreen : AppRatios.square,
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
