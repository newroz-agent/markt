import 'package:zerin_marketplace/features/business/domain/business_repository.dart';

/// Local shape check only. Ownership and seller kind are always authorized by
/// the UUID-first database RPCs.
abstract final class BusinessSellerId {
  static final RegExp _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  static bool isValid(String? value) =>
      value != null && _uuid.hasMatch(value.trim());

  static String requireValid(String value) {
    final trimmed = value.trim();
    if (!isValid(trimmed)) {
      throw const BusinessException(BusinessFailureReason.invalidInput);
    }
    return trimmed;
  }

  static String? requireValidNullable(String? value) =>
      value == null ? null : requireValid(value);
}
