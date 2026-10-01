import 'package:flutter/foundation.dart';
import 'package:zerin_marketplace/features/identity/domain/identity.dart';

enum SellSellerKind {
  private('private'),
  business('business');

  const SellSellerKind(this.databaseValue);
  final String databaseValue;
}

enum SellCondition {
  newItem('new'),
  used('used');

  const SellCondition(this.databaseValue);
  final String databaseValue;
}

enum ListingStatus {
  draft('draft'),
  pendingReview('pending_review'),
  active('active'),
  rejected('rejected'),
  sold('sold'),
  blocked('blocked');

  const ListingStatus(this.databaseValue);
  final String databaseValue;

  static ListingStatus fromDatabase(String value) => values.firstWhere(
    (status) => status.databaseValue == value,
    orElse: () => ListingStatus.draft,
  );
}

@immutable
class SellPhoto {
  const SellPhoto({required this.bytes, required this.name});

  final Uint8List bytes;
  final String name;
}

@immutable
class ListingTemplate {
  const ListingTemplate({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.condition,
    required this.specifications,
    this.imageUrl,
  });

  factory ListingTemplate.fromJson(Map<String, dynamic> json) {
    final images =
        (json['images'] as List? ?? const <Object>[])
            .whereType<Map<Object?, Object?>>()
            .map(Map<String, dynamic>.from)
            .toList()
          ..sort(
            (a, b) => ((a['sort_order'] as num?) ?? 0).compareTo(
              (b['sort_order'] as num?) ?? 0,
            ),
          );
    return ListingTemplate(
      id: json['id']! as String,
      title: json['title']! as String,
      categoryId: json['category_id']! as String,
      condition: (json['condition'] as String?) == 'new'
          ? SellCondition.newItem
          : SellCondition.used,
      specifications: Map<String, dynamic>.unmodifiable(
        json['specifications'] is Map
            ? Map<String, dynamic>.from(json['specifications'] as Map)
            : const <String, dynamic>{},
      ),
      imageUrl: images.isEmpty ? null : images.first['image_url'] as String?,
    );
  }

  final String id;
  final String title;
  final String categoryId;
  final SellCondition condition;
  final Map<String, dynamic> specifications;
  final String? imageUrl;
}

@immutable
class SellerIdentity {
  const SellerIdentity({
    required this.id,
    required this.kind,
    required this.name,
  });

  final String id;
  final SellSellerKind kind;
  final String name;
}

@immutable
class PreparedListingSubmission {
  const PreparedListingSubmission({
    required this.productId,
    required this.seller,
  });

  factory PreparedListingSubmission.fromJson(Map<String, dynamic> json) =>
      PreparedListingSubmission(
        productId: json['product_id']! as String,
        seller: SellerIdentity(
          id: json['seller_id']! as String,
          kind: (json['seller_kind'] as String?) == 'business'
              ? SellSellerKind.business
              : SellSellerKind.private,
          name: json['seller_name']! as String,
        ),
      );

  final String productId;
  final SellerIdentity seller;
}

@immutable
class SellListingDraft {
  const SellListingDraft({
    required this.identity,
    required this.title,
    required this.priceCents,
    this.compareAtPriceCents,
    required this.city,
    required this.categoryId,
    required this.condition,
    required this.description,
    required this.photos,
    this.specifications = const <String, dynamic>{},
  });

  final MarketplaceIdentity identity;
  SellSellerKind get sellerKind =>
      identity.isBusiness ? SellSellerKind.business : SellSellerKind.private;
  String get sellerName => identity.label;
  final String title;
  final int priceCents;

  /// Optional crossed-out original price. When set, the server requires it
  /// to be strictly greater than [priceCents]; null means no deal flag.
  final int? compareAtPriceCents;
  final String city;
  final String categoryId;
  final SellCondition condition;
  final String description;
  final List<SellPhoto> photos;
  final Map<String, dynamic> specifications;
}

@immutable
class MyListing {
  const MyListing({
    required this.identity,
    required this.id,
    required this.title,
    required this.priceCents,
    required this.currency,
    required this.city,
    required this.condition,
    required this.status,
    required this.createdAt,
    required this.imageUrls,
    this.moderationReason,
  });

  factory MyListing.fromJson(
    Map<String, dynamic> json, {
    required MarketplaceIdentity identity,
  }) {
    final imageRows =
        (json['images'] as List? ?? const <Object>[])
            .whereType<Map<Object?, Object?>>()
            .map(Map<String, dynamic>.from)
            .toList()
          ..sort(
            (a, b) => ((a['sort_order'] as num?) ?? 0).compareTo(
              (b['sort_order'] as num?) ?? 0,
            ),
          );
    return MyListing(
      identity: identity,
      id: json['id']! as String,
      title: json['title']! as String,
      priceCents: json['price_cents']! as int,
      currency: json['currency'] as String? ?? 'EUR',
      city: json['city']! as String,
      condition: json['condition']! as String,
      status: ListingStatus.fromDatabase(json['status']! as String),
      moderationReason: json['moderation_reason'] as String?,
      createdAt: DateTime.parse(json['created_at']! as String),
      imageUrls: List<String>.unmodifiable(
        imageRows
            .map((image) => image['image_url'])
            .whereType<String>()
            .where((url) => url.isNotEmpty),
      ),
    );
  }

  final MarketplaceIdentity identity;
  final String id;
  final String title;
  final int priceCents;
  final String currency;
  final String city;
  final String condition;
  final ListingStatus status;
  final String? moderationReason;
  final DateTime createdAt;
  final List<String> imageUrls;
}
