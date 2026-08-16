import 'package:zerin_marketplace/core/errors/app_exception.dart';
import 'package:zerin_marketplace/features/categories/domain/category_repository.dart';
import 'package:zerin_marketplace/features/categories/domain/marketplace_category.dart';

class UnconfiguredCategoryRepository implements CategoryRepository {
  const UnconfiguredCategoryRepository();

  @override
  Future<List<MarketplaceCategory>> fetchActiveCategories() =>
      Future<List<MarketplaceCategory>>.error(
        const AppException(AppFailureCode.backendNotConfigured),
      );
}
