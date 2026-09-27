import 'dart:typed_data';

import 'package:zerin_marketplace/features/business/domain/business_models.dart';

/// Owner-side failures with precise copy in the owner screens.
enum BusinessFailureReason {
  backendNotConfigured,
  notAuthenticated,

  /// Private (non-business) seller accounts cannot join the directory.
  privateSeller,
  invalidBusinessName,
  unsupportedCity,

  /// The type can only change in the directory profile once it exists.
  typeLockedByProfile,

  /// A document of this kind is already waiting for review.
  documentAlreadyPending,
  fileTooLarge,

  /// The server rejected the submitted values.
  invalidInput,
  unknown,
}

class BusinessException implements Exception {
  const BusinessException(this.reason, {this.cause});

  final BusinessFailureReason reason;
  final Object? cause;

  @override
  String toString() => 'BusinessException(reason: $reason, cause: $cause)';
}

abstract interface class BusinessRepository {
  Future<DirectoryOnboarding> fetchOnboarding();

  /// Creates a pending business seller for users without one, or sets the
  /// declared type of an existing business seller.
  Future<DirectoryOnboarding> startDirectory({
    required DirectoryType type,
    String? shopName,
    String? city,
  });

  /// Uploads into the private `seller-documents` bucket and records the
  /// document for the admin verification queue.
  Future<void> uploadDocument({
    required String sellerId,
    required SellerDocumentKind kind,
    required PickedDocumentFile file,
  });

  /// Withdraws a pending document (row and stored file).
  Future<void> withdrawDocument(SellerDocument document);

  Future<void> saveProfile(DirectoryProfile profile);

  /// Uploads a cover image and returns its storage path.
  Future<String> uploadCover({
    required String sellerId,
    required Uint8List webpBytes,
  });

  String? coverUrl(String? storagePath);

  Future<void> saveHours(List<OpeningInterval> intervals);

  Future<void> saveMenu(List<MenuSectionDraft> sections);
}

/// Picks identity/registration documents (photo or PDF) and cover images.
abstract interface class DocumentFileService {
  Future<PickedDocumentFile?> takePhoto();
  Future<PickedDocumentFile?> pickImage();
  Future<PickedDocumentFile?> pickPdf();

  /// A compressed WebP cover image, or null when cancelled.
  Future<Uint8List?> pickCoverImage();
}

class UnconfiguredBusinessRepository implements BusinessRepository {
  const UnconfiguredBusinessRepository();

  Never _unconfigured() =>
      throw const BusinessException(BusinessFailureReason.backendNotConfigured);

  @override
  Future<DirectoryOnboarding> fetchOnboarding() async =>
      DirectoryOnboarding.empty;

  @override
  Future<DirectoryOnboarding> startDirectory({
    required DirectoryType type,
    String? shopName,
    String? city,
  }) async => _unconfigured();

  @override
  Future<void> uploadDocument({
    required String sellerId,
    required SellerDocumentKind kind,
    required PickedDocumentFile file,
  }) async => _unconfigured();

  @override
  Future<void> withdrawDocument(SellerDocument document) async =>
      _unconfigured();

  @override
  Future<void> saveProfile(DirectoryProfile profile) async => _unconfigured();

  @override
  Future<String> uploadCover({
    required String sellerId,
    required Uint8List webpBytes,
  }) async => _unconfigured();

  @override
  String? coverUrl(String? storagePath) => null;

  @override
  Future<void> saveHours(List<OpeningInterval> intervals) async =>
      _unconfigured();

  @override
  Future<void> saveMenu(List<MenuSectionDraft> sections) async =>
      _unconfigured();
}

class UnavailableDocumentFileService implements DocumentFileService {
  const UnavailableDocumentFileService();

  @override
  Future<PickedDocumentFile?> takePhoto() async => null;

  @override
  Future<PickedDocumentFile?> pickImage() async => null;

  @override
  Future<PickedDocumentFile?> pickPdf() async => null;

  @override
  Future<Uint8List?> pickCoverImage() async => null;
}
