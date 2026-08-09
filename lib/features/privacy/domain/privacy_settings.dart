import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:zerin_marketplace/features/privacy/domain/notification_preferences.dart';

part 'privacy_settings.freezed.dart';

/// The privacy-relevant slice of `public.profiles`.
///
/// `analyticsConsentAt` is server-managed — the trigger raises if a client
/// tries to write it — so it is read-only here and used to show the user when
/// they granted consent.
@freezed
class PrivacySettings with _$PrivacySettings {
  const factory PrivacySettings({
    @Default(NotificationPreferences()) NotificationPreferences notifications,
    @Default(false) bool analyticsConsent,
    DateTime? analyticsConsentAt,
  }) = _PrivacySettings;

  const PrivacySettings._();
}
