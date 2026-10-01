import 'package:flutter/foundation.dart';

@immutable
class MapPoint {
  const MapPoint({required this.latitude, required this.longitude})
    : assert(latitude >= -90 && latitude <= 90),
      assert(longitude >= -180 && longitude <= 180);

  static MapPoint? tryParse(Object? latitude, Object? longitude) {
    final parsedLatitude = _asDouble(latitude);
    final parsedLongitude = _asDouble(longitude);
    if (parsedLatitude == null ||
        parsedLongitude == null ||
        parsedLatitude < -90 ||
        parsedLatitude > 90 ||
        parsedLongitude < -180 ||
        parsedLongitude > 180) {
      return null;
    }
    return MapPoint(latitude: parsedLatitude, longitude: parsedLongitude);
  }

  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapPoint &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}

@immutable
class GermanCity {
  const GermanCity({required this.name, required this.point});

  static const berlin = GermanCity(
    name: 'Berlin',
    point: MapPoint(latitude: 52.520008, longitude: 13.404954),
  );

  static GermanCity? tryFromJson(Map<String, dynamic> json) {
    final name = _requiredString(json['name']);
    final point = MapPoint.tryParse(json['latitude'], json['longitude']);
    if (name == null || point == null) return null;
    return GermanCity(name: name, point: point);
  }

  final String name;
  final MapPoint point;

  double get latitude => point.latitude;
  double get longitude => point.longitude;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GermanCity && name == other.name && point == other.point;

  @override
  int get hashCode => Object.hash(name, point);
}

enum MapRadius {
  km5(5),
  km10(10),
  km20(20),
  km30(30),
  km50(50),
  km100(100),
  all(null);

  const MapRadius(this.kilometers);

  final int? kilometers;

  bool get isAll => kilometers == null;
}

enum MapListingCondition {
  newItem('new'),
  used('used');

  const MapListingCondition(this.databaseValue);

  final String databaseValue;

  static MapListingCondition? fromDatabaseValue(Object? value) =>
      switch (value) {
        'new' => MapListingCondition.newItem,
        'used' => MapListingCondition.used,
        _ => null,
      };
}

enum MapSellerKind {
  privateSeller('private'),
  business('business');

  const MapSellerKind(this.databaseValue);

  final String databaseValue;

  static MapSellerKind? fromDatabaseValue(Object? value) => switch (value) {
    'private' => MapSellerKind.privateSeller,
    'business' => MapSellerKind.business,
    _ => null,
  };
}

enum MapSort {
  distance('distance'),
  newest('newest'),
  priceAscending('price_asc'),
  priceDescending('price_desc');

  const MapSort(this.databaseValue);

  final String databaseValue;
}

@immutable
class MapFilters {
  const MapFilters({
    this.query,
    this.categoryId,
    this.condition,
    this.sellerKind,
    this.minPriceCents,
    this.maxPriceCents,
    this.sort = MapSort.distance,
  }) : assert(minPriceCents == null || minPriceCents >= 0),
       assert(maxPriceCents == null || maxPriceCents >= 0),
       assert(
         minPriceCents == null ||
             maxPriceCents == null ||
             minPriceCents <= maxPriceCents,
       );

  final String? query;
  final String? categoryId;
  final MapListingCondition? condition;
  final MapSellerKind? sellerKind;
  final int? minPriceCents;
  final int? maxPriceCents;
  final MapSort sort;

