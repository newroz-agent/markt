// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'privacy_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$privacyRepositoryHash() => r'80ce139a973f243d04a2fe06fd637e2bdf5028ee';

/// See also [privacyRepository].
@ProviderFor(privacyRepository)
final privacyRepositoryProvider = Provider<PrivacyRepository>.internal(
  privacyRepository,
  name: r'privacyRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$privacyRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PrivacyRepositoryRef = ProviderRef<PrivacyRepository>;
String _$privacyControllerHash() => r'1a01370e3d7a96b0a815749b8871a32b5ed1ef3e';

/// Privacy state for the signed-in user.
///
/// Watches the auth state so signing out clears it instead of leaving another
/// user's consent and requests on screen.
///
/// Copied from [PrivacyController].
@ProviderFor(PrivacyController)
final privacyControllerProvider =
    AutoDisposeAsyncNotifierProvider<
      PrivacyController,
      PrivacyOverview
    >.internal(
      PrivacyController.new,
      name: r'privacyControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$privacyControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PrivacyController = AutoDisposeAsyncNotifier<PrivacyOverview>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
