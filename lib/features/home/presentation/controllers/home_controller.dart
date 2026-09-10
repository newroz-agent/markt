import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:zerin_marketplace/core/providers/infrastructure_providers.dart';
import 'package:zerin_marketplace/features/home/data/supabase_home_repository.dart';
import 'package:zerin_marketplace/features/home/data/unconfigured_home_repository.dart';
import 'package:zerin_marketplace/features/home/domain/home_feed.dart';
import 'package:zerin_marketplace/features/home/domain/home_repository.dart';

part 'home_controller.g.dart';

@Riverpod(keepAlive: true)
HomeRepository homeRepository(HomeRepositoryRef ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? const UnconfiguredHomeRepository()
      : SupabaseHomeRepository(client);
}

@riverpod
Future<HomeFeed> homeFeed(HomeFeedRef ref) =>
    ref.watch(homeRepositoryProvider).fetchHomeFeed();

@riverpod
Future<HomeProduct?> homeProduct(
  HomeProductRef ref, {
  required String productId,
}) => ref.watch(homeRepositoryProvider).fetchProduct(productId);

@riverpod
Future<MarketplaceStore?> sellerProfile(
  SellerProfileRef ref, {
  required String sellerId,
}) => ref.watch(homeRepositoryProvider).fetchSeller(sellerId);

@riverpod
Future<List<HomeProduct>> sellerProducts(
  SellerProductsRef ref, {
  required String sellerId,
  int offset = 0,
  int limit = 24,
  String? excludeProductId,
}) => ref
    .watch(homeRepositoryProvider)
    .fetchSellerProducts(
      sellerId,
      offset: offset,
      limit: limit,
      excludeProductId: excludeProductId,
    );

@riverpod
Future<List<HomeProduct>> similarProducts(
  SimilarProductsRef ref, {
  required String productId,
  required String categoryId,
}) => ref
    .watch(homeRepositoryProvider)
    .fetchSimilarProducts(productId: productId, categoryId: categoryId);