  MapFilters copyWith({
    Object? query = _sentinel,
    Object? categoryId = _sentinel,
    Object? condition = _sentinel,
    Object? sellerKind = _sentinel,
    Object? minPriceCents = _sentinel,
    Object? maxPriceCents = _sentinel,
    MapSort? sort,
  }) {
    return MapFilters(
      query: query == _sentinel ? this.query : query as String?,
      categoryId: categoryId == _sentinel
          ? this.categoryId
          : categoryId as String?,
      condition: condition == _sentinel
          ? this.condition
          : condition as MapListingCondition?,
      sellerKind: sellerKind == _sentinel
          ? this.sellerKind
          : sellerKind as MapSellerKind?,
      minPriceCents: minPriceCents == _sentinel
          ? this.minPriceCents
          : minPriceCents as int?,
      maxPriceCents: maxPriceCents == _sentinel
          ? this.maxPriceCents
          : maxPriceCents as int?,
      sort: sort ?? this.sort,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapFilters &&
          query == other.query &&
          categoryId == other.categoryId &&
          condition == other.condition &&
          sellerKind == other.sellerKind &&
          minPriceCents == other.minPriceCents &&
          maxPriceCents == other.maxPriceCents &&
          sort == other.sort;

  @override
  int get hashCode => Object.hash(
    query,
    categoryId,
    condition,
    sellerKind,
    minPriceCents,
    maxPriceCents,
    sort,
  );
}

@immutable
class MapQuery {
  const MapQuery({
    required this.center,
    this.radius = MapRadius.km30,
    this.filters = const MapFilters(),
    this.limit = 100,
    this.offset = 0,
  });

  final MapPoint center;
  final MapRadius radius;
  final MapFilters filters;
  final int limit;
  final int offset;

  MapQuery copyWith({
    MapPoint? center,
    MapRadius? radius,
    MapFilters? filters,
    int? limit,
    int? offset,
  }) {
    return MapQuery(
      center: center ?? this.center,
      radius: radius ?? this.radius,
      filters: filters ?? this.filters,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }
}

@immutable
class MapListing {
  const MapListing({
    required this.productId,
    required this.title,
    required this.priceCents,
    required this.currency,
    required this.condition,
    required this.city,
    required this.sellerId,
    required this.sellerName,
    required this.sellerKind,
    required this.categoryId,
    required this.marker,
    required this.distanceKm,
    required this.isPreciseBusiness,
    this.primaryImagePath,
    this.primaryImageUrl,
    this.publicAddress,
  });

  static MapListing? tryFromJson(Map<String, dynamic> json) {
    final productId = _requiredString(json['product_id']);
    final title = _requiredString(json['title']);
    final priceCents = _asInt(json['price_cents']);
    final currency = _requiredString(json['currency']);
    final condition = MapListingCondition.fromDatabaseValue(
      json['product_condition'],
    );
    final city = _requiredString(json['city']);
    final sellerId = _requiredString(json['seller_id']);
    final sellerName = _requiredString(json['seller_name']);
    final sellerKind = MapSellerKind.fromDatabaseValue(json['seller_kind']);
    final categoryId = _requiredString(json['category_id']);
    final marker = MapPoint.tryParse(
      json['marker_latitude'],
      json['marker_longitude'],
    );
    final distanceKm = _asDouble(json['distance_km']);
    final isPreciseBusiness = json['is_precise_business'];

    if (productId == null ||
        title == null ||
        priceCents == null ||
        priceCents < 0 ||
        currency == null ||
        condition == null ||
        city == null ||
        sellerId == null ||
        sellerName == null ||
        sellerKind == null ||
        categoryId == null ||
        marker == null ||
        distanceKm == null ||
        distanceKm < 0 ||
        isPreciseBusiness is! bool) {
      return null;
    }

    return MapListing(
      productId: productId,
      title: title,
      priceCents: priceCents,
      currency: currency,
      condition: condition,
      city: city,
      sellerId: sellerId,
      sellerName: sellerName,
      sellerKind: sellerKind,
      categoryId: categoryId,
      primaryImagePath: _optionalString(json['primary_image_path']),
      primaryImageUrl: _optionalString(json['primary_image_url']),
      marker: marker,
      distanceKm: distanceKm,
      isPreciseBusiness: isPreciseBusiness,
      publicAddress: isPreciseBusiness
          ? _optionalString(json['public_address'])
          : null,
    );
  }

  final String productId;
  final String title;
  final int priceCents;
  final String currency;
  final MapListingCondition condition;
  final String city;
  final String sellerId;
  final String sellerName;
  final MapSellerKind sellerKind;
  final String categoryId;
  final String? primaryImagePath;
  final String? primaryImageUrl;
  final MapPoint marker;
  final double distanceKm;
  final bool isPreciseBusiness;
  final String? publicAddress;

  String? get previewImageUrl => primaryImageUrl;

  MapListing copyWith({
    Object? primaryImagePath = _sentinel,
    Object? primaryImageUrl = _sentinel,
  }) {
    return MapListing(
      productId: productId,
      title: title,
      priceCents: priceCents,
      currency: currency,
      condition: condition,
      city: city,
      sellerId: sellerId,
      sellerName: sellerName,
      sellerKind: sellerKind,
      categoryId: categoryId,
      primaryImagePath: primaryImagePath == _sentinel
          ? this.primaryImagePath
          : primaryImagePath as String?,
      primaryImageUrl: primaryImageUrl == _sentinel
          ? this.primaryImageUrl
          : primaryImageUrl as String?,
      marker: marker,
      distanceKm: distanceKm,
      isPreciseBusiness: isPreciseBusiness,
      publicAddress: publicAddress,
    );
  }
}

@immutable
class MapSearchResult {
  MapSearchResult({
    required Iterable<MapListing> listings,
    required this.totalCount,
    required this.offset,
    required this.limit,
    required this.nextOffset,
  }) : assert(totalCount >= 0),
       assert(offset >= 0),
       assert(limit > 0 && limit <= 100),
       assert(nextOffset >= offset),
       listings = List<MapListing>.unmodifiable(listings);

  factory MapSearchResult.empty({int offset = 0, int limit = 100}) {
    final safeOffset = offset < 0 ? 0 : offset;
    final safeLimit = limit < 1
        ? 1
        : limit > 100
        ? 100
        : limit;
    return MapSearchResult(
      listings: const <MapListing>[],
      totalCount: 0,
      offset: safeOffset,
      limit: safeLimit,
      nextOffset: safeOffset,
    );
  }

  final List<MapListing> listings;
  final int totalCount;
  final int offset;
  final int limit;

  /// Server row offset for the next page. This advances independently from
  /// [listings] because malformed or duplicate rows are deliberately rejected.
  final int nextOffset;

  bool get hasMore => nextOffset < totalCount;
}

const _sentinel = Object();

String? _requiredString(Object? value) {
  if (value is! String) return null;
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

String? _optionalString(Object? value) => _requiredString(value);

double? _asDouble(Object? value) {
  final parsed = switch (value) {
    final num number => number.toDouble(),
    final String text => double.tryParse(text.trim()),
    _ => null,
  };
  return parsed != null && parsed.isFinite ? parsed : null;
}

int? _asInt(Object? value) {
  if (value is int) return value;
  final parsed = _asDouble(value);
  if (parsed == null || parsed.truncateToDouble() != parsed) return null;
  return parsed.toInt();
}
