import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:zerin_marketplace/core/errors/app_exception.dart';
import 'package:zerin_marketplace/core/storage/product_image_url_resolver.dart';
import 'package:zerin_marketplace/features/identity/domain/identity.dart';
import 'package:zerin_marketplace/features/sell/domain/sell_models.dart';
import 'package:zerin_marketplace/features/sell/domain/sell_repository.dart';

class SupabaseSellRepository implements SellRepository {
  SupabaseSellRepository(this._client);

  static const _templateColumns =
      'id, title, category_id, condition, specifications, '
      'images:product_images(image_url, storage_path, sort_order)';
  static const _myListingColumns =
      'id, seller_id, title, price_cents, currency, city, condition, status, '
      'moderation_reason, created_at, '
      'images:product_images(image_url, storage_path, sort_order)';

  final SupabaseClient _client;
  late final ProductImageUrlResolver _imageUrls = ProductImageUrlResolver(
    _client,
  );

  @override
  Future<List<ListingTemplate>> searchTemplates(String query) async {
    try {
      var request = _client
          .from('products')
          .select(_templateColumns)
          .eq('status', 'active')
          .eq('country_code', 'DE');
      final normalized = query.trim();
      if (normalized.isNotEmpty) {
        request = request.ilike('title', '%$normalized%');
      }
      final rows = await request
          .order('published_at', ascending: false)
          .limit(12);
      final resolved = await _imageUrls.resolveRows(rows);
      return resolved.map(ListingTemplate.fromJson).toList(growable: false);
    } on PostgrestException catch (error, stackTrace) {
      _throwBackend(error, stackTrace);
    }
  }

  @override
  Future<MyListing> submitListing(SellListingDraft draft) async {
    _requireUser();
    final uploadedPaths = <String>[];
    try {
      final preparedJson = await _client.rpc<Map<String, dynamic>>(
        'prepare_listing_submission',
        params: <String, dynamic>{
          'p_seller_id': draft.identity.sellerId,
          'p_seller_kind': draft.sellerKind.databaseValue,
          'p_seller_name': draft.sellerName,
          'p_city': draft.city,
        },
      );
      final prepared = PreparedListingSubmission.fromJson(preparedJson);
      if (prepared.seller.kind != draft.sellerKind ||
          (draft.identity.sellerId != null &&
              prepared.seller.id != draft.identity.sellerId)) {
        throw const AppException(AppFailureCode.unknown);
      }
      final listingIdentity = draft.identity.withSellerId(prepared.seller.id);

      for (final (index, photo) in draft.photos.indexed) {
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final path =
            '${prepared.seller.id}/${prepared.productId}/$timestamp-$index.webp';
        await _client.storage
            .from('product-images')
            .uploadBinary(
              path,
              photo.bytes,
              fileOptions: const FileOptions(contentType: 'image/webp'),
            );
        uploadedPaths.add(path);
      }

      await _client.rpc<Map<String, dynamic>>(
        'submit_listing',
        params: <String, dynamic>{
          'p_product_id': prepared.productId,
          'p_seller_id': prepared.seller.id,
          'p_category_id': draft.categoryId,
          'p_title': draft.title.trim(),
          'p_description': draft.description.trim(),
          'p_condition': draft.condition.databaseValue,
          'p_price_cents': draft.priceCents,
          'p_compare_at_price_cents': draft.compareAtPriceCents,
          'p_city': draft.city,
          'p_image_paths': uploadedPaths,
          'p_specifications': draft.specifications,
        },
      );
      return _fetchMyListing(prepared.productId, listingIdentity);
    } on AppException {
      await _removeStaged(uploadedPaths);
      rethrow;
    } on PostgrestException catch (error, stackTrace) {
      await _removeStaged(uploadedPaths);
      _throwBackend(error, stackTrace);
    } on StorageException catch (error, stackTrace) {
      await _removeStaged(uploadedPaths);
      _throwBackend(error, stackTrace);
    }
  }

  @override
  Future<List<MyListing>> fetchMyListings(IdentityCatalog catalog) async {
    _requireUser();
    final identitiesBySellerId = <String, MarketplaceIdentity>{
      for (final identity in catalog.identities) ?identity.sellerId: identity,
    };
    if (identitiesBySellerId.isEmpty) return const <MyListing>[];
    try {
      final rows = await _client
          .from('products')
          .select(_myListingColumns)
          .inFilter('seller_id', identitiesBySellerId.keys.toList())
          .order('created_at', ascending: false);
      final resolved = await _imageUrls.resolveRows(rows);
      return <MyListing>[
        for (final row in resolved)
          if (identitiesBySellerId[row['seller_id']] case final identity?)
            MyListing.fromJson(row, identity: identity),
      ];
    } on PostgrestException catch (error, stackTrace) {
      _throwBackend(error, stackTrace);
    }
  }

  Future<MyListing> _fetchMyListing(
    String productId,
    MarketplaceIdentity identity,
  ) async {
    final row = await _client
        .from('products')
        .select(_myListingColumns)
        .eq('id', productId)
        .single();
    return MyListing.fromJson(
      await _imageUrls.resolveRow(row),
      identity: identity,
    );
  }

  String _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) throw const AppException(AppFailureCode.notAuthenticated);
    return user.id;
  }

  Future<void> _removeStaged(List<String> paths) async {
    if (paths.isEmpty) return;
    try {
      await _client.storage.from('product-images').remove(paths);
    } on Object {
      // Preserve the original submission failure. Orphan cleanup can be retried.
    }
  }

  Never _throwBackend(Object error, StackTrace stackTrace) {
    Error.throwWithStackTrace(
      AppException(AppFailureCode.unknown, cause: error),
      stackTrace,
    );
  }
}
