import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:zerin_marketplace/core/errors/app_exception.dart';
import 'package:zerin_marketplace/features/home/domain/home_feed.dart';
import 'package:zerin_marketplace/features/home/domain/home_repository.dart';

class SupabaseHomeRepository implements HomeRepository {
  SupabaseHomeRepository(this._client);

  static const _campaignColumns =
      'id, slug, title_i18n, subtitle_i18n, image_url, sort_order';

  static const _storeColumns =
      'id, slug, shop_name, bio, avatar_url, banner_url, city, '
      'rating_average, rating_count, response_time_minutes';

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
  Future<HomeFeed> fetchHomeFeed({int limit = 10}) async {
    try {
      final campaignsFuture = _client
          .from('ad_campaigns')
          .select(_campaignColumns)
          .eq('is_active', true)
          .order('sort_order', ascending: true);
      final newestFuture = _productQuery(limit: limit);
      final dealsFuture = _productQuery(limit: limit, discountedOnly: true);
      final storesFuture = _client
          .from('sellers')
          .select(_storeColumns)
          .eq('status', 'approved')
          .order('rating_average', ascending: false)
          .order('rating_count', ascending: false)
          .limit(8);

      final rows = await Future.wait<dynamic>(<Future<dynamic>>[
        campaignsFuture,
        newestFuture,
        dealsFuture,
        storesFuture,
      ]);

      return HomeFeed(
        campaigns: _mapRows(rows[0], AdCampaign.fromJson),
        newArrivals: _mapRows(rows[1], HomeProduct.fromJson),
        deals: _mapRows(rows[2], HomeProduct.fromJson),
        popularStores: _mapRows(rows[3], MarketplaceStore.fromJson),
      );
    } on PostgrestException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        AppException(AppFailureCode.unknown, cause: error),
        stackTrace,
      );
    }
  }

  @override
  Future<HomeProduct?> fetchProduct(String productId) async {
    try {
      final row = await _client
          .from('products')
          .select(_productColumns)
          .eq('id', productId)
          .maybeSingle();
      return row == null ? null : HomeProduct.fromJson(row);
    } on PostgrestException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        AppException(AppFailureCode.unknown, cause: error),
        stackTrace,
      );
    }
  }

  Future<dynamic> _productQuery({
    required int limit,
    bool discountedOnly = false,
  }) {
    var query = _client
        .from('products')
        .select(_productColumns)
        .eq('status', 'active')
        .gt('quantity', 0);
    if (discountedOnly) {
      query = query.not('compare_at_price_cents', 'is', null);
    }
    return query.order('published_at', ascending: false).limit(limit);
  }

  List<T> _mapRows<T>(dynamic rows, T Function(Map<String, dynamic>) fromJson) {
    if (rows is! List) return const <Never>[] as List<T>;
    return rows
        .map((row) => fromJson(Map<String, dynamic>.from(row as Map)))
        .toList(growable: false);
  }
}
