import 'package:flutter/cupertino.dart' show CupertinoLocalizations;
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart' show initializeDateFormatting;
import 'package:intl/intl.dart' as intl;

/// Kurdish (`ku`) fallbacks for the framework-owned localizations.
///
/// Flutter ships translations for 84 languages and Kurdish is not one of them,
/// so `GlobalMaterialLocalizations.delegate.isSupported(Locale('ku'))` is
/// false. Nothing else fills the gap either: the framework's built-in fallback
/// only claims `en`, so under `ku` the lookup in `MaterialLocalizations.of`
/// resolves to null and its `!` throws. Both `privacy_screen.dart` and
/// `legal_screen.dart` call `formatFullDate` through it, so the crash is on a
/// path real users reach.
///
/// These delegates keep our own translated strings (`AppLocalizations`) while
/// borrowing English for the framework's widget furniture — date pickers,
/// "Cancel", the reorder hints. Wrong language on those, but the alternative
/// is a red screen.
///
/// `intl` has no `ku` locale data either, so every format below is built from
/// `en`. Constructing them with `'ku'` would throw inside `DateFormat`.
const String _fallbackLocale = 'en';

/// The global delegates prime `intl` via a `flutter_localizations` helper that
/// is library-private, and a `ku` launch never reaches them — so if this app
/// starts in Kurdish, nothing has loaded the date symbols yet and the first
/// `DateFormat` call throws `LocaleDataException`. Priming it here keeps the
/// fallback self-contained. `initializeDateFormatting` is synchronous inside
/// despite its `Future` return, and is a no-op once loaded.
void _ensureDateFormattingLoaded() {
  initializeDateFormatting(_fallbackLocale);
}

/// Order matters: register these ahead of the global delegates in
/// `localizationsDelegates`. `Localizations._loadAll` keeps the *first*
/// delegate per type whose `isSupported` returns true, and each of these
/// matches `ku` only, so the globals stay in charge of every other locale.
const List<LocalizationsDelegate<dynamic>> kuFallbackDelegates =
    <LocalizationsDelegate<dynamic>>[
      KuMaterialLocalizations.delegate,
      KuCupertinoLocalizations.delegate,
    ];

/// English material strings served under the `ku` locale name.
class KuMaterialLocalizations extends MaterialLocalizationEn {
  const KuMaterialLocalizations({
    super.localeName = 'ku',
    required super.fullYearFormat,
    required super.compactDateFormat,
    required super.shortDateFormat,
    required super.mediumDateFormat,
    required super.longDateFormat,
    required super.yearMonthFormat,
    required super.shortMonthDayFormat,
    required super.decimalFormat,
    required super.twoDigitZeroPaddedFormat,
  });

  static const LocalizationsDelegate<MaterialLocalizations> delegate =
      _KuMaterialLocalizationsDelegate();
}

class _KuMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _KuMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ku';

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    _ensureDateFormattingLoaded();
    return SynchronousFuture<MaterialLocalizations>(
      KuMaterialLocalizations(
        fullYearFormat: intl.DateFormat.y(_fallbackLocale),
        compactDateFormat: intl.DateFormat.yMd(_fallbackLocale),
        shortDateFormat: intl.DateFormat.yMMMd(_fallbackLocale),
        mediumDateFormat: intl.DateFormat.MMMEd(_fallbackLocale),
        longDateFormat: intl.DateFormat.yMMMMEEEEd(_fallbackLocale),
        yearMonthFormat: intl.DateFormat.yMMMM(_fallbackLocale),
        shortMonthDayFormat: intl.DateFormat.MMMd(_fallbackLocale),
        decimalFormat: intl.NumberFormat.decimalPattern(_fallbackLocale),
        twoDigitZeroPaddedFormat: intl.NumberFormat('00', _fallbackLocale),
      ),
    );
  }

  @override
  bool shouldReload(_KuMaterialLocalizationsDelegate old) => false;

  @override
  String toString() => 'KuMaterialLocalizations.delegate(ku)';
}

/// English Cupertino strings served under the `ku` locale name.
///
/// `SwitchListTile.adaptive` on the privacy screen resolves to the Cupertino
/// switch on iOS, so this is reachable on the same screen as the material gap.
class KuCupertinoLocalizations extends CupertinoLocalizationEn {
  const KuCupertinoLocalizations({
    super.localeName = 'ku',
    required super.fullYearFormat,
    required super.dayFormat,
    required super.weekdayFormat,
    required super.mediumDateFormat,
    required super.singleDigitHourFormat,
    required super.singleDigitMinuteFormat,
    required super.doubleDigitMinuteFormat,
    required super.singleDigitSecondFormat,
    required super.decimalFormat,
  });

  static const LocalizationsDelegate<CupertinoLocalizations> delegate =
      _KuCupertinoLocalizationsDelegate();
}

class _KuCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _KuCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ku';

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    _ensureDateFormattingLoaded();
    return SynchronousFuture<CupertinoLocalizations>(
      KuCupertinoLocalizations(
        fullYearFormat: intl.DateFormat.y(_fallbackLocale),
        dayFormat: intl.DateFormat.d(_fallbackLocale),
        weekdayFormat: intl.DateFormat.E(_fallbackLocale),
        mediumDateFormat: intl.DateFormat.MMMEd(_fallbackLocale),
        singleDigitHourFormat: intl.DateFormat('HH', _fallbackLocale),
        singleDigitMinuteFormat: intl.DateFormat.m(_fallbackLocale),
        doubleDigitMinuteFormat: intl.DateFormat('mm', _fallbackLocale),
        singleDigitSecondFormat: intl.DateFormat.s(_fallbackLocale),
        decimalFormat: intl.NumberFormat.decimalPattern(_fallbackLocale),
      ),
    );
  }

  @override
  bool shouldReload(_KuCupertinoLocalizationsDelegate old) => false;

  @override
  String toString() => 'KuCupertinoLocalizations.delegate(ku)';
}
