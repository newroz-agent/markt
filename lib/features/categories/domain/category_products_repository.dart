import 'package:flutter/foundation.dart';

import 'package:zerin_marketplace/features/home/domain/home_feed.dart';

enum CategoryProductConditionFilter { all, isNew, isUsed }

enum CategoryProductSort { newest, priceAscending, priceDescending }

@immutable
class CategoryProductsQuery {
  const CategoryProductsQuery({
    required this.categoryIds,
    this.condition = CategoryProductConditionFilter.all,
    this.sort = CategoryProductSort.newest,
    this.limit = 60,
  });

  final List<String> categoryIds;
  final CategoryProductConditionFilter condition;
  final CategoryProductSort sort;
  final int limit;
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
