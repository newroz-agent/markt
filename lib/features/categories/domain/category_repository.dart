import 'package:zerin_marketplace/features/categories/domain/marketplace_category.dart';

abstract interface class CategoryRepository {
  Future<List<MarketplaceCategory>> fetchActiveCategories();
}
