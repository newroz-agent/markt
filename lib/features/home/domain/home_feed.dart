import 'package:flutter/foundation.dart';

@immutable
class AdCampaign {
  const AdCampaign({
    required this.id,
    required this.slug,
    required this.titleI18n,
    required this.subtitleI18n,
    required this.imageUrl,
    required this.sortOrder,
  });

  factory AdCampaign.fromJson(Map<String, dynamic> json) {
    return AdCampaign(
      id: json['id']! as String,
      slug: json['slug']! as String,
      titleI18n: _stringMap(json['title_i18n']),
      subtitleI18n: _stringMap(json['subtitle_i18n']),
      imageUrl: json['image_url']! as String,
      sortOrder: json['sort_order']! as int,
    );
  }

  final String id;
  final String slug;
  final Map<String, String> titleI18n;
  final Map<String, String> subtitleI18n;
  final String imageUrl;
  final int sortOrder;

  String titleForLanguage(String languageCode) =>
      _localized(titleI18n, languageCode);

  String subtitleForLanguage(String languageCode) =>
      _localized(subtitleI18n, languageCode);
}

@immutable
class MarketplaceStore {
  const MarketplaceStore({
    required this.id,
    required this.slug,
    required this.shopName,
    required this.bio,
    required this.avatarUrl,
    required this.bannerUrl,
    required this.city,
    required this.ratingAverage,
    required this.ratingCount,
    required this.responseTimeMinutes,
    this.sellerKind,
    this.verified,
    this.countryCode,
  });

  factory MarketplaceStore.fromJson(Map<String, dynamic> json) {
    return MarketplaceStore(
      id: json['id']! as String,
      slug: json['slug']! as String,
      shopName: json['shop_name']! as String,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bannerUrl: json['banner_url'] as String?,
      city: json['city'] as String?,
      countryCode: json['country_code'] as String?,
      ratingAverage: (json['rating_average'] as num?)?.toDouble() ?? 0,
      ratingCount: json['rating_count'] as int? ?? 0,
      responseTimeMinutes: json['response_time_minutes'] as int?,
      sellerKind: json['kind'] as String?,
      verified: json['verified'] as bool?,
    );
  }

  final String id;
  final String slug;
  final String shopName;
  final String? bio;
  final String? avatarUrl;
  final String? bannerUrl;
  final String? city;
  final String? countryCode;
  final double ratingAverage;
  final int ratingCount;
  final int? responseTimeMinutes;

  /// `public.seller_kind`: `private` or `business`. Null when not selected.
  final String? sellerKind;

  /// Approved business seller with approved identity AND business registration
  /// documents; null when not fetched. Approval alone never implies a badge.
  final bool? verified;

  bool get isBusiness => sellerKind == 'business';
}

@immutable
class HomeProduct {
  const HomeProduct({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    required this.condition,
    required this.priceCents,
    required this.compareAtPriceCents,
    required this.currency,
    required this.vatRate,
    required this.priceIncludesVat,
    required this.freeShipping,
    required this.shippingCostCents,
    required this.ratingAverage,
    required this.ratingCount,
    required this.city,
    required this.publishedAt,
    required this.store,
    required this.imageUrls,
    this.categoryId,
    this.brandName,
    this.specifications = const <String, dynamic>{},
    this.countryCode,
  });

  factory HomeProduct.fromJson(Map<String, dynamic> json) {
    final seller = _mapOrNull(json['seller'] ?? json['sellers']);
    final imageRows =
        (json['images'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList()
          ..sort((a, b) {
            final order = ((a['sort_order'] as num?) ?? 0).compareTo(
              (b['sort_order'] as num?) ?? 0,
            );
            return order != 0
                ? order
                : (a['image_url'] as String? ?? '').compareTo(
                    b['image_url'] as String? ?? '',
                  );
          });
    final imageUrls = <String>[
      for (final image in imageRows)
        if (image['image_url'] is String &&
            (image['image_url'] as String).isNotEmpty)
          image['image_url'] as String,
    ];

    return HomeProduct(
      id: json['id']! as String,
      slug: json['slug']! as String,
      title: json['title']! as String,
      description: json['description']! as String,
      condition: json['condition']! as String,
      priceCents: json['price_cents']! as int,
      compareAtPriceCents: json['compare_at_price_cents'] as int?,
      currency: json['currency']! as String,
      vatRate: (json['vat_rate'] as num?)?.toDouble() ?? 19,
      priceIncludesVat: json['price_includes_vat'] as bool? ?? true,
      freeShipping: json['free_shipping'] as bool? ?? false,
      shippingCostCents: json['shipping_cost_cents'] as int? ?? 0,
      ratingAverage: (json['rating_average'] as num?)?.toDouble() ?? 0,
      ratingCount: json['rating_count'] as int? ?? 0,
      city: json['city'] as String?,
      countryCode: json['country_code'] as String?,
      publishedAt: DateTime.parse(json['published_at']! as String),
      store: seller == null ? null : MarketplaceStore.fromJson(seller),
      imageUrls: List<String>.unmodifiable(imageUrls),
      categoryId: json['category_id'] as String?,
      brandName: _mapOrNull(json['brand'])?['name'] as String?,
      specifications: Map<String, dynamic>.unmodifiable(
        _mapOrNull(json['specifications']) ?? const <String, dynamic>{},
      ),
    );
  }

  final String id;
  final String slug;
  final String title;
  final String description;
  final String condition;
  final int priceCents;
  final int? compareAtPriceCents;
  final String currency;
  final double vatRate;
  final bool priceIncludesVat;
  final bool freeShipping;
  final int shippingCostCents;
  final double ratingAverage;
  final int ratingCount;
  final String? city;
  final String? countryCode;
  final DateTime publishedAt;
  final MarketplaceStore? store;
  final List<String> imageUrls;
  final String? categoryId;
  final String? brandName;
  final Map<String, dynamic> specifications;

  bool get isDiscounted =>
      compareAtPriceCents != null && compareAtPriceCents! > priceCents;

  int get discountPercent => isDiscounted
      ? ((1 - priceCents / compareAtPriceCents!) * 100).round()
      : 0;
}

@immutable
class HomeFeed {
  const HomeFeed({
    required this.campaigns,
    required this.newArrivals,
    required this.deals,
    required this.popularStores,
  });

  final List<AdCampaign> campaigns;
  final List<HomeProduct> newArrivals;
  final List<HomeProduct> deals;
  final List<MarketplaceStore> popularStores;
}

Map<String, String> _stringMap(Object? value) {
  if (value is! Map) return const <String, String>{};
  return <String, String>{
    for (final entry in value.entries)
      if (entry.key is String && entry.value is String)
        entry.key as String: entry.value as String,
  };
}

Map<String, dynamic>? _mapOrNull(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

String _localized(Map<String, String> values, String languageCode) {
  return values[languageCode] ??
      values['de'] ??
      values.values.firstOrNull ??
      '';
}

extension on Iterable<String> {
  String? get firstOrNull => isEmpty ? null : first;
}
