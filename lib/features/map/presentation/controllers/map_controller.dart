import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerin_marketplace/core/providers/infrastructure_providers.dart';
import 'package:zerin_marketplace/features/map/data/geolocator_device_location_service.dart';
import 'package:zerin_marketplace/features/map/data/supabase_map_repository.dart';
import 'package:zerin_marketplace/features/map/data/url_launcher_directions_launcher.dart';
import 'package:zerin_marketplace/features/map/domain/device_location_service.dart';
import 'package:zerin_marketplace/features/map/domain/directions_launcher.dart';
import 'package:zerin_marketplace/features/map/domain/map_models.dart';
import 'package:zerin_marketplace/features/map/domain/map_repository.dart';

final mapRepositoryProvider = Provider<MapRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? const UnconfiguredMapRepository()
      : SupabaseMapRepository(client);
});

final deviceLocationServiceProvider = Provider<DeviceLocationService>(
  (ref) => const GeolocatorDeviceLocationService(),
);

final directionsLauncherProvider = Provider<DirectionsLauncher>(
  (ref) => UrlLauncherDirectionsLauncher(),
);

final mapControllerProvider =
    NotifierProvider<MapDiscoveryController, MapControllerState>(
      MapDiscoveryController.new,
    );

enum MapCenterSource { canonicalBerlin, manualCity, currentLocation }

/// Viewer coordinates are used only in memory as map/RPC input and never saved.
enum MapLocationPrivacy { transientViewerLocation }

@immutable
class MapControllerState {
  MapControllerState({
    required Iterable<GermanCity> cities,
    required this.center,
    required this.selectedCity,
    required this.centerSource,
    required this.radius,
    required this.filters,
    required this.result,
    required this.locationStatus,
    required this.isLoadingCities,
    required this.isRefreshing,
    required this.isLoadingMore,
    required this.hasInitialized,
    this.citiesError,
    this.listingsError,
    this.locationPrivacy = MapLocationPrivacy.transientViewerLocation,
  }) : cities = List<GermanCity>.unmodifiable(cities);

  factory MapControllerState.initial() => MapControllerState(
    cities: const <GermanCity>[GermanCity.berlin],
    center: GermanCity.berlin.point,
    selectedCity: GermanCity.berlin,
    centerSource: MapCenterSource.canonicalBerlin,
    radius: MapRadius.km30,
    filters: const MapFilters(),
    result: MapSearchResult.empty(),
    locationStatus: DeviceLocationStatus.notRequested,
    isLoadingCities: false,
    isRefreshing: false,
    isLoadingMore: false,
    hasInitialized: false,
  );

  final List<GermanCity> cities;
  final MapPoint center;
  final GermanCity? selectedCity;
  final MapCenterSource centerSource;
  final MapRadius radius;
  final MapFilters filters;
  final MapSearchResult result;
  final DeviceLocationStatus locationStatus;
  final MapLocationPrivacy locationPrivacy;
  final bool isLoadingCities;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasInitialized;
  final Object? citiesError;
  final Object? listingsError;

  List<MapListing> get listings => result.listings;
  bool get hasMore => result.hasMore;

  MapControllerState copyWith({
    Iterable<GermanCity>? cities,
    MapPoint? center,
    Object? selectedCity = _sentinel,
    MapCenterSource? centerSource,
    MapRadius? radius,
    MapFilters? filters,
    MapSearchResult? result,
    DeviceLocationStatus? locationStatus,
    bool? isLoadingCities,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasInitialized,
    Object? citiesError = _sentinel,
    Object? listingsError = _sentinel,
  }) {
    return MapControllerState(
      cities: cities ?? this.cities,
      center: center ?? this.center,
      selectedCity: selectedCity == _sentinel
          ? this.selectedCity
          : selectedCity as GermanCity?,
      centerSource: centerSource ?? this.centerSource,
      radius: radius ?? this.radius,
      filters: filters ?? this.filters,
      result: result ?? this.result,
      locationStatus: locationStatus ?? this.locationStatus,
      isLoadingCities: isLoadingCities ?? this.isLoadingCities,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasInitialized: hasInitialized ?? this.hasInitialized,
      citiesError: citiesError == _sentinel ? this.citiesError : citiesError,
      listingsError: listingsError == _sentinel
          ? this.listingsError
          : listingsError,
      locationPrivacy: locationPrivacy,
    );
  }
}

