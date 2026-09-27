import 'package:flutter_test/flutter_test.dart';
import 'package:zerin_marketplace/features/home/domain/home_feed.dart';
import 'package:zerin_marketplace/features/profile/domain/profile.dart';
import 'package:zerin_marketplace/features/profile/domain/profile_repository.dart';
import 'package:zerin_marketplace/features/profile/domain/public_identity_resolver.dart';

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository(this.summaries);

  final Map<String, PublicProfileSummary> summaries;
  final requestedIds = <List<String>>[];
  bool throwOnSummaries = false;

  @override
  Future<Map<String, PublicProfileSummary>> fetchPublicProfileSummaries(
    List<String> sellerIds,
  ) async {
    requestedIds.add(sellerIds);
    if (throwOnSummaries) throw StateError('offline');
    return {
      for (final entry in summaries.entries)
        if (sellerIds.contains(entry.key)) entry.key: entry.value,
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

MarketplaceStore _store({
  required String id,
  required String kind,
  String shopName = 'Stale Shop',
}) => MarketplaceStore(
  id: id,
  slug: 'slug-$id',
  shopName: shopName,
  bio: null,
  avatarUrl: 'https://seller.example/$id.jpg',
  bannerUrl: null,
  city: 'Hamburg',
  ratingAverage: 0,
  ratingCount: 0,
  responseTimeMinutes: null,
  sellerKind: kind,
);

HomeProduct _product(String id, MarketplaceStore? store) => HomeProduct(
  id: id,
  slug: id,
  title: 'Product $id',
  description: '',
  condition: 'used',
  priceCents: 1000,
  compareAtPriceCents: null,
  currency: 'EUR',
  vatRate: 19,
  priceIncludesVat: true,
  freeShipping: false,
  shippingCostCents: 0,
  ratingAverage: 0,
  ratingCount: 0,
  city: 'Hamburg',
  publishedAt: DateTime.utc(2026, 9, 2),
  store: store,
  imageUrls: const <String>[],
);

void main() {
  const summary = PublicProfileSummary(
    sellerId: 'private-1',
    displayName: 'Alice Public',
    username: 'alice_name',
    city: 'Berlin',
    avatarUrl: 'https://avatars.example/alice.webp',
  );

  test('overlays approved private seller identity onto listings', () async {
    final repo = _FakeProfileRepository({'private-1': summary});
    final resolver = PublicIdentityResolver(repo);
    final result = await resolver.overlayProducts(<HomeProduct>[
      _product('p1', _store(id: 'private-1', kind: 'private')),
    ]);
    final store = result.single.store!;
    expect(store.shopName, 'Alice Public');
    expect(store.profileUsername, 'alice_name');
    expect(store.avatarUrl, 'https://avatars.example/alice.webp');
    expect(store.city, 'Berlin');
    expect(store.hasPublicProfile, isTrue);
  });

  test(
    'business stores keep their distinct identity and never overlay',
    () async {
      final repo = _FakeProfileRepository({'private-1': summary});
      final resolver = PublicIdentityResolver(repo);
      final result = await resolver.overlayProducts(<HomeProduct>[
        _product(
          'p1',
          _store(id: 'business-1', kind: 'business', shopName: 'Trusted Store'),
        ),
      ]);
      final store = result.single.store!;
      expect(store.shopName, 'Trusted Store');
      expect(store.profileUsername, isNull);
      expect(store.hasPublicProfile, isFalse);
      // Business ids are never sent to the private-only summaries RPC.
      expect(repo.requestedIds, isEmpty);
    },
  );

  test('private seller without a summary is left unchanged', () async {
    final repo = _FakeProfileRepository(const {});
    final resolver = PublicIdentityResolver(repo);
    final result = await resolver.overlayProducts(<HomeProduct>[
      _product('p1', _store(id: 'private-2', kind: 'private')),
    ]);
    expect(result.single.store!.shopName, 'Stale Shop');
    expect(result.single.store!.profileUsername, isNull);
  });

  test('overlay failure degrades to the original listings', () async {
    final repo = _FakeProfileRepository({'private-1': summary})
      ..throwOnSummaries = true;
    final resolver = PublicIdentityResolver(repo);
    final products = <HomeProduct>[
      _product('p1', _store(id: 'private-1', kind: 'private')),
    ];
    final result = await resolver.overlayProducts(products);
    expect(result.single.store!.shopName, 'Stale Shop');
  });

  test('overlayStore applies to private and skips business', () async {
    final repo = _FakeProfileRepository({'private-1': summary});
    final resolver = PublicIdentityResolver(repo);
    final overlaid = await resolver.overlayStore(
      _store(id: 'private-1', kind: 'private'),
    );
    expect(overlaid!.profileUsername, 'alice_name');
    final business = await resolver.overlayStore(
      _store(id: 'business-1', kind: 'business', shopName: 'Trusted Store'),
    );
    expect(business!.shopName, 'Trusted Store');
    expect(business.profileUsername, isNull);
  });

  test(
    'overlayStores batches private identities and preserves businesses',
    () async {
      final repo = _FakeProfileRepository({'private-1': summary});
      final resolver = PublicIdentityResolver(repo);
      final stores = await resolver.overlayStores(<MarketplaceStore>[
        _store(id: 'private-1', kind: 'private'),
        _store(id: 'business-1', kind: 'business', shopName: 'Trusted Store'),
      ]);
      expect(stores.first.shopName, 'Alice Public');
      expect(stores.first.profileUsername, 'alice_name');
      expect(stores.last.shopName, 'Trusted Store');
      expect(stores.last.profileUsername, isNull);
      expect(repo.requestedIds.single, ['private-1']);
    },
  );

  test('empty product list returns immediately without RPC', () async {
    final repo = _FakeProfileRepository(const {});
    final resolver = PublicIdentityResolver(repo);
    expect(await resolver.overlayProducts(const <HomeProduct>[]), isEmpty);
    expect(repo.requestedIds, isEmpty);
  });
}
