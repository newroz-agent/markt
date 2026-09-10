// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_products_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$categoryProductsRepositoryHash() =>
    r'30b8fc1ee04c553bfa5798393ac16f8d59b3d58a';

/// See also [categoryProductsRepository].
@ProviderFor(categoryProductsRepository)
final categoryProductsRepositoryProvider =
    Provider<CategoryProductsRepository>.internal(
      categoryProductsRepository,
      name: r'categoryProductsRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$categoryProductsRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CategoryProductsRepositoryRef = ProviderRef<CategoryProductsRepository>;
String _$categoryChildrenHash() => r'8371706f7a79c5bcc6bfff56a217263437e1bd24';

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

/// See also [categoryChildren].
@ProviderFor(categoryChildren)
const categoryChildrenProvider = CategoryChildrenFamily();

/// See also [categoryChildren].
class CategoryChildrenFamily
    extends Family<AsyncValue<List<MarketplaceCategory>>> {
  /// See also [categoryChildren].
  const CategoryChildrenFamily();

  /// See also [categoryChildren].
  CategoryChildrenProvider call(String categoryId) {
    return CategoryChildrenProvider(categoryId);
  }

  @override
  CategoryChildrenProvider getProviderOverride(
    covariant CategoryChildrenProvider provider,
  ) {
    return call(provider.categoryId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'categoryChildrenProvider';
}

/// See also [categoryChildren].
class CategoryChildrenProvider
    extends AutoDisposeFutureProvider<List<MarketplaceCategory>> {
  /// See also [categoryChildren].
  CategoryChildrenProvider(String categoryId)
    : this._internal(
        (ref) => categoryChildren(ref as CategoryChildrenRef, categoryId),
        from: categoryChildrenProvider,
        name: r'categoryChildrenProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$categoryChildrenHash,
        dependencies: CategoryChildrenFamily._dependencies,
        allTransitiveDependencies:
            CategoryChildrenFamily._allTransitiveDependencies,
        categoryId: categoryId,
      );

  CategoryChildrenProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.categoryId,
  }) : super.internal();

  final String categoryId;

  @override
  Override overrideWith(
    FutureOr<List<MarketplaceCategory>> Function(CategoryChildrenRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CategoryChildrenProvider._internal(
        (ref) => create(ref as CategoryChildrenRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        categoryId: categoryId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<MarketplaceCategory>> createElement() {
    return _CategoryChildrenProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CategoryChildrenProvider && other.categoryId == categoryId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, categoryId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CategoryChildrenRef
    on AutoDisposeFutureProviderRef<List<MarketplaceCategory>> {
  /// The parameter `categoryId` of this provider.
  String get categoryId;
}

class _CategoryChildrenProviderElement
    extends AutoDisposeFutureProviderElement<List<MarketplaceCategory>>
    with CategoryChildrenRef {
  _CategoryChildrenProviderElement(super.provider);

  @override
  String get categoryId => (origin as CategoryChildrenProvider).categoryId;
}

String _$categoryByIdHash() => r'88a9f38d1ac97db26a325c8382b9a0f76fb236b3';

/// See also [categoryById].
@ProviderFor(categoryById)
const categoryByIdProvider = CategoryByIdFamily();

/// See also [categoryById].
class CategoryByIdFamily extends Family<AsyncValue<MarketplaceCategory?>> {
  /// See also [categoryById].
  const CategoryByIdFamily();

  /// See also [categoryById].
  CategoryByIdProvider call(String categoryId) {
    return CategoryByIdProvider(categoryId);
  }

  @override
  CategoryByIdProvider getProviderOverride(
    covariant CategoryByIdProvider provider,
  ) {
    return call(provider.categoryId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'categoryByIdProvider';
}

/// See also [categoryById].
class CategoryByIdProvider
    extends AutoDisposeFutureProvider<MarketplaceCategory?> {
  /// See also [categoryById].
  CategoryByIdProvider(String categoryId)
    : this._internal(
        (ref) => categoryById(ref as CategoryByIdRef, categoryId),
        from: categoryByIdProvider,
        name: r'categoryByIdProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$categoryByIdHash,
        dependencies: CategoryByIdFamily._dependencies,
        allTransitiveDependencies:
            CategoryByIdFamily._allTransitiveDependencies,
        categoryId: categoryId,
      );

  CategoryByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.categoryId,
  }) : super.internal();

  final String categoryId;

  @override
  Override overrideWith(
    FutureOr<MarketplaceCategory?> Function(CategoryByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CategoryByIdProvider._internal(
        (ref) => create(ref as CategoryByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        categoryId: categoryId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<MarketplaceCategory?> createElement() {
    return _CategoryByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CategoryByIdProvider && other.categoryId == categoryId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, categoryId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CategoryByIdRef on AutoDisposeFutureProviderRef<MarketplaceCategory?> {
  /// The parameter `categoryId` of this provider.
  String get categoryId;
}

class _CategoryByIdProviderElement
    extends AutoDisposeFutureProviderElement<MarketplaceCategory?>
    with CategoryByIdRef {
  _CategoryByIdProviderElement(super.provider);

  @override
  String get categoryId => (origin as CategoryByIdProvider).categoryId;
}

String _$categoryProductsFilterHash() =>
    r'3dea06a4cf6fa0fd3d4a9fd6d357fdc7f6f7a695';

abstract class _$CategoryProductsFilter
    extends BuildlessAutoDisposeNotifier<CategoryProductsFilterState> {
  late final String categoryId;

  CategoryProductsFilterState build(String categoryId);
}

/// See also [CategoryProductsFilter].
@ProviderFor(CategoryProductsFilter)
const categoryProductsFilterProvider = CategoryProductsFilterFamily();

/// See also [CategoryProductsFilter].
class CategoryProductsFilterFamily extends Family<CategoryProductsFilterState> {
  /// See also [CategoryProductsFilter].
  const CategoryProductsFilterFamily();

  /// See also [CategoryProductsFilter].
  CategoryProductsFilterProvider call(String categoryId) {
    return CategoryProductsFilterProvider(categoryId);
  }

  @override
  CategoryProductsFilterProvider getProviderOverride(
    covariant CategoryProductsFilterProvider provider,
  ) {
    return call(provider.categoryId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'categoryProductsFilterProvider';
}

/// See also [CategoryProductsFilter].
class CategoryProductsFilterProvider
    extends
        AutoDisposeNotifierProviderImpl<
          CategoryProductsFilter,
          CategoryProductsFilterState
        > {
  /// See also [CategoryProductsFilter].
  CategoryProductsFilterProvider(String categoryId)
    : this._internal(
        () => CategoryProductsFilter()..categoryId = categoryId,
        from: categoryProductsFilterProvider,
        name: r'categoryProductsFilterProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$categoryProductsFilterHash,
        dependencies: CategoryProductsFilterFamily._dependencies,
        allTransitiveDependencies:
            CategoryProductsFilterFamily._allTransitiveDependencies,
        categoryId: categoryId,
      );

  CategoryProductsFilterProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.categoryId,
  }) : super.internal();

  final String categoryId;

  @override
  CategoryProductsFilterState runNotifierBuild(
    covariant CategoryProductsFilter notifier,
  ) {
    return notifier.build(categoryId);
  }

  @override
  Override overrideWith(CategoryProductsFilter Function() create) {
    return ProviderOverride(
      origin: this,
      override: CategoryProductsFilterProvider._internal(
        () => create()..categoryId = categoryId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        categoryId: categoryId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<
    CategoryProductsFilter,
    CategoryProductsFilterState
  >
  createElement() {
    return _CategoryProductsFilterProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CategoryProductsFilterProvider &&
        other.categoryId == categoryId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, categoryId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CategoryProductsFilterRef
    on AutoDisposeNotifierProviderRef<CategoryProductsFilterState> {
  /// The parameter `categoryId` of this provider.
  String get categoryId;
}

class _CategoryProductsFilterProviderElement
    extends
        AutoDisposeNotifierProviderElement<
          CategoryProductsFilter,
          CategoryProductsFilterState
        >
    with CategoryProductsFilterRef {
  _CategoryProductsFilterProviderElement(super.provider);

  @override
  String get categoryId =>
      (origin as CategoryProductsFilterProvider).categoryId;
}

String _$categoryProductsHash() => r'6cb9fb330ede24c9c32540291e627ffa35c1d78f';

abstract class _$CategoryProducts
    extends BuildlessAutoDisposeAsyncNotifier<List<HomeProduct>> {
  late final String categoryId;

  FutureOr<List<HomeProduct>> build(String categoryId);
}

/// See also [CategoryProducts].
@ProviderFor(CategoryProducts)
const categoryProductsProvider = CategoryProductsFamily();

/// See also [CategoryProducts].
class CategoryProductsFamily extends Family<AsyncValue<List<HomeProduct>>> {
  /// See also [CategoryProducts].
  const CategoryProductsFamily();

  /// See also [CategoryProducts].
  CategoryProductsProvider call(String categoryId) {
    return CategoryProductsProvider(categoryId);
  }

  @override
  CategoryProductsProvider getProviderOverride(
    covariant CategoryProductsProvider provider,
  ) {
    return call(provider.categoryId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'categoryProductsProvider';
}

/// See also [CategoryProducts].
class CategoryProductsProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          CategoryProducts,
          List<HomeProduct>
        > {
  /// See also [CategoryProducts].
  CategoryProductsProvider(String categoryId)
    : this._internal(
        () => CategoryProducts()..categoryId = categoryId,
        from: categoryProductsProvider,
        name: r'categoryProductsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$categoryProductsHash,
        dependencies: CategoryProductsFamily._dependencies,
        allTransitiveDependencies:
            CategoryProductsFamily._allTransitiveDependencies,
        categoryId: categoryId,
      );

  CategoryProductsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.categoryId,
  }) : super.internal();

  final String categoryId;

  @override
  FutureOr<List<HomeProduct>> runNotifierBuild(
    covariant CategoryProducts notifier,
  ) {
    return notifier.build(categoryId);
  }

  @override
  Override overrideWith(CategoryProducts Function() create) {
    return ProviderOverride(
      origin: this,
      override: CategoryProductsProvider._internal(
        () => create()..categoryId = categoryId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        categoryId: categoryId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<CategoryProducts, List<HomeProduct>>
  createElement() {
    return _CategoryProductsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CategoryProductsProvider && other.categoryId == categoryId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, categoryId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CategoryProductsRef
    on AutoDisposeAsyncNotifierProviderRef<List<HomeProduct>> {
  /// The parameter `categoryId` of this provider.
  String get categoryId;
}

class _CategoryProductsProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          CategoryProducts,
          List<HomeProduct>
        >
    with CategoryProductsRef {
  _CategoryProductsProviderElement(super.provider);

  @override
  String get categoryId => (origin as CategoryProductsProvider).categoryId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
