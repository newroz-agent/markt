import 'package:zerin_marketplace/features/legal/domain/legal_document.dart';

abstract interface class LegalRepository {
  /// The active document for [kind] in [localeCode], or `null` when nothing is
  /// published yet.
  ///
  /// Implementations fall back to the German original when the requested
  /// locale has no active version: a missing translation must never leave a
  /// legally required page blank.
  Future<LegalDocument?> fetchDocument({
    required LegalDocumentKind kind,
    required String localeCode,
  });
}
