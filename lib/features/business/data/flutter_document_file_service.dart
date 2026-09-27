import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zerin_marketplace/features/business/domain/business_models.dart';
import 'package:zerin_marketplace/features/business/domain/business_repository.dart';

class FlutterDocumentFileService implements DocumentFileService {
  FlutterDocumentFileService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  static const _pdfGroup = XTypeGroup(
    label: 'PDF',
    extensions: <String>['pdf'],
    mimeTypes: <String>['application/pdf'],
    uniformTypeIdentifiers: <String>['com.adobe.pdf'],
  );

  final ImagePicker _picker;

  @override
  Future<PickedDocumentFile?> takePhoto() =>
      _pickDocumentImage(ImageSource.camera);

  @override
  Future<PickedDocumentFile?> pickImage() =>
      _pickDocumentImage(ImageSource.gallery);

  @override
  Future<PickedDocumentFile?> pickPdf() async {
    final file = await openFile(acceptedTypeGroups: const [_pdfGroup]);
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    // Only real PDFs reach the private bucket (magic bytes "%PDF").
    final isPdf =
        bytes.length > 4 &&
        bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46;
    return isPdf
        ? PickedDocumentFile(
            bytes: bytes,
            mimeType: 'application/pdf',
            extension: 'pdf',
          )
        : null;
  }

  @override
  Future<Uint8List?> pickCoverImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    if (file == null) return null;
    return FlutterImageCompress.compressWithList(
      await file.readAsBytes(),
      minWidth: 1600,
      minHeight: 900,
      quality: 82,
      format: CompressFormat.webp,
    );
  }

  /// Documents must stay legible for the admin review, so they are kept large
  /// and re-encoded as JPEG (HEIC and other formats are not accepted).
  Future<PickedDocumentFile?> _pickDocumentImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 95);
    if (file == null) return null;
    final bytes = await FlutterImageCompress.compressWithList(
      await file.readAsBytes(),
      minWidth: 2400,
      minHeight: 2400,
      quality: 88,
    );
    return PickedDocumentFile(
      bytes: bytes,
      mimeType: 'image/jpeg',
      extension: 'jpg',
    );
  }
}
