import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:zerin_marketplace/core/errors/app_exception.dart';
import 'package:zerin_marketplace/features/privacy/domain/data_subject_request.dart';
import 'package:zerin_marketplace/features/privacy/domain/notification_preferences.dart';
import 'package:zerin_marketplace/features/privacy/domain/privacy_overview.dart';
import 'package:zerin_marketplace/features/privacy/domain/privacy_repository.dart';
import 'package:zerin_marketplace/features/privacy/domain/privacy_settings.dart';

class SupabasePrivacyRepository implements PrivacyRepository {
  SupabasePrivacyRepository(this._client);

  /// Private bucket holding generated exports, keyed by `<user id>/<file>`.
  static const exportBucket = 'data-exports';

  /// How long a generated download link stays valid.
  static const exportUrlValidity = Duration(minutes: 10);

  /// Newest first, and capped: the screen only shows the latest request per
  /// kind, so the rest is history nobody reads.
  static const _requestLimit = 20;

  final SupabaseClient _client;

  @override
  Future<PrivacyOverview> fetchOverview() async {
    final userId = _requireUserId();

    return _guard(() async {
      final profile = await _client
          .from('profiles')
          .select('notification_preferences, analytics_consent, '
              'analytics_consent_at')
          .eq('id', userId)
          .maybeSingle();

      final requests = await _client
          .from('data_subject_requests')
          .select('id, kind, status, requested_at, export_storage_path, '
              'export_expires_at, completed_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(_requestLimit);

      return PrivacyOverview(
        settings: _settingsFrom(profile),
        requests: requests
            .map(DataSubjectRequest.fromJson)
            .toList(growable: false),
      );
    });
  }

  @override
  Future<void> saveNotificationPreferences(
    NotificationPreferences value,
  ) async {
    final userId = _requireUserId();
    await _guard(
      () => _client
          .from('profiles')
          .update(<String, dynamic>{'notification_preferences': value.toJson()})
          .eq('id', userId),
    );
  }

  @override
  Future<void> setAnalyticsConsent({required bool granted}) async {
    final userId = _requireUserId();
    // `analytics_consent_at` is deliberately not sent: the profile trigger
    // stamps it and raises if a client supplies its own value.
    await _guard(
      () => _client
          .from('profiles')
          .update(<String, dynamic>{'analytics_consent': granted})
          .eq('id', userId),
    );
  }

  @override
  Future<void> recordConsent({
    required String consentType,
    required bool granted,
    String? documentVersion,
  }) async {
    // `user_id` is not sent: the `protect_user_consent_write` trigger fills it
    // from `auth.uid()`, which is the value the audit trail must reflect.
    _requireUserId();
    await _guard(
      () => _client.from('user_consents').insert(<String, dynamic>{
        'consent_type': consentType,
        'granted': granted,
        'document_version': ?documentVersion,
      }),
    );
  }

  @override
  Future<String> requestDataExport() async {
    _requireUserId();
    final id = await _guard(() => _client.rpc<dynamic>('request_data_export'));
    return id! as String;
  }

  @override
  Future<String> requestAccountDeletion({
    required String confirmation,
    String? reason,
  }) async {
    _requireUserId();
    final id = await _guard(
      () => _client.rpc<dynamic>(
        'request_account_deletion',
        params: <String, dynamic>{
          'p_confirmation': confirmation,
          'p_reason': reason,
        },
      ),
    );
    return id! as String;
  }

  @override
  Future<bool> cancelAccountDeletion() async {
    _requireUserId();
    final cancelled = await _guard(
      () => _client.rpc<dynamic>('cancel_account_deletion'),
    );
    return cancelled == true;
  }

  @override
  Future<String?> createExportDownloadUrl(String storagePath) async {
    _requireUserId();
    try {
      return await _client.storage
          .from(exportBucket)
          .createSignedUrl(storagePath, exportUrlValidity.inSeconds);
    } on StorageException {
      // The object is gone once the retention window closes; the caller shows
      // "expired" rather than an error, which is what actually happened.
      return null;
    }
  }

  PrivacySettings _settingsFrom(Map<String, dynamic>? profile) {
    if (profile == null) return const PrivacySettings();

    final preferences = profile['notification_preferences'];
    final consentAt = profile['analytics_consent_at'] as String?;

    return PrivacySettings(
      notifications: preferences is Map<String, dynamic>
          ? NotificationPreferences.fromJson(preferences)
          : const NotificationPreferences(),
      analyticsConsent: profile['analytics_consent'] as bool? ?? false,
      analyticsConsentAt: consentAt == null
          ? null
          : DateTime.parse(consentAt).toLocal(),
    );
  }

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppException(AppFailureCode.notAuthenticated);
    }
    return userId;
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on PostgrestException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        AppException(_codeFor(error), cause: error),
        stackTrace,
      );
    }
  }

  /// Maps the SQLSTATEs the Phase 5 RPCs raise deliberately.
  AppFailureCode _codeFor(PostgrestException error) => switch (error.code) {
    '42501' => AppFailureCode.notAuthenticated,
    _ => AppFailureCode.unknown,
  };
}
