// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$categoryRepositoryHash() =>
    r'ee29d1bc4563a6bcc6ba9a6d3baead63c10420bd';

/// See also [categoryRepository].
@ProviderFor(categoryRepository)
final categoryRepositoryProvider = Provider<CategoryRepository>.internal(
  categoryRepository,
  name: r'categoryRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$categoryRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CategoryRepositoryRef = ProviderRef<CategoryRepository>;
String _$activeCategoriesHash() => r'45e408532b1ed1d5d57564cfa13ed9c63bf75597';

/// See also [activeCategories].
@ProviderFor(activeCategories)
final activeCategoriesProvider =
    FutureProvider<List<MarketplaceCategory>>.internal(
      activeCategories,
      name: r'activeCategoriesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$activeCategoriesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActiveCategoriesRef = FutureProviderRef<List<MarketplaceCategory>>;
String _$rootCategoriesHash() => r'3aab095d5c9868a416ff3566ad06c41f95130c8f';

/// See also [rootCategories].
@ProviderFor(rootCategories)
final rootCategoriesProvider =
    AutoDisposeFutureProvider<List<MarketplaceCategory>>.internal(
      rootCategories,
      name: r'rootCategoriesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$rootCategoriesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RootCategoriesRef =
    AutoDisposeFutureProviderRef<List<MarketplaceCategory>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
