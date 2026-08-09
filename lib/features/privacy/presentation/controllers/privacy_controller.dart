import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:zerin_marketplace/core/providers/infrastructure_providers.dart';
import 'package:zerin_marketplace/features/auth/presentation/controllers/auth_controller.dart';
import 'package:zerin_marketplace/features/privacy/data/supabase_privacy_repository.dart';
import 'package:zerin_marketplace/features/privacy/data/unconfigured_privacy_repository.dart';
import 'package:zerin_marketplace/features/privacy/domain/data_subject_request.dart';
import 'package:zerin_marketplace/features/privacy/domain/notification_preferences.dart';
import 'package:zerin_marketplace/features/privacy/domain/privacy_overview.dart';
import 'package:zerin_marketplace/features/privacy/domain/privacy_repository.dart';

part 'privacy_controller.g.dart';

/// Consent types recorded in `public.user_consents`.
///
/// The values must satisfy the column's `^[a-z][a-z0-9_.-]{1,79}$` check.
abstract final class ConsentTypes {
  static const analytics = 'analytics';
}

/// The literal the deletion RPC demands. Not localized: it is compared
/// verbatim in SQL, so translating it would make deletion impossible.
const deletionConfirmationWord = 'DELETE';

@Riverpod(keepAlive: true)
PrivacyRepository privacyRepository(PrivacyRepositoryRef ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? const UnconfiguredPrivacyRepository()
      : SupabasePrivacyRepository(client);
}

/// Privacy state for the signed-in user.
///
/// Watches the auth state so signing out clears it instead of leaving another
/// user's consent and requests on screen.
@riverpod
class PrivacyController extends _$PrivacyController {
  @override
  Future<PrivacyOverview> build() async {
    final user = await ref.watch(authStateProvider.future);
    if (user == null) return const PrivacyOverview();
    return ref.watch(privacyRepositoryProvider).fetchOverview();
  }

  PrivacyRepository get _repository => ref.read(privacyRepositoryProvider);

  Future<void> setNotificationChannel(
    NotificationChannel channel, {
    required bool enabled,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final next = current.settings.notifications.withChannel(
      channel,
      enabled: enabled,
    );
    // Optimistic: a toggle that waits for a round trip feels broken. The
    // catch below puts the old value back if the write is rejected.
    state = AsyncData(
      current.copyWith(
        settings: current.settings.copyWith(notifications: next),
      ),
    );

    try {
      await _repository.saveNotificationPreferences(next);
    } catch (error, stackTrace) {
      state = AsyncData(current);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> setAnalyticsConsent({required bool granted}) async {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncData(
      current.copyWith(
        settings: current.settings.copyWith(analyticsConsent: granted),
      ),
    );

    try {
      await _repository.setAnalyticsConsent(granted: granted);
      // The audit row is written after the profile so the trail never claims
      // a consent state the profile does not actually hold.
      await _repository.recordConsent(
        consentType: ConsentTypes.analytics,
        granted: granted,
      );
    } catch (error, stackTrace) {
      state = AsyncData(current);
      Error.throwWithStackTrace(error, stackTrace);
    }
    await _reload();
  }

  Future<void> requestDataExport() async {
    await _repository.requestDataExport();
    await _reload();
  }

  Future<void> requestAccountDeletion({String? reason}) async {
    await _repository.requestAccountDeletion(
      confirmation: deletionConfirmationWord,
      reason: reason,
    );
    await _reload();
  }

  /// Returns `false` when there was no pending deletion left to cancel —
  /// for instance because processing started while the screen was open.
  Future<bool> cancelAccountDeletion() async {
    final cancelled = await _repository.cancelAccountDeletion();
    await _reload();
    return cancelled;
  }

  Future<String?> createExportDownloadUrl(DataSubjectRequest request) {
    final path = request.exportStoragePath;
    if (path == null) return Future<String?>.value();
    return _repository.createExportDownloadUrl(path);
  }

  /// Re-reads from the server rather than patching locally: status is
  /// server-owned, and the RPCs are idempotent enough that the returned row
  /// may differ from what was just requested.
  Future<void> _reload() async {
    state = await AsyncValue.guard(_repository.fetchOverview);
  }
}
