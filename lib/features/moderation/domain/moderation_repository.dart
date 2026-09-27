import 'package:zerin_marketplace/core/errors/app_exception.dart';
import 'package:zerin_marketplace/features/moderation/domain/moderation_models.dart';

abstract interface class ModerationRepository {
  Future<bool> isAdmin();
  Future<ModerationDashboard> fetchDashboard();
  Future<void> moderate({required String productId, required ModerationDecision decision, String? reason});
  Future<SellerVerificationQueue> fetchSellerVerificationQueue();
  Future<ModerationReportsQueue> fetchReportsQueue();
  Future<void> moderateSellerDocument({required String documentId, required SellerDocumentDecision decision, String? note});
  Future<void> resolveReport({required String reportId, required ReportAction action, String? reason});
}

class UnconfiguredModerationRepository implements ModerationRepository {
  const UnconfiguredModerationRepository();
  @override Future<bool> isAdmin() async=>false;
  @override Future<ModerationDashboard> fetchDashboard() async=>throw const AppException(AppFailureCode.backendNotConfigured);
  @override Future<void> moderate({required String productId,required ModerationDecision decision,String? reason}) async=>throw const AppException(AppFailureCode.backendNotConfigured);
  @override Future<SellerVerificationQueue> fetchSellerVerificationQueue() async=>throw const AppException(AppFailureCode.backendNotConfigured);
  @override Future<ModerationReportsQueue> fetchReportsQueue() async=>throw const AppException(AppFailureCode.backendNotConfigured);
  @override Future<void> moderateSellerDocument({required String documentId,required SellerDocumentDecision decision,String? note}) async=>throw const AppException(AppFailureCode.backendNotConfigured);
  @override Future<void> resolveReport({required String reportId,required ReportAction action,String? reason}) async=>throw const AppException(AppFailureCode.backendNotConfigured);
}
