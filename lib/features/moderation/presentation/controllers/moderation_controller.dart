import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zerin_marketplace/core/errors/app_exception.dart';
import 'package:zerin_marketplace/core/providers/infrastructure_providers.dart';
import 'package:zerin_marketplace/core/providers/product_realtime_provider.dart';
import 'package:zerin_marketplace/features/auth/presentation/controllers/auth_controller.dart';
import 'package:zerin_marketplace/features/home/presentation/controllers/home_controller.dart';
import 'package:zerin_marketplace/features/moderation/data/supabase_moderation_repository.dart';
import 'package:zerin_marketplace/features/moderation/domain/moderation_models.dart';
import 'package:zerin_marketplace/features/moderation/domain/moderation_repository.dart';
import 'package:zerin_marketplace/features/sell/presentation/controllers/sell_controller.dart';

part 'moderation_controller.g.dart';

@Riverpod(keepAlive: true)
ModerationRepository moderationRepository(ModerationRepositoryRef ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? const UnconfiguredModerationRepository()
      : SupabaseModerationRepository(client);
}

@riverpod
Future<bool> currentUserIsAdmin(CurrentUserIsAdminRef ref) {
  ref.watch(authStateProvider.select((state) => state.valueOrNull?.id));
  return ref.watch(moderationRepositoryProvider).isAdmin();
}

@riverpod
Future<ModerationDashboard> moderationDashboard(
  ModerationDashboardRef ref,
) async {
  ref.watch(productRealtimeChangesProvider);
  if (!await ref.watch(currentUserIsAdminProvider.future)) {
    throw const AppException(AppFailureCode.notAuthenticated);
  }
  return ref.watch(moderationRepositoryProvider).fetchDashboard();
}

@riverpod
Future<SellerVerificationQueue> sellerVerificationQueue(
  SellerVerificationQueueRef ref,
) async {
  if (!await ref.watch(currentUserIsAdminProvider.future)) {
    throw const AppException(AppFailureCode.notAuthenticated);
  }
  return ref.watch(moderationRepositoryProvider).fetchSellerVerificationQueue();
}

@riverpod
Future<ModerationReportsQueue> moderationReportsQueue(
  ModerationReportsQueueRef ref,
) async {
  if (!await ref.watch(currentUserIsAdminProvider.future)) {
    throw const AppException(AppFailureCode.notAuthenticated);
  }
  return ref.watch(moderationRepositoryProvider).fetchReportsQueue();
}

@riverpod
class ModerationAction extends _$ModerationAction {
  @override
  FutureOr<void> build() {}

  Future<bool> decide({
    required String productId,
    required ModerationDecision decision,
    String? reason,
  }) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(moderationRepositoryProvider)
          .moderate(productId: productId, decision: decision, reason: reason),
    );
    if (!state.hasError) {
      ref.invalidate(moderationDashboardProvider);
      ref.invalidate(myListingsProvider);
      ref.invalidate(homeFeedProvider);
    }
    return !state.hasError;
  }

  Future<bool> decideDocument({required String documentId, required SellerDocumentDecision decision, String? note}) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(moderationRepositoryProvider).moderateSellerDocument(documentId: documentId, decision: decision, note: note));
    if (!state.hasError) ref.invalidate(sellerVerificationQueueProvider);
    return !state.hasError;
  }

  Future<bool> decideReport({required String reportId, required ReportAction action, String? reason}) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(moderationRepositoryProvider).resolveReport(reportId: reportId, action: action, reason: reason));
    if (!state.hasError) {
      ref.invalidate(moderationReportsQueueProvider);
      ref.invalidate(homeFeedProvider);
      ref.invalidate(myListingsProvider);
    }
    return !state.hasError;
  }
}
