import 'package:zerin_marketplace/features/home/domain/home_feed.dart';

abstract interface class HomeRepository {
  Future<HomeFeed> fetchHomeFeed({int limit = 10});

  /// Public active, in-stock product from an approved Germany-scoped seller.
  /// Owner/admin access does not make drafts visible through this method.
  Future<HomeProduct?> fetchProduct(String productId);

  /// Public profile of an approved Germany-scoped seller, or null.
  Future<MarketplaceStore?> fetchSeller(String sellerId);

  /// Germany-scoped active listings, newest first with an ID tie-breaker.
  /// A short page means the end; excludeProductId is filtered before paging.
  /// offset must be nonnegative and limit must be between 1 and 100.
  Future<List<HomeProduct>> fetchSellerProducts(
    String sellerId, {
    int offset = 0,
    int limit = 24,
    String? excludeProductId,
  });

  /// Active listings from the same category, excluding the given product.
  Future<List<HomeProduct>> fetchSimilarProducts({
    required String productId,
    required String categoryId,
  });

  /// Whether the signed-in user has favorited this product.
  Future<bool> fetchFavoriteState(String productId);

  /// The signed-in user's favorited active listings, newest favorite first.
  Future<List<HomeProduct>> fetchFavoriteProducts();

  /// The signed-in user's recently viewed active listings, most recent first.
  Future<List<HomeProduct>> fetchRecentlyViewedProducts();

  /// Records a product view for the signed-in user through the existing RPC.
  /// Callers must only invoke this for an explicit detail open, never previews.
  Future<void> recordProductView(String productId);

  /// Adds or removes the product favorite for the signed-in user.
  Future<void> setFavorite({required String productId, required bool favorite});

  /// Files a listing report with an enum-backed reason.
  Future<void> reportProduct({
    required String productId,
    required String reason,
    String? details,
  });
}
