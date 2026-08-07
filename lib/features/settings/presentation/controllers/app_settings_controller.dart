import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zerin_marketplace/core/providers/infrastructure_providers.dart';
import 'package:zerin_marketplace/features/settings/domain/app_settings.dart';

part 'app_settings_controller.g.dart';

abstract final class SettingsStorageKeys {
  static const locale = 'settings.locale';
  static const theme = 'settings.theme';
  static const onboardingComplete = 'onboarding.complete';
}

@Riverpod(keepAlive: true)
class AppSettingsController extends _$AppSettingsController {
  @override
  FutureOr<AppSettings> build() => _readSettings();

  Future<void> setLocale(String localeCode) async {
    await _persist(
      _current.copyWith(localeCode: localeCode),
      () => ref
          .read(sharedPreferencesProvider)
          .setString(SettingsStorageKeys.locale, localeCode),
    );
  }

  Future<void> setTheme(AppThemePreference preference) async {
    await _persist(
      _current.copyWith(themePreference: preference),
      () => ref
          .read(sharedPreferencesProvider)
          .setString(SettingsStorageKeys.theme, preference.name),
    );
  }

  Future<void> completeOnboarding() async {
    await _persist(
      _current.copyWith(onboardingComplete: true),
      () => ref
          .read(sharedPreferencesProvider)
          .setBool(SettingsStorageKeys.onboardingComplete, true),
    );
  }

  AppSettings get _current => state.asData?.value ?? _readSettings();

  AppSettings _readSettings() {
    final preferences = ref.read(sharedPreferencesProvider);
    final storedTheme = preferences.getString(SettingsStorageKeys.theme);

    return AppSettings(
      localeCode: preferences.getString(SettingsStorageKeys.locale) ?? 'de',
      themePreference: AppThemePreference.values.firstWhere(
        (value) => value.name == storedTheme,
        orElse: () => AppThemePreference.system,
      ),
      onboardingComplete:
          preferences.getBool(SettingsStorageKeys.onboardingComplete) ?? false,
    );
  }

  Future<void> _persist(AppSettings next, Future<bool> Function() write) async {
    try {
      final didWrite = await write();
      if (!didWrite) {
        throw StateError('Could not persist application settings.');
      }
      state = AsyncData(next);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}
