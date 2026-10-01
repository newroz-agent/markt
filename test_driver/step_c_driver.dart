import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

const outputDirectory = '/tmp/zerin-step-c-ios-screenshots';
const expectedScreenshots = <String>{
  'step_c_my_profile',
  'step_c_edit_profile',
  'step_c_public_profile',
  'step_c_message_seller_chat_handoff',
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
      final actualNames = screenshots
          .whereType<Map<Object?, Object?>>()
          .map((shot) => shot['screenshotName'])
          .whereType<String>()
          .toSet();
      if (screenshots.length != expectedScreenshots.length ||
          actualNames.length != expectedScreenshots.length ||
          !actualNames.containsAll(expectedScreenshots) ||
          checks?.length != expectedScreenshots.length ||
          checks?.values.any((value) => value != 'PASS') != false ||
          tests?.length != 1 ||
          tests?.values.any((value) => value != 'PASS') != false) {
        throw StateError(
          'Step C did not produce four passing iOS checkpoints; '
          'see $outputDirectory/results.json',
        );
      }
    },
  );
}
