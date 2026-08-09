// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'legal_document.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

LegalDocument _$LegalDocumentFromJson(Map<String, dynamic> json) {
  return _LegalDocument.fromJson(json);
}

/// @nodoc
mixin _$LegalDocument {
  String get id => throw _privateConstructorUsedError;
  LegalDocumentKind get kind => throw _privateConstructorUsedError;
  String get locale => throw _privateConstructorUsedError;
  String get version => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  @JsonKey(name: 'content_markdown')
  String get contentMarkdown => throw _privateConstructorUsedError;
  @JsonKey(name: 'effective_at')
  DateTime get effectiveAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'published_at')
  DateTime? get publishedAt => throw _privateConstructorUsedError;

  /// Serializes this LegalDocument to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LegalDocument
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LegalDocumentCopyWith<LegalDocument> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LegalDocumentCopyWith<$Res> {
  factory $LegalDocumentCopyWith(
    LegalDocument value,
    $Res Function(LegalDocument) then,
  ) = _$LegalDocumentCopyWithImpl<$Res, LegalDocument>;
  @useResult
  $Res call({
    String id,
    LegalDocumentKind kind,
    String locale,
    String version,
    String title,
    @JsonKey(name: 'content_markdown') String contentMarkdown,
    @JsonKey(name: 'effective_at') DateTime effectiveAt,
    @JsonKey(name: 'published_at') DateTime? publishedAt,
  });
}

/// @nodoc
class _$LegalDocumentCopyWithImpl<$Res, $Val extends LegalDocument>
    implements $LegalDocumentCopyWith<$Res> {
  _$LegalDocumentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LegalDocument
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? kind = null,
    Object? locale = null,
    Object? version = null,
    Object? title = null,
    Object? contentMarkdown = null,
    Object? effectiveAt = null,
    Object? publishedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            kind: null == kind
                ? _value.kind
                : kind // ignore: cast_nullable_to_non_nullable
                      as LegalDocumentKind,
            locale: null == locale
                ? _value.locale
                : locale // ignore: cast_nullable_to_non_nullable
                      as String,
            version: null == version
                ? _value.version
                : version // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            contentMarkdown: null == contentMarkdown
                ? _value.contentMarkdown
                : contentMarkdown // ignore: cast_nullable_to_non_nullable
                      as String,
            effectiveAt: null == effectiveAt
                ? _value.effectiveAt
                : effectiveAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            publishedAt: freezed == publishedAt
                ? _value.publishedAt
                : publishedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LegalDocumentImplCopyWith<$Res>
    implements $LegalDocumentCopyWith<$Res> {
  factory _$$LegalDocumentImplCopyWith(
    _$LegalDocumentImpl value,
    $Res Function(_$LegalDocumentImpl) then,
  ) = __$$LegalDocumentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    LegalDocumentKind kind,
    String locale,
    String version,
    String title,
    @JsonKey(name: 'content_markdown') String contentMarkdown,
    @JsonKey(name: 'effective_at') DateTime effectiveAt,
    @JsonKey(name: 'published_at') DateTime? publishedAt,
  });
}

/// @nodoc
class __$$LegalDocumentImplCopyWithImpl<$Res>
    extends _$LegalDocumentCopyWithImpl<$Res, _$LegalDocumentImpl>
    implements _$$LegalDocumentImplCopyWith<$Res> {
  __$$LegalDocumentImplCopyWithImpl(
    _$LegalDocumentImpl _value,
    $Res Function(_$LegalDocumentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LegalDocument
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? kind = null,
    Object? locale = null,
    Object? version = null,
    Object? title = null,
    Object? contentMarkdown = null,
    Object? effectiveAt = null,
    Object? publishedAt = freezed,
  }) {
    return _then(
      _$LegalDocumentImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        kind: null == kind
            ? _value.kind
            : kind // ignore: cast_nullable_to_non_nullable
                  as LegalDocumentKind,
        locale: null == locale
            ? _value.locale
            : locale // ignore: cast_nullable_to_non_nullable
                  as String,
        version: null == version
            ? _value.version
            : version // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        contentMarkdown: null == contentMarkdown
            ? _value.contentMarkdown
            : contentMarkdown // ignore: cast_nullable_to_non_nullable
                  as String,
        effectiveAt: null == effectiveAt
            ? _value.effectiveAt
            : effectiveAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        publishedAt: freezed == publishedAt
            ? _value.publishedAt
            : publishedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LegalDocumentImpl implements _LegalDocument {
  const _$LegalDocumentImpl({
    required this.id,
    required this.kind,
    required this.locale,
    required this.version,
    required this.title,
    @JsonKey(name: 'content_markdown') required this.contentMarkdown,
    @JsonKey(name: 'effective_at') required this.effectiveAt,
    @JsonKey(name: 'published_at') this.publishedAt,
  });

  factory _$LegalDocumentImpl.fromJson(Map<String, dynamic> json) =>
      _$$LegalDocumentImplFromJson(json);

  @override
  final String id;
  @override
  final LegalDocumentKind kind;
  @override
  final String locale;
  @override
  final String version;
  @override
  final String title;
  @override
  @JsonKey(name: 'content_markdown')
  final String contentMarkdown;
  @override
  @JsonKey(name: 'effective_at')
  final DateTime effectiveAt;
  @override
  @JsonKey(name: 'published_at')
  final DateTime? publishedAt;

  @override
  String toString() {
    return 'LegalDocument(id: $id, kind: $kind, locale: $locale, version: $version, title: $title, contentMarkdown: $contentMarkdown, effectiveAt: $effectiveAt, publishedAt: $publishedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LegalDocumentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.locale, locale) || other.locale == locale) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.contentMarkdown, contentMarkdown) ||
                other.contentMarkdown == contentMarkdown) &&
            (identical(other.effectiveAt, effectiveAt) ||
                other.effectiveAt == effectiveAt) &&
            (identical(other.publishedAt, publishedAt) ||
                other.publishedAt == publishedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    kind,
    locale,
    version,
    title,
    contentMarkdown,
    effectiveAt,
    publishedAt,
  );

  /// Create a copy of LegalDocument
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LegalDocumentImplCopyWith<_$LegalDocumentImpl> get copyWith =>
      __$$LegalDocumentImplCopyWithImpl<_$LegalDocumentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LegalDocumentImplToJson(this);
  }
}

abstract class _LegalDocument implements LegalDocument {
  const factory _LegalDocument({
    required final String id,
    required final LegalDocumentKind kind,
    required final String locale,
    required final String version,
    required final String title,
    @JsonKey(name: 'content_markdown') required final String contentMarkdown,
    @JsonKey(name: 'effective_at') required final DateTime effectiveAt,
    @JsonKey(name: 'published_at') final DateTime? publishedAt,
  }) = _$LegalDocumentImpl;

  factory _LegalDocument.fromJson(Map<String, dynamic> json) =
      _$LegalDocumentImpl.fromJson;

  @override
  String get id;
  @override
  LegalDocumentKind get kind;
  @override
  String get locale;
  @override
  String get version;
  @override
  String get title;
  @override
  @JsonKey(name: 'content_markdown')
  String get contentMarkdown;
  @override
  @JsonKey(name: 'effective_at')
  DateTime get effectiveAt;
  @override
  @JsonKey(name: 'published_at')
  DateTime? get publishedAt;

  /// Create a copy of LegalDocument
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LegalDocumentImplCopyWith<_$LegalDocumentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
