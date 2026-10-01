import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:zerin_marketplace/core/providers/infrastructure_providers.dart';
import 'package:zerin_marketplace/features/auth/presentation/controllers/auth_controller.dart';
import 'package:zerin_marketplace/features/business/data/flutter_document_file_service.dart';
import 'package:zerin_marketplace/features/business/data/supabase_business_repository.dart';
import 'package:zerin_marketplace/features/business/domain/business_models.dart';
import 'package:zerin_marketplace/features/business/domain/business_repository.dart';

part 'business_controller.g.dart';

@Riverpod(keepAlive: true)
BusinessRepository businessRepository(BusinessRepositoryRef ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? const UnconfiguredBusinessRepository()
      : SupabaseBusinessRepository(client);
}

@Riverpod(keepAlive: true)
DocumentFileService documentFileService(DocumentFileServiceRef ref) {
  // Picker plugins are unavailable on the web/test harness.
  if (kIsWeb) return const UnavailableDocumentFileService();
  return FlutterDocumentFileService();
}

/// This exact signed-in business seller's directory onboarding. Rebuilds on
/// account changes and never keeps another identity's data.
@riverpod
Future<DirectoryOnboarding> directoryOnboarding(
  DirectoryOnboardingRef ref,
  String businessSellerId,
) {
  ref.watch(authStateProvider.select((state) => state.valueOrNull?.id));
  return ref
      .watch(businessRepositoryProvider)
      .fetchOnboarding(sellerId: businessSellerId);
}
