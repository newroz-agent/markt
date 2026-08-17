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
}
