import 'package:zerin_marketplace/features/map/domain/map_models.dart';

abstract class MapRepository {
  Future<List<GermanCity>> fetchGermanCities();

  Future<MapSearchResult> fetchListings(MapQuery query);
}

class UnconfiguredMapRepository implements MapRepository {
  const UnconfiguredMapRepository();

  @override
  Future<List<GermanCity>> fetchGermanCities() async => const <GermanCity>[
    GermanCity.berlin,
  ];

  @override
  Future<MapSearchResult> fetchListings(MapQuery query) async =>
      MapSearchResult.empty(offset: query.offset, limit: query.limit);
}
