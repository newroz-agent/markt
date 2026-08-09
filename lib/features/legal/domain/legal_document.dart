import 'package:freezed_annotation/freezed_annotation.dart';

part 'legal_document.freezed.dart';
part 'legal_document.g.dart';

/// Route segments for `/legal/:document`, matching `legal_document_kind` in the
/// database one-for-one.
abstract final class LegalDocumentSlugs {
  static const imprint = 'imprint';
  static const terms = 'terms';
  static const privacy = 'privacy';
  static const withdrawal = 'withdrawal';

  static const all = <String>[imprint, terms, privacy, withdrawal];

  static LegalDocumentKind? parse(String slug) => switch (slug) {
    imprint => LegalDocumentKind.imprint,
    terms => LegalDocumentKind.terms,
    privacy => LegalDocumentKind.privacy,
    withdrawal => LegalDocumentKind.withdrawal,
    _ => null,
  };
}

/// Mirrors the `public.legal_document_kind` enum.
@JsonEnum(fieldRename: FieldRename.snake)
enum LegalDocumentKind {
  imprint,
  terms,
  privacy,
  withdrawal;

  String get slug => name;
}

/// One published version of a legal document, for a single locale.
///
/// The database keeps every version and flags at most one as active per
/// (kind, locale); this model always represents that active row.
@freezed
class LegalDocument with _$LegalDocument {
  const factory LegalDocument({
    required String id,
    required LegalDocumentKind kind,
    required String locale,
    required String version,
    required String title,
    @JsonKey(name: 'content_markdown') required String contentMarkdown,
    @JsonKey(name: 'effective_at') required DateTime effectiveAt,
    @JsonKey(name: 'published_at') DateTime? publishedAt,
  }) = _LegalDocument;

  factory LegalDocument.fromJson(Map<String, dynamic> json) =>
      _$LegalDocumentFromJson(json);
}
