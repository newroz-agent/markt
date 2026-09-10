// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_favorite_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$favoriteSessionHash() => r'29936172e455d186d722acab7076bd8ff9909ad5';

/// See also [_favoriteSession].
@ProviderFor(_favoriteSession)
final _favoriteSessionProvider = AutoDisposeProvider<_FavoriteSession>.internal(
  _favoriteSession,
  name: r'_favoriteSessionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$favoriteSessionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef _FavoriteSessionRef = AutoDisposeProviderRef<_FavoriteSession>;
String _$productFavoriteFutureHash() =>
    r'4206d8a4e6154aafbdaee6a4aabbbefa7fcdd234';

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

/// See also [_productFavoriteFuture].
@ProviderFor(_productFavoriteFuture)
const _productFavoriteFutureProvider = _ProductFavoriteFutureFamily();

/// See also [_productFavoriteFuture].
class _ProductFavoriteFutureFamily extends Family<AsyncValue<bool>> {
  /// See also [_productFavoriteFuture].
  const _ProductFavoriteFutureFamily();

  /// See also [_productFavoriteFuture].
  _ProductFavoriteFutureProvider call({required String productId}) {
    return _ProductFavoriteFutureProvider(productId: productId);
  }

  @override
  _ProductFavoriteFutureProvider getProviderOverride(
    covariant _ProductFavoriteFutureProvider provider,
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
  String? get name => r'_productFavoriteFutureProvider';
}

/// See also [_productFavoriteFuture].
class _ProductFavoriteFutureProvider extends AutoDisposeFutureProvider<bool> {
  /// See also [_productFavoriteFuture].
  _ProductFavoriteFutureProvider({required String productId})
    : this._internal(
        (ref) => _productFavoriteFuture(
          ref as _ProductFavoriteFutureRef,
          productId: productId,
        ),
        from: _productFavoriteFutureProvider,
        name: r'_productFavoriteFutureProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$productFavoriteFutureHash,
        dependencies: _ProductFavoriteFutureFamily._dependencies,
        allTransitiveDependencies:
            _ProductFavoriteFutureFamily._allTransitiveDependencies,
        productId: productId,
      );

  _ProductFavoriteFutureProvider._internal(
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
    FutureOr<bool> Function(_ProductFavoriteFutureRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: _ProductFavoriteFutureProvider._internal(
        (ref) => create(ref as _ProductFavoriteFutureRef),
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
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _ProductFavoriteFutureProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is _ProductFavoriteFutureProvider &&
        other.productId == productId;
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
mixin _ProductFavoriteFutureRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `productId` of this provider.
  String get productId;
}

class _ProductFavoriteFutureProviderElement
    extends AutoDisposeFutureProviderElement<bool>
    with _ProductFavoriteFutureRef {
  _ProductFavoriteFutureProviderElement(super.provider);

  @override
  String get productId => (origin as _ProductFavoriteFutureProvider).productId;
}

String _$productFavoriteHash() => r'589322181acc9fb696ec83cd9a20f4dca7eac0d0';

abstract class _$ProductFavorite
    extends BuildlessAutoDisposeNotifier<AsyncValue<bool>> {
  late final String productId;

  AsyncValue<bool> build({required String productId});
}

/// A synchronous facade avoids AsyncNotifier's previous-data retention across
/// accounts. Each auth session owns an independent async favorite notifier.
///
/// Copied from [ProductFavorite].
@ProviderFor(ProductFavorite)
const productFavoriteProvider = ProductFavoriteFamily();

/// A synchronous facade avoids AsyncNotifier's previous-data retention across
/// accounts. Each auth session owns an independent async favorite notifier.
///
/// Copied from [ProductFavorite].
class ProductFavoriteFamily extends Family<AsyncValue<bool>> {
  /// A synchronous facade avoids AsyncNotifier's previous-data retention across
  /// accounts. Each auth session owns an independent async favorite notifier.
  ///
  /// Copied from [ProductFavorite].
  const ProductFavoriteFamily();

  /// A synchronous facade avoids AsyncNotifier's previous-data retention across
  /// accounts. Each auth session owns an independent async favorite notifier.
  ///
  /// Copied from [ProductFavorite].
  ProductFavoriteProvider call({required String productId}) {
    return ProductFavoriteProvider(productId: productId);
  }

  @override
  ProductFavoriteProvider getProviderOverride(
    covariant ProductFavoriteProvider provider,
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
  String? get name => r'productFavoriteProvider';
}

/// A synchronous facade avoids AsyncNotifier's previous-data retention across
/// accounts. Each auth session owns an independent async favorite notifier.
///
/// Copied from [ProductFavorite].
class ProductFavoriteProvider
    extends AutoDisposeNotifierProviderImpl<ProductFavorite, AsyncValue<bool>> {
  /// A synchronous facade avoids AsyncNotifier's previous-data retention across
  /// accounts. Each auth session owns an independent async favorite notifier.
  ///
  /// Copied from [ProductFavorite].
  ProductFavoriteProvider({required String productId})
    : this._internal(
        () => ProductFavorite()..productId = productId,
        from: productFavoriteProvider,
        name: r'productFavoriteProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$productFavoriteHash,
        dependencies: ProductFavoriteFamily._dependencies,
        allTransitiveDependencies:
            ProductFavoriteFamily._allTransitiveDependencies,
        productId: productId,
      );

  ProductFavoriteProvider._internal(
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
  AsyncValue<bool> runNotifierBuild(covariant ProductFavorite notifier) {
    return notifier.build(productId: productId);
  }

  @override
  Override overrideWith(ProductFavorite Function() create) {
    return ProviderOverride(
      origin: this,
      override: ProductFavoriteProvider._internal(
        () => create()..productId = productId,
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
  AutoDisposeNotifierProviderElement<ProductFavorite, AsyncValue<bool>>
  createElement() {
    return _ProductFavoriteProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProductFavoriteProvider && other.productId == productId;
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
mixin ProductFavoriteRef on AutoDisposeNotifierProviderRef<AsyncValue<bool>> {
  /// The parameter `productId` of this provider.
  String get productId;
}

class _ProductFavoriteProviderElement
    extends
        AutoDisposeNotifierProviderElement<ProductFavorite, AsyncValue<bool>>
    with ProductFavoriteRef {
  _ProductFavoriteProviderElement(super.provider);

  @override
  String get productId => (origin as ProductFavoriteProvider).productId;
}

String _$accountFavoriteHash() => r'f10dad2100abc8544263712431a5981e1fa662f2';

abstract class _$AccountFavorite
    extends BuildlessAutoDisposeAsyncNotifier<bool> {
  late final String productId;
  late final _FavoriteSession session;

  FutureOr<bool> build({
    required String productId,
    required _FavoriteSession session,
  });
}

/// See also [_AccountFavorite].
@ProviderFor(_AccountFavorite)
const _accountFavoriteProvider = _AccountFavoriteFamily();

/// See also [_AccountFavorite].
class _AccountFavoriteFamily extends Family<AsyncValue<bool>> {
  /// See also [_AccountFavorite].
  const _AccountFavoriteFamily();

  /// See also [_AccountFavorite].
  _AccountFavoriteProvider call({
    required String productId,
    required _FavoriteSession session,
  }) {
    return _AccountFavoriteProvider(productId: productId, session: session);
  }

  @override
  _AccountFavoriteProvider getProviderOverride(
    covariant _AccountFavoriteProvider provider,
  ) {
    return call(productId: provider.productId, session: provider.session);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'_accountFavoriteProvider';
}

/// See also [_AccountFavorite].
class _AccountFavoriteProvider
    extends AutoDisposeAsyncNotifierProviderImpl<_AccountFavorite, bool> {
  /// See also [_AccountFavorite].
  _AccountFavoriteProvider({
    required String productId,
    required _FavoriteSession session,
  }) : this._internal(
         () => _AccountFavorite()
           ..productId = productId
           ..session = session,
         from: _accountFavoriteProvider,
         name: r'_accountFavoriteProvider',
         debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
             ? null
             : _$accountFavoriteHash,
         dependencies: _AccountFavoriteFamily._dependencies,
         allTransitiveDependencies:
             _AccountFavoriteFamily._allTransitiveDependencies,
         productId: productId,
         session: session,
       );

  _AccountFavoriteProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.productId,
    required this.session,
  }) : super.internal();

  final String productId;
  final _FavoriteSession session;

  @override
  FutureOr<bool> runNotifierBuild(covariant _AccountFavorite notifier) {
    return notifier.build(productId: productId, session: session);
  }

  @override
  Override overrideWith(_AccountFavorite Function() create) {
    return ProviderOverride(
      origin: this,
      override: _AccountFavoriteProvider._internal(
        () => create()
          ..productId = productId
          ..session = session,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        productId: productId,
        session: session,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<_AccountFavorite, bool>
  createElement() {
    return _AccountFavoriteProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is _AccountFavoriteProvider &&
        other.productId == productId &&
        other.session == session;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, productId.hashCode);
    hash = _SystemHash.combine(hash, session.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin _AccountFavoriteRef on AutoDisposeAsyncNotifierProviderRef<bool> {
  /// The parameter `productId` of this provider.
  String get productId;

  /// The parameter `session` of this provider.
  _FavoriteSession get session;
}

class _AccountFavoriteProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<_AccountFavorite, bool>
    with _AccountFavoriteRef {
  _AccountFavoriteProviderElement(super.provider);

  @override
  String get productId => (origin as _AccountFavoriteProvider).productId;
  @override
  _FavoriteSession get session => (origin as _AccountFavoriteProvider).session;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
