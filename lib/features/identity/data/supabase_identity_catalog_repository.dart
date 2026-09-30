import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerin_marketplace/core/errors/app_exception.dart';
import 'package:zerin_marketplace/core/storage/avatar_url_resolver.dart';
import 'package:zerin_marketplace/features/identity/domain/identity.dart';
import 'package:zerin_marketplace/features/identity/domain/identity_repository.dart';

class SupabaseIdentityCatalogRepository implements IdentityCatalogRepository {
  SupabaseIdentityCatalogRepository(this._client)
    : _avatarUrls = AvatarUrlResolver(_client);

  final SupabaseClient _client;
  final AvatarUrlResolver _avatarUrls;

  @override
  Future<IdentityCatalog> fetchMyIdentityCatalog() async {
    if (_client.auth.currentUser == null) {
      throw const AppException(AppFailureCode.notAuthenticated);
    }
    try {
      final json = await _client.rpc<Map<String, dynamic>>(
        'get_my_identity_catalog',
      );
      return _parseCatalog(json);
    } on PostgrestException catch (error, stackTrace) {
      final code = error.code == '42501'
          ? AppFailureCode.notAuthenticated
          : AppFailureCode.unknown;
      Error.throwWithStackTrace(AppException(code, cause: error), stackTrace);
    }
  }

  IdentityCatalog _parseCatalog(Map<String, dynamic> json) {
    final rawIdentities = json['identities'];
    if (rawIdentities is! List) {
      throw _invalidCatalog('identities must be an array');
    }

    MarketplaceIdentity? person;
    MarketplaceIdentity? business;
    for (final rawIdentity in rawIdentities) {
      if (rawIdentity is! Map) {
        throw _invalidCatalog('identity entries must be objects');
      }
      final map = Map<String, dynamic>.from(rawIdentity);
      final typeValue = _requiredString(map, 'identity_type');
      final sellerKind = _requiredString(map, 'kind');
      final sellerId = _optionalString(map, 'seller_id');
      final identity = MarketplaceIdentity(
        type: switch (typeValue) {
          'person' => MarketplaceIdentityType.person,
          'business' => MarketplaceIdentityType.business,
          _ => throw _invalidCatalog('unknown identity type'),
        },
        sellerId: sellerId,
        sellerKind: sellerKind,
        sellerStatus: _optionalString(map, 'status'),
        label: _requiredString(map, 'label'),
        avatarUrl: _avatarUrls.resolve(_optionalString(map, 'avatar_url')),
        username: _optionalString(map, 'username'),
      );

      if (identity.isPerson) {
        if (person != null || sellerKind != 'private') {
          throw _invalidCatalog('invalid person identity');
        }
        person = identity;
      } else {
        if (business != null || sellerKind != 'business' || sellerId == null) {
          throw _invalidCatalog('invalid business identity');
        }
        business = identity;
      }
    }

    if (person == null) {
      throw _invalidCatalog('person identity is required');
    }
    return IdentityCatalog(<MarketplaceIdentity>[person, ?business]);
  }

  String _requiredString(Map<String, dynamic> map, String key) {
    final value = _optionalString(map, key);
    if (value == null) throw _invalidCatalog('$key is required');
    return value;
  }

  String? _optionalString(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return null;
    if (value is! String || value.trim().isEmpty) {
      throw _invalidCatalog('$key must be a non-empty string');
    }
    return value.trim();
  }

  AppException _invalidCatalog(String reason) => AppException(
    AppFailureCode.unknown,
    cause: FormatException('Invalid identity catalog: $reason'),
  );
}
