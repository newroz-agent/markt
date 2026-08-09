import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zerin_marketplace/core/providers/infrastructure_providers.dart';
import 'package:zerin_marketplace/features/legal/data/supabase_legal_repository.dart';
import 'package:zerin_marketplace/features/legal/data/unconfigured_legal_repository.dart';
import 'package:zerin_marketplace/features/legal/domain/legal_document.dart';
import 'package:zerin_marketplace/features/legal/domain/legal_repository.dart';

part 'legal_controller.g.dart';

@Riverpod(keepAlive: true)
LegalRepository legalRepository(LegalRepositoryRef ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? const UnconfiguredLegalRepository()
      : SupabaseLegalRepository(client);
}

/// The active document for [kind] in [localeCode].
///
/// Keyed on the locale as well as the kind so switching language refetches
/// instead of showing the previous translation.
@riverpod
Future<LegalDocument?> legalDocument(
  LegalDocumentRef ref, {
  required LegalDocumentKind kind,
  required String localeCode,
}) {
  return ref
      .watch(legalRepositoryProvider)
      .fetchDocument(kind: kind, localeCode: localeCode);
}
