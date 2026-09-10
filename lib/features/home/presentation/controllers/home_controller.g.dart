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

String _$sellerProfileHash() => r'21ee56b755a76a2409a011a4c6d3a54d9a5bae8f';

/// See also [sellerProfile].
@ProviderFor(sellerProfile)
const sellerProfileProvider = SellerProfileFamily();

/// See also [sellerProfile].
class SellerProfileFamily extends Family<AsyncValue<MarketplaceStore?>> {
  /// See also [sellerProfile].
  const SellerProfileFamily();

  /// See also [sellerProfile].
  SellerProfileProvider call({required String sellerId}) {
    return SellerProfileProvider(sellerId: sellerId);
  }

  @override
  SellerProfileProvider getProviderOverride(
    covariant SellerProfileProvider provider,
  ) {
    return call(sellerId: provider.sellerId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'sellerProfileProvider';
}

/// See also [sellerProfile].
class SellerProfileProvider
    extends AutoDisposeFutureProvider<MarketplaceStore?> {
  /// See also [sellerProfile].
  SellerProfileProvider({required String sellerId})
    : this._internal(
        (ref) => sellerProfile(ref as SellerProfileRef, sellerId: sellerId),
        from: sellerProfileProvider,
        name: r'sellerProfileProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$sellerProfileHash,
        dependencies: SellerProfileFamily._dependencies,
        allTransitiveDependencies:
            SellerProfileFamily._allTransitiveDependencies,
        sellerId: sellerId,
      );

  SellerProfileProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.sellerId,
  }) : super.internal();

  final String sellerId;

