import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:zerin_marketplace/core/errors/app_exception.dart';
import 'package:zerin_marketplace/features/home/domain/home_feed.dart';
import 'package:zerin_marketplace/features/home/domain/home_repository.dart';

class SupabaseHomeRepository implements HomeRepository {
  SupabaseHomeRepository(this._client);

  static const _campaignColumns =
      'id, slug, title_i18n, subtitle_i18n, image_url, sort_order';

  static const _storeColumns =
      'id, slug, shop_name, bio, avatar_url, banner_url, city, country_code, '
      'rating_average, rating_count, response_time_minutes, kind';

  static const _productColumns =
      'id, slug, title, description, condition, price_cents, '
      'compare_at_price_cents, currency, vat_rate, price_includes_vat, '
      'free_shipping, shipping_cost_cents, rating_average, rating_count, '
      'city, country_code, category_id, specifications, brand:brands(name), published_at, '
      'seller:sellers!inner(id, slug, shop_name, bio, avatar_url, '
      'banner_url, city, country_code, rating_average, rating_count, '
      'response_time_minutes, kind), '
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
      final newestFuture = _homeProductQuery(limit: limit);
      final dealsFuture = _homeProductQuery(limit: limit, discountedOnly: true);
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
      final row = await _publicProducts().eq('id', productId).maybeSingle();
      if (row == null) return null;
      return HomeProduct.fromJson(row);
    } on PostgrestException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        AppException(AppFailureCode.unknown, cause: error),
        stackTrace,
      );
    }
  }

  @override
  Future<MarketplaceStore?> fetchSeller(String sellerId) async {
    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        _client
            .from('sellers')
            .select(_storeColumns)
            .eq('id', sellerId)
            .eq('status', 'approved')
            .eq('phase3_in_germany', true)
            .maybeSingle(),
        _client.rpc<bool>(
          'is_verified_seller',
          params: {'target_seller_id': sellerId},
        ),
      ]);
      final row = results[0];
      if (row == null) return null;
      return MarketplaceStore.fromJson({
        ...Map<String, dynamic>.from(row as Map),
        'verified': results[1] == true,
      });
    } on PostgrestException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        AppException(AppFailureCode.unknown, cause: error),
        stackTrace,
      );
    }
  }

  @override
  Future<List<HomeProduct>> fetchSellerProducts(
    String sellerId, {
    int offset = 0,
    int limit = 24,
    String? excludeProductId,
  }) async {
    if (offset < 0) throw ArgumentError.value(offset, 'offset');
    if (limit < 1 || limit > 100) throw ArgumentError.value(limit, 'limit');
    try {
      final rows = await _productQuery(
        sellerId: sellerId,
        offset: offset,
        limit: limit,
        excludeProductId: excludeProductId,
      );
      return _mapRows(rows, HomeProduct.fromJson);
    } on PostgrestException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        AppException(AppFailureCode.unknown, cause: error),
        stackTrace,
      );
    }
  }

  @override
  Future<List<HomeProduct>> fetchSimilarProducts({
    required String productId,
    required String categoryId,
  }) async {
    try {
      final rows = await _productQuery(
        categoryId: categoryId,
        excludeProductId: productId,
        limit: 8,
      );
      return _mapRows(rows, HomeProduct.fromJson);
    } on PostgrestException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        AppException(AppFailureCode.unknown, cause: error),
        stackTrace,
      );
    }
  }

  @override
  Future<bool> fetchFavoriteState(String productId) async {
    final userId = _requireUser();
    try {
      final rows = await _client
          .from('favorites')
          .select('product_id')
          .eq('user_id', userId)
          .eq('product_id', productId)
          .limit(1);
      return rows.isNotEmpty;
    } on PostgrestException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        AppException(AppFailureCode.unknown, cause: error),
        stackTrace,
      );
    }
  }

  @override
  Future<void> setFavorite({
    required String productId,
    required bool favorite,
  }) async {
    final userId = _requireUser();
    try {
      if (favorite) {
        await _client
            .from('favorites')
            .upsert(
              {'user_id': userId, 'product_id': productId},
              onConflict: 'user_id,product_id',
              ignoreDuplicates: true,
            );
      } else {
        await _client
            .from('favorites')
            .delete()
            .eq('user_id', userId)
            .eq('product_id', productId);
      }
    } on PostgrestException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        AppException(AppFailureCode.unknown, cause: error),
        stackTrace,
      );
    }
  }

  @override
  Future<void> reportProduct({
    required String productId,
    required String reason,
    String? details,
  }) async {
    _requireUser();
    try {
      await _client.from('reports').insert({
        'product_id': productId,
        'reporter_id': _requireUser(),
        // Enum-backed reason; validated server-side.
        'reason': reason,
        if (details != null && details.trim().isNotEmpty)
          'details': details.trim(),
      });
    } on PostgrestException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        AppException(AppFailureCode.unknown, cause: error),
        stackTrace,
      );
    }
  }

  String _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) throw const AppException(AppFailureCode.notAuthenticated);
    return user.id;
  }

  // Home retains its pre-Phase3 behavior, including unknown-country entries.
  Future<dynamic> _homeProductQuery({
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

  // Phase3 requires explicit seller AND item countries, including for pickup.
  PostgrestFilterBuilder<List<Map<String, dynamic>>> _publicProducts() =>
      _client
          .from('products')
          .select(_productColumns)
          .eq('status', 'active')
          .eq('seller.status', 'approved')
          .eq('seller.phase3_in_germany', true)
          .eq('country_code', 'DE')
          .gt('quantity', 0);

  Future<dynamic> _productQuery({
    required int limit,
    int offset = 0,
    bool discountedOnly = false,
    String? sellerId,
    String? categoryId,
    String? excludeProductId,
  }) {
    var query = _publicProducts();
    if (sellerId != null) query = query.eq('seller_id', sellerId);
    if (categoryId != null) query = query.eq('category_id', categoryId);
    if (excludeProductId != null) query = query.neq('id', excludeProductId);
    if (discountedOnly) {
      query = query.not('compare_at_price_cents', 'is', null);
    }
    return query
        .order('published_at', ascending: false)
        .order('id', ascending: true)
        .range(offset, offset + limit - 1);
  }

  List<T> _mapRows<T>(dynamic rows, T Function(Map<String, dynamic>) fromJson) {
    if (rows is! List) return const <Never>[] as List<T>;
    return rows
        .map((row) => fromJson(Map<String, dynamic>.from(row as Map)))
        .toList(growable: false);
  }
}
