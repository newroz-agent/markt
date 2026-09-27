import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerin_marketplace/core/storage/avatar_url_resolver.dart';
import 'package:zerin_marketplace/features/profile/domain/profile.dart';
import 'package:zerin_marketplace/features/profile/domain/profile_errors.dart';
import 'package:zerin_marketplace/features/profile/domain/profile_repository.dart';

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client)
    : _avatarUrls = AvatarUrlResolver(_client);

  final SupabaseClient _client;
  final AvatarUrlResolver _avatarUrls;

  static const _avatarsBucket = 'avatars';

  @override
  Future<MyProfile> fetchMyProfile() async {
    _requireUser();
    try {
      final json = await _client.rpc<Map<String, dynamic>>('get_my_profile');
      return _myProfileFromJson(json);
    } on PostgrestException catch (error, stackTrace) {
      Error.throwWithStackTrace(_mapError(error), stackTrace);
    }
  }

  @override
  Future<PublicProfile?> fetchPublicProfile(String username) async {
    try {
      final json = await _client.rpc<dynamic>(
        'get_public_profile',
        params: {'p_username': username},
      );
      if (json == null) return null;
      return _publicProfileFromJson(Map<String, dynamic>.from(json as Map));
    } on PostgrestException catch (error, stackTrace) {
      Error.throwWithStackTrace(_mapError(error), stackTrace);
    }
  }

  @override
  Future<UsernameAvailability> checkUsername(String username) async {
    _requireUser();
    try {
      final result = await _client.rpc<String>(
        'check_profile_username',
        params: {'p_username': username},
      );
      return UsernameAvailabilityParsing.fromServer(result);
    } on PostgrestException catch (error, stackTrace) {
      Error.throwWithStackTrace(_mapError(error), stackTrace);
    }
  }

  @override
  Future<MyProfile> updateMyProfile({
    required String displayName,
    required String username,
    required String city,
    String? bio,
  }) async {
    _requireUser();
    try {
      final json = await _client.rpc<Map<String, dynamic>>(
        'update_my_profile',
        params: <String, dynamic>{
          'p_display_name': displayName,
          'p_username': username,
          'p_city': city,
          'p_bio': bio,
        },
      );
      return _myProfileFromJson(json);
    } on PostgrestException catch (error, stackTrace) {
      Error.throwWithStackTrace(_mapUpdateError(error), stackTrace);
    }
  }

  @override
  Future<MyProfile> uploadAvatar(Uint8List bytes) async {
    _requireUser();
    String? stagedObject;
    var committed = false;
    try {
      final prepared = await _client.rpc<Map<String, dynamic>>(
        'prepare_profile_avatar_upload',
      );
      stagedObject = prepared['avatar_object'] as String?;
      if (stagedObject == null || stagedObject.isEmpty) {
        throw const ProfileException(ProfileFailureReason.avatarUnavailable);
      }
      await _client.storage
          .from(_avatarsBucket)
          .uploadBinary(
            stagedObject,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/webp'),
          );
      final result = await _client.rpc<Map<String, dynamic>>(
        'commit_profile_avatar',
        params: {'p_avatar_object': stagedObject},
      );
      committed = true;
      // Best-effort delete of the replaced object; the RPC already swapped it.
      await _removeObject(result['previous_avatar_object'] as String?);
      return fetchMyProfile();
    } catch (error, stackTrace) {
      if (!committed) await _removeObject(stagedObject);
      final mapped = switch (error) {
        final ProfileException value => value,
        final StorageException value => ProfileException(
          ProfileFailureReason.avatarUnavailable,
          cause: value,
        ),
        final PostgrestException value => _mapError(value),
        _ => ProfileException(
          ProfileFailureReason.avatarUnavailable,
          cause: error,
        ),
      };
      Error.throwWithStackTrace(mapped, stackTrace);
    }
  }

  @override
  Future<MyProfile> clearAvatar() async {
    _requireUser();
    try {
      final cleared = await _client.rpc<Map<String, dynamic>>(
        'clear_my_profile_avatar',
      );
      await _removeObject(cleared['previous_avatar_object'] as String?);
      return fetchMyProfile();
    } on PostgrestException catch (error, stackTrace) {
      Error.throwWithStackTrace(_mapError(error), stackTrace);
    }
  }

  @override
  Future<Map<String, PublicProfileSummary>> fetchPublicProfileSummaries(
    List<String> sellerIds,
  ) async {
    final ids = sellerIds.toSet().toList(growable: false);
    if (ids.isEmpty) return const <String, PublicProfileSummary>{};
    try {
      final rows = await _client.rpc<List<dynamic>>(
        'get_public_profile_summaries',
        params: {'p_seller_ids': ids},
      );
      final result = <String, PublicProfileSummary>{};
      for (final row in rows) {
        final map = Map<String, dynamic>.from(row as Map);
        final sellerId = map['seller_id'] as String?;
        if (sellerId == null) continue;
        result[sellerId] = PublicProfileSummary(
          sellerId: sellerId,
          displayName: map['display_name'] as String?,
          username: map['username'] as String?,
          city: map['city'] as String?,
          avatarUrl: _avatarUrls.resolve(map['avatar_object'] as String?),
        );
      }
      return result;
    } on PostgrestException catch (error, stackTrace) {
      Error.throwWithStackTrace(_mapError(error), stackTrace);
    }
  }

  Future<void> _removeObject(String? object) async {
    if (object == null || object.isEmpty) return;
    try {
      await _client.storage.from(_avatarsBucket).remove([object]);
    } on Object {
      // Orphan cleanup is best-effort; the profile already points elsewhere.
    }
  }

  MyProfile _myProfileFromJson(Map<String, dynamic> json) {
    final seller = json['seller'];
    return MyProfile(
      displayName: json['display_name'] as String?,
      username: json['username'] as String?,
      city: json['city'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: _avatarUrls.resolve(json['avatar_object'] as String?),
      listingCount: (json['listing_count'] as num?)?.toInt() ?? 0,
      seller: seller is Map
          ? ProfileSeller.fromJson(Map<String, dynamic>.from(seller))
          : null,
    );
  }

  PublicProfile _publicProfileFromJson(Map<String, dynamic> json) {
    final seller = json['seller'];
    return PublicProfile(
      displayName: json['display_name'] as String?,
      username: json['username'] as String?,
      city: json['city'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: _avatarUrls.resolve(json['avatar_object'] as String?),
      listingCount: (json['listing_count'] as num?)?.toInt() ?? 0,
      isSelf: json['is_self'] as bool? ?? false,
      seller: seller is Map
          ? ProfileSeller.fromJson(Map<String, dynamic>.from(seller))
          : null,
    );
  }

  void _requireUser() {
    if (_client.auth.currentUser == null) {
      throw const ProfileException(ProfileFailureReason.notAuthenticated);
    }
  }

  ProfileException _mapError(PostgrestException error) {
    return switch (error.code) {
      '42501' => ProfileException(
        ProfileFailureReason.notAuthenticated,
        cause: error,
      ),
      'P0002' => ProfileException(ProfileFailureReason.notFound, cause: error),
      _ => ProfileException(ProfileFailureReason.unknown, cause: error),
    };
  }

  // update_my_profile raises 23505 for a taken username and 22023 for the
  // display name, reserved username, city, and bio validation errors. The
  // message text disambiguates the 22023 cases for inline copy.
  ProfileException _mapUpdateError(PostgrestException error) {
    if (error.code == '23505') {
      return ProfileException(ProfileFailureReason.usernameTaken, cause: error);
    }
    if (error.code == '22023') {
      final message = error.message.toLowerCase();
      if (message.contains('reserved')) {
        return ProfileException(
          ProfileFailureReason.usernameReserved,
          cause: error,
        );
      }
      if (message.contains('city')) {
        return ProfileException(
          ProfileFailureReason.unsupportedCity,
          cause: error,
        );
      }
      if (message.contains('display name')) {
        return ProfileException(
          ProfileFailureReason.invalidDisplayName,
          cause: error,
        );
      }
      if (message.contains('bio')) {
        return ProfileException(ProfileFailureReason.bioTooLong, cause: error);
      }
      return ProfileException(
        ProfileFailureReason.usernameInvalid,
        cause: error,
      );
    }
    return _mapError(error);
  }
}
