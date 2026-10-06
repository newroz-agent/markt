import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

const outputDirectory = 'docs/evidence/step-e3/ios';
const expectedScreenshots = <String>{
  'step_e3_demo_home_angebote',
  'step_e3_demo_category_anzuege',
  'step_e3_demo_category_goldschmuck',
  'step_e3_demo_category_silberschmuck',
  'step_e3_demo_category_eheringe',
  'step_e3_demo_category_saiteninstrumente',
  'step_e3_demo_category_schlaginstrumente',
  'step_e3_demo_category_gewuerze-importwaren',
  'step_e3_demo_category_suesswaren',
  'step_e3_demo_listing_detail',
  'step_e3_demo_map',
  'step_e3_demo_home_ku',
  'step_e3_demo_home_ar',
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
      const signature = <int>[137, 80, 78, 71, 13, 10, 26, 10];
      if (bytes.length < 24) return false;
      for (var i = 0; i < signature.length; i++) {
        if (bytes[i] != signature[i]) return false;
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
              if (shot['bytes'] case final List<Object?> bytes)
                'bytes': bytes.length,
              if (shot['bytes'] case final List<Object?> bytes)
                'width': _pngDimension(bytes.cast<int>(), 16),
              if (shot['bytes'] case final List<Object?> bytes)
                'height': _pngDimension(bytes.cast<int>(), 20),
            },
      ];
      await File('$outputDirectory/results.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert(metadata),
        flush: true,
      );
      final actual = screenshots
          .whereType<Map<Object?, Object?>>()
          .map((shot) => shot['screenshotName'])
          .whereType<String>()
          .toSet();
      // Identical captures mean a screen was shot before its content loaded.
      final distinct = screenshots
          .whereType<Map<Object?, Object?>>()
          .map((shot) => shot['bytes'])
          .whereType<List<Object?>>()
          .map((bytes) => Object.hashAll(bytes))
          .toSet();
      final checks = data?['checks'] as Map?;
      final tests = data?['tests'] as Map?;
      if (actual.length != expectedScreenshots.length ||
          !actual.containsAll(expectedScreenshots) ||
          distinct.length != expectedScreenshots.length ||
          checks?.length != expectedScreenshots.length ||
          checks?.values.any((value) => value != 'PASS') != false ||
          tests?.length != 1 ||
          tests?.values.any((value) => value != 'PASS') != false) {
        throw StateError(
          'E3.0 screenshot evidence incomplete; see $outputDirectory/results.json',
        );
      }
    },
  );
}