  @override
  Override overrideWith(
    FutureOr<MarketplaceStore?> Function(SellerProfileRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SellerProfileProvider._internal(
        (ref) => create(ref as SellerProfileRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        sellerId: sellerId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<MarketplaceStore?> createElement() {
    return _SellerProfileProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SellerProfileProvider && other.sellerId == sellerId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, sellerId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SellerProfileRef on AutoDisposeFutureProviderRef<MarketplaceStore?> {
  /// The parameter `sellerId` of this provider.
  String get sellerId;
}

class _SellerProfileProviderElement
    extends AutoDisposeFutureProviderElement<MarketplaceStore?>
    with SellerProfileRef {
  _SellerProfileProviderElement(super.provider);

  @override
  String get sellerId => (origin as SellerProfileProvider).sellerId;
}

String _$sellerProductsHash() => r'3c9aa0fe95b86f65bdb1f2886bcc3f5c2814db43';

/// See also [sellerProducts].
@ProviderFor(sellerProducts)
const sellerProductsProvider = SellerProductsFamily();

/// See also [sellerProducts].
class SellerProductsFamily extends Family<AsyncValue<List<HomeProduct>>> {
  /// See also [sellerProducts].
  const SellerProductsFamily();

  /// See also [sellerProducts].
  SellerProductsProvider call({
    required String sellerId,
    int offset = 0,
    int limit = 24,
    String? excludeProductId,
  }) {
    return SellerProductsProvider(
      sellerId: sellerId,
      offset: offset,
      limit: limit,
      excludeProductId: excludeProductId,
    );
  }

  @override
  SellerProductsProvider getProviderOverride(
    covariant SellerProductsProvider provider,
  ) {
    return call(
      sellerId: provider.sellerId,
      offset: provider.offset,
      limit: provider.limit,
      excludeProductId: provider.excludeProductId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'sellerProductsProvider';
}

/// See also [sellerProducts].
class SellerProductsProvider
    extends AutoDisposeFutureProvider<List<HomeProduct>> {
  /// See also [sellerProducts].
  SellerProductsProvider({
    required String sellerId,
    int offset = 0,
    int limit = 24,
    String? excludeProductId,
  }) : this._internal(
         (ref) => sellerProducts(
           ref as SellerProductsRef,
           sellerId: sellerId,
           offset: offset,
           limit: limit,
           excludeProductId: excludeProductId,
         ),
         from: sellerProductsProvider,
         name: r'sellerProductsProvider',
         debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
             ? null
             : _$sellerProductsHash,
         dependencies: SellerProductsFamily._dependencies,
         allTransitiveDependencies:
             SellerProductsFamily._allTransitiveDependencies,
         sellerId: sellerId,
         offset: offset,
         limit: limit,
         excludeProductId: excludeProductId,
       );

  SellerProductsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.sellerId,
    required this.offset,
    required this.limit,
    required this.excludeProductId,
  }) : super.internal();

  final String sellerId;
  final int offset;
  final int limit;
  final String? excludeProductId;

  @override
  Override overrideWith(
    FutureOr<List<HomeProduct>> Function(SellerProductsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SellerProductsProvider._internal(
        (ref) => create(ref as SellerProductsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        sellerId: sellerId,
        offset: offset,
        limit: limit,
        excludeProductId: excludeProductId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<HomeProduct>> createElement() {
    return _SellerProductsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SellerProductsProvider &&
        other.sellerId == sellerId &&
        other.offset == offset &&
        other.limit == limit &&
        other.excludeProductId == excludeProductId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, sellerId.hashCode);
    hash = _SystemHash.combine(hash, offset.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);
    hash = _SystemHash.combine(hash, excludeProductId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SellerProductsRef on AutoDisposeFutureProviderRef<List<HomeProduct>> {
  /// The parameter `sellerId` of this provider.
  String get sellerId;

  /// The parameter `offset` of this provider.
  int get offset;

  /// The parameter `limit` of this provider.
  int get limit;

  /// The parameter `excludeProductId` of this provider.
  String? get excludeProductId;
}

class _SellerProductsProviderElement
    extends AutoDisposeFutureProviderElement<List<HomeProduct>>
    with SellerProductsRef {
  _SellerProductsProviderElement(super.provider);

  @override
  String get sellerId => (origin as SellerProductsProvider).sellerId;
  @override
  int get offset => (origin as SellerProductsProvider).offset;
  @override
  int get limit => (origin as SellerProductsProvider).limit;
  @override
  String? get excludeProductId =>
      (origin as SellerProductsProvider).excludeProductId;
}

String _$similarProductsHash() => r'74dd3cb844f366ff0973557185538598305a7fe9';

/// See also [similarProducts].
@ProviderFor(similarProducts)
const similarProductsProvider = SimilarProductsFamily();

/// See also [similarProducts].
class SimilarProductsFamily extends Family<AsyncValue<List<HomeProduct>>> {
  /// See also [similarProducts].
  const SimilarProductsFamily();

  /// See also [similarProducts].
  SimilarProductsProvider call({
    required String productId,
    required String categoryId,
  }) {
    return SimilarProductsProvider(
      productId: productId,
      categoryId: categoryId,
    );
  }

  @override
  SimilarProductsProvider getProviderOverride(
    covariant SimilarProductsProvider provider,
  ) {
    return call(productId: provider.productId, categoryId: provider.categoryId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'similarProductsProvider';
}

/// See also [similarProducts].
class SimilarProductsProvider
    extends AutoDisposeFutureProvider<List<HomeProduct>> {
  /// See also [similarProducts].
  SimilarProductsProvider({
    required String productId,
    required String categoryId,
  }) : this._internal(
         (ref) => similarProducts(
           ref as SimilarProductsRef,
           productId: productId,
           categoryId: categoryId,
         ),
         from: similarProductsProvider,
         name: r'similarProductsProvider',
         debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
             ? null
             : _$similarProductsHash,
         dependencies: SimilarProductsFamily._dependencies,
         allTransitiveDependencies:
             SimilarProductsFamily._allTransitiveDependencies,
         productId: productId,
         categoryId: categoryId,
       );

  SimilarProductsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.productId,
    required this.categoryId,
  }) : super.internal();

  final String productId;
  final String categoryId;

  @override
  Override overrideWith(
    FutureOr<List<HomeProduct>> Function(SimilarProductsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SimilarProductsProvider._internal(
        (ref) => create(ref as SimilarProductsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        productId: productId,
        categoryId: categoryId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<HomeProduct>> createElement() {
    return _SimilarProductsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SimilarProductsProvider &&
        other.productId == productId &&
        other.categoryId == categoryId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, productId.hashCode);
    hash = _SystemHash.combine(hash, categoryId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SimilarProductsRef on AutoDisposeFutureProviderRef<List<HomeProduct>> {
  /// The parameter `productId` of this provider.
  String get productId;

  /// The parameter `categoryId` of this provider.
  String get categoryId;
}

class _SimilarProductsProviderElement
    extends AutoDisposeFutureProviderElement<List<HomeProduct>>
    with SimilarProductsRef {
  _SimilarProductsProviderElement(super.provider);

  @override
  String get productId => (origin as SimilarProductsProvider).productId;
  @override
  String get categoryId => (origin as SimilarProductsProvider).categoryId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
