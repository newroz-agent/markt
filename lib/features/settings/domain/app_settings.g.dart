// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppSettingsImpl _$$AppSettingsImplFromJson(Map<String, dynamic> json) =>
    _$AppSettingsImpl(
      localeCode: json['localeCode'] as String? ?? 'de',
      themePreference:
          $enumDecodeNullable(
            _$AppThemePreferenceEnumMap,
            json['themePreference'],
          ) ??
          AppThemePreference.system,
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
    );

Map<String, dynamic> _$$AppSettingsImplToJson(_$AppSettingsImpl instance) =>
    <String, dynamic>{
      'localeCode': instance.localeCode,
      'themePreference': _$AppThemePreferenceEnumMap[instance.themePreference]!,
      'onboardingComplete': instance.onboardingComplete,
    };

const _$AppThemePreferenceEnumMap = {
  AppThemePreference.system: 'system',
  AppThemePreference.light: 'light',
  AppThemePreference.dark: 'dark',
};
