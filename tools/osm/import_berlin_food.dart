// Idempotent import of a Berlin food snapshot into the LOCAL Supabase database.
//
//   dart run tools/osm/import_berlin_food.dart tools/osm/snapshots/berlin-food-YYYY-MM-DD.json
//   dart run tools/osm/import_berlin_food.dart <snapshot> --apply
//
// Without --apply it only prints mapping stats. With --apply it pipes one call
// to public.import_osm_directory_places into the local Docker Desktop database
// container. There is deliberately no option to target a remote project.
import 'dart:convert';
import 'dart:io';

import 'osm_food.dart';

const _localDbContainer = 'supabase_db_flutterapp';
const _rejectedHoursLog = 'docs/evidence/step-e1-5/rejected-opening-hours.txt';

Future<void> main(List<String> args) async {
  final apply = args.contains('--apply');
  final paths = args.where((arg) => !arg.startsWith('--')).toList();
  final snapshotDate = paths.length == 1
      ? RegExp(
          r'berlin-food-(\d{4}-\d{2}-\d{2})\.json$',
        ).firstMatch(paths.single)?.group(1)
      : null;
  if (snapshotDate == null) {
    stderr.writeln(
      'Usage: dart run tools/osm/import_berlin_food.dart '
      'tools/osm/snapshots/berlin-food-YYYY-MM-DD.json [--apply]',
    );
    exitCode = 64;
    return;
  }

  final snapshot =
      jsonDecode(File(paths.single).readAsStringSync()) as Map<String, dynamic>;
  final elements = (snapshot['elements'] as List).cast<Map<String, dynamic>>();
  final places = <Map<String, Object?>>[];
  final rejectedHours = <String>[];
  var skipped = 0;
  for (final element in elements) {
    final tags = (element['tags'] as Map?)?.cast<String, dynamic>() ?? const {};
    if (!isInScope(tags)) continue;
    final mapped = mapElement(element);
    if (mapped == null) {
      skipped++;
      continue;
    }
    places.add(mapped.payload);
    if (mapped.rejectedHours case final raw?) {
      rejectedHours.add('${element['type']}/${element['id']}\t$raw');
    }
  }

  _printStats(places, rejectedHours.length, skipped);
  File(_rejectedHoursLog)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('${rejectedHours.join('\n')}\n');
  stdout.writeln('Rejected opening_hours strings logged to $_rejectedHoursLog');

  if (!apply) {
    stdout.writeln(
      '\nDry run only. Re-run with --apply to write to the local database.',
    );
    return;
  }
  stdout.writeln('\nApplying to local container $_localDbContainer …');
  stdout.writeln(await _applyLocally(places, snapshotDate));
}

void _printStats(
  List<Map<String, Object?>> places,
  int rejectedHours,
  int skipped,
) {
  int count(bool Function(Map<String, Object?>) test) =>
      places.where(test).length;
  final perType = <String, int>{};
  final perCuisine = <String, int>{};
  for (final place in places) {
    perType.update(place['type']! as String, (n) => n + 1, ifAbsent: () => 1);
    for (final cuisine in place['cuisines']! as List) {
      perCuisine.update(cuisine as String, (n) => n + 1, ifAbsent: () => 1);
    }
  }
  final withHours = count((p) => (p['hours']! as List).isNotEmpty);
  final withRawHours = withHours + rejectedHours;
  stdout
    ..writeln(
      'Mapped places: ${places.length} (skipped without coordinates/too long: $skipped)',
    )
    ..writeln(
      '  opening hours parsed: $withHours of $withRawHours with an opening_hours tag '
      '(rejected: $rejectedHours)',
    )
    ..writeln('  phone: ${count((p) => p['phone'] != null)}')
    ..writeln('  website: ${count((p) => p['website'] != null)}')
    ..writeln('  OSM email: ${count((p) => p['email'] != null)}')
    ..writeln('Per type: ${_sorted(perType)}')
    ..writeln('Per cuisine: ${_sorted(perCuisine)}');
}

String _sorted(Map<String, int> counts) {
  final entries = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return entries.map((e) => '${e.key}=${e.value}').join(', ');
}

Future<String> _applyLocally(
  List<Map<String, Object?>> places,
  String snapshotDate,
) async {
  const tag = r'$zerin_osm_payload$';
  final payload = jsonEncode(places);
  if (payload.contains(tag)) {
    throw StateError('Payload contains the SQL quote tag');
  }
  final process = await Process.start('docker', [
    'exec',
    '-i',
    _localDbContainer,
    'psql',
    '-U',
    'postgres',
    '-d',
    'postgres',
    '-X',
    '-q',
    '-A',
    '-t',
    '-v',
    'ON_ERROR_STOP=1',
  ]);
  process.stdin.write(
    "select public.import_osm_directory_places($tag$payload$tag::jsonb, '$snapshotDate'::date);\n",
  );
  await process.stdin.close();
  final output = await process.stdout.transform(utf8.decoder).join();
  final errors = await process.stderr.transform(utf8.decoder).join();
  if (await process.exitCode != 0) {
    throw ProcessException('docker', const [
      'exec',
      _localDbContainer,
      'psql',
    ], errors);
  }
  return const JsonEncoder.withIndent('  ').convert(jsonDecode(output.trim()));
}
