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
    this.sort = CategoryProductSort.newest,
  });

  final String? subcategoryId;
  final CategoryProductConditionFilter condition;
  final CategoryProductSort sort;

  CategoryProductsFilterState copyWith({
    Object? subcategoryId = _sentinel,
    CategoryProductConditionFilter? condition,
    CategoryProductSort? sort,
  }) {
    return CategoryProductsFilterState(
      subcategoryId: subcategoryId == _sentinel
          ? this.subcategoryId
          : subcategoryId as String?,
      condition: condition ?? this.condition,
      sort: sort ?? this.sort,
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

  void setSort(CategoryProductSort sort) {
    state = state.copyWith(sort: sort);
  }
}

@riverpod
Future<List<HomeProduct>> categoryProducts(
  CategoryProductsRef ref,
  String categoryId,
) async {
  final query = ref.watch(categoryProductsFilterProvider(categoryId));
  final children = await ref.watch(categoryChildrenProvider(categoryId).future);

  // A selected subcategory narrows to itself; otherwise the whole subtree
  // (the category plus its children) is queried.
  final ids = switch (query.subcategoryId) {
    final subcategoryId?
        when children.any((child) => child.id == subcategoryId) =>
      <String>[subcategoryId],
    _ => <String>[categoryId, for (final child in children) child.id],
  };

  return ref
      .watch(categoryProductsRepositoryProvider)
      .fetchCategoryProducts(
        CategoryProductsQuery(
          categoryIds: ids,
          condition: query.condition,
          sort: query.sort,
        ),
      );
}
