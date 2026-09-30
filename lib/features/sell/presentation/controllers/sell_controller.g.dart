// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sell_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sellRepositoryHash() => r'cbd6ddbbddce99da49223ba3f7354bd3c1464ea1';

/// See also [sellRepository].
@ProviderFor(sellRepository)
final sellRepositoryProvider = Provider<SellRepository>.internal(
  sellRepository,
  name: r'sellRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sellRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SellRepositoryRef = ProviderRef<SellRepository>;
String _$sellImageServiceHash() => r'e5965c3e2397bd5b84584756a5ead8d3e6e17931';

/// See also [sellImageService].
@ProviderFor(sellImageService)
final sellImageServiceProvider = Provider<SellImageService>.internal(
  sellImageService,
  name: r'sellImageServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sellImageServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SellImageServiceRef = ProviderRef<SellImageService>;
String _$listingTemplatesHash() => r'37586c5e5a073a4949ad7d34a235917e545d6e0b';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [listingTemplates].
@ProviderFor(listingTemplates)
const listingTemplatesProvider = ListingTemplatesFamily();

/// See also [listingTemplates].
class ListingTemplatesFamily extends Family<AsyncValue<List<ListingTemplate>>> {
  /// See also [listingTemplates].
  const ListingTemplatesFamily();

  /// See also [listingTemplates].
  ListingTemplatesProvider call(String query) {
    return ListingTemplatesProvider(query);
  }

  @override
  ListingTemplatesProvider getProviderOverride(
    covariant ListingTemplatesProvider provider,
  ) {
    return call(provider.query);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'listingTemplatesProvider';
}

/// See also [listingTemplates].
class ListingTemplatesProvider
    extends AutoDisposeFutureProvider<List<ListingTemplate>> {
  /// See also [listingTemplates].
  ListingTemplatesProvider(String query)
    : this._internal(
        (ref) => listingTemplates(ref as ListingTemplatesRef, query),
        from: listingTemplatesProvider,
        name: r'listingTemplatesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$listingTemplatesHash,
        dependencies: ListingTemplatesFamily._dependencies,
        allTransitiveDependencies:
            ListingTemplatesFamily._allTransitiveDependencies,
        query: query,
      );

  ListingTemplatesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.query,
  }) : super.internal();

  final String query;

  @override
  Override overrideWith(
    FutureOr<List<ListingTemplate>> Function(ListingTemplatesRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ListingTemplatesProvider._internal(
        (ref) => create(ref as ListingTemplatesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<ListingTemplate>> createElement() {
    return _ListingTemplatesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ListingTemplatesProvider && other.query == query;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ListingTemplatesRef
    on AutoDisposeFutureProviderRef<List<ListingTemplate>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _ListingTemplatesProviderElement
    extends AutoDisposeFutureProviderElement<List<ListingTemplate>>
    with ListingTemplatesRef {
  _ListingTemplatesProviderElement(super.provider);

  @override
  String get query => (origin as ListingTemplatesProvider).query;
}

String _$myListingsHash() => r'ce0e6376c2480b2758bf07302059241a246536d4';

/// See also [myListings].
@ProviderFor(myListings)
final myListingsProvider = AutoDisposeFutureProvider<List<MyListing>>.internal(
  myListings,
  name: r'myListingsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$myListingsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MyListingsRef = AutoDisposeFutureProviderRef<List<MyListing>>;
String _$sellSubmissionControllerHash() =>
    r'ba8f74ab3b7091cae4c097b7f8e0e20fec1a99e6';

/// See also [SellSubmissionController].
@ProviderFor(SellSubmissionController)
final sellSubmissionControllerProvider =
    AutoDisposeAsyncNotifierProvider<
      SellSubmissionController,
      MyListing?
    >.internal(
      SellSubmissionController.new,
      name: r'sellSubmissionControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$sellSubmissionControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SellSubmissionController = AutoDisposeAsyncNotifier<MyListing?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
