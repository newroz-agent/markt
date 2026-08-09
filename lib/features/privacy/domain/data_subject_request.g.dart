// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_subject_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DataSubjectRequestImpl _$$DataSubjectRequestImplFromJson(
  Map<String, dynamic> json,
) => _$DataSubjectRequestImpl(
  id: json['id'] as String,
  kind: $enumDecode(_$DataSubjectRequestKindEnumMap, json['kind']),
  status: $enumDecode(_$DataSubjectRequestStatusEnumMap, json['status']),
  requestedAt: DateTime.parse(json['requested_at'] as String),
  exportStoragePath: json['export_storage_path'] as String?,
  exportExpiresAt: json['export_expires_at'] == null
      ? null
      : DateTime.parse(json['export_expires_at'] as String),
  completedAt: json['completed_at'] == null
      ? null
      : DateTime.parse(json['completed_at'] as String),
);

Map<String, dynamic> _$$DataSubjectRequestImplToJson(
  _$DataSubjectRequestImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'kind': _$DataSubjectRequestKindEnumMap[instance.kind]!,
  'status': _$DataSubjectRequestStatusEnumMap[instance.status]!,
  'requested_at': instance.requestedAt.toIso8601String(),
  'export_storage_path': instance.exportStoragePath,
  'export_expires_at': instance.exportExpiresAt?.toIso8601String(),
  'completed_at': instance.completedAt?.toIso8601String(),
};

const _$DataSubjectRequestKindEnumMap = {
  DataSubjectRequestKind.export: 'export',
  DataSubjectRequestKind.deletion: 'deletion',
};

const _$DataSubjectRequestStatusEnumMap = {
  DataSubjectRequestStatus.requested: 'requested',
  DataSubjectRequestStatus.verifying: 'verifying',
  DataSubjectRequestStatus.processing: 'processing',
  DataSubjectRequestStatus.completed: 'completed',
  DataSubjectRequestStatus.rejected: 'rejected',
  DataSubjectRequestStatus.cancelled: 'cancelled',
};
