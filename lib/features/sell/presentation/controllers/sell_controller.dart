import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zerin_marketplace/core/errors/app_exception.dart';
import 'package:zerin_marketplace/core/providers/infrastructure_providers.dart';
import 'package:zerin_marketplace/core/providers/product_realtime_provider.dart';
import 'package:zerin_marketplace/features/auth/presentation/controllers/auth_controller.dart';
import 'package:zerin_marketplace/features/identity/presentation/controllers/identity_controller.dart';
import 'package:zerin_marketplace/features/sell/data/flutter_sell_image_service.dart';
import 'package:zerin_marketplace/features/sell/data/supabase_sell_repository.dart';
import 'package:zerin_marketplace/features/sell/domain/sell_image_service.dart';
import 'package:zerin_marketplace/features/sell/domain/sell_models.dart';
import 'package:zerin_marketplace/features/sell/domain/sell_repository.dart';

part 'sell_controller.g.dart';

@Riverpod(keepAlive: true)
SellRepository sellRepository(SellRepositoryRef ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? const UnconfiguredSellRepository()
      : SupabaseSellRepository(client);
}

@Riverpod(keepAlive: true)
SellImageService sellImageService(SellImageServiceRef ref) =>
    FlutterSellImageService();

@riverpod
Future<List<ListingTemplate>> listingTemplates(
  ListingTemplatesRef ref,
  String query,
) => ref.watch(sellRepositoryProvider).searchTemplates(query);

@riverpod
Future<List<MyListing>> myListings(MyListingsRef ref) async {
  ref.watch(authStateProvider.select((state) => state.valueOrNull?.id));
  ref.watch(productRealtimeChangesProvider);
  if (ref.read(authRepositoryProvider).currentUser == null) {
    throw const AppException(AppFailureCode.notAuthenticated);
  }
  final identitySession = await ref.watch(
    validatedIdentitySessionProvider.future,
  );
  if (identitySession == null) {
    throw const AppException(AppFailureCode.notAuthenticated);
  }
  return ref
      .watch(sellRepositoryProvider)
      .fetchMyListings(identitySession.catalog);
}

@riverpod
class SellSubmissionController extends _$SellSubmissionController {
  @override
  FutureOr<MyListing?> build() => null;

  Future<MyListing?> submit(SellListingDraft draft) async {
    if (state.isLoading) return null;
    state = const AsyncLoading();
    final refreshLazyPrivateIdentity =
        draft.identity.isPerson && draft.identity.sellerId == null;
    try {
      final listing = await ref
          .read(sellRepositoryProvider)
          .submitListing(draft);
      state = AsyncData(listing);
      ref.invalidate(myListingsProvider);
      return listing;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    } finally {
      // Preparation commits before photo upload/submission. Even on failure it
      // may have lazily created the private seller, so always refresh catalog.
      if (refreshLazyPrivateIdentity) {
        ref.read(identityCatalogRevisionProvider.notifier).bump();
      }
    }
  }

  void reset() => state = const AsyncData(null);
}
