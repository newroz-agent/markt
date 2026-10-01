import 'dart:typed_data';

import 'package:zerin_marketplace/features/profile/domain/profile.dart';
import 'package:zerin_marketplace/features/profile/domain/profile_errors.dart';

abstract interface class ProfileRepository {
  /// The signed-in user's own profile. Throws [ProfileException] when there is
  /// no session or the profile row is missing.
  Future<MyProfile> fetchMyProfile();

  /// A public profile by normalized username, or null when it does not exist.
  Future<PublicProfile?> fetchPublicProfile(String username);

  /// Advisory availability check for a candidate username.
  Future<UsernameAvailability> checkUsername(String username);

  /// Saves the profile. The database is authoritative: a conflict/reserved/
  /// invalid result surfaces as a typed [ProfileException].
  Future<MyProfile> updateMyProfile({
    required String displayName,
    required String username,
    required String city,
    String? bio,
  });

  /// Uploads [bytes] as the profile avatar and commits it. Returns the updated
  /// profile with a resolved public avatar URL.
  Future<MyProfile> uploadAvatar(Uint8List bytes);

  /// Clears the profile avatar. Returns the updated profile.
  Future<MyProfile> clearAvatar();

  /// Batch overlay of approved private-seller public identity, keyed by seller
  /// id. Business sellers and non-approved sellers are simply absent.
  Future<Map<String, PublicProfileSummary>> fetchPublicProfileSummaries(
    List<String> sellerIds,
  );
}
