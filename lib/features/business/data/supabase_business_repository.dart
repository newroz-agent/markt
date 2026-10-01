import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerin_marketplace/features/business/domain/business_models.dart';
import 'package:zerin_marketplace/features/business/domain/business_repository.dart';
import 'package:zerin_marketplace/features/business/domain/business_seller_id.dart';

class SupabaseBusinessRepository implements BusinessRepository {
  SupabaseBusinessRepository(this._client);

  static const _documentsBucket = 'seller-documents';
  static const _coversBucket = 'directory-covers';

  final SupabaseClient _client;

  @override
  Future<DirectoryOnboarding> fetchOnboarding({
    required String sellerId,
  }) async {
    _requireUser();
    final scopedSellerId = BusinessSellerId.requireValid(sellerId);
    return _guard(() async {
      final onboarding = DirectoryOnboarding.fromJson(
        await _client.rpc<Map<String, dynamic>>(
          'get_my_directory_onboarding',
          params: <String, dynamic>{'p_seller_id': scopedSellerId},
        ),
      );
      _requireMatchingBusiness(onboarding, scopedSellerId);
      return onboarding;
    });
  }

  @override
  Future<DirectoryOnboarding> createBusiness({
    required String? existingPrivateSellerId,
    required DirectoryType type,
    required String shopName,
    required String city,
  }) async {
    _requireUser();
    final privateSellerId = BusinessSellerId.requireValidNullable(
      existingPrivateSellerId,
    );
    return _guard(() async {
      final onboarding = DirectoryOnboarding.fromJson(
        await _client.rpc<Map<String, dynamic>>(
          'owner_start_directory',
          params: <String, dynamic>{
            // The key must remain present when null so PostgREST chooses the
            // UUID-first F2a overload rather than the temporary legacy one.
            'p_existing_private_seller_id': privateSellerId,
            'p_directory_type': type.databaseValue,
            'p_shop_name': shopName.trim(),
            'p_city': city,
          },
        ),
      );
      final createdSellerId = onboarding.seller?.id;
      if (createdSellerId == null ||
          !BusinessSellerId.isValid(createdSellerId) ||
          onboarding.seller?.kind != 'business') {
        throw const BusinessException(BusinessFailureReason.invalidInput);
      }
      return onboarding;
    });
  }

  @override
  Future<DirectoryOnboarding> setDirectoryType({
    required String sellerId,
    required DirectoryType type,
  }) async {
    _requireUser();
    final scopedSellerId = BusinessSellerId.requireValid(sellerId);
    return _guard(() async {
      final onboarding = DirectoryOnboarding.fromJson(
        await _client.rpc<Map<String, dynamic>>(
          'owner_set_directory_type',
          params: <String, dynamic>{
            'p_seller_id': scopedSellerId,
            'p_directory_type': type.databaseValue,
          },
        ),
      );
      _requireMatchingBusiness(onboarding, scopedSellerId);
      return onboarding;
    });
  }

  @override
  Future<void> uploadDocument({
    required String sellerId,
    required SellerDocumentKind kind,
    required PickedDocumentFile file,
  }) async {
    _requireUser();
    final scopedSellerId = BusinessSellerId.requireValid(sellerId);
    if (file.isTooLarge) {
      throw const BusinessException(BusinessFailureReason.fileTooLarge);
    }
    final path =
        '$scopedSellerId/${kind.databaseValue}/'
        '${DateTime.now().microsecondsSinceEpoch}.${file.extension}';
    await _guard(
      () => _client.storage
          .from(_documentsBucket)
          .uploadBinary(
            path,
            file.bytes,
            fileOptions: FileOptions(contentType: file.mimeType),
          ),
    );
    try {
      await _guard(
        () => _client.from('seller_documents').insert(<String, dynamic>{
          'seller_id': scopedSellerId,
          'kind': kind.databaseValue,
          'storage_path': path,
          'mime_type': file.mimeType,
        }),
      );
    } on BusinessException {
      await _removeQuietly(_documentsBucket, path);
      rethrow;
    }
  }

  @override
  Future<void> withdrawDocument({
    required String sellerId,
    required SellerDocument document,
  }) async {
    _requireUser();
    final scopedSellerId = BusinessSellerId.requireValid(sellerId);
    if (!document.storagePath.startsWith('$scopedSellerId/')) {
      throw const BusinessException(BusinessFailureReason.invalidInput);
    }
    await _guard(
      () => _client
          .from('seller_documents')
          .delete()
          .eq('id', document.id)
          .eq('seller_id', scopedSellerId),
    );
    await _removeQuietly(_documentsBucket, document.storagePath);
  }

