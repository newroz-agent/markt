import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zerin_marketplace/features/profile/domain/avatar_image_service.dart';

class FlutterAvatarImageService implements AvatarImageService {
  FlutterAvatarImageService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<Uint8List?> pickFromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    return file == null ? null : _compress(await file.readAsBytes());
  }

  @override
  Future<Uint8List?> takePhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 95,
    );
    return file == null ? null : _compress(await file.readAsBytes());
  }

  // Avatars stay small and square-friendly; the public bucket stores WebP.
  Future<Uint8List> _compress(Uint8List bytes) =>
      FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 512,
        minHeight: 512,
        quality: 80,
        format: CompressFormat.webp,
      );
}
