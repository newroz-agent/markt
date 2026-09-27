import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:zerin_marketplace/core/providers/infrastructure_providers.dart';
import 'package:zerin_marketplace/core/providers/product_realtime_provider.dart';
import 'package:zerin_marketplace/features/home/data/supabase_home_repository.dart';
import 'package:zerin_marketplace/features/home/data/unconfigured_home_repository.dart';
import 'package:zerin_marketplace/features/home/domain/home_feed.dart';
import 'package:zerin_marketplace/features/home/domain/home_repository.dart';
import 'package:zerin_marketplace/features/profile/presentation/controllers/profile_controller.dart';

part 'home_controller.g.dart';

@Riverpod(keepAlive: true)
HomeRepository homeRepository(HomeRepositoryRef ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? const UnconfiguredHomeRepository()
      : SupabaseHomeRepository(client);
}

@riverpod
Future<HomeFeed> homeFeed(HomeFeedRef ref) async {
  ref.watch(productRealtimeChangesProvider);
  final resolver = ref.watch(publicIdentityResolverProvider);
  final feed = await ref.watch(homeRepositoryProvider).fetchHomeFeed();
  // Overlay approved private-seller person identity; business stores untouched.
  final results =
      await Future.wait<List<HomeProduct>>(<Future<List<HomeProduct>>>[
        resolver.overlayProducts(feed.newArrivals),
        resolver.overlayProducts(feed.deals),
      ]);
  final popularStores = await resolver.overlayStores(feed.popularStores);
  return HomeFeed(
    campaigns: feed.campaigns,
    newArrivals: results[0],
    deals: results[1],
    popularStores: popularStores,
  );
}

@riverpod
Future<HomeProduct?> homeProduct(
  HomeProductRef ref, {
  required String productId,
}) async {
  ref.watch(productRealtimeChangesProvider);
  final product = await ref
      .watch(homeRepositoryProvider)
      .fetchProduct(productId);
  if (product == null) return null;
  final overlaid = await ref
      .watch(publicIdentityResolverProvider)
      .overlayProducts(<HomeProduct>[product]);
  return overlaid.first;
}

@riverpod
Future<MarketplaceStore?> sellerProfile(
  SellerProfileRef ref, {
  required String sellerId,
}) async {
  final store = await ref.watch(homeRepositoryProvider).fetchSeller(sellerId);
  return ref.watch(publicIdentityResolverProvider).overlayStore(store);
}

@riverpod
Future<List<HomeProduct>> sellerProducts(
  SellerProductsRef ref, {
  required String sellerId,
  int offset = 0,
  int limit = 24,
  String? excludeProductId,
}) async {
  final products = await ref
      .watch(homeRepositoryProvider)
      .fetchSellerProducts(
        sellerId,
        offset: offset,
        limit: limit,
        excludeProductId: excludeProductId,
      );
  return ref.watch(publicIdentityResolverProvider).overlayProducts(products);
}

@riverpod
Future<List<HomeProduct>> similarProducts(
  SimilarProductsRef ref, {
  required String productId,
  required String categoryId,
}) async {
  final products = await ref
      .watch(homeRepositoryProvider)
      .fetchSimilarProducts(productId: productId, categoryId: categoryId);
  return ref.watch(publicIdentityResolverProvider).overlayProducts(products);
}

@riverpod
Future<List<HomeProduct>> favoriteProducts(FavoriteProductsRef ref) async {
  ref.watch(productRealtimeChangesProvider);
  final products = await ref
      .watch(homeRepositoryProvider)
      .fetchFavoriteProducts();
  return ref.watch(publicIdentityResolverProvider).overlayProducts(products);
}

@riverpod
Future<List<HomeProduct>> recentlyViewedProducts(
  RecentlyViewedProductsRef ref,
) async {
  ref.watch(productRealtimeChangesProvider);
  final products = await ref
      .watch(homeRepositoryProvider)
      .fetchRecentlyViewedProducts();
  return ref.watch(publicIdentityResolverProvider).overlayProducts(products);
}
