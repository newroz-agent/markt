import 'package:flutter/material.dart';

import 'package:zerin_marketplace/l10n/app_localizations.dart';

export 'package:zerin_marketplace/l10n/app_localizations.dart';

/// Locale definitions and normalization shared by the app shell and settings.
abstract final class AppLocale {
  static const german = Locale('de');
  static const english = Locale('en');
  static const arabic = Locale('ar');
  static const turkish = Locale('tr');
  static const kurdish = Locale('ku');

  /// German is the product language and fallback locale for unsupported devices.
  static const defaultLocale = german;

  static const supportedLocales = AppLocalizations.supportedLocales;

  static const _rtlLanguageCodes = {'ar'};

  static bool isRtl(Locale locale) =>
      _rtlLanguageCodes.contains(locale.languageCode);

  /// Maps regional variants such as `de_AT` or `ar_SA` to a supported locale.
  static Locale normalize(Locale locale) {
    for (final supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return supportedLocale;
      }
    }

    return defaultLocale;
  }
}

extension AppLocalizationsBuildContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  Locale get appLocale => Localizations.localeOf(this);

  /// Uses Flutter's resolved directionality so nested locale overrides work too.
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;
}

extension AppLocaleDisplayName on Locale {
  String localizedDisplayName(AppLocalizations l10n) {
    return switch (languageCode) {
      'de' => l10n.languageGerman,
      'en' => l10n.languageEnglish,
      'ar' => l10n.languageArabic,
      'tr' => l10n.languageTurkish,
      'ku' => l10n.languageKurdish,
      _ => languageCode,
    };
  }
}
