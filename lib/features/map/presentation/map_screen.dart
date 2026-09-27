import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:zerin_marketplace/app/router/app_router.dart';
import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/features/categories/domain/marketplace_category.dart';
import 'package:zerin_marketplace/features/categories/presentation/controllers/category_controller.dart';
import 'package:zerin_marketplace/features/home/presentation/home_formatters.dart';
import 'package:zerin_marketplace/features/map/domain/device_location_service.dart';
import 'package:zerin_marketplace/features/map/domain/map_models.dart';
import 'package:zerin_marketplace/features/map/presentation/controllers/map_controller.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

typedef MapTileLayerBuilder = Widget Function();

/// Injectable so widget tests can exercise real marker/controller behavior
/// without making tile-network requests. Production always uses OSM tiles.
final mapTileLayerBuilderProvider = Provider<MapTileLayerBuilder>(
  (ref) =>
      () => fm.TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'de.zerin.marketplace',
        maxZoom: 19,
      ),
);

/// Dedicated public marketplace Map route. It intentionally lives outside the
/// five-tab shell and receives only privacy-safe server-projected marker points.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({this.initialCategoryId, super.key});

  final String? initialCategoryId;

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  static final Uri _osmCopyright = Uri.https(
    'www.openstreetmap.org',
    '/copyright',
  );

  final fm.MapController _flutterMapController = fm.MapController();
  bool _mapReady = false;
  bool _initialCategoryApplied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyInitialCategory();
    });
  }

  void _applyInitialCategory() {
    if (_initialCategoryApplied) return;
    _initialCategoryApplied = true;
    final categoryId = widget.initialCategoryId?.trim();
    if (categoryId == null || categoryId.isEmpty) return;
    final controller = ref.read(mapControllerProvider.notifier);
    final current = ref.read(mapControllerProvider).filters;
    unawaited(controller.setFilters(current.copyWith(categoryId: categoryId)));
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCategoryId != widget.initialCategoryId) {
      _initialCategoryApplied = false;
      _applyInitialCategory();
    }
  }

  @override
  void dispose() {
    _flutterMapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mapControllerProvider);
    final controller = ref.read(mapControllerProvider.notifier);
    final l10n = context.l10n;

    ref.listen<MapControllerState>(mapControllerProvider, (previous, next) {
      if (!_mapReady) return;
      final centerChanged = previous?.center != next.center;
      final radiusChanged = previous?.radius != next.radius;
      if (!centerChanged && !radiusChanged) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_mapReady) return;
        _flutterMapController.move(_latLng(next.center), _zoomFor(next.radius));
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mapTitle),
        actions: <Widget>[
          Badge(
            isLabelVisible: _activeFilterCount(state.filters) > 0,
            label: Text('${_activeFilterCount(state.filters)}'),
            child: IconButton(
              key: const ValueKey('map-filter-action'),
              tooltip: l10n.mapFiltersTooltip,
              onPressed: () => _showFilters(state.filters),
              icon: const Icon(Icons.tune_rounded),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: fm.FlutterMap(
              key: const ValueKey('step-d-map'),
              mapController: _flutterMapController,
              options: fm.MapOptions(
                initialCenter: _latLng(state.center),
                initialZoom: _zoomFor(state.radius),
                minZoom: 5,
                maxZoom: 18,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                onMapReady: () => _mapReady = true,
              ),
              children: <Widget>[
                ref.watch(mapTileLayerBuilderProvider)(),
                if (state.centerSource == MapCenterSource.currentLocation)
                  fm.CircleLayer(
                    circles: <fm.CircleMarker>[
                      fm.CircleMarker(
                        point: _latLng(state.center),
                        radius: 10,
                        color: Theme.of(context).colorScheme.primary.withValues(
                          alpha: AppOpacity.overlay,
                        ),
                        borderColor: Theme.of(context).colorScheme.primary,
                        borderStrokeWidth: AppStrokes.heavy,
                      ),
                    ],
                  ),
                MarkerClusterLayerWidget(
                  options: MarkerClusterLayerOptions(
                    markers: _markers(state.listings),
                    size: const Size(48, 48),
                    maxClusterRadius: 72,
                    disableClusteringAtZoom: 16,
                    maxZoom: 18,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    alignment: Alignment.center,
                    markerChildBehavior: true,
                    showPolygon: false,
                    builder: (context, markers) =>
                        _ClusterPin(count: markers.length),
                  ),
                ),
              ],
            ),
          ),
          PositionedDirectional(
            top: AppSpacing.sm,
            start: AppSpacing.sm,
            end: AppSpacing.sm,
            child: _MapControlPanel(
              state: state,
              onRadiusChanged: controller.setRadius,
              onChooseCity: _showCityPicker,
            ),
          ),
          PositionedDirectional(
            top: 150,
            end: AppSpacing.sm,
            child: Column(
              children: <Widget>[
                _MapIconButton(
                  key: const ValueKey('map-current-location-action'),
                  tooltip: l10n.mapUseMyLocation,
                  loading:
                      state.locationStatus == DeviceLocationStatus.requesting,
                  icon: Icons.my_location_rounded,
                  onPressed: controller.retryCurrentLocation,
                ),
                const SizedBox(height: AppSpacing.xs),
                _MapIconButton(
                  key: const ValueKey('map-city-action'),
                  tooltip: l10n.mapChooseCity,
                  icon: Icons.location_city_rounded,
                  onPressed: _showCityPicker,
                ),
              ],
            ),
          ),
          if (state.isRefreshing && state.listings.isNotEmpty)
            const PositionedDirectional(
              top: 142,
              start: AppSpacing.md,
              end: AppSpacing.md,
              child: LinearProgressIndicator(minHeight: AppStrokes.progress),
            ),
          if (state.isRefreshing &&
              state.listings.isEmpty &&
              !state.hasInitialized)
            Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const SizedBox.square(
                        dimension: AppSizes.iconMedium,
                        child: CircularProgressIndicator(
                          strokeWidth: AppStrokes.progress,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(l10n.mapLoading),
                    ],
                  ),
                ),
              ),
            ),
          if (state.hasInitialized &&
              !state.isRefreshing &&
              state.listings.isEmpty)
            PositionedDirectional(
              start: AppSpacing.md,
              end: AppSpacing.md,
              bottom: 104,
              child: _MapMessageCard(
                icon: Icons.location_searching_rounded,
                title: l10n.mapEmptyTitle,
                body: l10n.mapEmptyBody,
              ),
            ),
          if (state.listingsError != null && !state.isRefreshing)
            PositionedDirectional(
              start: AppSpacing.md,
              end: AppSpacing.md,
              bottom: 104,
              child: _MapMessageCard(
                icon: Icons.cloud_off_rounded,
                title: l10n.stateErrorTitle,
                body: l10n.stateErrorMessage,
                action: TextButton(
                  onPressed: controller.refresh,
                  child: Text(l10n.actionRetry),
                ),
              ),
            ),
          if (_locationMessage(l10n, state.locationStatus) case final message?)
            PositionedDirectional(
              start: AppSpacing.md,
              end: AppSpacing.md,
              bottom: 48,
              child: _LocationFallbackBanner(
                message: message,
                onChooseCity: _showCityPicker,
                onRetry: controller.retryCurrentLocation,
              ),
            ),
          PositionedDirectional(
            end: AppSpacing.xs,
            bottom: AppSpacing.xs,
            child: Material(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: AppOpacity.raised),
              borderRadius: AppRadius.small,
              child: InkWell(
                borderRadius: AppRadius.small,
                onTap: () => launchUrl(
                  _osmCopyright,
                  mode: LaunchMode.externalApplication,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xxs,
                  ),
                  child: Text(
                    l10n.mapOsmAttribution,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<fm.Marker> _markers(List<MapListing> listings) => <fm.Marker>[
    for (final listing in listings)
      fm.Marker(
        point: _latLng(listing.marker),
        width: 54,
        height: 54,
        alignment: Alignment.topCenter,
        child: Semantics(
          button: true,
          label: context.l10n.mapPinSemantic(
            title: listing.title,
            city: listing.city,
          ),
          child: GestureDetector(
            key: ValueKey('map-pin-${listing.productId}'),
            behavior: HitTestBehavior.opaque,
            onTap: () => _showListingPreview(listing),
            child: _ListingPin(preciseBusiness: listing.isPreciseBusiness),
          ),
        ),
      ),
  ];

  Future<void> _showCityPicker() async {
    final state = ref.read(mapControllerProvider);
    final selected = await showAppBottomSheet<GermanCity>(
      context: context,
      title: context.l10n.mapChooseCity,
      scrollable: false,
      child: _CityPickerSheet(
        cities: state.cities,
        selected: state.selectedCity,
      ),
    );
    if (selected != null && mounted) {
      await ref.read(mapControllerProvider.notifier).selectCity(selected);
    }
  }

  Future<void> _showFilters(MapFilters initial) async {
    final filters = await showAppBottomSheet<MapFilters>(
      context: context,
      title: context.l10n.mapFiltersTitle,
      scrollable: false,
      child: _MapFilterSheet(initial: initial),
    );
    if (filters != null && mounted) {
      await ref.read(mapControllerProvider.notifier).setFilters(filters);
    }
  }

  Future<void> _showListingPreview(MapListing listing) async {
    await showAppBottomSheet<void>(
      context: context,
      title: listing.title,
      child: _ListingPreview(
        listing: listing,
        onDirections: () => _openDirections(listing),
        onOpenListing: () => _openListing(listing),
      ),
    );
  }

  Future<void> _openDirections(MapListing listing) async {
    final opened = await ref
        .read(directionsLauncherProvider)
        .launchDirections(listing);
    if (!opened && mounted) {
      AppSnackBar.show(
        context,
        message: context.l10n.mapDirectionsFailed,
        variant: AppSnackBarVariant.error,
      );
    }
  }

  Future<void> _openListing(MapListing listing) async {
    Navigator.of(context).pop();
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    await ProductDetailRoute(
      productId: listing.productId,
      heroTag: 'map-${listing.productId}',
    ).push<void>(context);
  }
}

class _MapControlPanel extends StatelessWidget {
  const _MapControlPanel({
    required this.state,
    required this.onRadiusChanged,
    required this.onChooseCity,
  });

  final MapControllerState state;
  final ValueChanged<MapRadius> onRadiusChanged;
  final VoidCallback onChooseCity;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final centerLabel = state.centerSource == MapCenterSource.currentLocation
        ? l10n.mapCenterCurrent
        : l10n.mapCenterCity(
            city: state.selectedCity?.name ?? GermanCity.berlin.name,
          );
    return Material(
      color: Theme.of(
        context,
      ).colorScheme.surface.withValues(alpha: AppOpacity.strong),
      elevation: AppElevation.low,
      borderRadius: AppRadius.large,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.place_outlined, size: AppSizes.iconMedium),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      centerLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  TextButton(
                    key: const ValueKey('map-center-city-button'),
                    onPressed: onChooseCity,
                    child: Text(l10n.mapChooseCity),
                  ),
                ],
              ),
              SizedBox(
                height: AppSizes.chipHeight,
                child: ListView.separated(
                  key: const ValueKey('map-radius-row'),
                  scrollDirection: Axis.horizontal,
                  itemCount: MapRadius.values.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.xs),
                  itemBuilder: (context, index) {
                    final radius = MapRadius.values[index];
                    return AppChip(
                      key: ValueKey('map-radius-${radius.name}'),
                      label: _radiusLabel(l10n, radius),
                      selected: radius == state.radius,
                      variant: AppChipVariant.outlined,
                      onSelected: (_) => onRadiusChanged(radius),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                l10n.mapListingsCount(count: state.result.totalCount),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapIconButton extends StatelessWidget {
  const _MapIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.loading = false,
    super.key,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    elevation: AppElevation.medium,
    shape: const CircleBorder(),
    child: IconButton(
      tooltip: tooltip,
      onPressed: loading ? null : onPressed,
      icon: loading
          ? const SizedBox.square(
              dimension: AppSizes.iconMedium,
              child: CircularProgressIndicator(
                strokeWidth: AppStrokes.progress,
              ),
            )
          : Icon(icon),
    ),
  );
}

class _ListingPin extends StatelessWidget {
  const _ListingPin({required this.preciseBusiness});

  final bool preciseBusiness;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.topCenter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: preciseBusiness
              ? context.semanticColors.accent
              : scheme.primary,
          shape: BoxShape.circle,
          border: Border.all(color: scheme.surface, width: AppStrokes.heavy),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: scheme.shadow.withValues(alpha: AppOpacity.overlay),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: SizedBox.square(
          dimension: 44,
          child: Icon(
            preciseBusiness ? Icons.store_rounded : Icons.location_on_rounded,
            color: preciseBusiness
                ? context.semanticColors.onAccent
                : scheme.onPrimary,
          ),
        ),
      ),
    );
  }
}

