import 'package:flutter/foundation.dart';

@immutable
class ModerationCounts {
  const ModerationCounts({required this.pending, required this.approvedToday, required this.rejectedToday});
  factory ModerationCounts.fromJson(Map<String, dynamic> json) => ModerationCounts(pending: (json['pending'] as num?)?.toInt() ?? 0, approvedToday: (json['approved_today'] as num?)?.toInt() ?? 0, rejectedToday: (json['rejected_today'] as num?)?.toInt() ?? 0);
  final int pending;
  final int approvedToday;
  final int rejectedToday;
}

@immutable
class ModerationItem {
  const ModerationItem({required this.id, required this.title, required this.description, required this.condition, required this.priceCents, required this.currency, required this.city, required this.specifications, required this.createdAt, required this.sellerName, required this.sellerKind, required this.categoryNames, required this.imageUrls});
  factory ModerationItem.fromJson(Map<String, dynamic> json) {
    final seller = Map<String, dynamic>.from(json['seller'] as Map);
    final category = Map<String, dynamic>.from(json['category'] as Map);
    final images = (json['images'] as List? ?? const <Object>[]).whereType<Map<Object?, Object?>>().map(Map<String, dynamic>.from).toList()..sort((a,b)=>((a['sort_order'] as num?)??0).compareTo((b['sort_order'] as num?)??0));
    return ModerationItem(id: json['id']! as String, title: json['title']! as String, description: json['description']! as String, condition: json['condition']! as String, priceCents: (json['price_cents'] as num).toInt(), currency: json['currency'] as String? ?? 'EUR', city: json['city']! as String, specifications: json['specifications'] is Map ? Map<String,dynamic>.unmodifiable(Map<String,dynamic>.from(json['specifications'] as Map)) : const {}, createdAt: DateTime.parse(json['created_at']! as String), sellerName: seller['name']! as String, sellerKind: seller['kind']! as String, categoryNames: Map<String,String>.unmodifiable({for(final code in const ['de','en','ar','tr','ku']) if(category['name_$code'] is String) code:category['name_$code'] as String}), imageUrls: List<String>.unmodifiable(images.map((image)=>image['image_url']).whereType<String>().where((url)=>url.isNotEmpty)));
  }
  final String id,title,description,condition,currency,city,sellerName,sellerKind;
  final int priceCents;
  final Map<String,dynamic> specifications;
  final DateTime createdAt;
  final Map<String,String> categoryNames;
  final List<String> imageUrls;
  String categoryName(String languageCode)=>categoryNames[languageCode]??categoryNames['de']??'';
}

@immutable
class ModerationDashboard {
  const ModerationDashboard({required this.counts,required this.items});
  factory ModerationDashboard.fromJson(Map<String,dynamic> json)=>ModerationDashboard(counts:ModerationCounts.fromJson(Map<String,dynamic>.from(json['counts'] as Map)),items:(json['items'] as List? ?? const <Object>[]).whereType<Map<Object?,Object?>>().map((item)=>ModerationItem.fromJson(Map<String,dynamic>.from(item))).toList(growable:false));
  final ModerationCounts counts;
  final List<ModerationItem> items;
}

enum ModerationDecision { approve, reject }
enum SellerDocumentDecision { approve, reject }
enum ReportAction { dismiss, blockListing }

@immutable
class SellerDocumentItem {
  const SellerDocumentItem({required this.id,required this.sellerId,required this.kind,required this.mimeType,required this.createdAt,required this.shopName,required this.sellerKind,required this.signedUrl});
  factory SellerDocumentItem.fromJson(Map<String,dynamic> json)=>SellerDocumentItem(id:json['id'] as String,sellerId:json['seller_id'] as String,kind:json['kind'] as String,mimeType:json['mime_type'] as String,createdAt:DateTime.parse(json['created_at'] as String),shopName:json['shop_name'] as String,sellerKind:json['seller_kind'] as String,signedUrl:json['signed_url'] as String?);
  final String id,sellerId,kind,mimeType,shopName,sellerKind;
  final DateTime createdAt;
  final String? signedUrl;
}

@immutable
class SellerVerificationQueue {
  const SellerVerificationQueue({required this.items,required this.pending});
  factory SellerVerificationQueue.fromJson(Map<String,dynamic> json)=>SellerVerificationQueue(items:(json['items'] as List? ?? const <Object>[]).whereType<Map<Object?,Object?>>().map((item)=>SellerDocumentItem.fromJson(Map<String,dynamic>.from(item))).toList(growable:false),pending:(json['pending'] as num?)?.toInt()??0);
  final List<SellerDocumentItem> items;
  final int pending;
}

@immutable
class ModerationReport {
  const ModerationReport({required this.id,required this.productId,required this.sellerId,required this.reviewId,required this.messageId,required this.reporterId,required this.reason,required this.details,required this.status,required this.createdAt,required this.targetType, required this.title,required this.productStatus,required this.shopName, required this.messageKind, required this.messageBody, required this.messageMediaPath, required this.messageProductId});
  factory ModerationReport.fromJson(Map<String,dynamic> json)=>ModerationReport(id:json['id'] as String,productId:json['product_id'] as String?,sellerId:json['seller_id'] as String?,reviewId:json['review_id'] as String?,messageId:json['message_id'] as String?,reporterId:json['reporter_id'] as String?,targetType:json['target_type'] as String,reason:json['reason'] as String,details:json['details'] as String?,status:json['status'] as String,createdAt:DateTime.parse(json['created_at'] as String),title:json['title'] as String?,productStatus:json['product_status'] as String?,shopName:json['shop_name'] as String?,messageKind:json['message_kind'] as String?,messageBody:json['message_body'] as String?,messageMediaPath:json['message_media_path'] as String?,messageProductId:json['message_product_id'] as String?);
  final String id,reason,status,targetType;
  final String? productId,sellerId,reviewId,messageId,reporterId,details,title,productStatus,shopName,messageKind,messageBody,messageMediaPath,messageProductId;
  final DateTime createdAt;
}

@immutable
class ModerationReportsQueue {
  const ModerationReportsQueue({required this.items,required this.open});
  factory ModerationReportsQueue.fromJson(Map<String,dynamic> json)=>ModerationReportsQueue(items:(json['items'] as List? ?? const <Object>[]).whereType<Map<Object?,Object?>>().map((item)=>ModerationReport.fromJson(Map<String,dynamic>.from(item))).toList(growable:false),open:(json['open'] as num?)?.toInt()??0);
  final List<ModerationReport> items;
  final int open;
}
