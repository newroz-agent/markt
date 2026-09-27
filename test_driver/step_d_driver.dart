import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

const outputDirectory = 'docs/evidence/step-d';
const expectedScreenshots = <String>{
  'step_d_map_pins_30km',
  'step_d_radius_all_clusters',
  'step_d_private_pin_preview',
  'step_d_listing_detail_handoff',
};

int _pngDimension(List<int> bytes, int offset) =>
    (bytes[offset] << 24) |
    (bytes[offset + 1] << 16) |
    (bytes[offset + 2] << 8) |
    bytes[offset + 3];

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
      final checks = data?['checks'] as Map?;
      final tests = data?['tests'] as Map?;
      final evidence = data?['evidence'] as Map?;
      final actualNames = screenshots
          .whereType<Map<Object?, Object?>>()
          .map((shot) => shot['screenshotName'])
          .whereType<String>()
          .toSet();
      final nearCount = evidence?['near_count'] as num?;
      final allCount = evidence?['all_count'] as num?;
      final privateJitter = evidence?['private_jitter_km'] as num?;
      if (screenshots.length != expectedScreenshots.length ||
          actualNames.length != expectedScreenshots.length ||
          !actualNames.containsAll(expectedScreenshots) ||
          checks?.length != expectedScreenshots.length ||
          checks?.values.any((value) => value != 'PASS') != false ||
          tests?.length != 1 ||
          tests?.values.any((value) => value != 'PASS') != false ||
          nearCount == null ||
          allCount == null ||
          allCount <= nearCount ||
          privateJitter == null ||
          privateJitter < 0.29 ||
          privateJitter > 0.51) {
        throw StateError(
          'Step D did not produce four passing real-iOS Map checkpoints; '
          'see $outputDirectory/results.json',
        );
      }
    },
  );
}
