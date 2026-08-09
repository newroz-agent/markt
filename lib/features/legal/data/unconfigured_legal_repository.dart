import 'package:zerin_marketplace/features/legal/domain/legal_document.dart';
import 'package:zerin_marketplace/features/legal/domain/legal_repository.dart';

/// Used when no backend is configured. Reports "nothing published yet" rather
/// than an error, so the legal pages stay reachable in a keyless demo build.
class UnconfiguredLegalRepository implements LegalRepository {
  const UnconfiguredLegalRepository();

  @override
  Future<LegalDocument?> fetchDocument({
    required LegalDocumentKind kind,
    required String localeCode,
  }) async => null;
}
