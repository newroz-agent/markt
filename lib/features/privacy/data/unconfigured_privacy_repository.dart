import 'package:zerin_marketplace/core/errors/app_exception.dart';
import 'package:zerin_marketplace/features/privacy/domain/notification_preferences.dart';
import 'package:zerin_marketplace/features/privacy/domain/privacy_overview.dart';
import 'package:zerin_marketplace/features/privacy/domain/privacy_repository.dart';

/// Privacy repository for builds without Supabase credentials.
///
/// Reads succeed with defaults so the screen renders, but every write fails:
/// pretending a consent change or a deletion request was recorded would be a
/// lie about a legally binding action.
class UnconfiguredPrivacyRepository implements PrivacyRepository {
  const UnconfiguredPrivacyRepository();

  static const _unavailable = AppException(AppFailureCode.backendNotConfigured);

  @override
  Future<PrivacyOverview> fetchOverview() async => const PrivacyOverview();

  @override
  Future<void> saveNotificationPreferences(NotificationPreferences value) =>
      Future<void>.error(_unavailable);

  @override
  Future<void> setAnalyticsConsent({required bool granted}) =>
      Future<void>.error(_unavailable);

  @override
  Future<void> recordConsent({
    required String consentType,
    required bool granted,
    String? documentVersion,
  }) => Future<void>.error(_unavailable);

  @override
  Future<String> requestDataExport() => Future<String>.error(_unavailable);

  @override
  Future<String> requestAccountDeletion({
    required String confirmation,
    String? reason,
  }) => Future<String>.error(_unavailable);

  @override
  Future<bool> cancelAccountDeletion() => Future<bool>.error(_unavailable);

  @override
  Future<String?> createExportDownloadUrl(String storagePath) =>
      Future<String?>.error(_unavailable);
}
