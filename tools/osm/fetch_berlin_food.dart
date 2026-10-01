// Fetches one dated Overpass snapshot of Berlin restaurants, cafés and fast food.
//
//   dart run tools/osm/fetch_berlin_food.dart
//
// Single bounded request, no retries (Overpass usage policy). Re-imports read
// the snapshot instead of querying again.
import 'dart:convert';
import 'dart:io';

const _endpoint = 'https://overpass-api.de/api/interpreter';

const _query = '''
[out:json][timeout:180];
area["boundary"="administrative"]["admin_level"="4"]["name"="Berlin"]->.berlin;
nwr["amenity"~"^(restaurant|cafe|fast_food)\$"]["name"]["cuisine"](area.berlin);
out center tags;
''';

Future<void> main() async {
  final date = DateTime.now().toUtc().toIso8601String().substring(0, 10);
  final target = File('tools/osm/snapshots/berlin-food-$date.json');
  if (target.existsSync()) {
    stderr.writeln('Snapshot already exists: ${target.path} (not re-querying)');
    exitCode = 1;
    return;
  }

  final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);
  try {
    final request = await client.postUrl(Uri.parse(_endpoint));
    request.headers
      ..contentType = ContentType('application', 'x-www-form-urlencoded')
      ..set(
        HttpHeaders.userAgentHeader,
        'zerin-e1.5-osm-import/1.0 (one-off snapshot)',
      );
    request.write('data=${Uri.encodeQueryComponent(_query)}');
    final response = await request.close().timeout(
      const Duration(seconds: 200),
    );
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) {
      stderr.writeln('Overpass returned HTTP ${response.statusCode}:\n$body');
      exitCode = 1;
      return;
    }
    final elements =
        (jsonDecode(body) as Map<String, dynamic>)['elements'] as List;
    target.parent.createSync(recursive: true);
    target.writeAsStringSync(body);
    stdout.writeln('Saved ${elements.length} elements to ${target.path}');
  } finally {
    client.close();
  }
}
