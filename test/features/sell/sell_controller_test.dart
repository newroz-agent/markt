import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerin_marketplace/core/errors/app_exception.dart';
import 'package:zerin_marketplace/features/auth/domain/auth_repository.dart';
import 'package:zerin_marketplace/features/auth/domain/auth_user.dart';
import 'package:zerin_marketplace/features/auth/presentation/controllers/auth_controller.dart';
import 'package:zerin_marketplace/features/identity/data/active_identity_store.dart';
import 'package:zerin_marketplace/features/identity/domain/identity.dart';
import 'package:zerin_marketplace/features/identity/domain/identity_repository.dart';
import 'package:zerin_marketplace/features/identity/presentation/controllers/identity_controller.dart';
import 'package:zerin_marketplace/features/sell/domain/sell_models.dart';
import 'package:zerin_marketplace/features/sell/domain/sell_repository.dart';
import 'package:zerin_marketplace/features/sell/presentation/controllers/sell_controller.dart';

const _user = AuthUser(id: 'lazy-owner', email: 'lazy@example.invalid');
const _privateSellerId = '11111111-1111-4111-8111-111111111111';
const _personWithoutSeller = MarketplaceIdentity(
  type: MarketplaceIdentityType.person,
  sellerId: null,
  sellerKind: 'private',
  sellerStatus: null,
  label: 'Lazy Owner',
  avatarUrl: null,
  username: 'lazy_owner',
);

class _AuthRepository implements AuthRepository {
  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthUser?> get authStateChanges => Stream.value(_user);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _Store implements ActiveIdentityStore {
  String? selection;

  @override
  String? read(String userId) => selection;

  @override
  Future<void> write(String userId, String selectionKey) async =>
      selection = selectionKey;

  @override
  Future<void> remove(String userId) async => selection = null;
}

class _SellRepository implements SellRepository {
  var attempts = 0;
  var privateSellerCreated = false;

  @override
  Future<MyListing> submitListing(SellListingDraft draft) async {
    attempts++;
    if (attempts == 1) {
      // Models prepare_listing_submission committing the lazy private seller,
      // followed by a photo-upload failure.
      privateSellerCreated = true;
      throw const AppException(AppFailureCode.network);
    }
    if (privateSellerCreated && draft.identity.sellerId == null) {
      throw const AppException(
        AppFailureCode.unknown,
        cause: 'duplicate (user_id, kind)',
      );
    }
    return MyListing(
      identity: draft.identity,
      id: 'listing',
      title: draft.title,
      priceCents: draft.priceCents,
      currency: 'EUR',
      city: draft.city,
      condition: draft.condition.databaseValue,
      status: ListingStatus.pendingReview,
      createdAt: DateTime.utc(2026, 9, 30),
      imageUrls: const <String>[],
    );
  }

  @override
  Future<List<MyListing>> fetchMyListings(IdentityCatalog catalog) async =>
      const <MyListing>[];

  @override
  Future<List<ListingTemplate>> searchTemplates(String query) async =>
      const <ListingTemplate>[];
}

class _CatalogRepository implements IdentityCatalogRepository {
  _CatalogRepository(this.sell);

  final _SellRepository sell;
  var fetches = 0;

  @override
  Future<IdentityCatalog> fetchMyIdentityCatalog() async {
    fetches++;
    return IdentityCatalog(<MarketplaceIdentity>[
      sell.privateSellerCreated
          ? _personWithoutSeller.withSellerId(_privateSellerId)
          : _personWithoutSeller,
    ]);
  }
}

SellListingDraft _draft(MarketplaceIdentity identity) => SellListingDraft(
  identity: identity,
  title: 'Lazy private listing',
  priceCents: 2500,
  city: 'Berlin',
  categoryId: 'category',
  condition: SellCondition.used,
  description: 'A complete lazy private listing description.',
  photos: const <SellPhoto>[],
);

Future<IdentitySessionState> _identityState(ProviderContainer container) async {
  for (var attempt = 0; attempt < 30; attempt++) {
    await container.pump();
    final state = container.read(activeIdentityControllerProvider);
    if (!state.isLoading && state.hasValue && state.requireValue != null) {
      return state.requireValue!;
    }
  }
  fail('Identity catalog did not settle.');
}

void main() {
  test(
    'lazy private upload failure refreshes catalog and retry avoids unique',
    () async {
      final sell = _SellRepository();
      final catalog = _CatalogRepository(sell);
      final container = ProviderContainer(
        overrides: <Override>[
          authRepositoryProvider.overrideWithValue(_AuthRepository()),
          identityCatalogRepositoryProvider.overrideWithValue(catalog),
          activeIdentityStoreProvider.overrideWithValue(_Store()),
          sellRepositoryProvider.overrideWithValue(sell),
        ],
      );
      addTearDown(container.dispose);
      final identitySubscription = container.listen(
        activeIdentityControllerProvider,
        (_, _) {},
        fireImmediately: true,
      );
      final submissionSubscription = container.listen(
        sellSubmissionControllerProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(identitySubscription.close);
      addTearDown(submissionSubscription.close);

      final initial = await _identityState(container);
      expect(initial.catalog.person?.sellerId, isNull);
      expect(catalog.fetches, 1);

      final first = await container
          .read(sellSubmissionControllerProvider.notifier)
          .submit(_draft(initial.catalog.person!));
      expect(first, isNull);
      expect(container.read(sellSubmissionControllerProvider).hasError, isTrue);

      final refreshed = await _identityState(container);
      expect(catalog.fetches, 2, reason: 'failure bumps catalog revision');
      expect(refreshed.catalog.person?.sellerId, _privateSellerId);

      final retry = await container
          .read(sellSubmissionControllerProvider.notifier)
          .submit(_draft(refreshed.catalog.person!));
      expect(retry, isNotNull);
      expect(retry?.identity.sellerId, _privateSellerId);
      expect(sell.attempts, 2);
    },
  );
}
