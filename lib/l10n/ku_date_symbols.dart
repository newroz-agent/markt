import 'package:intl/date_symbol_data_custom.dart' as custom;
import 'package:intl/date_symbols.dart' show DateSymbols;

/// Kurmanji (`ku`) date/time data for `intl`.
///
/// CLDR has no Kurmanji locale, so `intl` ships none and `DateFormat('ku')`
/// throws `LocaleDataException`. This supplies the data by hand through
/// `initializeDateFormattingCustom`.
///
/// The month names are the Kurdish calendar names in common use (Çile … Kanûn),
/// not transliterated Gregorian ones. Weekdays start at Sunday because that is
/// the order `DateSymbols` indexes them in, regardless of which day the week is
/// displayed as starting on (`FIRSTDAYOFWEEK`).
const List<String> kuWeekdays = <String>[
  'Yekşem',
  'Duşem',
  'Sêşem',
  'Çarşem',
  'Pêncşem',
  'În',
  'Şemî',
];

const List<String> kuMonths = <String>[
  'Çile',
  'Sibat',
  'Adar',
  'Nîsan',
  'Gulan',
  'Hezîran',
  'Tîrmeh',
  'Tebax',
  'Îlon',
  'Cotmeh',
  'Mijdar',
  'Kanûn',
];

/// Short forms are the first three letters, except where that would collide.
/// `În` is only two letters long to begin with.
const List<String> _shortWeekdays = <String>[
  'Yek',
  'Du',
  'Sê',
  'Çar',
  'Pên',
  'În',
  'Şem',
];

const List<String> _narrowWeekdays = <String>[
  'Y',
  'D',
  'S',
  'Ç',
  'P',
  'Î',
  'Ş',
];

const List<String> _shortMonths = <String>[
  'Çil',
  'Sib',
  'Ada',
  'Nîs',
  'Gul',
  'Hez',
  'Tîr',
  'Teb',
  'Îlo',
  'Cot',
  'Mij',
  'Kan',
];

const List<String> _narrowMonths = <String>[
  'Ç',
  'S',
  'A',
  'N',
  'G',
  'H',
  'T',
  'T',
  'Î',
  'C',
  'M',
  'K',
];

/// Patterns follow Turkish: day before month, 24-hour clock, `d MMMM y EEEE`
/// as the long form. Kurmanji is written in the same Latin script and orders
/// dates the same way.
const Map<String, String> _kuPatterns = <String, String>{
  'd': 'd',
  'E': 'ccc',
  'EEEE': 'cccc',
  'LLL': 'LLL',
  'LLLL': 'LLLL',
  'M': 'L',
  'Md': 'd/M',
  'MEd': 'd/M EEE',
  'MMM': 'LLL',
  'MMMd': 'd MMM',
  'MMMEd': 'd MMM EEE',
  'MMMM': 'LLLL',
  'MMMMd': 'd MMMM',
  'MMMMEEEEd': 'd MMMM y EEEE',
  'QQQ': 'QQQ',
  'QQQQ': 'QQQQ',
  'y': 'y',
  'yM': 'MM/y',
  'yMd': 'dd.MM.y',
  'yMEd': 'd.M.y EEE',
  'yMMM': 'MMM y',
  'yMMMd': 'd MMM y',
  'yMMMEd': 'd MMM y EEE',
  'yMMMM': 'MMMM y',
  'yMMMMd': 'd MMMM y',
  'yMMMMEEEEd': 'd MMMM y EEEE',
  'yQQQ': 'y QQQ',
  'yQQQQ': 'y QQQQ',
  'H': 'HH',
  'Hm': 'HH:mm',
  'Hms': 'HH:mm:ss',
  'j': 'HH',
  'jm': 'HH:mm',
  'jms': 'HH:mm:ss',
  'jmv': 'HH:mm v',
  'jmz': 'HH:mm z',
  'jz': 'HH z',
  'm': 'm',
  'ms': 'mm:ss',
  's': 's',
  'v': 'v',
  'z': 'z',
  'zzzz': 'zzzz',
  'ZZZZ': 'ZZZZ',
};

DateSymbols _buildKuSymbols() => DateSymbols(
  NAME: 'ku',
  ERAS: const <String>['BZ', 'PZ'],
  ERANAMES: const <String>['Berî zayînê', 'Piştî zayînê'],
  NARROWMONTHS: _narrowMonths,
  STANDALONENARROWMONTHS: _narrowMonths,
  MONTHS: kuMonths,
  STANDALONEMONTHS: kuMonths,
  SHORTMONTHS: _shortMonths,
  STANDALONESHORTMONTHS: _shortMonths,
  WEEKDAYS: kuWeekdays,
  STANDALONEWEEKDAYS: kuWeekdays,
  SHORTWEEKDAYS: _shortWeekdays,
  STANDALONESHORTWEEKDAYS: _shortWeekdays,
  NARROWWEEKDAYS: _narrowWeekdays,
  STANDALONENARROWWEEKDAYS: _narrowWeekdays,
  SHORTQUARTERS: const <String>['Ç1', 'Ç2', 'Ç3', 'Ç4'],
  QUARTERS: const <String>[
    'Çarêka 1em',
    'Çarêka 2em',
    'Çarêka 3em',
    'Çarêka 4em',
  ],
  AMPMS: const <String>['BN', 'PN'],
  DATEFORMATS: const <String>['d MMMM y EEEE', 'd MMMM y', 'd MMM y', 'd.MM.y'],
  TIMEFORMATS: const <String>[
    'HH:mm:ss zzzz',
    'HH:mm:ss z',
    'HH:mm:ss',
    'HH:mm',
  ],
  DATETIMEFORMATS: const <String>['{1} {0}', '{1} {0}', '{1} {0}', '{1} {0}'],
  FIRSTDAYOFWEEK: 0,
  WEEKENDRANGE: const <int>[5, 6],
  FIRSTWEEKCUTOFFDAY: 6,
);

bool _initialized = false;

/// Registers the Kurmanji date symbols with `intl`.
///
/// Flutter's global localization delegates use the same custom initializer for
/// their generated date data. Starting in `ku` therefore creates the map with
/// Kurmanji, while loading any built-in locale later appends its own symbols.
void ensureKuDateFormatting() {
  if (_initialized) return;

  custom.initializeDateFormattingCustom(
    locale: 'ku',
    symbols: _buildKuSymbols(),
    patterns: _kuPatterns,
  );
  _initialized = true;
}
