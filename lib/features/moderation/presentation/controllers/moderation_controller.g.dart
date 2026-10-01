// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'moderation_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$moderationRepositoryHash() =>
    r'c2585900b6206a7ace670d1b0dc79fcfeff28307';

/// See also [moderationRepository].
@ProviderFor(moderationRepository)
final moderationRepositoryProvider = Provider<ModerationRepository>.internal(
  moderationRepository,
  name: r'moderationRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$moderationRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ModerationRepositoryRef = ProviderRef<ModerationRepository>;
String _$currentUserIsAdminHash() =>
    r'3923f88e344b0f349881430297779a02a23a98c6';

/// See also [currentUserIsAdmin].
@ProviderFor(currentUserIsAdmin)
final currentUserIsAdminProvider = AutoDisposeFutureProvider<bool>.internal(
  currentUserIsAdmin,
  name: r'currentUserIsAdminProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserIsAdminHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserIsAdminRef = AutoDisposeFutureProviderRef<bool>;
String _$moderationDashboardHash() =>
    r'5a7b6c8c98004f5594751fec1d6bfcd9ebc3983c';

/// See also [moderationDashboard].
@ProviderFor(moderationDashboard)
final moderationDashboardProvider =
    AutoDisposeFutureProvider<ModerationDashboard>.internal(
      moderationDashboard,
      name: r'moderationDashboardProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$moderationDashboardHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ModerationDashboardRef =
    AutoDisposeFutureProviderRef<ModerationDashboard>;
String _$sellerVerificationQueueHash() =>
    r'188b327fd673dd2bbb810766f9ee5c98cadf8b3a';

/// See also [sellerVerificationQueue].
@ProviderFor(sellerVerificationQueue)
final sellerVerificationQueueProvider =
    AutoDisposeFutureProvider<SellerVerificationQueue>.internal(
      sellerVerificationQueue,
      name: r'sellerVerificationQueueProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$sellerVerificationQueueHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SellerVerificationQueueRef =
    AutoDisposeFutureProviderRef<SellerVerificationQueue>;
String _$moderationReportsQueueHash() =>
    r'1e20a4238f4b9fdeda9cd11231a4a8f3d13a374e';

/// See also [moderationReportsQueue].
@ProviderFor(moderationReportsQueue)
final moderationReportsQueueProvider =
    AutoDisposeFutureProvider<ModerationReportsQueue>.internal(
      moderationReportsQueue,
      name: r'moderationReportsQueueProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$moderationReportsQueueHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ModerationReportsQueueRef =
    AutoDisposeFutureProviderRef<ModerationReportsQueue>;
String _$moderationActionHash() => r'cc93c778ffd6acf0de74218bf931c2c83c87f395';

/// See also [ModerationAction].
@ProviderFor(ModerationAction)
final moderationActionProvider =
    AsyncNotifierProvider<ModerationAction, void>.internal(
      ModerationAction.new,
      name: r'moderationActionProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$moderationActionHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ModerationAction = AsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
