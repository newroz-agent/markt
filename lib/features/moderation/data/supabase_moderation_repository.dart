import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerin_marketplace/core/errors/app_exception.dart';
import 'package:zerin_marketplace/core/storage/product_image_url_resolver.dart';
import 'package:zerin_marketplace/features/moderation/domain/moderation_models.dart';
import 'package:zerin_marketplace/features/moderation/domain/moderation_repository.dart';

class SupabaseModerationRepository implements ModerationRepository {
  SupabaseModerationRepository(this._client);

  final SupabaseClient _client;
  late final ProductImageUrlResolver _imageUrls =
      ProductImageUrlResolver(_client);

  @override
  Future<bool> isAdmin() async {
    if (_client.auth.currentUser == null) return false;
    try {
      return await _client.rpc<bool>('is_admin');
    } on PostgrestException catch (e, s) {
      _throwBackend(e, s);
    }
  }

  @override
  Future<ModerationDashboard> fetchDashboard() async {
    _requireUser();
    try {
      final json = await _client.rpc<Map<String, dynamic>>(
        'get_moderation_dashboard',
        params: const {'p_limit': 50},
      );
      final rows = json['items'];
      if (rows is List) {
        json['items'] = await _imageUrls.resolveRows(rows);
      }
      return ModerationDashboard.fromJson(json);
    } on PostgrestException catch (e, s) {
      _throwBackend(e, s);
    }
  }

  @override
  Future<void> moderate({
    required String productId,
    required ModerationDecision decision,
    String? reason,
  }) async {
    _requireUser();
    try {
      await _client.rpc<void>(
        'moderate_listing',
        params: {
          'p_product_id': productId,
          'p_decision': decision.name,
          'p_reason': reason?.trim(),
        },
      );
    } on PostgrestException catch (e, s) {
      _throwBackend(e, s);
    }
  }

  @override
  Future<SellerVerificationQueue> fetchSellerVerificationQueue() async {
    _requireUser();
    try {
      final json = await _client.rpc<Map<String, dynamic>>(
        'get_admin_verification_queue',
        params: const {'p_limit': 50},
      );
      json['items'] = await _resolveDocuments(json['items']);
      return SellerVerificationQueue.fromJson(json);
    } on PostgrestException catch (e, s) {
      _throwBackend(e, s);
    }
  }

  @override
  Future<ModerationReportsQueue> fetchReportsQueue() async {
    _requireUser();
    try {
      return ModerationReportsQueue.fromJson(
        await _client.rpc<Map<String, dynamic>>(
          'get_admin_reports',
          params: const {'p_limit': 50},
        ),
      );
    } on PostgrestException catch (e, s) {
      _throwBackend(e, s);
    }
  }

  Future<List<Map<String, dynamic>>> _resolveDocuments(Object? raw) async {
    if (raw is! List) return const [];
    return Future.wait(
      raw.whereType<Map<Object?, Object?>>().map((value) async {
        final row = Map<String, dynamic>.from(value);
        final path = row.remove('storage_path') as String?;
        if (path != null) {
          try {
            row['signed_url'] = await _client.storage
                .from('seller-documents')
                .createSignedUrl(path, const Duration(hours: 1).inSeconds);
          } on StorageException {
            row['signed_url'] = null;
          }
        }
        return row;
      }),
    );
  }

  @override
  Future<void> moderateSellerDocument({
    required String documentId,
    required SellerDocumentDecision decision,
    String? note,
  }) async {
    _requireUser();
    try {
      await _client.rpc<void>(
        'moderate_seller_document',
        params: {
          'p_document_id': documentId,
          'p_decision': decision.name,
          'p_note': note?.trim(),
        },
      );
    } on PostgrestException catch (e, s) {
      _throwBackend(e, s);
    }
  }

  @override
  Future<void> resolveReport({
    required String reportId,
    required ReportAction action,
    String? reason,
  }) async {
    _requireUser();
    try {
      await _client.rpc<void>(
        'resolve_report',
        params: {
          'p_report_id': reportId,
          'p_action': action == ReportAction.blockListing
              ? 'block_listing'
              : 'dismiss',
          'p_reason': reason?.trim(),
        },
      );
    } on PostgrestException catch (e, s) {
      _throwBackend(e, s);
    }
  }

  void _requireUser() {
    if (_client.auth.currentUser == null) {
      throw const AppException(AppFailureCode.notAuthenticated);
    }
  }

  Never _throwBackend(Object error, StackTrace stackTrace) =>
      Error.throwWithStackTrace(
        AppException(AppFailureCode.unknown, cause: error),
        stackTrace,
      );
}
