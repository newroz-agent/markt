import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

const outputDirectory =
    '/var/folders/r3/zkdqwz554pj7y_b9s3n0yx6m0000gn/T/kilo/phase3-screenshots';

Future<void> main() async {
  final directory = Directory(outputDirectory);
  if (!await directory.parent.exists()) {
    throw StateError('Approved screenshot parent directory is missing.');
  }
  await directory.create();
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      if (!RegExp(r'^phase3_[a-z0-9_]+$').hasMatch(name)) return false;
      const pngSignature = <int>[137, 80, 78, 71, 13, 10, 26, 10];
      if (bytes.length < 24) return false;
      for (var i = 0; i < pngSignature.length; i++) {
        if (bytes[i] != pngSignature[i]) return false;
      }
      await File('$outputDirectory/$name.png').writeAsBytes(bytes, flush: true);
      return true;
    },
    writeResponseOnFailure: true,
    responseDataCallback: (data) async {
      final metadata = <String, dynamic>{...?data};
      metadata['screenshots'] = [
        for (final shot in data?['screenshots'] as List? ?? [])
          {
            'name': shot['screenshotName'],
            'bytes': (shot['bytes'] as List).length,
          },
      ];
      await File('$outputDirectory/results.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert(metadata),
        flush: true,
      );
      final tests = data?['tests'] as Map?;
      if (tests == null ||
          tests.length != 6 ||
          tests.values.any((result) => result != 'PASS')) {
        throw StateError(
          'Phase3 did not complete all six tests successfully; '
          'see $outputDirectory/results.json and device test output.',
        );
      }
    },
  );
}
