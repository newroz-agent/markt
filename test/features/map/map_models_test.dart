import 'package:flutter_test/flutter_test.dart';
import 'package:zerin_marketplace/features/map/data/url_launcher_directions_launcher.dart';
import 'package:zerin_marketplace/features/map/domain/map_models.dart';

void main() {
  test('radius choices match the server contract including null Alle', () {
    expect(MapRadius.values.map((radius) => radius.kilometers), <int?>[
      5,
      10,
      20,
      30,
      50,
      100,
      null,
    ]);
  });

  test('private RPC row discards an injected exact address', () {
    final listing = MapListing.tryFromJson(
      _row(precise: false, address: 'Private Home Street 1'),
    );

    expect(listing, isNotNull);
    expect(listing!.publicAddress, isNull);
    expect(listing.isPreciseBusiness, isFalse);
    expect(buildExternalDirectionsUri(listing), isNull);
  });

  test('only a server-flagged precise business can build directions', () {
    final listing = MapListing.tryFromJson(
      _row(precise: true, address: 'Public Store Street 1'),
    )!;

    expect(listing.publicAddress, 'Public Store Street 1');
    final uri = buildExternalDirectionsUri(listing);
    expect(uri, isNotNull);
    expect(uri!.host, 'www.google.com');
    expect(uri.path, '/maps/dir/');
    expect(uri.queryParameters, <String, String>{
      'api': '1',
      'destination': '52.516275,13.377704',
    });
  });

  test('malformed or out-of-range marker rows are rejected', () {
    expect(
      MapListing.tryFromJson(_row(precise: false)..['marker_latitude'] = 91),
      isNull,
    );
    expect(
      MapListing.tryFromJson(_row(precise: false)..['distance_km'] = -1),
      isNull,
    );
    expect(
      MapListing.tryFromJson(_row(precise: false)..['seller_kind'] = 'admin'),
      isNull,
    );
  });
}

Map<String, Object?> _row({required bool precise, String? address}) =>
    <String, Object?>{
      'product_id': 'product-1',
      'title': 'Map Listing',
      'price_cents': 2500,
      'currency': 'EUR',
      'product_condition': 'used',
      'city': 'Berlin',
      'seller_id': 'seller-1',
      'seller_name': 'Seller',
      'seller_kind': precise ? 'business' : 'private',
      'category_id': 'category-1',
      'primary_image_path': null,
      'primary_image_url': null,
      'marker_latitude': 52.516275,
      'marker_longitude': 13.377704,
      'distance_km': 1.5,
      'is_precise_business': precise,
      'public_address': address,
    };
