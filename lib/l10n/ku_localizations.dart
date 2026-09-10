import 'package:flutter/cupertino.dart' show CupertinoLocalizations;
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;
import 'package:zerin_marketplace/l10n/ku_date_symbols.dart';

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
/// These delegates subclass the German implementations for reach — the
/// framework exposes hundreds of strings — but dates render with real Kurmanji
/// symbols (see [ensureKuDateFormatting]) and the labels users actually read
/// are overridden below. German is the explicit framework fallback for the
/// remaining long tail: date-picker
/// help text, reorder hints, and similar rarely-surfaced strings.
const String _localeName = 'ku';
const String _numberLocale = 'de';

/// Order matters: register these ahead of the global delegates in
/// `localizationsDelegates`. `Localizations._loadAll` keeps the *first*
/// delegate per type whose `isSupported` returns true, and each of these
/// matches `ku` only, so the globals stay in charge of every other locale.
const List<LocalizationsDelegate<dynamic>> kuFallbackDelegates =
    <LocalizationsDelegate<dynamic>>[
      KuMaterialLocalizations.delegate,
      KuCupertinoLocalizations.delegate,
    ];

/// Material strings under `ku`: Kurmanji for the labels users read on every
/// dialog and app bar, inherited German for the long tail.
class KuMaterialLocalizations extends MaterialLocalizationDe {
  const KuMaterialLocalizations({
    super.localeName = _localeName,
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

  @override
  String get okButtonLabel => 'Temam';

  @override
  String get cancelButtonLabel => 'Betal bike';

  @override
  String get closeButtonLabel => 'Bigire';

  @override
  String get closeButtonTooltip => 'Bigire';

  @override
  String get backButtonTooltip => 'Vegere';

  @override
  String get searchFieldLabel => 'Bigere';

  @override
  String get copyButtonLabel => 'Kopî bike';

  @override
  String get pasteButtonLabel => 'Pêve bike';

  @override
  String get cutButtonLabel => 'Jê bike';

  @override
  String get selectAllButtonLabel => 'Hemûyan hilbijêre';

  @override
  String get deleteButtonTooltip => 'Jê bibe';

  @override
  String get saveButtonLabel => 'Tomar bike';

  @override
  String get nextPageTooltip => 'Rûpela pêş';

  @override
  String get previousPageTooltip => 'Rûpela paş';

  @override
  String get moreButtonTooltip => 'Zêdetir';

  @override
  String get refreshIndicatorSemanticLabel => 'Nû bike';
}

class _KuMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _KuMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ku';

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    ensureKuDateFormatting();
    return SynchronousFuture<MaterialLocalizations>(
      KuMaterialLocalizations(
        fullYearFormat: intl.DateFormat.y(_localeName),
        compactDateFormat: intl.DateFormat.yMd(_localeName),
        shortDateFormat: intl.DateFormat.yMMMd(_localeName),
        mediumDateFormat: intl.DateFormat.MMMEd(_localeName),
        longDateFormat: intl.DateFormat.yMMMMEEEEd(_localeName),
        yearMonthFormat: intl.DateFormat.yMMMM(_localeName),
        shortMonthDayFormat: intl.DateFormat.MMMd(_localeName),
        // `intl` has no `ku` number symbols. Keep the existing Latin-digit
        // behavior while all date formats use the custom Kurmanji symbols.
        decimalFormat: intl.NumberFormat.decimalPattern(_numberLocale),
        twoDigitZeroPaddedFormat: intl.NumberFormat('00', _numberLocale),
      ),
    );
  }

  @override
  bool shouldReload(_KuMaterialLocalizationsDelegate old) => false;

  @override
  String toString() => 'KuMaterialLocalizations.delegate(ku)';
}

/// Cupertino strings under `ku`.
///
/// `SwitchListTile.adaptive` on the privacy screen resolves to the Cupertino
/// switch on iOS, so this is reachable on the same screen as the material gap.
class KuCupertinoLocalizations extends CupertinoLocalizationDe {
  const KuCupertinoLocalizations({
    super.localeName = _localeName,
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

  @override
  String get cancelButtonLabel => 'Betal bike';

  @override
  String get backButtonLabel => 'Vegere';

  @override
  String get searchTextFieldPlaceholderLabel => 'Bigere';

  @override
  String get copyButtonLabel => 'Kopî bike';

  @override
  String get pasteButtonLabel => 'Pêve bike';

  @override
  String get cutButtonLabel => 'Jê bike';

  @override
  String get selectAllButtonLabel => 'Hemûyan hilbijêre';
}

class _KuCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _KuCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ku';

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    ensureKuDateFormatting();
    return SynchronousFuture<CupertinoLocalizations>(
      KuCupertinoLocalizations(
        fullYearFormat: intl.DateFormat.y(_localeName),
        dayFormat: intl.DateFormat.d(_localeName),
        weekdayFormat: intl.DateFormat.E(_localeName),
        mediumDateFormat: intl.DateFormat.MMMEd(_localeName),
        singleDigitHourFormat: intl.DateFormat('HH', _localeName),
        singleDigitMinuteFormat: intl.DateFormat.m(_localeName),
        doubleDigitMinuteFormat: intl.DateFormat('mm', _localeName),
        singleDigitSecondFormat: intl.DateFormat.s(_localeName),
        decimalFormat: intl.NumberFormat.decimalPattern(_numberLocale),
      ),
    );
  }

  @override
  bool shouldReload(_KuCupertinoLocalizationsDelegate old) => false;

  @override
  String toString() => 'KuCupertinoLocalizations.delegate(ku)';
}
