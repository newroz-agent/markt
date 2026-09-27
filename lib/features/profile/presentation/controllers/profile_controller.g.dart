// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$profileRepositoryHash() => r'6678301dc5b5eff84fe68859ff8ef94edc136edf';

/// See also [profileRepository].
@ProviderFor(profileRepository)
final profileRepositoryProvider = Provider<ProfileRepository>.internal(
  profileRepository,
  name: r'profileRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$profileRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProfileRepositoryRef = ProviderRef<ProfileRepository>;
String _$avatarImageServiceHash() =>
    r'3ede99ffd5cf2903877fda9f1d5242169af4fd0a';

/// See also [avatarImageService].
@ProviderFor(avatarImageService)
final avatarImageServiceProvider = Provider<AvatarImageService>.internal(
  avatarImageService,
  name: r'avatarImageServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$avatarImageServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AvatarImageServiceRef = ProviderRef<AvatarImageService>;
String _$publicIdentityResolverHash() =>
    r'6eed054b82606388edc991cac148d98c248fb7c1';

/// See also [publicIdentityResolver].
@ProviderFor(publicIdentityResolver)
final publicIdentityResolverProvider =
    Provider<PublicIdentityResolver>.internal(
      publicIdentityResolver,
      name: r'publicIdentityResolverProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$publicIdentityResolverHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PublicIdentityResolverRef = ProviderRef<PublicIdentityResolver>;
String _$myProfileHash() => r'6d0c9379334e25545ecee27fe06ffd204ce1b726';

/// The signed-in user's own profile. Rebuilds when the auth session changes and
/// never retains a previous account's data.
///
/// Copied from [myProfile].
@ProviderFor(myProfile)
final myProfileProvider = AutoDisposeFutureProvider<MyProfile?>.internal(
  myProfile,
  name: r'myProfileProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$myProfileHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MyProfileRef = AutoDisposeFutureProviderRef<MyProfile?>;
String _$publicProfileHash() => r'5e0274a693cc2bb4c06f74b17f1d6be841cc4122';

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

/// See also [publicProfile].
@ProviderFor(publicProfile)
const publicProfileProvider = PublicProfileFamily();

/// See also [publicProfile].
class PublicProfileFamily extends Family<AsyncValue<PublicProfile?>> {
  /// See also [publicProfile].
  const PublicProfileFamily();

  /// See also [publicProfile].
  PublicProfileProvider call({required String username}) {
    return PublicProfileProvider(username: username);
  }

  @override
  PublicProfileProvider getProviderOverride(
    covariant PublicProfileProvider provider,
  ) {
    return call(username: provider.username);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'publicProfileProvider';
}

/// See also [publicProfile].
class PublicProfileProvider extends AutoDisposeFutureProvider<PublicProfile?> {
  /// See also [publicProfile].
  PublicProfileProvider({required String username})
    : this._internal(
        (ref) => publicProfile(ref as PublicProfileRef, username: username),
        from: publicProfileProvider,
        name: r'publicProfileProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$publicProfileHash,
        dependencies: PublicProfileFamily._dependencies,
        allTransitiveDependencies:
            PublicProfileFamily._allTransitiveDependencies,
        username: username,
      );

  PublicProfileProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.username,
  }) : super.internal();

  final String username;

  @override
  Override overrideWith(
    FutureOr<PublicProfile?> Function(PublicProfileRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PublicProfileProvider._internal(
        (ref) => create(ref as PublicProfileRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        username: username,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<PublicProfile?> createElement() {
    return _PublicProfileProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PublicProfileProvider && other.username == username;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, username.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PublicProfileRef on AutoDisposeFutureProviderRef<PublicProfile?> {
  /// The parameter `username` of this provider.
  String get username;
}

class _PublicProfileProviderElement
    extends AutoDisposeFutureProviderElement<PublicProfile?>
    with PublicProfileRef {
  _PublicProfileProviderElement(super.provider);

  @override
  String get username => (origin as PublicProfileProvider).username;
}

String _$editProfileControllerHash() =>
    r'58895469b553bcdca44f9666c36e6296cfb799c6';

/// See also [EditProfileController].
@ProviderFor(EditProfileController)
final editProfileControllerProvider =
    AutoDisposeNotifierProvider<
      EditProfileController,
      EditProfileState
    >.internal(
      EditProfileController.new,
      name: r'editProfileControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$editProfileControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$EditProfileController = AutoDisposeNotifier<EditProfileState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
