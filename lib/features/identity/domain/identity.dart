import 'package:flutter/foundation.dart';

enum MarketplaceIdentityType { person, business }

/// A safe identity returned by `get_my_identity_catalog`.
///
/// This is display/default-context data only. Every operation that needs a seller
/// must still pass its explicit seller ID to a server-authorized RPC.
@immutable
class MarketplaceIdentity {
  const MarketplaceIdentity({
    required this.type,
    required this.sellerId,
    required this.sellerKind,
    required this.sellerStatus,
    required this.label,
    required this.avatarUrl,
    required this.username,
  });

  static const personSelectionKey = 'person';

  final MarketplaceIdentityType type;
  final String? sellerId;
  final String sellerKind;
  final String? sellerStatus;
  final String label;
  final String? avatarUrl;
  final String? username;

  bool get isPerson => type == MarketplaceIdentityType.person;
  bool get isBusiness => type == MarketplaceIdentityType.business;
  bool get isVerifiedBusiness => isBusiness && sellerStatus == 'approved';

  /// Stable device preference key. The person key does not change when their
  /// lazily-created private seller ID changes from null to a UUID.
  String get selectionKey =>
      isPerson ? personSelectionKey : 'business:${sellerId ?? ''}';

  MarketplaceIdentity withSellerId(String value) => MarketplaceIdentity(
    type: type,
    sellerId: value,
    sellerKind: sellerKind,
    sellerStatus: sellerStatus,
    label: label,
    avatarUrl: avatarUrl,
    username: username,
  );
}

@immutable
class IdentityCatalog {
  IdentityCatalog(Iterable<MarketplaceIdentity> identities)
    : identities = List<MarketplaceIdentity>.unmodifiable(identities);

  final List<MarketplaceIdentity> identities;

  MarketplaceIdentity? get person => _byType(MarketplaceIdentityType.person);
  MarketplaceIdentity? get business =>
      _byType(MarketplaceIdentityType.business);

  /// Required fallback order: person/private, then business, then none.
  MarketplaceIdentity? get fallbackIdentity => person ?? business;

  MarketplaceIdentity? identityForSelectionKey(String? selectionKey) {
    if (selectionKey == null) return null;
    for (final identity in identities) {
      if (identity.selectionKey == selectionKey) return identity;
    }
    return null;
  }

  MarketplaceIdentity? _byType(MarketplaceIdentityType type) {
    for (final identity in identities) {
      if (identity.type == type) return identity;
    }
    return null;
  }
}

@immutable
class IdentitySessionState {
  const IdentitySessionState({
    required this.catalog,
    required this.activeIdentity,
  });

  final IdentityCatalog catalog;
  final MarketplaceIdentity? activeIdentity;

  bool isActive(MarketplaceIdentity identity) =>
      activeIdentity?.selectionKey == identity.selectionKey;

  IdentitySessionState copyWith({MarketplaceIdentity? activeIdentity}) =>
      IdentitySessionState(catalog: catalog, activeIdentity: activeIdentity);
}
