import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerin_marketplace/app/app.dart';
import 'package:zerin_marketplace/app/router/app_router.dart';
import 'package:zerin_marketplace/core/config/app_environment.dart';
import 'package:zerin_marketplace/core/providers/infrastructure_providers.dart';
import 'package:zerin_marketplace/features/home/presentation/home_foundation_screen.dart';
import 'package:zerin_marketplace/features/map/domain/device_location_service.dart';
import 'package:zerin_marketplace/features/map/domain/map_models.dart';
import 'package:zerin_marketplace/features/map/presentation/controllers/map_controller.dart';
import 'package:zerin_marketplace/features/map/presentation/map_screen.dart';
import 'package:zerin_marketplace/features/products/presentation/product_detail_screen.dart';
import 'package:zerin_marketplace/features/settings/presentation/controllers/app_settings_controller.dart';

const _berlinLatitude = 52.520008;
const _berlinLongitude = 13.404954;
const _preciseLatitude = 52.516275;
const _preciseLongitude = 13.377704;
const _preciseAddress = 'Unter den Linden 77, Berlin';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late SupabaseClient client;
  late SharedPreferences preferences;
  late ProviderContainer container;
  late GoRouter router;
  late String privateProductId;
  late String preciseProductId;
  late double privateJitterKm;
  late int nearCount;
  late int allCount;
  final checks = <String, String>{};

  Future<void> until(
    WidgetTester tester,
    bool Function() condition,
    String reason,
  ) async {
    final deadline = DateTime.now().add(const Duration(seconds: 60));
    while (!condition() && DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(condition(), isTrue, reason: reason);
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> screenshot(WidgetTester tester, String name) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    final bytes = await binding.takeScreenshot('step_d_$name');
    expect(bytes.length, greaterThan(1000));
    checks[name] = 'PASS';
  }

  Map<String, dynamic> rpcParams(int? radius) => <String, dynamic>{
    'center_lat': _berlinLatitude,
    'center_lng': _berlinLongitude,
    'radius_km': radius,
    'p_query': null,
    'p_category_id': null,
    'p_condition': null,
    'p_seller_kind': null,
    'p_min_price_cents': null,
    'p_max_price_cents': null,
    'p_sort': 'distance',
    'p_limit': 100,
    'p_offset': 0,
  };

  setUpAll(() async {
    expect(AppEnvironment.isSupabaseConfigured, isTrue);
    expect(
      <String>['localhost', '127.0.0.1', '::1'],
      contains(Uri.parse(AppEnvironment.supabaseUrl).host),
      reason: 'Step D acceptance is intentionally restricted to local Supabase',
    );
    client = SupabaseClient(
      AppEnvironment.supabaseUrl,
      AppEnvironment.supabaseAnonKey,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    preferences = await SharedPreferences.getInstance();
    await preferences.setBool(SettingsStorageKeys.onboardingComplete, true);

    final nearRows = await client.rpc<List<dynamic>>(
      'listings_within_radius',
      params: rpcParams(30),
    );
    final allRows = await client.rpc<List<dynamic>>(
      'listings_within_radius',
      params: rpcParams(null),
    );
    nearCount = nearRows.length;
    allCount = allRows.length;
    expect(nearCount, greaterThan(0));
    expect(allCount, greaterThan(nearCount));

    final private = nearRows.whereType<Map<dynamic, dynamic>>().firstWhere(
      (row) => row['seller_kind'] == 'private',
    );
    final precise = nearRows.whereType<Map<dynamic, dynamic>>().firstWhere(
      (row) => row['is_precise_business'] == true,
    );
    privateProductId = private['product_id']! as String;
    preciseProductId = precise['product_id']! as String;
    expect(private['public_address'], isNull);
    expect(precise['public_address'], _preciseAddress);
    expect(
      _number(precise['marker_latitude']),
      closeTo(_preciseLatitude, 0.000001),
    );
    expect(
      _number(precise['marker_longitude']),
      closeTo(_preciseLongitude, 0.000001),
    );
    privateJitterKm = _distanceKm(
      _berlinLatitude,
      _berlinLongitude,
      _number(private['marker_latitude']),
      _number(private['marker_longitude']),
    );
    expect(privateJitterKm, inInclusiveRange(0.29, 0.51));
  });

  tearDownAll(() async {
    binding.reportData ??= <String, dynamic>{};
    binding.reportData!['checks'] = checks;
    binding.reportData!['tests'] = <String, String>{
      for (final entry in binding.results.entries)
        entry.key: entry.value == 'success' ? 'PASS' : 'FAIL',
    };
    binding.reportData!['runtime'] = <String, String>{
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'device': const String.fromEnvironment(
        'STEP_D_DEVICE',
        defaultValue: 'unknown',
      ),
    };
    binding.reportData!['evidence'] = <String, Object>{
      'near_count': nearCount,
      'all_count': allCount,
      'private_product_id': privateProductId,
      'private_jitter_km': privateJitterKm,
      'precise_product_id': preciseProductId,
      'precise_store_latitude': _preciseLatitude,
      'precise_store_longitude': _preciseLongitude,
      'precise_store_address': _preciseAddress,
    };
    await client.dispose();
  });

  testWidgets('real iOS Map radius, private preview, and detail hand-off', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(preferences),
          supabaseClientProvider.overrideWithValue(client),
        ],
        child: const ZerinApp(),
      ),
    );
    await tester.pump();
    container = ProviderScope.containerOf(
      tester.element(find.byType(ZerinApp)),
    );
    await container
        .read(appSettingsControllerProvider.notifier)
        .setLocale('de');
    router = container.read(appRouterProvider);
    router.go(const MarketplaceRoute().location);
    await until(
      tester,
      () =>
          find.byType(HomeFoundationScreen).evaluate().isNotEmpty &&
          find.byKey(const ValueKey('home-map-action')).evaluate().isNotEmpty,
      'Home exposes the dedicated Map entry point',
    );

    await tester.tap(find.byKey(const ValueKey('home-map-action')));
    await until(
      tester,
      () =>
          find.byType(MapScreen).evaluate().isNotEmpty &&
          container.read(mapControllerProvider).hasInitialized &&
          container.read(mapControllerProvider).listings.length == nearCount,
      'Production /map loads server-filtered Berlin markers',
    );
    final initial = container.read(mapControllerProvider);
    expect(initial.locationStatus, DeviceLocationStatus.available);
    expect(initial.centerSource, MapCenterSource.currentLocation);
    expect(initial.radius, MapRadius.km30);
    expect(
      initial.listings.any((item) => item.productId == privateProductId),
      isTrue,
    );
    expect(
      initial.listings.any((item) => item.productId == preciseProductId),
      isTrue,
    );
    expect(
      find
          .byWidgetPredicate(
            (widget) =>
                widget.key is ValueKey<String> &&
                (widget.key! as ValueKey<String>).value.startsWith(
                  'map-cluster-',
                ),
          )
          .evaluate()
          .isNotEmpty,
      isTrue,
      reason: 'Berlin listings render through the real clustering layer',
    );
    await screenshot(tester, 'map_pins_30km');

    final radiusRow = find.byKey(const ValueKey('map-radius-row'));
    final allRadius = find.byKey(const ValueKey('map-radius-all'));
    for (
      var attempt = 0;
      attempt < 5 && allRadius.evaluate().isEmpty;
      attempt++
    ) {
      await tester.drag(radiusRow, const Offset(-280, 0));
      await tester.pumpAndSettle();
    }
    expect(allRadius, findsOneWidget);
    await tester.tap(allRadius);
    await until(
      tester,
      () =>
          container.read(mapControllerProvider).radius == MapRadius.all &&
          container.read(mapControllerProvider).listings.length == allCount,
      'Alle radius visibly loads the larger server-filtered Germany set',
    );
    expect(allCount, greaterThan(nearCount));
    await screenshot(tester, 'radius_all_clusters');

    final radius30 = find.byKey(const ValueKey('map-radius-km30'));
    for (
      var attempt = 0;
      attempt < 5 && radius30.evaluate().isEmpty;
      attempt++
    ) {
      await tester.drag(radiusRow, const Offset(280, 0));
      await tester.pumpAndSettle();
    }
    expect(radius30, findsOneWidget);
    await tester.tap(radius30);
    await until(
      tester,
      () =>
          container.read(mapControllerProvider).radius == MapRadius.km30 &&
          container.read(mapControllerProvider).listings.length == nearCount,
      '30 km radius restores the Berlin marker set',
    );

    final privateListing = container
        .read(mapControllerProvider)
        .listings
        .firstWhere((item) => item.productId == privateProductId);
    final map = tester.widget<fm.FlutterMap>(find.byType(fm.FlutterMap));
    map.mapController!.move(
      LatLng(privateListing.marker.latitude, privateListing.marker.longitude),
      17,
    );
    await tester.pumpAndSettle();
    final privatePin = find.byKey(ValueKey('map-pin-$privateProductId'));
    expect(privatePin.hitTestable(), findsOneWidget);
    await tester.tap(privatePin.hitTestable());
    await tester.pumpAndSettle();

    expect(
      find.byKey(ValueKey('map-preview-$privateProductId')),
      findsOneWidget,
    );
    expect(find.text(_preciseAddress), findsNothing);
    expect(find.text('Route berechnen'), findsNothing);
    expect(
      find.text('Ungefährer Standort zum Schutz privater Verkäufer'),
      findsOneWidget,
    );
    await screenshot(tester, 'private_pin_preview');

    await tester.tap(
      find.byKey(ValueKey('map-open-listing-$privateProductId')),
    );
    await until(
      tester,
      () => find.byType(ProductDetailScreen).evaluate().isNotEmpty,
      'Map preview opens the existing listing detail screen',
    );
    final detail = tester.widget<ProductDetailScreen>(
      find.byType(ProductDetailScreen),
    );
    expect(detail.productId, privateProductId);
    expect(
      ProductDetailRoute(productId: privateProductId).location,
      '/products/$privateProductId',
    );
    await screenshot(tester, 'listing_detail_handoff');

    expect(checks, hasLength(4));
  });
}

double _number(Object? value) => switch (value) {
  final num number => number.toDouble(),
  final String text => double.parse(text),
  _ => throw FormatException('Expected numeric map value: $value'),
};

double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
  const earthRadius = 6371.0088;
  final latDelta = _radians(lat2 - lat1);
  final lngDelta = _radians(lng2 - lng1);
  final a =
      math.sin(latDelta / 2) * math.sin(latDelta / 2) +
      math.cos(_radians(lat1)) *
          math.cos(_radians(lat2)) *
          math.sin(lngDelta / 2) *
          math.sin(lngDelta / 2);
  return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _radians(double degrees) => degrees * math.pi / 180;
