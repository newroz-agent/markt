// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$homeRepositoryHash() => r'b6f39bcf6cbe275cb297a1f390b33b3b865a21ad';

/// See also [homeRepository].
@ProviderFor(homeRepository)
final homeRepositoryProvider = Provider<HomeRepository>.internal(
  homeRepository,
  name: r'homeRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$homeRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HomeRepositoryRef = ProviderRef<HomeRepository>;
String _$homeFeedHash() => r'58e90a64e7e5dc394ff9de005652f96bc37a634e';

/// See also [homeFeed].
@ProviderFor(homeFeed)
final homeFeedProvider = AutoDisposeFutureProvider<HomeFeed>.internal(
  homeFeed,
  name: r'homeFeedProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$homeFeedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HomeFeedRef = AutoDisposeFutureProviderRef<HomeFeed>;
String _$homeProductHash() => r'6711b896746e571f9dd0a513864f3e844b82b475';

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

/// See also [homeProduct].
@ProviderFor(homeProduct)
const homeProductProvider = HomeProductFamily();

/// See also [homeProduct].
class HomeProductFamily extends Family<AsyncValue<HomeProduct?>> {
  /// See also [homeProduct].
  const HomeProductFamily();

  /// See also [homeProduct].
  HomeProductProvider call({required String productId}) {
    return HomeProductProvider(productId: productId);
  }

  @override
  HomeProductProvider getProviderOverride(
    covariant HomeProductProvider provider,
  ) {
    return call(productId: provider.productId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'homeProductProvider';
}

/// See also [homeProduct].
class HomeProductProvider extends AutoDisposeFutureProvider<HomeProduct?> {
  /// See also [homeProduct].
  HomeProductProvider({required String productId})
    : this._internal(
        (ref) => homeProduct(ref as HomeProductRef, productId: productId),
        from: homeProductProvider,
        name: r'homeProductProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$homeProductHash,
        dependencies: HomeProductFamily._dependencies,
        allTransitiveDependencies: HomeProductFamily._allTransitiveDependencies,
        productId: productId,
      );

  HomeProductProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.productId,
  }) : super.internal();

  final String productId;

  @override
  Override overrideWith(
    FutureOr<HomeProduct?> Function(HomeProductRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HomeProductProvider._internal(
        (ref) => create(ref as HomeProductRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        productId: productId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<HomeProduct?> createElement() {
    return _HomeProductProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HomeProductProvider && other.productId == productId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, productId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin HomeProductRef on AutoDisposeFutureProviderRef<HomeProduct?> {
  /// The parameter `productId` of this provider.
  String get productId;
}

class _HomeProductProviderElement
    extends AutoDisposeFutureProviderElement<HomeProduct?>
    with HomeProductRef {
  _HomeProductProviderElement(super.provider);

  @override
  String get productId => (origin as HomeProductProvider).productId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