class _ClusterPin extends StatelessWidget {
  const _ClusterPin({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.mapClusterSemantic(count: count),
    button: true,
    child: DecoratedBox(
      key: ValueKey('map-cluster-$count'),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: AppStrokes.heavy,
        ),
      ),
      child: Center(
        child: Text(
          '$count',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}

class _MapMessageCard extends StatelessWidget {
  const _MapMessageCard({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: <Widget>[
          Icon(icon),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                Text(body, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (action case final action?) ...<Widget>[
            const SizedBox(width: AppSpacing.xs),
            action,
          ],
        ],
      ),
    ),
  );
}

class _LocationFallbackBanner extends StatelessWidget {
  const _LocationFallbackBanner({
    required this.message,
    required this.onChooseCity,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onChooseCity;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    key: const ValueKey('map-location-fallback'),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(message, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              TextButton(
                onPressed: onRetry,
                child: Text(context.l10n.actionRetry),
              ),
              TextButton(
                key: const ValueKey('map-fallback-city-action'),
                onPressed: onChooseCity,
                child: Text(context.l10n.mapChooseCity),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _CityPickerSheet extends StatefulWidget {
  const _CityPickerSheet({required this.cities, required this.selected});

  final List<GermanCity> cities;
  final GermanCity? selected;

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalized = _query.trim().toLowerCase();
    final visible = widget.cities
        .where(
          (city) =>
              normalized.isEmpty ||
              city.name.toLowerCase().contains(normalized),
        )
        .toList(growable: false);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.62,
      child: Column(
        children: <Widget>[
          AppTextField(
            key: const ValueKey('map-city-search'),
            controller: _search,
            hint: context.l10n.mapCitySearchHint,
            prefix: const Icon(Icons.search_rounded),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: ListView.builder(
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final city = visible[index];
                final selected = city.name == widget.selected?.name;
                return ListTile(
                  key: ValueKey('map-city-${city.name}'),
                  leading: Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                  ),
                  title: Text(city.name),
                  onTap: () => Navigator.of(context).pop(city),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MapFilterSheet extends ConsumerStatefulWidget {
  const _MapFilterSheet({required this.initial});

  final MapFilters initial;

  @override
  ConsumerState<_MapFilterSheet> createState() => _MapFilterSheetState();
}

class _MapFilterSheetState extends ConsumerState<_MapFilterSheet> {
  late String? _categoryId;
  late MapListingCondition? _condition;
  late MapSellerKind? _sellerKind;
  late final TextEditingController _minimum;
  late final TextEditingController _maximum;
  String? _priceError;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initial.categoryId;
    _condition = widget.initial.condition;
    _sellerKind = widget.initial.sellerKind;
    _minimum = TextEditingController(
      text: _euroText(widget.initial.minPriceCents),
    );
    _maximum = TextEditingController(
      text: _euroText(widget.initial.maxPriceCents),
    );
  }

  @override
  void dispose() {
    _minimum.dispose();
    _maximum.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final categories =
        ref.watch(activeCategoriesProvider).asData?.value ??
        const <MarketplaceCategory>[];
    final knownCategory = categories.any(
      (category) => category.id == _categoryId,
    );
    if (!knownCategory) _categoryId = null;

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.64,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: ListView(
              children: <Widget>[
                DropdownButtonFormField<String?>(
                  key: const ValueKey('map-filter-category'),
                  initialValue: _categoryId,
                  decoration: InputDecoration(labelText: l10n.mapCategoryLabel),
                  items: <DropdownMenuItem<String?>>[
                    DropdownMenuItem<String?>(child: Text(l10n.mapCategoryAll)),
                    for (final category in categories)
                      DropdownMenuItem<String?>(
                        value: category.id,
                        child: Text(
                          category.nameForLanguage(
                            Localizations.localeOf(context).languageCode,
                          ),
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => _categoryId = value),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<MapListingCondition?>(
                  key: const ValueKey('map-filter-condition'),
                  initialValue: _condition,
                  decoration: InputDecoration(
                    labelText: l10n.filterConditionLabel,
                  ),
                  items: <DropdownMenuItem<MapListingCondition?>>[
                    DropdownMenuItem<MapListingCondition?>(
                      child: Text(l10n.mapConditionAll),
                    ),
                    DropdownMenuItem<MapListingCondition?>(
                      value: MapListingCondition.newItem,
                      child: Text(l10n.productConditionNew),
                    ),
                    DropdownMenuItem<MapListingCondition?>(
                      value: MapListingCondition.used,
                      child: Text(l10n.productConditionUsed),
                    ),
                  ],
                  onChanged: (value) => setState(() => _condition = value),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<MapSellerKind?>(
                  key: const ValueKey('map-filter-seller-kind'),
                  initialValue: _sellerKind,
                  decoration: InputDecoration(
                    labelText: l10n.filterSellerKindLabel,
                  ),
                  items: <DropdownMenuItem<MapSellerKind?>>[
                    DropdownMenuItem<MapSellerKind?>(
                      child: Text(l10n.filterSellerKindAll),
                    ),
                    DropdownMenuItem<MapSellerKind?>(
                      value: MapSellerKind.privateSeller,
                      child: Text(l10n.filterSellerKindPrivate),
                    ),
                    DropdownMenuItem<MapSellerKind?>(
                      value: MapSellerKind.business,
                      child: Text(l10n.filterSellerKindBusiness),
                    ),
                  ],
                  onChanged: (value) => setState(() => _sellerKind = value),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: AppTextField(
                        key: const ValueKey('map-filter-min-price'),
                        controller: _minimum,
                        label: l10n.mapPriceMin,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppTextField(
                        key: const ValueKey('map-filter-max-price'),
                        controller: _maximum,
                        label: l10n.mapPriceMax,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_priceError case final error?) ...<Widget>[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: AppButton.ghost(
                  label: l10n.actionClearAll,
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(MapFilters(sort: widget.initial.sort)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  key: const ValueKey('map-filter-apply'),
                  label: l10n.actionApply,
                  onPressed: _apply,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _apply() {
    final minimum = _parseEuros(_minimum.text);
    final maximum = _parseEuros(_maximum.text);
    final invalid =
        (_minimum.text.trim().isNotEmpty && minimum == null) ||
        (_maximum.text.trim().isNotEmpty && maximum == null) ||
        (minimum != null && maximum != null && minimum > maximum);
    if (invalid) {
      setState(() => _priceError = context.l10n.mapPriceInvalid);
      return;
    }
    Navigator.of(context).pop(
      MapFilters(
        query: widget.initial.query,
        categoryId: _categoryId,
        condition: _condition,
        sellerKind: _sellerKind,
        minPriceCents: minimum,
        maxPriceCents: maximum,
        sort: widget.initial.sort,
      ),
    );
  }
}

class _ListingPreview extends StatelessWidget {
  const _ListingPreview({
    required this.listing,
    required this.onDirections,
    required this.onOpenListing,
  });

  final MapListing listing;
  final VoidCallback onDirections;
  final VoidCallback onOpenListing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final price = formatMarketplacePrice(
      Localizations.localeOf(context),
      listing.priceCents,
      listing.currency,
    );
    return Column(
      key: ValueKey('map-preview-${listing.productId}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ClipRRect(
          borderRadius: AppRadius.large,
          child: SizedBox(
            height: 180,
            child: listing.previewImageUrl == null
                ? ColoredBox(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    child: const Center(child: Icon(Icons.image_outlined)),
                  )
                : CachedNetworkImage(
                    imageUrl: listing.previewImageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => ColoredBox(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(listing.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          price,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            AppChip(
              label: listing.condition == MapListingCondition.newItem
                  ? l10n.productConditionNew
                  : l10n.productConditionUsed,
              leading: const Icon(
                Icons.sell_outlined,
                size: AppSizes.iconSmall,
              ),
            ),
            AppChip(
              label: listing.city,
              leading: const Icon(
                Icons.location_city_outlined,
                size: AppSizes.iconSmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              listing.isPreciseBusiness
                  ? Icons.verified_rounded
                  : Icons.privacy_tip_outlined,
              size: AppSizes.iconMedium,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                listing.isPreciseBusiness
                    ? l10n.mapPreciseStoreLocation
                    : l10n.mapApproximateLocation,
              ),
            ),
          ],
        ),
        if (listing.isPreciseBusiness &&
            listing.publicAddress != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(listing.publicAddress!),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (listing.isPreciseBusiness) ...<Widget>[
          AppButton.secondary(
            key: ValueKey('map-directions-${listing.productId}'),
            label: l10n.mapDirections,
            leading: const Icon(Icons.directions_outlined),
            onPressed: onDirections,
            expand: true,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        AppButton(
          key: ValueKey('map-open-listing-${listing.productId}'),
          label: l10n.mapOpenListing,
          leading: const Icon(Icons.open_in_new_rounded),
          onPressed: onOpenListing,
          expand: true,
        ),
      ],
    );
  }
}

LatLng _latLng(MapPoint point) => LatLng(point.latitude, point.longitude);

double _zoomFor(MapRadius radius) => switch (radius) {
  MapRadius.km5 => 12,
  MapRadius.km10 => 11,
  MapRadius.km20 => 10,
  MapRadius.km30 => 9.5,
  MapRadius.km50 => 9,
  MapRadius.km100 => 8,
  MapRadius.all => 5.5,
};

String _radiusLabel(AppLocalizations l10n, MapRadius radius) =>
    radius.isAll ? l10n.mapRadiusAll : '${radius.kilometers} km';

int _activeFilterCount(MapFilters filters) => <Object?>[
  filters.query,
  filters.categoryId,
  filters.condition,
  filters.sellerKind,
  filters.minPriceCents,
  filters.maxPriceCents,
].where((value) => value != null).length;

String? _locationMessage(AppLocalizations l10n, DeviceLocationStatus status) =>
    switch (status) {
      DeviceLocationStatus.serviceDisabled => l10n.mapLocationServiceDisabled,
      DeviceLocationStatus.denied => l10n.mapLocationDenied,
      DeviceLocationStatus.deniedForever => l10n.mapLocationDeniedForever,
      DeviceLocationStatus.unavailable => l10n.mapLocationUnavailable,
      _ => null,
    };

String _euroText(int? cents) {
  if (cents == null) return '';
  if (cents % 100 == 0) return '${cents ~/ 100}';
  return (cents / 100).toStringAsFixed(2).replaceAll('.', ',');
}

int? _parseEuros(String value) {
  final normalized = value.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  final euros = double.tryParse(normalized);
  if (euros == null || !euros.isFinite || euros < 0) return null;
  return (euros * 100).round();
}
