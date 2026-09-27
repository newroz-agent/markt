import 'dart:typed_data';

import 'package:zerin_marketplace/features/profile/domain/profile.dart';
import 'package:zerin_marketplace/features/profile/domain/profile_errors.dart';
import 'package:zerin_marketplace/features/profile/domain/profile_repository.dart';

class UnconfiguredProfileRepository implements ProfileRepository {
  const UnconfiguredProfileRepository();

  Never _unconfigured() =>
      throw const ProfileException(ProfileFailureReason.backendNotConfigured);

  @override
  Future<MyProfile> fetchMyProfile() async => _unconfigured();

  @override
  Future<PublicProfile?> fetchPublicProfile(String username) async =>
      _unconfigured();

  @override
  Future<UsernameAvailability> checkUsername(String username) async =>
      _unconfigured();

  @override
  Future<MyProfile> updateMyProfile({
    required String displayName,
    required String username,
    required String city,
    String? bio,
  }) async => _unconfigured();

  @override
  Future<MyProfile> uploadAvatar(Uint8List bytes) async => _unconfigured();

  @override
  Future<MyProfile> clearAvatar() async => _unconfigured();

  @override
  Future<Map<String, PublicProfileSummary>> fetchPublicProfileSummaries(
    List<String> sellerIds,
  ) async => const <String, PublicProfileSummary>{};
}
