// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'legal_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$legalRepositoryHash() => r'2eef2e6722eb5d8f88a6b5b951fc86c31f763bf9';

/// See also [legalRepository].
@ProviderFor(legalRepository)
final legalRepositoryProvider = Provider<LegalRepository>.internal(
  legalRepository,
  name: r'legalRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$legalRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LegalRepositoryRef = ProviderRef<LegalRepository>;
String _$legalDocumentHash() => r'07362cdde7b4b2b4a8d2d6976a26d5cca1df2850';

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

/// The active document for [kind] in [localeCode].
///
/// Keyed on the locale as well as the kind so switching language refetches
/// instead of showing the previous translation.
///
/// Copied from [legalDocument].
@ProviderFor(legalDocument)
const legalDocumentProvider = LegalDocumentFamily();

/// The active document for [kind] in [localeCode].
///
/// Keyed on the locale as well as the kind so switching language refetches
/// instead of showing the previous translation.
///
/// Copied from [legalDocument].
class LegalDocumentFamily extends Family<AsyncValue<LegalDocument?>> {
  /// The active document for [kind] in [localeCode].
  ///
  /// Keyed on the locale as well as the kind so switching language refetches
  /// instead of showing the previous translation.
  ///
  /// Copied from [legalDocument].
  const LegalDocumentFamily();

  /// The active document for [kind] in [localeCode].
  ///
  /// Keyed on the locale as well as the kind so switching language refetches
  /// instead of showing the previous translation.
  ///
  /// Copied from [legalDocument].
  LegalDocumentProvider call({
    required LegalDocumentKind kind,
    required String localeCode,
  }) {
    return LegalDocumentProvider(kind: kind, localeCode: localeCode);
  }

  @override
  LegalDocumentProvider getProviderOverride(
    covariant LegalDocumentProvider provider,
  ) {
    return call(kind: provider.kind, localeCode: provider.localeCode);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'legalDocumentProvider';
}

/// The active document for [kind] in [localeCode].
///
/// Keyed on the locale as well as the kind so switching language refetches
/// instead of showing the previous translation.
///
/// Copied from [legalDocument].
class LegalDocumentProvider extends AutoDisposeFutureProvider<LegalDocument?> {
  /// The active document for [kind] in [localeCode].
  ///
  /// Keyed on the locale as well as the kind so switching language refetches
  /// instead of showing the previous translation.
  ///
  /// Copied from [legalDocument].
  LegalDocumentProvider({
    required LegalDocumentKind kind,
    required String localeCode,
  }) : this._internal(
         (ref) => legalDocument(
           ref as LegalDocumentRef,
           kind: kind,
           localeCode: localeCode,
         ),
         from: legalDocumentProvider,
         name: r'legalDocumentProvider',
         debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
             ? null
             : _$legalDocumentHash,
         dependencies: LegalDocumentFamily._dependencies,
         allTransitiveDependencies:
             LegalDocumentFamily._allTransitiveDependencies,
         kind: kind,
         localeCode: localeCode,
       );

  LegalDocumentProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.kind,
    required this.localeCode,
  }) : super.internal();

  final LegalDocumentKind kind;
  final String localeCode;

  @override
  Override overrideWith(
    FutureOr<LegalDocument?> Function(LegalDocumentRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LegalDocumentProvider._internal(
        (ref) => create(ref as LegalDocumentRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        kind: kind,
        localeCode: localeCode,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<LegalDocument?> createElement() {
    return _LegalDocumentProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LegalDocumentProvider &&
        other.kind == kind &&
        other.localeCode == localeCode;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, kind.hashCode);
    hash = _SystemHash.combine(hash, localeCode.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin LegalDocumentRef on AutoDisposeFutureProviderRef<LegalDocument?> {
  /// The parameter `kind` of this provider.
  LegalDocumentKind get kind;

  /// The parameter `localeCode` of this provider.
  String get localeCode;
}

class _LegalDocumentProviderElement
    extends AutoDisposeFutureProviderElement<LegalDocument?>
    with LegalDocumentRef {
  _LegalDocumentProviderElement(super.provider);

  @override
  LegalDocumentKind get kind => (origin as LegalDocumentProvider).kind;
  @override
  String get localeCode => (origin as LegalDocumentProvider).localeCode;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
