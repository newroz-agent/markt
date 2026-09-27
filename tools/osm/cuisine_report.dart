// Checkpoint report (§2): counts per mapped app cuisine and per amenity from a snapshot.
//
//   dart run tools/osm/cuisine_report.dart tools/osm/snapshots/berlin-food-YYYY-MM-DD.json
import 'dart:convert';
import 'dart:io';

import 'osm_food.dart';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln(
      'Usage: dart run tools/osm/cuisine_report.dart <snapshot.json>',
    );
    exitCode = 64;
    return;
  }
  final snapshot =
      jsonDecode(File(args.single).readAsStringSync()) as Map<String, dynamic>;
  final elements = (snapshot['elements'] as List).cast<Map<String, dynamic>>();

  final inScope = elements
      .where((e) => isInScope((e['tags'] as Map).cast()))
      .toList();
  final perCuisine = <String, int>{};
  final perAmenity = <String, int>{};
  final perAmenityCuisine = <String, int>{};
  var multiValued = 0;
  var withEmail = 0;

  for (final element in inScope) {
    final tags = (element['tags'] as Map).cast<String, dynamic>();
    final amenity = tags['amenity'] as String;
    final matched = mapCuisines(tags['cuisine'] as String?);
    perAmenity.update(amenity, (n) => n + 1, ifAbsent: () => 1);
    for (final cuisine in matched) {
      perCuisine.update(cuisine, (n) => n + 1, ifAbsent: () => 1);
      perAmenityCuisine.update(
        '$amenity/$cuisine',
        (n) => n + 1,
        ifAbsent: () => 1,
      );
    }
    if (cuisineValues(tags['cuisine'] as String?).length > 1) multiValued++;
    if (tags['email'] != null || tags['contact:email'] != null) withEmail++;
  }

  stdout
    ..writeln('Snapshot elements: ${elements.length}')
    ..writeln('In scope (named, mapped cuisine): ${inScope.length}')
    ..writeln('  multi-valued cuisine tag: $multiValued')
    ..writeln('  with OSM email: $withEmail')
    ..writeln('\nPer amenity:');
  for (final entry in perAmenity.entries) {
    stdout.writeln('  ${entry.key.padRight(12)} ${entry.value}');
  }
  stdout.writeln(
    '\nPer app cuisine (an element counts once per mapped cuisine):',
  );
  final sorted = perCuisine.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  for (final entry in sorted) {
    stdout.writeln('  ${entry.key.padRight(15)} ${entry.value}');
  }
  stdout.writeln('\nPer amenity × cuisine:');
  final grid = perAmenityCuisine.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  for (final entry in grid) {
    stdout.writeln('  ${entry.key.padRight(26)} ${entry.value}');
  }
}
