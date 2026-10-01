import 'package:zerin_marketplace/features/home/domain/home_feed.dart';
import 'package:zerin_marketplace/features/profile/domain/profile.dart';
import 'package:zerin_marketplace/features/profile/domain/profile_repository.dart';

/// Overlays approved private-seller person identity (display name, @username,
/// avatar, city) from `get_public_profile_summaries` onto listing/detail/chat
/// data, while preserving distinct business store name/logo. Business sellers
/// and non-approved private sellers are never modified.
class PublicIdentityResolver {
  const PublicIdentityResolver(this._repository);

  final ProfileRepository _repository;

  /// Returns [products] with private-seller store identity overlaid. Business
  /// stores pass through unchanged. Failures degrade to the original list.
  Future<List<HomeProduct>> overlayProducts(List<HomeProduct> products) async {
    if (products.isEmpty) return products;
    final sellerIds = <String>{
      for (final product in products)
        if (product.store != null && !product.store!.isBusiness)
          product.store!.id,
    };
    if (sellerIds.isEmpty) return products;
    final summaries = await _summariesOrEmpty(sellerIds.toList());
    if (summaries.isEmpty) return products;
    return <HomeProduct>[
      for (final product in products) _applyToProduct(product, summaries),
    ];
  }

  /// Returns a single [store] with private-seller identity overlaid, or the
  /// original store when it is a business or has no approved public profile.
  Future<MarketplaceStore?> overlayStore(MarketplaceStore? store) async {
    if (store == null || store.isBusiness) return store;
    final summaries = await _summariesOrEmpty(<String>[store.id]);
    final summary = summaries[store.id];
    return summary == null ? store : _applyToStore(store, summary);
  }

  /// Overlays a list of private stores in one summaries RPC. Business stores
  /// are preserved and never included in the request.
  Future<List<MarketplaceStore>> overlayStores(
    List<MarketplaceStore> stores,
  ) async {
    if (stores.isEmpty) return stores;
    final sellerIds = <String>{
      for (final store in stores)
        if (!store.isBusiness) store.id,
    };
    if (sellerIds.isEmpty) return stores;
    final summaries = await _summariesOrEmpty(sellerIds.toList());
    if (summaries.isEmpty) return stores;
    return <MarketplaceStore>[
      for (final store in stores)
        if (store.isBusiness || summaries[store.id] == null)
          store
        else
          _applyToStore(store, summaries[store.id]!),
    ];
  }

  Future<Map<String, PublicProfileSummary>> _summariesOrEmpty(
    List<String> sellerIds,
  ) async {
    try {
      return await _repository.fetchPublicProfileSummaries(sellerIds);
    } on Object {
      // Identity overlay is advisory; never fail the underlying listing view.
      return const <String, PublicProfileSummary>{};
    }
  }

  HomeProduct _applyToProduct(
    HomeProduct product,
    Map<String, PublicProfileSummary> summaries,
  ) {
    final store = product.store;
    if (store == null || store.isBusiness) return product;
    final summary = summaries[store.id];
    if (summary == null) return product;
    return HomeProduct(
      id: product.id,
      slug: product.slug,
      title: product.title,
      description: product.description,
      condition: product.condition,
      priceCents: product.priceCents,
      compareAtPriceCents: product.compareAtPriceCents,
      currency: product.currency,
      vatRate: product.vatRate,
      priceIncludesVat: product.priceIncludesVat,
      freeShipping: product.freeShipping,
      shippingCostCents: product.shippingCostCents,
      ratingAverage: product.ratingAverage,
      ratingCount: product.ratingCount,
      city: product.city,
      publishedAt: product.publishedAt,
      store: _applyToStore(store, summary),
      imageUrls: product.imageUrls,
      categoryId: product.categoryId,
      brandName: product.brandName,
      specifications: product.specifications,
      countryCode: product.countryCode,
    );
  }

  MarketplaceStore _applyToStore(
    MarketplaceStore store,
    PublicProfileSummary summary,
  ) {
    return store.copyWith(
      // Private sellers show their person display name, not any stale shop_name.
      shopName: (summary.displayName?.trim().isNotEmpty ?? false)
          ? summary.displayName!.trim()
          : store.shopName,
      avatarUrl: summary.avatarUrl ?? store.avatarUrl,
      city: (summary.city?.trim().isNotEmpty ?? false)
          ? summary.city
          : store.city,
      profileUsername: summary.username,
    );
  }
}
