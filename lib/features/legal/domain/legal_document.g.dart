// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'legal_document.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LegalDocumentImpl _$$LegalDocumentImplFromJson(Map<String, dynamic> json) =>
    _$LegalDocumentImpl(
      id: json['id'] as String,
      kind: $enumDecode(_$LegalDocumentKindEnumMap, json['kind']),
      locale: json['locale'] as String,
      version: json['version'] as String,
      title: json['title'] as String,
      contentMarkdown: json['content_markdown'] as String,
      effectiveAt: DateTime.parse(json['effective_at'] as String),
      publishedAt: json['published_at'] == null
          ? null
          : DateTime.parse(json['published_at'] as String),
    );

Map<String, dynamic> _$$LegalDocumentImplToJson(_$LegalDocumentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': _$LegalDocumentKindEnumMap[instance.kind]!,
      'locale': instance.locale,
      'version': instance.version,
      'title': instance.title,
      'content_markdown': instance.contentMarkdown,
      'effective_at': instance.effectiveAt.toIso8601String(),
      'published_at': instance.publishedAt?.toIso8601String(),
    };

const _$LegalDocumentKindEnumMap = {
  LegalDocumentKind.imprint: 'imprint',
  LegalDocumentKind.terms: 'terms',
  LegalDocumentKind.privacy: 'privacy',
  LegalDocumentKind.withdrawal: 'withdrawal',
};
