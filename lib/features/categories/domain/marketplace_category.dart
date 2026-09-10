import 'package:flutter/foundation.dart';

@immutable
class MarketplaceCategory {
  const MarketplaceCategory({
    required this.id,
    required this.parentId,
    required this.slug,
    required this.nameDe,
    required this.nameEn,
    required this.nameAr,
    required this.nameTr,
    this.nameKu,
    required this.iconKey,
    required this.imageUrl,
    required this.sortOrder,
  });

  factory MarketplaceCategory.fromJson(Map<String, dynamic> json) {
    return MarketplaceCategory(
      id: json['id']! as String,
      parentId: json['parent_id'] as String?,
      slug: json['slug']! as String,
      nameDe: json['name_de']! as String,
      nameEn: json['name_en']! as String,
      nameAr: json['name_ar']! as String,
      nameTr: json['name_tr']! as String,
      nameKu: json['name_ku'] as String?,
      iconKey: json['icon_key']! as String,
      imageUrl: json['image_url']! as String,
      sortOrder: json['sort_order']! as int,
    );
  }

  final String id;
  final String? parentId;
  final String slug;
  final String nameDe;
  final String nameEn;
  final String nameAr;
  final String nameTr;
  final String? nameKu;
  final String iconKey;
  final String imageUrl;
  final int sortOrder;

  bool get isRoot => parentId == null;

  String nameForLanguage(String languageCode) => switch (languageCode) {
    'en' => nameEn,
    'ar' => nameAr,
    'tr' => nameTr,
    // Kurdish is first-class; unreviewed rows fall back to German.
    'ku' => nameKu ?? nameDe,
    _ => nameDe,
  };
}
