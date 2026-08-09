// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'data_subject_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

DataSubjectRequest _$DataSubjectRequestFromJson(Map<String, dynamic> json) {
  return _DataSubjectRequest.fromJson(json);
}

/// @nodoc
mixin _$DataSubjectRequest {
  String get id => throw _privateConstructorUsedError;
  DataSubjectRequestKind get kind => throw _privateConstructorUsedError;
  DataSubjectRequestStatus get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'requested_at')
  DateTime get requestedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'export_storage_path')
  String? get exportStoragePath => throw _privateConstructorUsedError;
  @JsonKey(name: 'export_expires_at')
  DateTime? get exportExpiresAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'completed_at')
  DateTime? get completedAt => throw _privateConstructorUsedError;

  /// Serializes this DataSubjectRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DataSubjectRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DataSubjectRequestCopyWith<DataSubjectRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DataSubjectRequestCopyWith<$Res> {
  factory $DataSubjectRequestCopyWith(
    DataSubjectRequest value,
    $Res Function(DataSubjectRequest) then,
  ) = _$DataSubjectRequestCopyWithImpl<$Res, DataSubjectRequest>;
  @useResult
  $Res call({
    String id,
    DataSubjectRequestKind kind,
    DataSubjectRequestStatus status,
    @JsonKey(name: 'requested_at') DateTime requestedAt,
    @JsonKey(name: 'export_storage_path') String? exportStoragePath,
    @JsonKey(name: 'export_expires_at') DateTime? exportExpiresAt,
    @JsonKey(name: 'completed_at') DateTime? completedAt,
  });
}

/// @nodoc
class _$DataSubjectRequestCopyWithImpl<$Res, $Val extends DataSubjectRequest>
    implements $DataSubjectRequestCopyWith<$Res> {
  _$DataSubjectRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DataSubjectRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? kind = null,
    Object? status = null,
    Object? requestedAt = null,
    Object? exportStoragePath = freezed,
    Object? exportExpiresAt = freezed,
    Object? completedAt = freezed,
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
                      as DataSubjectRequestKind,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as DataSubjectRequestStatus,
            requestedAt: null == requestedAt
                ? _value.requestedAt
                : requestedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            exportStoragePath: freezed == exportStoragePath
                ? _value.exportStoragePath
                : exportStoragePath // ignore: cast_nullable_to_non_nullable
                      as String?,
            exportExpiresAt: freezed == exportExpiresAt
                ? _value.exportExpiresAt
                : exportExpiresAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            completedAt: freezed == completedAt
                ? _value.completedAt
                : completedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DataSubjectRequestImplCopyWith<$Res>
    implements $DataSubjectRequestCopyWith<$Res> {
  factory _$$DataSubjectRequestImplCopyWith(
    _$DataSubjectRequestImpl value,
    $Res Function(_$DataSubjectRequestImpl) then,
  ) = __$$DataSubjectRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    DataSubjectRequestKind kind,
    DataSubjectRequestStatus status,
    @JsonKey(name: 'requested_at') DateTime requestedAt,
    @JsonKey(name: 'export_storage_path') String? exportStoragePath,
    @JsonKey(name: 'export_expires_at') DateTime? exportExpiresAt,
    @JsonKey(name: 'completed_at') DateTime? completedAt,
  });
}

