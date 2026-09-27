import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zerin_marketplace/app/router/app_router.dart';
import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/features/map/domain/device_location_service.dart';
import 'package:zerin_marketplace/features/map/domain/directions_launcher.dart';
import 'package:zerin_marketplace/features/map/domain/map_models.dart';
import 'package:zerin_marketplace/features/map/domain/map_repository.dart';
import 'package:zerin_marketplace/features/map/presentation/controllers/map_controller.dart';
import 'package:zerin_marketplace/features/map/presentation/map_screen.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

void main() {
  testWidgets(
    'denied GPS falls back to Berlin and radius changes server query',
    (tester) async {
      final repository = _Repository(
        (query) => <MapListing>[_listing('radius-${query.radius.name}')],
      );
      final harness = await _pumpMap(tester, repository: repository);
      addTearDown(harness.router.dispose);

      expect(
        find.byKey(const ValueKey('map-location-fallback')),
        findsOneWidget,
      );
      expect(repository.queries.last.center, GermanCity.berlin.point);
      expect(repository.queries.last.radius, MapRadius.km30);
      expect(find.byKey(const ValueKey('map-pin-radius-km30')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('map-radius-km5')));
      await _settle(tester);

      expect(repository.queries.last.radius, MapRadius.km5);
      expect(find.byKey(const ValueKey('map-pin-radius-km5')), findsOneWidget);
      expect(find.byKey(const ValueKey('map-pin-radius-km30')), findsNothing);
    },
  );

  testWidgets('shared condition and price filters reach the server query', (
    tester,
  ) async {
    final repository = _Repository((_) => <MapListing>[_listing('filtered')]);
    final harness = await _pumpMap(tester, repository: repository);
    addTearDown(harness.router.dispose);

    await tester.tap(find.byKey(const ValueKey('map-filter-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('map-filter-condition')), findsOneWidget);
    expect(find.byKey(const ValueKey('map-filter-min-price')), findsOneWidget);
    expect(find.byKey(const ValueKey('map-filter-max-price')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('map-filter-condition')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Used').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('map-filter-min-price')),
        matching: find.byType(EditableText),
      ),
      '10',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('map-filter-max-price')),
        matching: find.byType(EditableText),
      ),
      '25,50',
    );
    await tester.tap(find.byKey(const ValueKey('map-filter-apply')));
    await tester.pumpAndSettle();

    final filters = repository.queries.last.filters;
    expect(filters.condition, MapListingCondition.used);
    expect(filters.minPriceCents, 1000);
    expect(filters.maxPriceCents, 2550);
  });

  testWidgets(
    'private pin preview has no address and opens existing detail path',
    (tester) async {
      final repository = _Repository((_) => <MapListing>[_listing('private')]);
      final harness = await _pumpMap(tester, repository: repository);
      addTearDown(harness.router.dispose);

      await tester.tap(find.byKey(const ValueKey('map-pin-private')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('map-preview-private')), findsOneWidget);
      expect(
        find.text('Approximate location protecting private sellers'),
        findsOneWidget,
      );
      expect(find.text('Private Street 1'), findsNothing);
      expect(find.text('Get directions'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('map-open-listing-private')));
      await tester.pumpAndSettle();

      expect(find.text('detail private'), findsOneWidget);
    },
  );

  testWidgets('verified-store preview alone exposes directions', (
    tester,
  ) async {
    final directions = _Directions();
    final repository = _Repository(
      (_) => <MapListing>[
        _listing('store', precise: true, address: 'Public Store Street 1'),
      ],
    );
    final harness = await _pumpMap(
      tester,
      repository: repository,
      directions: directions,
    );
    addTearDown(harness.router.dispose);

    await tester.tap(find.byKey(const ValueKey('map-pin-store')));
    await tester.pumpAndSettle();
    expect(
      find.text('Precise location of a verified business'),
      findsOneWidget,
    );
    expect(find.text('Public Store Street 1'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('map-directions-store')));
    await tester.pump();
    expect(directions.opened, <String>['store']);
  });

  testWidgets('nearby markers render as a tappable cluster', (tester) async {
    final repository = _Repository(
      (_) => <MapListing>[
        _listing('one'),
        _listing(
          'two',
          point: const MapPoint(latitude: 52.520009, longitude: 13.404955),
        ),
      ],
    );
    final harness = await _pumpMap(tester, repository: repository);
    addTearDown(harness.router.dispose);

    expect(find.byKey(const ValueKey('map-cluster-2')), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  test('typed Map route is dedicated and category-aware', () {
    expect(const MapRoute().location, '/map');
    expect(
      const MapRoute(categoryId: 'bikes').location,
      '/map?category-id=bikes',
    );
  });
}

Future<_Harness> _pumpMap(
  WidgetTester tester, {
  required _Repository repository,
  DirectionsLauncher? directions,
}) async {
  final router = GoRouter(
    initialLocation: '/map',
    routes: <RouteBase>[
      GoRoute(path: '/map', builder: (_, _) => const MapScreen()),
      GoRoute(
        path: '/products/:productId',
        builder: (_, state) =>
            Scaffold(body: Text('detail ${state.pathParameters['productId']}')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        mapRepositoryProvider.overrideWithValue(repository),
        deviceLocationServiceProvider.overrideWithValue(
          const _Location(DeviceLocationResult.denied()),
        ),
        directionsLauncherProvider.overrideWithValue(
          directions ?? _Directions(),
        ),
        mapTileLayerBuilderProvider.overrideWithValue(
          () => const ColoredBox(color: Color(0xFFE9E4D5)),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: AppLocale.english,
        supportedLocales: AppLocale.supportedLocales,
        localizationsDelegates: AppLocale.localizationsDelegates,
        theme: AppTheme.light,
      ),
    ),
  );
  await _settle(tester);
  return _Harness(router);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 600));
}

class _Harness {
  const _Harness(this.router);

  final GoRouter router;
}

class _Repository implements MapRepository {
  _Repository(this.listingsFor);

  final List<MapListing> Function(MapQuery query) listingsFor;
  final queries = <MapQuery>[];

  @override
  Future<List<GermanCity>> fetchGermanCities() async => const <GermanCity>[
    GermanCity.berlin,
  ];

  @override
  Future<MapSearchResult> fetchListings(MapQuery query) async {
    queries.add(query);
    final listings = listingsFor(query);
    return MapSearchResult(
      listings: listings,
      totalCount: listings.length,
      offset: query.offset,
      limit: query.limit,
      nextOffset: query.offset + listings.length,
    );
  }
}

class _Location implements DeviceLocationService {
  const _Location(this.result);

  final DeviceLocationResult result;

  @override
  Future<DeviceLocationResult> getCurrentLocation() async => result;
}

class _Directions implements DirectionsLauncher {
  final opened = <String>[];

  @override
  Future<bool> launchDirections(MapListing listing) async {
    opened.add(listing.productId);
    return true;
  }
}

MapListing _listing(
  String id, {
  bool precise = false,
  String? address,
  MapPoint? point,
}) => MapListing(
  productId: id,
  title: 'Listing $id',
  priceCents: 2500,
  currency: 'EUR',
  condition: MapListingCondition.used,
  city: 'Berlin',
  sellerId: 'seller-$id',
  sellerName: 'Seller',
  sellerKind: precise ? MapSellerKind.business : MapSellerKind.privateSeller,
  categoryId: 'category',
  marker: point ?? GermanCity.berlin.point,
  distanceKm: 1,
  isPreciseBusiness: precise,
  publicAddress: precise ? address : 'Private Street 1',
);
