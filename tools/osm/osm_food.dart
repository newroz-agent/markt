// Shared OSM mapping rules for the E1.5 Berlin food import.
// Only dart: imports so the tools run with plain `dart run`.

/// OSM `cuisine` values in scope, mapped to `public.directory_cuisine` values.
/// Agreed at the §2 checkpoint (docs/plans/step-e1-5-osm-restaurant-import.md).
const cuisineAliases = <String, String>{
  'kurdish': 'kurdish',
  'turkish': 'turkish',
  'syrian': 'syrian',
  'lebanese': 'lebanese',
  'arabic': 'arabic',
  'arab': 'arabic',
  'egyptian': 'arabic',
  'yemeni': 'arabic',
  'yemenese': 'arabic',
  'iraqi': 'iraqi',
  'persian': 'persian',
  'iranian': 'persian',
  'middle_eastern': 'middle_eastern',
  'levantine': 'middle_eastern',
  'levante': 'middle_eastern',
  'palestinian': 'middle_eastern',
  'oriental': 'middle_eastern',
  'kebab': 'kebab',
  'döner': 'kebab',
  'shawarma': 'kebab',
  'falafel': 'falafel',
};

const includedAmenities = <String>{'restaurant', 'cafe', 'fast_food'};

/// Splits a multi-valued OSM `cuisine` tag (`turkish;kebab`) into normalized values.
List<String> cuisineValues(String? raw) {
  if (raw == null) return const [];
  return raw
      .split(';')
      .map((value) => value.trim().toLowerCase())
      .where((value) => value.isNotEmpty)
      .toList();
}

/// The app cuisines for a raw OSM tag, in tag order without duplicates.
/// Empty when no value is in scope.
List<String> mapCuisines(String? raw) =>
    {for (final value in cuisineValues(raw)) ?cuisineAliases[value]}.toList();

/// Whether an Overpass element's tags belong in the v1 import scope.
bool isInScope(Map<String, dynamic> tags) {
  final name = (tags['name'] as String?)?.trim() ?? '';
  return name.isNotEmpty &&
      includedAmenities.contains(tags['amenity']) &&
      mapCuisines(tags['cuisine'] as String?).isNotEmpty;
}

/// One weekly opening interval. [weekday] uses the database convention
/// (0 = Sunday … 6 = Saturday). A close before the open time runs past midnight.
class OpeningInterval {
  const OpeningInterval(this.weekday, this.opensAt, this.closesAt);

  final int weekday;
  final String opensAt;
  final String closesAt;

  Map<String, Object> toJson() => {
    'weekday': weekday,
    'opens_at': opensAt,
    'closes_at': closesAt,
  };

  @override
  bool operator ==(Object other) =>
      other is OpeningInterval &&
      other.weekday == weekday &&
      other.opensAt == opensAt &&
      other.closesAt == closesAt;

  @override
  int get hashCode => Object.hash(weekday, opensAt, closesAt);

  @override
  String toString() => '$weekday $opensAt-$closesAt';
}

const _osmDays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
const _day = '(?:Mo|Tu|We|Th|Fr|Sa|Su)';
const _daySpec = '$_day(?:\\s*-\\s*$_day)?';
const _time = '\\d{1,2}:\\d{2}';
const _range = '$_time\\s*-\\s*$_time';
final _rulePattern = RegExp(
  '^(?:($_daySpec(?:\\s*,\\s*$_daySpec)*)\\s+)?'
  '($_range(?:\\s*,\\s*$_range)*|off|closed)\$',
);
// A comma after a time range that starts a new weekday selector is an additive rule.
final _additiveSeparator = RegExp(r'(?<=\d)\s*,\s*(?=[A-Z][a-z])');
const _maxIntervalsPerDay = 6;

