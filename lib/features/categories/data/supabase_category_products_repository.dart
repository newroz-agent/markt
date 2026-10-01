import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:zerin_marketplace/core/errors/app_exception.dart';
import 'package:zerin_marketplace/core/storage/product_image_url_resolver.dart';
import 'package:zerin_marketplace/features/categories/domain/category_products_repository.dart';
import 'package:zerin_marketplace/features/home/domain/home_feed.dart';

class SupabaseCategoryProductsRepository implements CategoryProductsRepository {
  SupabaseCategoryProductsRepository(this._client);

  static const _productColumns =
      'id, slug, title, description, condition, price_cents, '
      'compare_at_price_cents, currency, vat_rate, price_includes_vat, '
      'free_shipping, shipping_cost_cents, rating_average, rating_count, '
      'city, country_code, published_at, '
      'seller:sellers!inner(id, slug, shop_name, bio, avatar_url, '
      'banner_url, city, country_code, rating_average, rating_count, '
      'response_time_minutes, kind), '
      'images:product_images(image_url, storage_path, sort_order)';

  final SupabaseClient _client;
  late final ProductImageUrlResolver _imageUrls = ProductImageUrlResolver(
    _client,
  );

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

      switch (query.sellerKind) {
        case CategoryProductSellerKindFilter.private:
          request = request.eq('seller.kind', 'private');
        case CategoryProductSellerKindFilter.business:
          request = request.eq('seller.kind', 'business');
        case CategoryProductSellerKindFilter.all:
          break;
      }

      // Germany-only marketplace: cities are German labels set on listings.
      final city = query.city?.trim();
      if (city != null && city.isNotEmpty) {
        request = request.eq('city', city);
      }

      final search = query.query?.trim();
      if (search != null && search.isNotEmpty) {
        request = request.ilike('title', '%$search%');
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

      final rows = await sorted.range(
        query.offset,
        query.offset + query.limit - 1,
      );
      final resolvedRows = await _imageUrls.resolveRows(rows);
      return resolvedRows.map(HomeProduct.fromJson).toList(growable: false);
    } on PostgrestException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        AppException(AppFailureCode.unknown, cause: error),
        stackTrace,
      );
    }
  }
}
