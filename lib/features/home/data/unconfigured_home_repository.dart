import 'package:zerin_marketplace/core/errors/app_exception.dart';
import 'package:zerin_marketplace/features/home/domain/home_feed.dart';
import 'package:zerin_marketplace/features/home/domain/home_repository.dart';

class UnconfiguredHomeRepository implements HomeRepository {
  const UnconfiguredHomeRepository();

  @override
  Future<HomeFeed> fetchHomeFeed({int limit = 10}) => Future<HomeFeed>.error(
    const AppException(AppFailureCode.backendNotConfigured),
  );

  @override
  Future<HomeProduct?> fetchProduct(String productId) =>
      Future<HomeProduct?>.error(
        const AppException(AppFailureCode.backendNotConfigured),
      );

  @override
  Future<MarketplaceStore?> fetchSeller(String sellerId) =>
      Future<MarketplaceStore?>.error(
        const AppException(AppFailureCode.backendNotConfigured),
      );

  @override
  Future<List<HomeProduct>> fetchSellerProducts(
    String sellerId, {
    int offset = 0,
    int limit = 24,
    String? excludeProductId,
  }) => Future<List<HomeProduct>>.error(
    const AppException(AppFailureCode.backendNotConfigured),
  );

  @override
  Future<List<HomeProduct>> fetchSimilarProducts({
    required String productId,
    required String categoryId,
  }) => Future<List<HomeProduct>>.error(
    const AppException(AppFailureCode.backendNotConfigured),
  );

  @override
  Future<bool> fetchFavoriteState(String productId) => Future<bool>.error(
    const AppException(AppFailureCode.backendNotConfigured),
  );

  @override
  Future<List<HomeProduct>> fetchFavoriteProducts() =>
      Future<List<HomeProduct>>.error(
        const AppException(AppFailureCode.backendNotConfigured),
      );

  @override
  Future<List<HomeProduct>> fetchRecentlyViewedProducts() =>
      Future<List<HomeProduct>>.error(
        const AppException(AppFailureCode.backendNotConfigured),
      );

  @override
  Future<void> recordProductView(String productId) => Future<void>.error(
    const AppException(AppFailureCode.backendNotConfigured),
  );

  @override
  Future<void> setFavorite({
    required String productId,
    required bool favorite,
  }) => Future<void>.error(
    const AppException(AppFailureCode.backendNotConfigured),
  );

  @override
  Future<void> reportProduct({
    required String productId,
    required String reason,
    String? details,
  }) => Future<void>.error(
    const AppException(AppFailureCode.backendNotConfigured),
  );
}
