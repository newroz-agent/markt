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
