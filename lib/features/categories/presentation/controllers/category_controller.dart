import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:zerin_marketplace/core/providers/infrastructure_providers.dart';
import 'package:zerin_marketplace/features/categories/data/supabase_category_repository.dart';
import 'package:zerin_marketplace/features/categories/data/unconfigured_category_repository.dart';
import 'package:zerin_marketplace/features/categories/domain/category_repository.dart';
import 'package:zerin_marketplace/features/categories/domain/marketplace_category.dart';

part 'category_controller.g.dart';

@Riverpod(keepAlive: true)
CategoryRepository categoryRepository(CategoryRepositoryRef ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? const UnconfiguredCategoryRepository()
      : SupabaseCategoryRepository(client);
}

@Riverpod(keepAlive: true)
Future<List<MarketplaceCategory>> activeCategories(ActiveCategoriesRef ref) {
  return ref.watch(categoryRepositoryProvider).fetchActiveCategories();
}

@riverpod
Future<List<MarketplaceCategory>> rootCategories(RootCategoriesRef ref) async {
  final categories = await ref.watch(activeCategoriesProvider.future);
  return categories
      .where((category) => category.isRoot)
      .toList(growable: false);
}
