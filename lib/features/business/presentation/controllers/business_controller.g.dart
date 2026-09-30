// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$businessRepositoryHash() =>
    r'0aeda22e153ed0a59b476c161429df182b71ba92';

/// See also [businessRepository].
@ProviderFor(businessRepository)
final businessRepositoryProvider = Provider<BusinessRepository>.internal(
  businessRepository,
  name: r'businessRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$businessRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BusinessRepositoryRef = ProviderRef<BusinessRepository>;
String _$documentFileServiceHash() =>
    r'52e5ba9a05aacd7524fef62204991107f5e50ea4';

/// See also [documentFileService].
@ProviderFor(documentFileService)
final documentFileServiceProvider = Provider<DocumentFileService>.internal(
  documentFileService,
  name: r'documentFileServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$documentFileServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DocumentFileServiceRef = ProviderRef<DocumentFileService>;
String _$directoryOnboardingHash() =>
    r'301a95af8b8d6a5618063b521c4b5920d9238518';

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

/// This exact signed-in business seller's directory onboarding. Rebuilds on
/// account changes and never keeps another identity's data.
///
/// Copied from [directoryOnboarding].
@ProviderFor(directoryOnboarding)
const directoryOnboardingProvider = DirectoryOnboardingFamily();

/// This exact signed-in business seller's directory onboarding. Rebuilds on
/// account changes and never keeps another identity's data.
///
/// Copied from [directoryOnboarding].
class DirectoryOnboardingFamily
    extends Family<AsyncValue<DirectoryOnboarding>> {
  /// This exact signed-in business seller's directory onboarding. Rebuilds on
  /// account changes and never keeps another identity's data.
  ///
  /// Copied from [directoryOnboarding].
  const DirectoryOnboardingFamily();

  /// This exact signed-in business seller's directory onboarding. Rebuilds on
  /// account changes and never keeps another identity's data.
  ///
  /// Copied from [directoryOnboarding].
  DirectoryOnboardingProvider call(String businessSellerId) {
    return DirectoryOnboardingProvider(businessSellerId);
  }

  @override
  DirectoryOnboardingProvider getProviderOverride(
    covariant DirectoryOnboardingProvider provider,
  ) {
    return call(provider.businessSellerId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'directoryOnboardingProvider';
}

/// This exact signed-in business seller's directory onboarding. Rebuilds on
/// account changes and never keeps another identity's data.
///
/// Copied from [directoryOnboarding].
class DirectoryOnboardingProvider
    extends AutoDisposeFutureProvider<DirectoryOnboarding> {
  /// This exact signed-in business seller's directory onboarding. Rebuilds on
  /// account changes and never keeps another identity's data.
  ///
  /// Copied from [directoryOnboarding].
  DirectoryOnboardingProvider(String businessSellerId)
    : this._internal(
        (ref) => directoryOnboarding(
          ref as DirectoryOnboardingRef,
          businessSellerId,
        ),
        from: directoryOnboardingProvider,
        name: r'directoryOnboardingProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$directoryOnboardingHash,
        dependencies: DirectoryOnboardingFamily._dependencies,
        allTransitiveDependencies:
            DirectoryOnboardingFamily._allTransitiveDependencies,
        businessSellerId: businessSellerId,
      );

  DirectoryOnboardingProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.businessSellerId,
  }) : super.internal();

  final String businessSellerId;

  @override
  Override overrideWith(
    FutureOr<DirectoryOnboarding> Function(DirectoryOnboardingRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DirectoryOnboardingProvider._internal(
        (ref) => create(ref as DirectoryOnboardingRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        businessSellerId: businessSellerId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<DirectoryOnboarding> createElement() {
    return _DirectoryOnboardingProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DirectoryOnboardingProvider &&
        other.businessSellerId == businessSellerId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, businessSellerId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DirectoryOnboardingRef
    on AutoDisposeFutureProviderRef<DirectoryOnboarding> {
  /// The parameter `businessSellerId` of this provider.
  String get businessSellerId;
}

class _DirectoryOnboardingProviderElement
    extends AutoDisposeFutureProviderElement<DirectoryOnboarding>
    with DirectoryOnboardingRef {
  _DirectoryOnboardingProviderElement(super.provider);

  @override
  String get businessSellerId =>
      (origin as DirectoryOnboardingProvider).businessSellerId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
