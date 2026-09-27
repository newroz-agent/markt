import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

const outputDirectory = 'docs/evidence/step-b';
const expectedScreenshots = <String>{
  'step_b_catalog_template_search',
  'step_b_free_form_details',
  'step_b_photo_upload',
  'step_b_pending_confirmation',
  'step_b_public_before_approval',
  'step_b_moderation_queue',
  'step_b_public_after_approval',
};
const countKeys = <String>{'listings', 'image_rows', 'storage_objects'};

int _pngDimension(List<int> bytes, int offset) =>
    (bytes[offset] << 24) |
    (bytes[offset + 1] << 16) |
    (bytes[offset + 2] << 8) |
    bytes[offset + 3];

bool _matchingCounts(
  Map<Object?, Object?>? before,
  Map<Object?, Object?>? after,
) {
  if (before == null || after == null) return false;
  if (before.keys.toSet().difference(countKeys).isNotEmpty ||
      countKeys
          .difference(before.keys.whereType<String>().toSet())
          .isNotEmpty ||
      after.keys.toSet().difference(countKeys).isNotEmpty ||
      countKeys.difference(after.keys.whereType<String>().toSet()).isNotEmpty) {
    return false;
  }
  return countKeys.every(
    (key) => before[key] is int && before[key] == after[key],
  );
}

Future<void> main() async {
  final directory = Directory(outputDirectory);
  if (await directory.exists()) await directory.delete(recursive: true);
  await directory.create(recursive: true);
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      if (!expectedScreenshots.contains(name)) return false;
      const pngSignature = <int>[137, 80, 78, 71, 13, 10, 26, 10];
      if (bytes.length < 24) return false;
      for (var index = 0; index < pngSignature.length; index++) {
        if (bytes[index] != pngSignature[index]) return false;
      }
      await File('$outputDirectory/$name.png').writeAsBytes(bytes, flush: true);
      return true;
    },
    writeResponseOnFailure: true,
    responseDataCallback: (data) async {
      final metadata = <String, dynamic>{...?data};
      final screenshots = data?['screenshots'] as List? ?? const <Object>[];
      metadata['screenshots'] = <Map<String, Object?>>[
        for (final shot in screenshots.whereType<Map<Object?, Object?>>())
          if (shot['screenshotName'] case final String name)
            <String, Object?>{
              'name': name,
              if (shot['bytes']
                  case final List<Object?> rawBytes) ...<String, Object?>{
                'bytes': rawBytes.length,
                'width': _pngDimension(rawBytes.cast<int>(), 16),
                'height': _pngDimension(rawBytes.cast<int>(), 20),
              },
            },
      ];
      await File('$outputDirectory/results.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert(metadata),
        flush: true,
      );

      final actualNames = screenshots
          .whereType<Map<Object?, Object?>>()
          .map((shot) => shot['screenshotName'])
          .whereType<String>()
          .toSet();
      final checks = data?['checks'] as Map?;
      final tests = data?['tests'] as Map?;
      final cleanup = data?['cleanup'] as Map?;
      final counts = data?['counts'] as Map?;
      final before = counts?['before'] as Map<Object?, Object?>?;
      final after = counts?['after'] as Map<Object?, Object?>?;
      final countsMatch = _matchingCounts(before, after);

      if (screenshots.length != expectedScreenshots.length ||
          actualNames.length != expectedScreenshots.length ||
          !actualNames.containsAll(expectedScreenshots) ||
          checks?.length != expectedScreenshots.length ||
          checks?.values.any((value) => value != 'PASS') != false ||
          tests?.length != 1 ||
          tests?.values.any((value) => value != 'PASS') != false ||
          cleanup?['deleted_listings'] != 1 ||
          cleanup?['removed_objects'] != 1 ||
          counts?['matched'] != true ||
          !countsMatch) {
        throw StateError(
          'Step B did not restore listing/image/Storage counts after seven '
          'passing iOS checkpoints; see $outputDirectory/results.json',
        );
      }
    },
  );
}
