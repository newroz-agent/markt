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
    r'e1d992f57c713b915ec051be2a8a64fcfbb8200e';

/// The signed-in owner's directory onboarding. Rebuilds on account changes and
/// never keeps a previous account's data.
///
/// Copied from [directoryOnboarding].
@ProviderFor(directoryOnboarding)
final directoryOnboardingProvider =
    AutoDisposeFutureProvider<DirectoryOnboarding>.internal(
      directoryOnboarding,
      name: r'directoryOnboardingProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$directoryOnboardingHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DirectoryOnboardingRef =
    AutoDisposeFutureProviderRef<DirectoryOnboarding>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
