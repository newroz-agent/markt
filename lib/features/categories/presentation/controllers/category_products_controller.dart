import 'package:flutter/foundation.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:zerin_marketplace/core/providers/infrastructure_providers.dart';
import 'package:zerin_marketplace/features/categories/data/supabase_category_products_repository.dart';
import 'package:zerin_marketplace/features/categories/domain/category_products_repository.dart';
import 'package:zerin_marketplace/features/categories/domain/marketplace_category.dart';
import 'package:zerin_marketplace/features/categories/presentation/controllers/category_controller.dart';
import 'package:zerin_marketplace/features/home/domain/home_feed.dart';

part 'category_products_controller.g.dart';

@Riverpod(keepAlive: true)
CategoryProductsRepository categoryProductsRepository(
  CategoryProductsRepositoryRef ref,
) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? const UnconfiguredCategoryProductsRepository()
      : SupabaseCategoryProductsRepository(client);
}

@riverpod
Future<List<MarketplaceCategory>> categoryChildren(
  CategoryChildrenRef ref,
  String categoryId,
) async {
  final categories = await ref.watch(activeCategoriesProvider.future);
  return categories
      .where((category) => category.parentId == categoryId)
      .toList(growable: false);
}

@riverpod
Future<MarketplaceCategory?> categoryById(
  CategoryByIdRef ref,
  String categoryId,
) async {
  final categories = await ref.watch(activeCategoriesProvider.future);
  for (final category in categories) {
    if (category.id == categoryId) return category;
  }
  return null;
}

@immutable
class CategoryProductsFilterState {
  const CategoryProductsFilterState({
    this.subcategoryId,
    this.condition = CategoryProductConditionFilter.all,
    this.sellerKind = CategoryProductSellerKindFilter.all,
    this.sort = CategoryProductSort.newest,
    this.viewMode = CategoryProductViewMode.grid,
    this.city,
    this.searchQuery,
  });

  final String? subcategoryId;
  final CategoryProductConditionFilter condition;
  final CategoryProductSellerKindFilter sellerKind;
  final CategoryProductSort sort;
  final CategoryProductViewMode viewMode;

  /// Germany-only city filter; null means "Überall" (no restriction).
  final String? city;
  final String? searchQuery;

  CategoryProductsFilterState copyWith({
    Object? subcategoryId = _sentinel,
    CategoryProductConditionFilter? condition,
    CategoryProductSellerKindFilter? sellerKind,
    CategoryProductSort? sort,
    CategoryProductViewMode? viewMode,
    Object? city = _sentinel,
    Object? searchQuery = _sentinel,
  }) {
    return CategoryProductsFilterState(
      subcategoryId: subcategoryId == _sentinel
          ? this.subcategoryId
          : subcategoryId as String?,
      condition: condition ?? this.condition,
      sellerKind: sellerKind ?? this.sellerKind,
      sort: sort ?? this.sort,
      viewMode: viewMode ?? this.viewMode,
      city: city == _sentinel ? this.city : city as String?,
      searchQuery: searchQuery == _sentinel
          ? this.searchQuery
          : searchQuery as String?,
    );
  }

  static const _sentinel = Object();
}

@riverpod
class CategoryProductsFilter extends _$CategoryProductsFilter {
  @override
  CategoryProductsFilterState build(String categoryId) =>
      const CategoryProductsFilterState();

  void selectSubcategory(String? subcategoryId) {
    state = state.copyWith(subcategoryId: subcategoryId);
  }

  void setCondition(CategoryProductConditionFilter condition) {
    state = state.copyWith(condition: condition);
  }

  void setSellerKind(CategoryProductSellerKindFilter sellerKind) {
    state = state.copyWith(sellerKind: sellerKind);
  }

  void setSort(CategoryProductSort sort) {
    state = state.copyWith(sort: sort);
  }

  void setViewMode(CategoryProductViewMode viewMode) {
    state = state.copyWith(viewMode: viewMode);
  }

  void setCity(String? city) {
    state = state.copyWith(city: city);
  }

  void setSearchQuery(String? searchQuery) {
    final trimmed = searchQuery?.trim();
    state = state.copyWith(
      searchQuery: trimmed == null || trimmed.isEmpty ? null : trimmed,
    );
  }
}

@riverpod
class CategoryProducts extends _$CategoryProducts {
  static const _pageSize = 24;

  @override
  Future<List<HomeProduct>> build(String categoryId) async {
    final query = ref.watch(categoryProductsFilterProvider(categoryId));
    final children = await ref.watch(categoryChildrenProvider(categoryId).future);

    // A selected subcategory narrows to itself; otherwise the whole subtree
    // (the category plus its children) is queried.
    final ids = switch (query.subcategoryId) {
      final subcategoryId? when children.any(
        (child) => child.id == subcategoryId,
      ) =>
        <String>[subcategoryId],
      _ => <String>[categoryId, for (final child in children) child.id],
    };

    return ref
        .watch(categoryProductsRepositoryProvider)
        .fetchCategoryProducts(
          CategoryProductsQuery(
            categoryIds: ids,
            condition: query.condition,
            sellerKind: query.sellerKind,
            sort: query.sort,
            city: query.city,
            query: query.searchQuery,
            // Default page size (24) matches _pageSize used by hasMore.
          ),
        );
  }

  bool get hasMore {
    final value = state.asData?.value;
    return value != null && value.length >= _pageSize;
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || current.length < _pageSize) return;
    if (state.isLoading || state.isRefreshing) return;

    state = await AsyncValue.guard(() async {
      final query = ref.read(categoryProductsFilterProvider(categoryId));
      final children = await ref.read(
        categoryChildrenProvider(categoryId).future,
      );
      final ids = switch (query.subcategoryId) {
        final subcategoryId? when children.any(
          (child) => child.id == subcategoryId,
        ) =>
          <String>[subcategoryId],
        _ => <String>[categoryId, for (final child in children) child.id],
      };
      final older = await ref
          .read(categoryProductsRepositoryProvider)
          .fetchCategoryProducts(
            CategoryProductsQuery(
              categoryIds: ids,
              condition: query.condition,
              sellerKind: query.sellerKind,
              sort: query.sort,
              city: query.city,
              query: query.searchQuery,
              // Default page size (24) matches _pageSize used by hasMore.
              offset: current.length,
            ),
          );
      final known = {
        for (final product in current) product.id,
      };
      return [
        ...current,
        // Live feeds can shift; never emit a duplicate row.
        for (final product in older)
          if (known.add(product.id)) product,
      ];
    });
  }
}