class MapDiscoveryController extends Notifier<MapControllerState> {
  Future<void>? _initialization;
  bool _disposed = false;
  int _centerRevision = 0;
  int _locationGeneration = 0;
  int _queryGeneration = 0;

  @override
  MapControllerState build() {
    ref.onDispose(() {
      _disposed = true;
      _locationGeneration++;
      _queryGeneration++;
    });
    unawaited(Future<void>.microtask(initialize));
    return MapControllerState.initial();
  }

  Future<void> initialize() {
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    final centerRevision = _centerRevision;
    final locationGeneration = ++_locationGeneration;
    state = state.copyWith(
      isLoadingCities: true,
      locationStatus: DeviceLocationStatus.requesting,
      citiesError: null,
      listingsError: null,
    );

    // Start the one-shot location attempt without making city loading block it.
    final locationFuture = _currentLocation();
    Object? citiesError;
    var cities = const <GermanCity>[GermanCity.berlin];
    try {
      final loaded = await ref.read(mapRepositoryProvider).fetchGermanCities();
      cities = _withBerlinFallback(loaded);
    } on Object catch (error) {
      citiesError = error;
    }
    if (_disposed) return;

    state = state.copyWith(
      cities: cities,
      isLoadingCities: false,
      citiesError: citiesError,
    );

    final location = await locationFuture;
    if (_disposed || locationGeneration != _locationGeneration) return;
    if (centerRevision != _centerRevision) {
      // A manual city selected while permission UI was open must keep control,
      // but the terminal permission/service status remains visible to the UI.
      state = state.copyWith(locationStatus: location.status);
      return;
    }
    _applyLocationOrFallback(location, fallbackCity: _berlin(cities));
    await _fetchFirstPage();
  }

  Future<void> retryCurrentLocation() async {
    final centerRevision = _centerRevision;
    final locationGeneration = ++_locationGeneration;
    _queryGeneration++;
    state = state.copyWith(
      locationStatus: DeviceLocationStatus.requesting,
      isRefreshing: false,
      isLoadingMore: false,
      listingsError: null,
    );
    final manualFallback = state.selectedCity ?? _berlin(state.cities);
    final location = await _currentLocation();
    if (_disposed || locationGeneration != _locationGeneration) return;
    if (centerRevision != _centerRevision) {
      state = state.copyWith(locationStatus: location.status);
      return;
    }
    _applyLocationOrFallback(location, fallbackCity: manualFallback);
    await _fetchFirstPage();
  }

  Future<void> selectCity(GermanCity city) async {
    final selected = _cityNamed(city.name, state.cities) ?? city;
    _centerRevision++;
    state = state.copyWith(
      center: selected.point,
      selectedCity: selected,
      centerSource: MapCenterSource.manualCity,
      listingsError: null,
    );
    await _fetchFirstPage();
  }

  Future<bool> selectCityByName(String name) async {
    final city = _cityNamed(name.trim(), state.cities);
    if (city == null) return false;
    await selectCity(city);
    return true;
  }

  Future<void> setRadius(MapRadius radius) async {
    if (radius == state.radius) return;
    state = state.copyWith(radius: radius, listingsError: null);
    await _fetchFirstPage();
  }

  Future<void> setFilters(MapFilters filters) async {
    if (filters == state.filters) return;
    state = state.copyWith(filters: filters, listingsError: null);
    await _fetchFirstPage();
  }

  Future<void> refresh() => _fetchFirstPage();

