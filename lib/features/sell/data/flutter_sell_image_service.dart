import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zerin_marketplace/features/sell/domain/sell_image_service.dart';
import 'package:zerin_marketplace/features/sell/domain/sell_models.dart';

class FlutterSellImageService implements SellImageService {
  FlutterSellImageService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<List<SellPhoto>> pickFromGallery() async {
    final files = await _picker.pickMultiImage(imageQuality: 95);
    return Future.wait(files.map(_compressFile));
  }

  @override
  Future<SellPhoto?> takePhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 95,
    );
    return file == null ? null : _compressFile(file);
  }

  @override
  Future<SellPhoto?> importTemplateImage(String imageUrl) async {
    final uri = Uri.tryParse(imageUrl);
    if (uri == null || !uri.hasScheme) return null;

    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final chunks = <int>[];
      await for (final chunk in response) {
        chunks.addAll(chunk);
      }
      return SellPhoto(
        bytes: await _compress(Uint8List.fromList(chunks)),
        name: 'catalog-template.webp',
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<SellPhoto> _compressFile(XFile file) async => SellPhoto(
    bytes: await _compress(await file.readAsBytes()),
    name: '${file.name.replaceAll(RegExp(r'\.[^.]+$'), '')}.webp',
  );

  Future<Uint8List> _compress(Uint8List bytes) =>
      FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 1600,
        minHeight: 1600,
        quality: 82,
        format: CompressFormat.webp,
      );
}
