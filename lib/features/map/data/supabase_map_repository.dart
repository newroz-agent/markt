import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerin_marketplace/core/errors/app_exception.dart';
import 'package:zerin_marketplace/core/storage/product_image_url_resolver.dart';
import 'package:zerin_marketplace/features/map/domain/map_models.dart';
import 'package:zerin_marketplace/features/map/domain/map_repository.dart';

class SupabaseMapRepository implements MapRepository {
  SupabaseMapRepository(this._client);

  final SupabaseClient _client;
  late final ProductImageUrlResolver _imageUrls = ProductImageUrlResolver(
    _client,
  );

  @override
  Future<List<GermanCity>> fetchGermanCities() async {
    try {
      final rows = await _client
          .from('german_cities')
          .select('name, latitude, longitude')
          .order('name', ascending: true);
      final citiesByName = <String, GermanCity>{};
      for (final raw in rows) {
        final row = _stringKeyedMap(raw);
        if (row == null) continue;
        final city = GermanCity.tryFromJson(row);
        if (city != null) citiesByName.putIfAbsent(city.name, () => city);
      }
      final cities = citiesByName.values.toList(growable: false)
        ..sort((left, right) => left.name.compareTo(right.name));
      return List<GermanCity>.unmodifiable(cities);
    } on PostgrestException catch (error, stackTrace) {
      _throwBackend(error, stackTrace);
    }
  }

  @override
  Future<MapSearchResult> fetchListings(MapQuery query) async {
    final limit = _boundedLimit(query.limit);
    final offset = query.offset < 0 ? 0 : query.offset;
    final queryText = _normalizedText(query.filters.query);
    final categoryId = _normalizedText(query.filters.categoryId);

    try {
      // Viewer coordinates are transient RPC inputs only. This repository never
      // inserts, updates, logs, or otherwise persists them.
      final rows = await _client.rpc<List<dynamic>>(
        'listings_within_radius',
        params: <String, dynamic>{
          'center_lat': query.center.latitude,
          'center_lng': query.center.longitude,
          'radius_km': query.radius.kilometers,
          'p_query': queryText,
          'p_category_id': categoryId,
          'p_condition': query.filters.condition?.databaseValue,
          'p_seller_kind': query.filters.sellerKind?.databaseValue,
          'p_min_price_cents': query.filters.minPriceCents,
          'p_max_price_cents': query.filters.maxPriceCents,
          'p_sort': query.filters.sort.databaseValue,
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      final seenProductIds = <String>{};
      final parsed = <MapListing>[];
      int? totalCount;

      for (final raw in rows) {
        final row = _stringKeyedMap(raw);
        if (row == null) continue;
        final rowTotalCount = _nonNegativeInt(row['total_count']);
        if (rowTotalCount != null &&
            (totalCount == null || rowTotalCount > totalCount)) {
          totalCount = rowTotalCount;
        }

        final listing = MapListing.tryFromJson(row);
        if (listing == null || !seenProductIds.add(listing.productId)) continue;
        parsed.add(listing);
      }

      final listings = await Future.wait(parsed.map(_resolvePreviewImage));
      return MapSearchResult(
        listings: listings,
        totalCount: totalCount ?? offset + rows.length,
        offset: offset,
        limit: limit,
        nextOffset: offset + rows.length,
      );
    } on PostgrestException catch (error, stackTrace) {
      _throwBackend(error, stackTrace);
    }
  }

  Future<MapListing> _resolvePreviewImage(MapListing listing) async {
    if (listing.primaryImageUrl != null || listing.primaryImagePath == null) {
      return listing;
    }

    final resolved = await _imageUrls.resolveRow(<String, dynamic>{
      'images': <Map<String, dynamic>>[
        <String, dynamic>{
          'image_url': listing.primaryImageUrl,
          'storage_path': listing.primaryImagePath,
          'sort_order': 0,
        },
      ],
    });
    final images = resolved['images'];
    if (images is! List || images.isEmpty) return listing;
    final image = _stringKeyedMap(images.first);
    final resolvedUrl = _normalizedText(image?['image_url']);
    return resolvedUrl == null
        ? listing
        : listing.copyWith(primaryImageUrl: resolvedUrl);
  }

  Never _throwBackend(Object error, StackTrace stackTrace) {
    Error.throwWithStackTrace(
      AppException(AppFailureCode.unknown, cause: error),
      stackTrace,
    );
  }
}

int _boundedLimit(int value) {
  if (value < 1) return 1;
  if (value > 100) return 100;
  return value;
}

int? _nonNegativeInt(Object? value) {
  final parsed = switch (value) {
    final int number => number,
    final num number when number.isFinite && number.truncate() == number =>
      number.toInt(),
    final String text => int.tryParse(text.trim()),
    _ => null,
  };
  return parsed != null && parsed >= 0 ? parsed : null;
}

String? _normalizedText(Object? value) {
  if (value is! String) return null;
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

Map<String, dynamic>? _stringKeyedMap(Object? value) {
  if (value is! Map) return null;
  final result = <String, dynamic>{};
  for (final entry in value.entries) {
    if (entry.key is! String) return null;
    result[entry.key as String] = entry.value;
  }
  return result;
}
