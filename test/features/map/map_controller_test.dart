import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerin_marketplace/features/map/domain/device_location_service.dart';
import 'package:zerin_marketplace/features/map/domain/map_models.dart';
import 'package:zerin_marketplace/features/map/domain/map_repository.dart';
import 'package:zerin_marketplace/features/map/presentation/controllers/map_controller.dart';

void main() {
  test(
    'denied location falls back to canonical Berlin and server query',
    () async {
      final repository = _MapRepository();
      final container = ProviderContainer(
        overrides: <Override>[
          mapRepositoryProvider.overrideWithValue(repository),
          deviceLocationServiceProvider.overrideWithValue(
            const _LocationService(DeviceLocationResult.denied()),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(mapControllerProvider.notifier).initialize();
      final state = container.read(mapControllerProvider);

      expect(state.locationStatus, DeviceLocationStatus.denied);
      expect(state.centerSource, MapCenterSource.canonicalBerlin);
      expect(state.selectedCity, GermanCity.berlin);
      expect(state.center, GermanCity.berlin.point);
      expect(repository.queries.single.radius, MapRadius.km30);
      expect(repository.queries.single.center, GermanCity.berlin.point);
      expect(state.listings.single.productId, 'km30');
    },
  );

  test(
    'manual city and current-location retry remain transient query centers',
    () async {
      final repository = _MapRepository();
      final location = _MutableLocationService(
        const DeviceLocationResult.serviceDisabled(),
      );
      final container = ProviderContainer(
        overrides: <Override>[
          mapRepositoryProvider.overrideWithValue(repository),
          deviceLocationServiceProvider.overrideWithValue(location),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(mapControllerProvider.notifier);
      await controller.initialize();

      const hamburg = GermanCity(
        name: 'Hamburg',
        point: MapPoint(latitude: 53.551086, longitude: 9.993682),
      );
      await controller.selectCity(hamburg);
      expect(
        container.read(mapControllerProvider).centerSource,
        MapCenterSource.manualCity,
      );
      expect(repository.queries.last.center, hamburg.point);

      location.result = const DeviceLocationResult.available(
        MapPoint(latitude: 52.500001, longitude: 13.400001),
      );
      await controller.retryCurrentLocation();
      final state = container.read(mapControllerProvider);
      expect(state.centerSource, MapCenterSource.currentLocation);
      expect(state.selectedCity, isNull);
      expect(state.locationPrivacy, MapLocationPrivacy.transientViewerLocation);
      expect(repository.queries.last.center, state.center);
    },
  );

  test(
    'late radius response cannot replace the newer visible marker set',
    () async {
      final repository = _MapRepository();
      final container = ProviderContainer(
        overrides: <Override>[
          mapRepositoryProvider.overrideWithValue(repository),
          deviceLocationServiceProvider.overrideWithValue(
            const _LocationService(DeviceLocationResult.denied()),
          ),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(mapControllerProvider.notifier);
      await controller.initialize();

      final five = Completer<MapSearchResult>();
      final hundred = Completer<MapSearchResult>();
      repository.onFetch = (query) => switch (query.radius) {
        MapRadius.km5 => five.future,
        MapRadius.km100 => hundred.future,
        _ => Future<MapSearchResult>.value(_result(query.radius.name)),
      };

      final oldRequest = controller.setRadius(MapRadius.km5);
      await Future<void>.delayed(Duration.zero);
      final newRequest = controller.setRadius(MapRadius.km100);
      await Future<void>.delayed(Duration.zero);

      hundred.complete(_result('new-100'));
      await newRequest;
      five.complete(_result('stale-5'));
      await oldRequest;

      final state = container.read(mapControllerProvider);
      expect(state.radius, MapRadius.km100);
      expect(state.listings.single.productId, 'new-100');
      expect(state.isRefreshing, isFalse);
    },
  );
}

class _MapRepository implements MapRepository {
  final queries = <MapQuery>[];
  Future<MapSearchResult> Function(MapQuery query)? onFetch;

  @override
  Future<List<GermanCity>> fetchGermanCities() async => const <GermanCity>[
    GermanCity.berlin,
    GermanCity(
      name: 'Hamburg',
      point: MapPoint(latitude: 53.551086, longitude: 9.993682),
    ),
  ];

  @override
  Future<MapSearchResult> fetchListings(MapQuery query) {
    queries.add(query);
    return onFetch?.call(query) ??
        Future<MapSearchResult>.value(_result(query.radius.name));
  }
}

class _LocationService implements DeviceLocationService {
  const _LocationService(this.result);

  final DeviceLocationResult result;

  @override
  Future<DeviceLocationResult> getCurrentLocation() async => result;
}

class _MutableLocationService implements DeviceLocationService {
  _MutableLocationService(this.result);

  DeviceLocationResult result;

  @override
  Future<DeviceLocationResult> getCurrentLocation() async => result;
}

MapSearchResult _result(String id) => MapSearchResult(
  listings: <MapListing>[_listing(id)],
  totalCount: 1,
  offset: 0,
  limit: 100,
  nextOffset: 1,
);

MapListing _listing(String id) => MapListing(
  productId: id,
  title: 'Listing $id',
  priceCents: 2500,
  currency: 'EUR',
  condition: MapListingCondition.used,
  city: 'Berlin',
  sellerId: 'seller-$id',
  sellerName: 'Seller',
  sellerKind: MapSellerKind.privateSeller,
  categoryId: 'category',
  marker: GermanCity.berlin.point,
  distanceKm: 1,
  isPreciseBusiness: false,
);