/// Parses an OSM `opening_hours` value into weekly intervals.
///
/// Only the plain weekly subset is accepted: weekday selectors, `HH:MM-HH:MM`
/// ranges, `off`/`closed`, `;` override rules, `,` additive rules and `24/7`.
/// Anything else (PH, SH, sunrise, weeks, months, dates, comments, open ends,
/// extended hours, overlaps) returns null. Never guesses.
List<OpeningInterval>? parseOpeningHours(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return null;
  if (value == '24/7') {
    return [
      for (var day = 0; day < 7; day++) OpeningInterval(day, '00:00', '24:00'),
    ];
  }

  // Keyed by OSM day index (0 = Mo … 6 = Su).
  final week = <int, List<(String, String)>>{};
  final segments = value.split(';');
  // A single trailing `;` is harmless; any other empty rule is rejected below.
  if (segments.length > 1 && segments.last.trim().isEmpty) {
    segments.removeLast();
  }
  for (final segment in segments) {
    final rules = segment.trim().split(_additiveSeparator);
    if (rules.first.isEmpty) return null;
    for (final (index, rule) in rules.indexed) {
      final match = _rulePattern.firstMatch(rule.trim());
      if (match == null) return null;
      final days = match.group(1) == null
          ? List.generate(7, (i) => i)
          : _parseDays(match.group(1)!);
      final times = match.group(2)!;
      final ranges = times == 'off' || times == 'closed'
          ? <(String, String)>[]
          : _parseRanges(times);
      if (ranges == null) return null;
      for (final day in days) {
        if (index == 0) {
          week[day] = [...ranges];
        } else {
          (week[day] ??= []).addAll(ranges);
        }
      }
    }
  }

  final intervals = <OpeningInterval>[];
  for (final MapEntry(key: day, value: ranges) in week.entries) {
    final unique = ranges.toSet().toList();
    if (unique.length > _maxIntervalsPerDay || _overlaps(unique)) return null;
    for (final (opens, closes) in unique) {
      intervals.add(OpeningInterval((day + 1) % 7, opens, closes));
    }
  }
  if (intervals.isEmpty) return null;
  intervals.sort((a, b) {
    final byDay = a.weekday.compareTo(b.weekday);
    return byDay != 0 ? byDay : a.opensAt.compareTo(b.opensAt);
  });
  return intervals;
}

List<int> _parseDays(String selector) {
  final days = <int>[];
  for (final spec in selector.split(',')) {
    final bounds = spec
        .split('-')
        .map((d) => _osmDays.indexOf(d.trim()))
        .toList();
    if (bounds.length == 1) {
      days.add(bounds.single);
      continue;
    }
    // Ranges may wrap around the week (Fr-Mo).
    for (var day = bounds.first; ; day = (day + 1) % 7) {
      days.add(day);
      if (day == bounds.last) break;
    }
  }
  return days;
}

List<(String, String)>? _parseRanges(String times) {
  final ranges = <(String, String)>[];
  for (final range in times.split(',')) {
    final parts = range.split('-').map((t) => t.trim()).toList();
    final opens = _normalizeTime(parts.first, allowEndOfDay: false);
    final closes = _normalizeTime(parts.last, allowEndOfDay: true);
    if (opens == null || closes == null || opens == closes) return null;
    ranges.add((opens, closes));
  }
  return ranges;
}

String? _normalizeTime(String value, {required bool allowEndOfDay}) {
  final [hourText, minuteText] = value.split(':');
  final hour = int.parse(hourText);
  final minute = int.parse(minuteText);
  if (minute > 59) return null;
  if (hour == 24 && minute == 0 && allowEndOfDay) return '24:00';
  if (hour > 23) return null;
  return '${hour.toString().padLeft(2, '0')}:$minuteText';
}

int _minutes(String time) {
  final [hour, minute] = time.split(':').map(int.parse).toList();
  return hour * 60 + minute;
}

bool _overlaps(List<(String, String)> ranges) {
  // Overnight ranges extend to the end of this day for the overlap check.
  final spans = [
    for (final (opens, closes) in ranges)
      (
        _minutes(opens),
        _minutes(closes) <= _minutes(opens) ? 24 * 60 : _minutes(closes),
      ),
  ]..sort((a, b) => a.$1.compareTo(b.$1));
  for (var i = 1; i < spans.length; i++) {
    if (spans[i].$1 < spans[i - 1].$2) return true;
  }
  return false;
}

