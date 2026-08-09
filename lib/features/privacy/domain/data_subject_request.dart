import 'package:freezed_annotation/freezed_annotation.dart';

part 'data_subject_request.freezed.dart';
part 'data_subject_request.g.dart';

/// Mirrors `public.data_subject_request_kind`.
@JsonEnum()
enum DataSubjectRequestKind { export, deletion }

/// Mirrors `public.data_subject_request_status`.
@JsonEnum()
enum DataSubjectRequestStatus {
  requested,
  verifying,
  processing,
  completed,
  rejected,
  cancelled;

  /// Whether the request is still moving.
  ///
  /// Matches the predicate of `data_subject_one_open_request_idx`, so a user
  /// with an open request cannot start a second one of the same kind.
  bool get isOpen => switch (this) {
    DataSubjectRequestStatus.requested ||
    DataSubjectRequestStatus.verifying ||
    DataSubjectRequestStatus.processing => true,
    DataSubjectRequestStatus.completed ||
    DataSubjectRequestStatus.rejected ||
    DataSubjectRequestStatus.cancelled => false,
  };

  /// Whether the user can still call `cancel_account_deletion` on it.
  ///
  /// The RPC only touches `requested` and `verifying`; once processing starts
  /// the deletion is under way and cancelling is no longer offered.
  bool get isCancellable =>
      this == DataSubjectRequestStatus.requested ||
      this == DataSubjectRequestStatus.verifying;
}

/// A DSGVO Art. 15 (export) or Art. 17 (deletion) request.
@freezed
class DataSubjectRequest with _$DataSubjectRequest {
  const factory DataSubjectRequest({
    required String id,
    required DataSubjectRequestKind kind,
    required DataSubjectRequestStatus status,
    @JsonKey(name: 'requested_at') required DateTime requestedAt,
    @JsonKey(name: 'export_storage_path') String? exportStoragePath,
    @JsonKey(name: 'export_expires_at') DateTime? exportExpiresAt,
    @JsonKey(name: 'completed_at') DateTime? completedAt,
  }) = _DataSubjectRequest;

  const DataSubjectRequest._();

  factory DataSubjectRequest.fromJson(Map<String, dynamic> json) =>
      _$DataSubjectRequestFromJson(json);

  /// Whether a finished export is still downloadable.
  bool isDownloadable(DateTime now) =>
      kind == DataSubjectRequestKind.export &&
      status == DataSubjectRequestStatus.completed &&
      exportStoragePath != null &&
      (exportExpiresAt == null || exportExpiresAt!.isAfter(now));
}
