import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:zerin_marketplace/core/errors/app_exception.dart';
import 'package:zerin_marketplace/features/categories/domain/category_products_repository.dart';
import 'package:zerin_marketplace/features/home/domain/home_feed.dart';

class SupabaseCategoryProductsRepository implements CategoryProductsRepository {
  SupabaseCategoryProductsRepository(this._client);

  static const _productColumns =
      'id, slug, title, description, condition, price_cents, '
      'compare_at_price_cents, currency, vat_rate, price_includes_vat, '
      'free_shipping, shipping_cost_cents, rating_average, rating_count, '
      'city, published_at, '
      'seller:sellers!inner(id, slug, shop_name, bio, avatar_url, '
      'banner_url, city, rating_average, rating_count, '
      'response_time_minutes), '
      'images:product_images(image_url, storage_path, sort_order)';

  final SupabaseClient _client;

  @override
  Future<List<HomeProduct>> fetchCategoryProducts(
    CategoryProductsQuery query,
  ) async {
    if (query.categoryIds.isEmpty) return const <HomeProduct>[];
    try {
      var request = _client
          .from('products')
          .select(_productColumns)
          .eq('status', 'active')
          .gt('quantity', 0)
          .inFilter('category_id', query.categoryIds);

      switch (query.condition) {
        case CategoryProductConditionFilter.isNew:
          request = request.eq('condition', 'new');
        case CategoryProductConditionFilter.isUsed:
          request = request.eq('condition', 'used');
        case CategoryProductConditionFilter.all:
          break;
      }

      final PostgrestTransformBuilder<dynamic> sorted = switch (query.sort) {
        CategoryProductSort.newest => request.order(
          'published_at',
          ascending: false,
        ),
        CategoryProductSort.priceAscending => request.order(
          'price_cents',
          ascending: true,
        ),
        CategoryProductSort.priceDescending => request.order(
          'price_cents',
          ascending: false,
        ),
      };

      final rows = await sorted.limit(query.limit);
      if (rows is! List) return const <HomeProduct>[];
      return rows
          .map(
            (row) =>
                HomeProduct.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList(growable: false);
    } on PostgrestException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        AppException(AppFailureCode.unknown, cause: error),
        stackTrace,
      );
    }
  }
}