/// Result of mapping one Overpass element.
class MappedPlace {
  const MappedPlace(this.payload, {this.rejectedHours});

  /// Row for `public.import_osm_directory_places`.
  final Map<String, Object?> payload;

  /// The raw `opening_hours` string when it was present but not importable.
  final String? rejectedHours;
}

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final _bareDomain = RegExp(
  r'^[a-z0-9.-]+\.[a-z]{2,}(/\S*)?$',
  caseSensitive: false,
);

/// Maps an in-scope Overpass element to an import row, or null when it is out
/// of scope or lacks coordinates. Only OSM-provided values are used.
MappedPlace? mapElement(Map<String, dynamic> element) {
  final tags = (element['tags'] as Map?)?.cast<String, dynamic>() ?? const {};
  if (!isInScope(tags)) return null;
  final center = (element['center'] as Map?)?.cast<String, dynamic>();
  final latitude = (element['lat'] ?? center?['lat']) as num?;
  final longitude = (element['lon'] ?? center?['lon']) as num?;
  final name = (tags['name'] as String).trim();
  if (latitude == null || longitude == null || name.length > 200) return null;

  final rawHours = _text(tags['opening_hours'], maxLength: 1000);
  final hours = parseOpeningHours(rawHours);
  final rawCuisine = (tags['cuisine'] as String).trim();

  return MappedPlace({
    'osm_type': element['type'],
    'osm_id': element['id'],
    'name': name,
    'type': tags['amenity'],
    'cuisines': mapCuisines(rawCuisine),
    'osm_cuisine': rawCuisine.length > 255
        ? rawCuisine.substring(0, 255)
        : rawCuisine,
    'latitude': latitude,
    'longitude': longitude,
    'addr_street': _text(tags['addr:street'], maxLength: 200),
    'addr_housenumber': _text(tags['addr:housenumber'], maxLength: 40),
    'addr_postcode': _text(tags['addr:postcode'], maxLength: 20),
    'addr_city': _text(tags['addr:city'], maxLength: 100),
    'phone': _phone(_firstValue(tags['phone'] ?? tags['contact:phone'])),
    'website': _website(
      _firstValue(tags['website'] ?? tags['contact:website']),
    ),
    'email': _email(_firstValue(tags['email'] ?? tags['contact:email'])),
    'has_halal': _diet(tags['diet:halal']),
    'has_vegetarian': _diet(tags['diet:vegetarian']),
    'has_vegan': _diet(tags['diet:vegan']),
    'hours': [
      for (final interval in hours ?? const <OpeningInterval>[])
        interval.toJson(),
    ],
  }, rejectedHours: rawHours != null && hours == null ? rawHours : null);
}

String? _text(Object? value, {required int maxLength}) {
  final text = (value as String?)?.trim() ?? '';
  return text.isEmpty || text.length > maxLength ? null : text;
}

String? _firstValue(Object? value) =>
    _text((value as String?)?.split(';').first, maxLength: 500);

String? _phone(String? value) =>
    value == null || value.length < 3 || value.length > 60 ? null : value;

String? _website(String? value) {
  if (value == null) return null;
  final scheme = RegExp(r'^https?://', caseSensitive: false);
  final url = scheme.hasMatch(value)
      ? value.replaceFirstMapped(scheme, (match) => match[0]!.toLowerCase())
      : _bareDomain.hasMatch(value)
      ? 'https://$value'
      : null;
  return url != null && !url.contains(RegExp(r'\s')) ? url : null;
}

String? _email(String? value) {
  if (value == null) return null;
  final email = value.toLowerCase().replaceFirst(RegExp('^mailto:'), '');
  return email.length <= 254 && _emailPattern.hasMatch(email) ? email : null;
}

bool? _diet(Object? value) => value == 'yes' || value == 'only' ? true : null;
