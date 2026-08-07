import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

enum AppThemePreference { system, light, dark }

@freezed
class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default('de') String localeCode,
    @Default(AppThemePreference.system) AppThemePreference themePreference,
    @Default(false) bool onboardingComplete,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
}
