/// Profile-specific failures, kept separate from the shared [AppFailureCode]
/// so username availability and avatar flows can surface precise inline copy.
enum ProfileFailureReason {
  /// Backend not configured (unconfigured fallback repository).
  backendNotConfigured,

  /// No authenticated session for an action that requires one.
  notAuthenticated,

  /// The requested profile does not exist.
  notFound,

  /// Username fails syntax/length rules (server-authoritative `invalid`).
  usernameInvalid,

  /// Username is reserved or would impersonate a verified business/admin.
  usernameReserved,

  /// Username is already taken by another profile.
  usernameTaken,

  /// The submitted city is not a supported German city.
  unsupportedCity,

  /// The display name is empty or exceeds the allowed length.
  invalidDisplayName,

  /// The bio exceeds the allowed length.
  bioTooLong,

  /// The avatar object could not be prepared, uploaded, or committed.
  avatarUnavailable,

  /// Network transport error.
  network,

  /// Any other unexpected failure.
  unknown,
}

/// Thrown by the profile repository/controllers. Carries a precise
/// [ProfileFailureReason] so the edit form can render inline conflict copy.
class ProfileException implements Exception {
  const ProfileException(this.reason, {this.cause});

  final ProfileFailureReason reason;
  final Object? cause;

  @override
  String toString() => 'ProfileException(reason: $reason, cause: $cause)';
}

/// Result of an advisory username availability check.
enum UsernameAvailability { available, taken, reserved, invalid }

extension UsernameAvailabilityParsing on UsernameAvailability {
  static UsernameAvailability fromServer(String value) => switch (value) {
    'available' => UsernameAvailability.available,
    'taken' => UsernameAvailability.taken,
    'reserved' => UsernameAvailability.reserved,
    _ => UsernameAvailability.invalid,
  };
}
