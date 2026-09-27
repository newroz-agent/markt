import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

const outputDirectory = '/tmp/zerin-step-b-ios-screenshots';

Future<void> main() async {
  final directory = Directory(outputDirectory);
  if (await directory.exists()) await directory.delete(recursive: true);
  await directory.create(recursive: true);
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      if (!RegExp(r'^step_b_[a-z0-9_]+$').hasMatch(name)) return false;
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
          <String, Object?>{
            'name': shot['screenshotName'],
            'bytes': (shot['bytes'] as List<Object?>).length,
          },
      ];
      await File('$outputDirectory/results.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert(metadata),
        flush: true,
      );
      final checks = data?['checks'] as Map?;
      final tests = data?['tests'] as Map?;
      if (screenshots.length != 7 ||
          checks?.length != 7 ||
          checks?.values.any((value) => value != 'PASS') != false ||
          tests?.length != 1 ||
          tests?.values.any((value) => value != 'PASS') != false) {
        throw StateError(
          'Step B did not produce seven passing iOS checkpoints; '
          'see $outputDirectory/results.json',
        );
      }
    },
  );
}
