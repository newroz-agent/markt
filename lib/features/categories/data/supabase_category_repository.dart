import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:zerin_marketplace/core/errors/app_exception.dart';
import 'package:zerin_marketplace/features/categories/domain/category_repository.dart';
import 'package:zerin_marketplace/features/categories/domain/marketplace_category.dart';

class SupabaseCategoryRepository implements CategoryRepository {
  SupabaseCategoryRepository(this._client);

  static const _columns =
      'id, parent_id, slug, name_de, name_en, name_ar, name_tr, name_ku, '
      'icon_key, image_url, sort_order';

  final SupabaseClient _client;

  @override
  Future<List<MarketplaceCategory>> fetchActiveCategories() async {
    try {
      final rows = await _client
          .from('categories')
          .select(_columns)
          .eq('is_active', true)
          .order('sort_order', ascending: true)
          .order('name_de', ascending: true);

      return rows.map(MarketplaceCategory.fromJson).toList(growable: false);
    } on PostgrestException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        AppException(AppFailureCode.unknown, cause: error),
        stackTrace,
      );
    }
  }
}
