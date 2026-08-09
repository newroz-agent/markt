import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerin_marketplace/core/errors/app_exception.dart';
import 'package:zerin_marketplace/features/legal/domain/legal_document.dart';
import 'package:zerin_marketplace/features/legal/domain/legal_repository.dart';

class SupabaseLegalRepository implements LegalRepository {
  SupabaseLegalRepository(this._client);

  /// The locale every document is guaranteed to exist in. German law binds the
  /// German text, so it is both the fallback and the authoritative version.
  static const fallbackLocale = 'de';

  /// Locales the `public.app_language` enum accepts. A locale outside this set
  /// (currently `ku`) is served the German original rather than querying for a
  /// value the enum would reject.
  static const supportedLocales = <String>{'de', 'en', 'ar', 'tr'};

  static const _columns =
      'id, kind, locale, version, title, content_markdown, '
      'effective_at, published_at';

  final SupabaseClient _client;

  @override
  Future<LegalDocument?> fetchDocument({
    required LegalDocumentKind kind,
    required String localeCode,
  }) async {
    final requested = localeCode.split('_').first.toLowerCase();
    final locales = <String>[
      if (supportedLocales.contains(requested) && requested != fallbackLocale)
        requested,
      fallbackLocale,
    ];

    for (final locale in locales) {
      final document = await _fetchActive(kind: kind, locale: locale);
      if (document != null) return document;
    }
    return null;
  }

  Future<LegalDocument?> _fetchActive({
    required LegalDocumentKind kind,
    required String locale,
  }) async {
    try {
      final row = await _client
          .from('legal_documents')
          .select(_columns)
          .eq('kind', kind.name)
          .eq('locale', locale)
          .eq('is_active', true)
          .lte('effective_at', DateTime.now().toUtc().toIso8601String())
          .maybeSingle();
      return row == null ? null : LegalDocument.fromJson(row);
    } on PostgrestException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        AppException(AppFailureCode.unknown, cause: error),
        stackTrace,
      );
    }
  }
}