/// @nodoc
class __$$DataSubjectRequestImplCopyWithImpl<$Res>
    extends _$DataSubjectRequestCopyWithImpl<$Res, _$DataSubjectRequestImpl>
    implements _$$DataSubjectRequestImplCopyWith<$Res> {
  __$$DataSubjectRequestImplCopyWithImpl(
    _$DataSubjectRequestImpl _value,
    $Res Function(_$DataSubjectRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DataSubjectRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? kind = null,
    Object? status = null,
    Object? requestedAt = null,
    Object? exportStoragePath = freezed,
    Object? exportExpiresAt = freezed,
    Object? completedAt = freezed,
  }) {
    return _then(
      _$DataSubjectRequestImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        kind: null == kind
            ? _value.kind
            : kind // ignore: cast_nullable_to_non_nullable
                  as DataSubjectRequestKind,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as DataSubjectRequestStatus,
        requestedAt: null == requestedAt
            ? _value.requestedAt
            : requestedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        exportStoragePath: freezed == exportStoragePath
            ? _value.exportStoragePath
            : exportStoragePath // ignore: cast_nullable_to_non_nullable
                  as String?,
        exportExpiresAt: freezed == exportExpiresAt
            ? _value.exportExpiresAt
            : exportExpiresAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        completedAt: freezed == completedAt
            ? _value.completedAt
            : completedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DataSubjectRequestImpl extends _DataSubjectRequest {
  const _$DataSubjectRequestImpl({
    required this.id,
    required this.kind,
    required this.status,
    @JsonKey(name: 'requested_at') required this.requestedAt,
    @JsonKey(name: 'export_storage_path') this.exportStoragePath,
    @JsonKey(name: 'export_expires_at') this.exportExpiresAt,
    @JsonKey(name: 'completed_at') this.completedAt,
  }) : super._();

  factory _$DataSubjectRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$DataSubjectRequestImplFromJson(json);

  @override
  final String id;
  @override
  final DataSubjectRequestKind kind;
  @override
  final DataSubjectRequestStatus status;
  @override
  @JsonKey(name: 'requested_at')
  final DateTime requestedAt;
  @override
  @JsonKey(name: 'export_storage_path')
  final String? exportStoragePath;
  @override
  @JsonKey(name: 'export_expires_at')
  final DateTime? exportExpiresAt;
  @override
  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;

  @override
  String toString() {
    return 'DataSubjectRequest(id: $id, kind: $kind, status: $status, requestedAt: $requestedAt, exportStoragePath: $exportStoragePath, exportExpiresAt: $exportExpiresAt, completedAt: $completedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DataSubjectRequestImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.requestedAt, requestedAt) ||
                other.requestedAt == requestedAt) &&
            (identical(other.exportStoragePath, exportStoragePath) ||
                other.exportStoragePath == exportStoragePath) &&
            (identical(other.exportExpiresAt, exportExpiresAt) ||
                other.exportExpiresAt == exportExpiresAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    kind,
    status,
    requestedAt,
    exportStoragePath,
    exportExpiresAt,
    completedAt,
  );

  /// Create a copy of DataSubjectRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DataSubjectRequestImplCopyWith<_$DataSubjectRequestImpl> get copyWith =>
      __$$DataSubjectRequestImplCopyWithImpl<_$DataSubjectRequestImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$DataSubjectRequestImplToJson(this);
  }
}

abstract class _DataSubjectRequest extends DataSubjectRequest {
  const factory _DataSubjectRequest({
    required final String id,
    required final DataSubjectRequestKind kind,
    required final DataSubjectRequestStatus status,
    @JsonKey(name: 'requested_at') required final DateTime requestedAt,
    @JsonKey(name: 'export_storage_path') final String? exportStoragePath,
    @JsonKey(name: 'export_expires_at') final DateTime? exportExpiresAt,
    @JsonKey(name: 'completed_at') final DateTime? completedAt,
  }) = _$DataSubjectRequestImpl;
  const _DataSubjectRequest._() : super._();

  factory _DataSubjectRequest.fromJson(Map<String, dynamic> json) =
      _$DataSubjectRequestImpl.fromJson;

  @override
  String get id;
  @override
  DataSubjectRequestKind get kind;
  @override
  DataSubjectRequestStatus get status;
  @override
  @JsonKey(name: 'requested_at')
  DateTime get requestedAt;
  @override
  @JsonKey(name: 'export_storage_path')
  String? get exportStoragePath;
  @override
  @JsonKey(name: 'export_expires_at')
  DateTime? get exportExpiresAt;
  @override
  @JsonKey(name: 'completed_at')
  DateTime? get completedAt;

  /// Create a copy of DataSubjectRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DataSubjectRequestImplCopyWith<_$DataSubjectRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
