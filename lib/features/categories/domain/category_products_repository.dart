import 'package:flutter/foundation.dart';

import 'package:zerin_marketplace/features/home/domain/home_feed.dart';

enum CategoryProductConditionFilter { all, isNew, isUsed }

/// Public seller type. Values mirror `public.seller_kind`.
enum CategoryProductSellerKindFilter { all, private, business }

enum CategoryProductSort { newest, priceAscending, priceDescending }

/// View mode for the results surface. Grid and list share one query state so
/// map/list synchronization (Phase 9) can reuse it.
enum CategoryProductViewMode { grid, list }

@immutable
class CategoryProductsQuery {
  const CategoryProductsQuery({
    required this.categoryIds,
    this.condition = CategoryProductConditionFilter.all,
    this.sellerKind = CategoryProductSellerKindFilter.all,
    this.sort = CategoryProductSort.newest,
    this.city,
    this.query,
    this.limit = 24,
    this.offset = 0,
  });

  final List<String> categoryIds;
  final CategoryProductConditionFilter condition;
  final CategoryProductSellerKindFilter sellerKind;
  final CategoryProductSort sort;

  /// Germany-only: this filters on the listing's German city label.
  final String? city;

  /// In-category free-text search over titles (search-ready architecture;
  /// the global search experience builds on the same server pattern).
  final String? query;

  final int limit;
  final int offset;

  CategoryProductsQuery copyWith({
    List<String>? categoryIds,
    CategoryProductConditionFilter? condition,
    CategoryProductSellerKindFilter? sellerKind,
    CategoryProductSort? sort,
    Object? city = _sentinel,
    Object? searchQuery = _sentinel,
    int? limit,
    int? offset,
  }) {
    return CategoryProductsQuery(
      categoryIds: categoryIds ?? this.categoryIds,
      condition: condition ?? this.condition,
      sellerKind: sellerKind ?? this.sellerKind,
      sort: sort ?? this.sort,
      city: city == _sentinel ? this.city : city as String?,
      query: searchQuery == _sentinel ? query : searchQuery as String?,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  static const _sentinel = Object();
}

abstract class CategoryProductsRepository {
  Future<List<HomeProduct>> fetchCategoryProducts(CategoryProductsQuery query);
}

class UnconfiguredCategoryProductsRepository
    implements CategoryProductsRepository {
  const UnconfiguredCategoryProductsRepository();

  @override
  Future<List<HomeProduct>> fetchCategoryProducts(
    CategoryProductsQuery query,
  ) async => const <HomeProduct>[];
}
