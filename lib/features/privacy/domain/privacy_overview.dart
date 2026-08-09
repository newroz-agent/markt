import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:zerin_marketplace/features/privacy/domain/data_subject_request.dart';
import 'package:zerin_marketplace/features/privacy/domain/privacy_settings.dart';

part 'privacy_overview.freezed.dart';

/// Everything the privacy screen needs, loaded as one unit.
///
/// Settings and requests are fetched together so the screen cannot show a
/// stale deletion banner next to a fresh consent toggle.
@freezed
class PrivacyOverview with _$PrivacyOverview {
  const factory PrivacyOverview({
    @Default(PrivacySettings()) PrivacySettings settings,
    @Default(<DataSubjectRequest>[]) List<DataSubjectRequest> requests,
  }) = _PrivacyOverview;

  const PrivacyOverview._();

  /// The request of [kind] that is still moving, if any.
  ///
  /// The database allows at most one, so the first match is the only match.
  DataSubjectRequest? openRequest(DataSubjectRequestKind kind) =>
      requests.firstWhereOrNull(
        (request) => request.kind == kind && request.status.isOpen,
      );

  /// The most recent request of [kind], open or finished.
  ///
  /// Relies on the repository returning rows newest first.
  DataSubjectRequest? latestRequest(DataSubjectRequestKind kind) =>
      requests.firstWhereOrNull((request) => request.kind == kind);
}
