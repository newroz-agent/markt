import 'package:zerin_marketplace/features/privacy/domain/notification_preferences.dart';
import 'package:zerin_marketplace/features/privacy/domain/privacy_overview.dart';

/// Reads and writes the user's privacy state.
///
/// Every method assumes an authenticated caller: the RPCs raise `42501`
/// without one, and the profile row is reachable only through its own RLS
/// policy.
abstract interface class PrivacyRepository {
  Future<PrivacyOverview> fetchOverview();

  Future<void> saveNotificationPreferences(NotificationPreferences value);

  /// Writes `profiles.analytics_consent`; the timestamp is set by the trigger.
  Future<void> setAnalyticsConsent({required bool granted});

  /// Records an explicit consent decision in `public.user_consents`.
  ///
  /// Rows there are append-only and immutable — the audit trail for what the
  /// user agreed to and when.
  Future<void> recordConsent({
    required String consentType,
    required bool granted,
    String? documentVersion,
  });

  /// Requests a DSGVO Art. 15 data export, returning the request id.
  ///
  /// Idempotent: an already-open export returns that request instead of
  /// queueing a second one.
  Future<String> requestDataExport();

  /// Requests account deletion. [confirmation] must be the literal `DELETE`
  /// the RPC checks for, or it raises `22023`.
  Future<String> requestAccountDeletion({
    required String confirmation,
    String? reason,
  });

  /// Cancels a pending deletion. `false` means there was nothing to cancel.
  Future<bool> cancelAccountDeletion();

  /// A time-limited URL for a completed export, or `null` if it has expired.
  Future<String?> createExportDownloadUrl(String storagePath);
}
