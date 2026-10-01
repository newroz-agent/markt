import 'package:supabase_flutter/supabase_flutter.dart';

/// Resolves protected `product-images` storage paths without changing seeded
/// external image URLs. RLS still decides whether the caller may sign a path.
class ProductImageUrlResolver {
  ProductImageUrlResolver(this._client);

  static const signedUrlLifetime = Duration(hours: 1);

  final SupabaseClient _client;

  Future<Map<String, dynamic>> resolveRow(Map<String, dynamic> row) async {
    final copy = Map<String, dynamic>.from(row);
    final rawImages = copy['images'];
    if (rawImages is! List) return copy;

    copy['images'] = await Future.wait<Map<String, dynamic>>(
      rawImages.whereType<Map<Object?, Object?>>().map((raw) async {
        final image = Map<String, dynamic>.from(raw);
        final currentUrl = image['image_url'] as String?;
        final storagePath = image['storage_path'] as String?;
        if ((currentUrl == null || currentUrl.isEmpty) &&
            storagePath != null &&
            storagePath.split('/').length == 3) {
          try {
            image['image_url'] = await _client.storage
                .from('product-images')
                .createSignedUrl(storagePath, signedUrlLifetime.inSeconds);
          } on StorageException {
            // Keep the image unavailable rather than failing the entire listing.
          }
        }
        return image;
      }),
    );
    return copy;
  }

  Future<List<Map<String, dynamic>>> resolveRows(Object? rows) async {
    if (rows is! List) return const <Map<String, dynamic>>[];
    return Future.wait(
      rows.whereType<Map<Object?, Object?>>().map(
        (row) => resolveRow(Map<String, dynamic>.from(row)),
      ),
    );
  }
}
