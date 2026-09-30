// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'identity_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$identityCatalogRepositoryHash() =>
    r'd795818d58ca4b5282846963a94901f5faf0fbc4';

/// See also [identityCatalogRepository].
@ProviderFor(identityCatalogRepository)
final identityCatalogRepositoryProvider =
    Provider<IdentityCatalogRepository>.internal(
      identityCatalogRepository,
      name: r'identityCatalogRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$identityCatalogRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IdentityCatalogRepositoryRef = ProviderRef<IdentityCatalogRepository>;
String _$identitySessionHash() => r'da62ea422e94430436af7d2f2147d608a973ea90';

/// See also [_identitySession].
@ProviderFor(_identitySession)
final _identitySessionProvider = AutoDisposeProvider<_IdentitySession>.internal(
  _identitySession,
  name: r'_identitySessionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$identitySessionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef _IdentitySessionRef = AutoDisposeProviderRef<_IdentitySession>;
String _$identityCatalogRevisionHash() =>
    r'94f760e30104126021d0482b05ae9480ec5f42a4';

/// See also [IdentityCatalogRevision].
@ProviderFor(IdentityCatalogRevision)
final identityCatalogRevisionProvider =
    NotifierProvider<IdentityCatalogRevision, int>.internal(
      IdentityCatalogRevision.new,
      name: r'identityCatalogRevisionProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$identityCatalogRevisionHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$IdentityCatalogRevision = Notifier<int>;
String _$activeIdentityControllerHash() =>
    r'ce8049f4ea60b8cef7e0c9cb095729d6a4e90835';

/// Synchronous facade that never retains one account's value while another
/// account's freshly server-validated catalog is loading.
///
/// Copied from [ActiveIdentityController].
@ProviderFor(ActiveIdentityController)
final activeIdentityControllerProvider =
    AutoDisposeNotifierProvider<
      ActiveIdentityController,
      AsyncValue<IdentitySessionState?>
    >.internal(
      ActiveIdentityController.new,
      name: r'activeIdentityControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$activeIdentityControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ActiveIdentityController =
    AutoDisposeNotifier<AsyncValue<IdentitySessionState?>>;
String _$accountIdentityControllerHash() =>
    r'0435b16b366ec61dd0181bef34e112fd5fe78f3d';

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

abstract class _$AccountIdentityController
    extends BuildlessAutoDisposeAsyncNotifier<IdentitySessionState> {
  late final _IdentitySession session;

  FutureOr<IdentitySessionState> build({required _IdentitySession session});
}

/// See also [_AccountIdentityController].
@ProviderFor(_AccountIdentityController)
const _accountIdentityControllerProvider = _AccountIdentityControllerFamily();

/// See also [_AccountIdentityController].
class _AccountIdentityControllerFamily
    extends Family<AsyncValue<IdentitySessionState>> {
  /// See also [_AccountIdentityController].
  const _AccountIdentityControllerFamily();

  /// See also [_AccountIdentityController].
  _AccountIdentityControllerProvider call({required _IdentitySession session}) {
    return _AccountIdentityControllerProvider(session: session);
  }

  @override
  _AccountIdentityControllerProvider getProviderOverride(
    covariant _AccountIdentityControllerProvider provider,
  ) {
    return call(session: provider.session);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'_accountIdentityControllerProvider';
}

/// See also [_AccountIdentityController].
class _AccountIdentityControllerProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          _AccountIdentityController,
          IdentitySessionState
        > {
  /// See also [_AccountIdentityController].
  _AccountIdentityControllerProvider({required _IdentitySession session})
    : this._internal(
        () => _AccountIdentityController()..session = session,
        from: _accountIdentityControllerProvider,
        name: r'_accountIdentityControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$accountIdentityControllerHash,
        dependencies: _AccountIdentityControllerFamily._dependencies,
        allTransitiveDependencies:
            _AccountIdentityControllerFamily._allTransitiveDependencies,
        session: session,
      );

  _AccountIdentityControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.session,
  }) : super.internal();

  final _IdentitySession session;

  @override
  FutureOr<IdentitySessionState> runNotifierBuild(
    covariant _AccountIdentityController notifier,
  ) {
    return notifier.build(session: session);
  }

  @override
  Override overrideWith(_AccountIdentityController Function() create) {
    return ProviderOverride(
      origin: this,
      override: _AccountIdentityControllerProvider._internal(
        () => create()..session = session,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        session: session,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<
    _AccountIdentityController,
    IdentitySessionState
  >
  createElement() {
    return _AccountIdentityControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is _AccountIdentityControllerProvider &&
        other.session == session;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, session.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin _AccountIdentityControllerRef
    on AutoDisposeAsyncNotifierProviderRef<IdentitySessionState> {
  /// The parameter `session` of this provider.
  _IdentitySession get session;
}

class _AccountIdentityControllerProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          _AccountIdentityController,
          IdentitySessionState
        >
    with _AccountIdentityControllerRef {
  _AccountIdentityControllerProviderElement(super.provider);

  @override
  _IdentitySession get session =>
      (origin as _AccountIdentityControllerProvider).session;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
