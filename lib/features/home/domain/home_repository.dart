import 'package:zerin_marketplace/features/home/domain/home_feed.dart';

abstract interface class HomeRepository {
  Future<HomeFeed> fetchHomeFeed({int limit = 10});

  Future<HomeProduct?> fetchProduct(String productId);
}
