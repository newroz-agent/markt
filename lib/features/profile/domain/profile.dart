import 'package:flutter/foundation.dart';

/// Seller identity attached to a profile. `status` is only present on the
/// owner's own profile (`get_my_profile`); public profiles omit it.
@immutable
class ProfileSeller {
  const ProfileSeller({
    required this.id,
    required this.kind,
    required this.verified,
    this.status,
    this.storeName,
  });

  factory ProfileSeller.fromJson(Map<String, dynamic> json) => ProfileSeller(
    id: json['id']! as String,
    kind: json['kind'] as String? ?? 'private',
    status: json['status'] as String?,
    storeName: json['store_name'] as String?,
    verified: json['verified'] as bool? ?? false,
  );

  final String id;

  /// `public.seller_kind`: `private` or `business`.
  final String kind;

  /// Only present on the owner's own profile. Null for public projections.
  final String? status;

  /// Business store name; null for private sellers.
  final String? storeName;

  final bool verified;

  bool get isBusiness => kind == 'business';

  /// Approved sellers can receive chat. Public projections have no status and
  /// are only returned when already approved, so treat null status as approved.
  bool get isApproved => status == null || status == 'approved';
}

/// The signed-in user's own profile (`get_my_profile`). Never carries email or
/// auth identifiers. `avatarUrl` is a resolved public URL, never an object path.
@immutable
class MyProfile {
  const MyProfile({
    required this.displayName,
    required this.username,
    required this.city,
    required this.bio,
    required this.avatarUrl,
    required this.listingCount,
    required this.seller,
  });

  final String? displayName;
  final String? username;
  final String? city;
  final String? bio;
  final String? avatarUrl;
  final int listingCount;
  final ProfileSeller? seller;
}

/// A public profile (`get_public_profile`). Only safe fields, a resolved public
/// avatar URL, and an `isSelf` marker. The seller (if any) omits status.
@immutable
class PublicProfile {
  const PublicProfile({
    required this.displayName,
    required this.username,
    required this.city,
    required this.bio,
    required this.avatarUrl,
    required this.listingCount,
    required this.isSelf,
    required this.seller,
  });

  final String? displayName;
  final String? username;
  final String? city;
  final String? bio;
  final String? avatarUrl;
  final int listingCount;
  final bool isSelf;
  final ProfileSeller? seller;
}

/// Overlay identity for an approved private seller, resolved from
/// `get_public_profile_summaries`. Only these fields overlay a listing's
/// display identity; business store name/logo is preserved as-is.
@immutable
class PublicProfileSummary {
  const PublicProfileSummary({
    required this.sellerId,
    required this.displayName,
    required this.username,
    required this.city,
    required this.avatarUrl,
  });

  final String sellerId;
  final String? displayName;
  final String? username;
  final String? city;

  /// Resolved public avatar URL, never an object path. Null when unavailable.
  final String? avatarUrl;
}