  Future<void> loadMore() async {
    final current = state.result;
    if (state.isRefreshing ||
        state.isLoadingMore ||
        state.locationStatus == DeviceLocationStatus.requesting ||
        !current.hasMore) {
      return;
    }

    final generation = _queryGeneration;
    state = state.copyWith(isLoadingMore: true, listingsError: null);
    try {
      final page = await ref
          .read(mapRepositoryProvider)
          .fetchListings(_query(offset: current.nextOffset));
      if (_disposed || generation != _queryGeneration) return;

      final knownIds = <String>{
        for (final listing in current.listings) listing.productId,
      };
      final merged = <MapListing>[
        ...current.listings,
        for (final listing in page.listings)
          if (knownIds.add(listing.productId)) listing,
      ];
      final pageAdvanced = page.nextOffset > current.nextOffset;
      final reportedTotal = pageAdvanced ? page.totalCount : current.nextOffset;
      final safeTotal = reportedTotal < merged.length
          ? merged.length
          : reportedTotal;
      state = state.copyWith(
        result: MapSearchResult(
          listings: merged,
          totalCount: safeTotal,
          offset: current.offset,
          limit: page.limit,
          nextOffset: page.nextOffset,
        ),
        isLoadingMore: false,
      );
    } on Object catch (error) {
      if (!_disposed && generation == _queryGeneration) {
        state = state.copyWith(isLoadingMore: false, listingsError: error);
      }
    }
  }

  Future<DeviceLocationResult> _currentLocation() async {
    try {
      return await ref.read(deviceLocationServiceProvider).getCurrentLocation();
    } on Object {
      return const DeviceLocationResult.unavailable();
    }
  }

  void _applyLocationOrFallback(
    DeviceLocationResult location, {
    required GermanCity fallbackCity,
  }) {
    final point = location.point;
    if (location.isAvailable && point != null) {
      state = state.copyWith(
        center: point,
        selectedCity: null,
        centerSource: MapCenterSource.currentLocation,
        locationStatus: DeviceLocationStatus.available,
      );
      return;
    }

    state = state.copyWith(
      center: fallbackCity.point,
      selectedCity: fallbackCity,
      centerSource: fallbackCity.name == GermanCity.berlin.name
          ? MapCenterSource.canonicalBerlin
          : MapCenterSource.manualCity,
      locationStatus: location.status,
    );
  }

  Future<void> _fetchFirstPage() async {
    final generation = ++_queryGeneration;
    state = state.copyWith(
      isRefreshing: true,
      isLoadingMore: false,
      listingsError: null,
    );
    try {
      final result = await ref
          .read(mapRepositoryProvider)
          .fetchListings(_query());
      if (_disposed || generation != _queryGeneration) return;
      state = state.copyWith(
        result: result,
        isRefreshing: false,
        hasInitialized: true,
      );
    } on Object catch (error) {
      if (!_disposed && generation == _queryGeneration) {
        state = state.copyWith(
          isRefreshing: false,
          hasInitialized: true,
          listingsError: error,
        );
      }
    }
  }

  MapQuery _query({int offset = 0}) => MapQuery(
    center: state.center,
    radius: state.radius,
    filters: state.filters,
    offset: offset,
  );
}

List<GermanCity> _withBerlinFallback(List<GermanCity> cities) {
  final byName = <String, GermanCity>{
    for (final city in cities) city.name: city,
  };
  byName.putIfAbsent(GermanCity.berlin.name, () => GermanCity.berlin);
  final result = byName.values.toList(growable: false)
    ..sort((left, right) => left.name.compareTo(right.name));
  return result;
}

GermanCity _berlin(List<GermanCity> cities) =>
    _cityNamed(GermanCity.berlin.name, cities) ?? GermanCity.berlin;

GermanCity? _cityNamed(String name, List<GermanCity> cities) {
  for (final city in cities) {
    if (city.name == name) return city;
  }
  return null;
}

const _sentinel = Object();
