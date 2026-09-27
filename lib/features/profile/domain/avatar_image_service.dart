import 'dart:typed_data';

/// Picks and compresses a square-ish avatar to WebP bytes for upload.
abstract interface class AvatarImageService {
  /// Picks one image from the gallery and returns compressed WebP bytes, or
  /// null when the user cancels.
  Future<Uint8List?> pickFromGallery();

  /// Captures one image from the camera and returns compressed WebP bytes, or
  /// null when the user cancels.
  Future<Uint8List?> takePhoto();
}

/// Fallback used when image plugins are unavailable (e.g. tests, unconfigured).
class UnavailableAvatarImageService implements AvatarImageService {
  const UnavailableAvatarImageService();

  @override
  Future<Uint8List?> pickFromGallery() async => null;

  @override
  Future<Uint8List?> takePhoto() async => null;
}