  @override
  Future<void> saveProfile({
    required String sellerId,
    required DirectoryProfile profile,
  }) async {
    _requireUser();
    final scopedSellerId = BusinessSellerId.requireValid(sellerId);
    await _guard(
      () => _client.rpc<Map<String, dynamic>>(
        'owner_upsert_directory_profile',
        params: <String, dynamic>{
          'p_seller_id': scopedSellerId,
          ...profile.toRpcParams(),
        },
      ),
    );
  }

  @override
  Future<String> uploadCover({
    required String sellerId,
    required Uint8List webpBytes,
  }) async {
    _requireUser();
    final scopedSellerId = BusinessSellerId.requireValid(sellerId);
    final path = '$scopedSellerId/${_uuidV4()}.webp';
    await _guard(
      () => _client.storage
          .from(_coversBucket)
          .uploadBinary(
            path,
            webpBytes,
            fileOptions: const FileOptions(contentType: 'image/webp'),
          ),
    );
    return path;
  }

  @override
  String? coverUrl(String? storagePath) => storagePath == null
      ? null
      : _client.storage.from(_coversBucket).getPublicUrl(storagePath);

  @override
  Future<void> saveHours({
    required String sellerId,
    required List<OpeningInterval> intervals,
  }) async {
    _requireUser();
    final scopedSellerId = BusinessSellerId.requireValid(sellerId);
    await _guard(
      () => _client.rpc<List<dynamic>>(
        'owner_replace_directory_hours',
        params: <String, dynamic>{
          'p_seller_id': scopedSellerId,
          'p_intervals': [
            for (final (index, interval) in intervals.indexed)
              interval.toJson(index),
          ],
        },
      ),
    );
  }

  @override
  Future<void> saveMenu({
    required String sellerId,
    required List<MenuSectionDraft> sections,
  }) async {
    _requireUser();
    final scopedSellerId = BusinessSellerId.requireValid(sellerId);
    await _guard(
      () => _client.rpc<List<dynamic>>(
        'owner_replace_directory_menu',
        params: <String, dynamic>{
          'p_seller_id': scopedSellerId,
          'p_sections': [
            for (final (index, section) in sections.indexed)
              section.toJson(index),
          ],
        },
      ),
    );
  }

  void _requireMatchingBusiness(
    DirectoryOnboarding onboarding,
    String sellerId,
  ) {
    final seller = onboarding.seller;
    if (seller == null || seller.id != sellerId || seller.kind != 'business') {
      throw const BusinessException(BusinessFailureReason.invalidInput);
    }
  }

  void _requireUser() {
    if (_client.auth.currentUser == null) {
      throw const BusinessException(BusinessFailureReason.notAuthenticated);
    }
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        BusinessException(_reasonFor(error), cause: error),
        stackTrace,
      );
    } on StorageException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        BusinessException(BusinessFailureReason.unknown, cause: error),
        stackTrace,
      );
    }
  }

  /// Maps the SQLSTATEs and messages raised by the E1/E2 owner contracts.
  static BusinessFailureReason _reasonFor(PostgrestException error) {
    final message = error.message.toLowerCase();
    return switch (error.code) {
      '42501' when message.contains('authentication required') =>
        BusinessFailureReason.notAuthenticated,
      '42501' => BusinessFailureReason.invalidInput,
      '22023' when message.contains('business name') =>
        BusinessFailureReason.invalidBusinessName,
      '22023' when message.contains('german city') =>
        BusinessFailureReason.unsupportedCity,
      '22023' when message.contains('directory profile') =>
        BusinessFailureReason.typeLockedByProfile,
      '23505' => BusinessFailureReason.documentAlreadyPending,
      '22023' || '23514' || '22P02' => BusinessFailureReason.invalidInput,
      _ => BusinessFailureReason.unknown,
    };
  }

  Future<void> _removeQuietly(String bucket, String path) async {
    try {
      await _client.storage.from(bucket).remove(<String>[path]);
    } on StorageException {
      // The row is already gone or was never written; an orphaned object is
      // only reachable by its owner and admins and can be cleaned up later.
    }
  }

  static String _uuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
