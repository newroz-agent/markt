import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

String _snakeCase(String name) => name.replaceAllMapped(
  RegExp('[A-Z]'),
  (match) => '_${match[0]!.toLowerCase()}',
);

/// `public.directory_business_type`.
enum DirectoryType {
  restaurant,
  cafe,
  fastFood,
  doctor;

  String get databaseValue => _snakeCase(name);

  /// Restaurants, cafés and fast food share cuisines, menus and reviews.
  bool get isFood => this != doctor;

  static DirectoryType? fromDatabase(Object? value) =>
      values.firstWhereOrNull((type) => type.databaseValue == value);
}

/// `public.directory_cuisine`.
enum DirectoryCuisine {
  kurdish,
  syrian,
  turkish,
  arabic,
  persian,
  lebanese,
  iraqi,
  middleEastern,
  kebab,
  falafel,
  german,
  italian,
  mediterranean,
  indian,
  asian,
  international;

  String get databaseValue => _snakeCase(name);

  static DirectoryCuisine? fromDatabase(Object? value) =>
      values.firstWhereOrNull((cuisine) => cuisine.databaseValue == value);
}

/// `public.directory_spoken_language`.
enum SpokenLanguage {
  kurdish,
  arabic,
  turkish,
  german,
  english;

  String get databaseValue => name;

  static SpokenLanguage? fromDatabase(Object? value) =>
      values.firstWhereOrNull((language) => language.databaseValue == value);
}

/// `public.directory_doctor_specialty`.
enum DoctorSpecialty {
  generalMedicine,
  internalMedicine,
  pediatrics,
  gynecology,
  dermatology,
  orthopedics,
  neurology,
  psychiatry,
  ophthalmology,
  ent,
  dentistry,
  cardiology,
  urology,
  other;

  String get databaseValue => _snakeCase(name);

  static DoctorSpecialty? fromDatabase(Object? value) =>
      values.firstWhereOrNull((specialty) => specialty.databaseValue == value);
}

/// `public.directory_insurance`.
enum InsuranceAcceptance {
  statutory('statutory'),
  privateOnly('private'),
  both('both');

  const InsuranceAcceptance(this.databaseValue);

  final String databaseValue;

  static InsuranceAcceptance? fromDatabase(Object? value) =>
      values.firstWhereOrNull((insurance) => insurance.databaseValue == value);
}

/// The seller document kinds the directory flow asks for.
enum SellerDocumentKind {
  identity,
  businessRegistration,
  medicalProfessionalRegistration;

  String get databaseValue => _snakeCase(name);

  static SellerDocumentKind? fromDatabase(Object? value) =>
      values.firstWhereOrNull((kind) => kind.databaseValue == value);
}

/// `public.seller_document_status`.
enum SellerDocumentStatus {
  pending,
  approved,
  rejected;

  static SellerDocumentStatus fromDatabase(Object? value) =>
      values.firstWhereOrNull((status) => status.name == value) ?? pending;
}

@immutable
class DirectorySeller {
  const DirectorySeller({
    required this.id,
    required this.kind,
    required this.status,
    required this.shopName,
    required this.city,
    required this.directoryType,
  });

  factory DirectorySeller.fromJson(Map<String, dynamic> json) =>
      DirectorySeller(
        id: json['id']! as String,
        kind: json['kind']! as String,
        status: json['status']! as String,
        shopName: json['shop_name']! as String,
        city: json['city'] as String?,
        directoryType: DirectoryType.fromDatabase(json['directory_type']),
      );

  final String id;
  final String kind;
  final String status;
  final String shopName;
  final String? city;
  final DirectoryType? directoryType;

  bool get isBusiness => kind == 'business';
}

@immutable
class SellerDocument {
  const SellerDocument({
    required this.id,
    required this.kind,
    required this.status,
    required this.adminNote,
    required this.mimeType,
    required this.storagePath,
    required this.createdAt,
  });

  factory SellerDocument.fromJson(Map<String, dynamic> json) => SellerDocument(
    id: json['id']! as String,
    kind: SellerDocumentKind.fromDatabase(json['kind']),
    status: SellerDocumentStatus.fromDatabase(json['status']),
    adminNote: json['admin_note'] as String?,
    mimeType: json['mime_type']! as String,
    storagePath: json['storage_path']! as String,
    createdAt: DateTime.parse(json['created_at']! as String),
  );

  /// Null for kinds outside the directory flow (e.g. VAT certificates).
  final SellerDocumentKind? kind;
  final String id;
  final SellerDocumentStatus status;
  final String? adminNote;
  final String mimeType;
  final String storagePath;
  final DateTime createdAt;

  bool get isPdf => mimeType == 'application/pdf';
}

/// Owner-editable directory profile (`owner_upsert_directory_profile`).
@immutable
class DirectoryProfile {
  const DirectoryProfile({
    required this.type,
    required this.description,
    required this.phone,
    required this.languages,
    this.website,
    this.coverImagePath,
    this.cuisines = const <DirectoryCuisine>{},
    this.priceLevel,
    this.hasHalal = false,
    this.hasVegetarianOptions = false,
    this.hasVeganOptions = false,
    this.specialty,
    this.insurance,
    this.isPublished = false,
  });

  factory DirectoryProfile.fromJson(Map<String, dynamic> json) =>
      DirectoryProfile(
        type: DirectoryType.fromDatabase(json['type'])!,
        description: json['description']! as String,
        phone: json['phone']! as String,
        website: json['website'] as String?,
        coverImagePath: json['cover_image_path'] as String?,
        languages: _enumSet(json['languages'], SpokenLanguage.fromDatabase),
        cuisines: _enumSet(json['cuisines'], DirectoryCuisine.fromDatabase),
        priceLevel: (json['price_level'] as num?)?.toInt(),
        hasHalal: json['has_halal'] as bool? ?? false,
        hasVegetarianOptions: json['has_vegetarian_options'] as bool? ?? false,
        hasVeganOptions: json['has_vegan_options'] as bool? ?? false,
        specialty: DoctorSpecialty.fromDatabase(json['specialty']),
        insurance: InsuranceAcceptance.fromDatabase(json['insurance']),
        isPublished: json['is_published'] as bool? ?? false,
      );

  final DirectoryType type;
  final String description;
  final String phone;
  final String? website;
  final String? coverImagePath;
  final Set<SpokenLanguage> languages;
  final Set<DirectoryCuisine> cuisines;
  final int? priceLevel;
  final bool hasHalal;
  final bool hasVegetarianOptions;
  final bool hasVeganOptions;
  final DoctorSpecialty? specialty;
  final InsuranceAcceptance? insurance;
  final bool isPublished;

  DirectoryProfile copyWith({bool? isPublished}) => DirectoryProfile(
    type: type,
    description: description,
    phone: phone,
    website: website,
    coverImagePath: coverImagePath,
    languages: languages,
    cuisines: cuisines,
    priceLevel: priceLevel,
    hasHalal: hasHalal,
    hasVegetarianOptions: hasVegetarianOptions,
    hasVeganOptions: hasVeganOptions,
    specialty: specialty,
    insurance: insurance,
    isPublished: isPublished ?? this.isPublished,
  );

  /// Parameters for `owner_upsert_directory_profile`. Type-specific fields are
  /// cleared for the other type so the server's type checks always hold.
  Map<String, dynamic> toRpcParams() => <String, dynamic>{
    'p_type': type.databaseValue,
    'p_description': description.trim(),
    'p_phone': phone.trim(),
    'p_website': website?.trim(),
    'p_cover_image_path': coverImagePath,
    'p_languages': [for (final language in languages) language.databaseValue],
    'p_cuisines': type.isFood
        ? [for (final cuisine in cuisines) cuisine.databaseValue]
        : const <String>[],
    'p_price_level': type.isFood ? priceLevel : null,
    'p_has_halal': type.isFood && hasHalal,
    'p_has_vegetarian_options': type.isFood && hasVegetarianOptions,
    'p_has_vegan_options': type.isFood && hasVeganOptions,
    'p_specialty': type.isFood ? null : specialty?.databaseValue,
    'p_insurance': type.isFood ? null : insurance?.databaseValue,
    'p_is_published': isPublished,
  };

  static Set<T> _enumSet<T>(Object? raw, T? Function(Object?) parse) => {
    if (raw is List)
      for (final value in raw) ?parse(value),
  };
}

/// Minutes since midnight. 24:00 is the end of the day.
@immutable
class DirectoryTime implements Comparable<DirectoryTime> {
  const DirectoryTime(this.minutes)
    : assert(minutes >= 0 && minutes <= 24 * 60);

  factory DirectoryTime.parse(String value) {
    final [hour, minute] = value.split(':').take(2).map(int.parse).toList();
    return DirectoryTime(hour * 60 + minute);
  }

  final int minutes;

  int get hour => minutes ~/ 60;
  int get minute => minutes % 60;

  String get databaseValue =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  int compareTo(DirectoryTime other) => minutes.compareTo(other.minutes);

  @override
  bool operator ==(Object other) =>
      other is DirectoryTime && other.minutes == minutes;

  @override
  int get hashCode => minutes.hashCode;
}

/// A weekly opening interval. [weekday] follows the database (0 = Sunday).
/// A closing time before the opening time runs past midnight.
@immutable
class OpeningInterval {
  const OpeningInterval({
    required this.weekday,
    required this.opensAt,
    required this.closesAt,
  });

  factory OpeningInterval.fromJson(Map<String, dynamic> json) =>
      OpeningInterval(
        weekday: (json['weekday']! as num).toInt(),
        opensAt: DirectoryTime.parse(json['opens_at']! as String),
        closesAt: DirectoryTime.parse(json['closes_at']! as String),
      );

  final int weekday;
  final DirectoryTime opensAt;
  final DirectoryTime closesAt;

  bool get isOvernight => closesAt.minutes < opensAt.minutes;

  Map<String, dynamic> toJson(int sortOrder) => <String, dynamic>{
    'weekday': weekday,
    'opens_at': opensAt.databaseValue,
    'closes_at': closesAt.databaseValue,
    'sort_order': sortOrder,
  };

  @override
  bool operator ==(Object other) =>
      other is OpeningInterval &&
      other.weekday == weekday &&
      other.opensAt == opensAt &&
      other.closesAt == closesAt;

  @override
  int get hashCode => Object.hash(weekday, opensAt, closesAt);
}

@immutable
class MenuItemDraft {
  const MenuItemDraft({
    required this.name,
    required this.priceCents,
    this.description,
    this.isAvailable = true,
    this.isHalal = false,
    this.isVegetarian = false,
    this.isVegan = false,
  });

  factory MenuItemDraft.fromJson(Map<String, dynamic> json) => MenuItemDraft(
    name: json['name']! as String,
    description: json['description'] as String?,
    priceCents: (json['price_cents']! as num).toInt(),
    isAvailable: json['is_available'] as bool? ?? true,
    isHalal: json['is_halal'] as bool? ?? false,
    isVegetarian: json['is_vegetarian'] as bool? ?? false,
    isVegan: json['is_vegan'] as bool? ?? false,
  );

  final String name;
  final String? description;
  final int priceCents;
  final bool isAvailable;
  final bool isHalal;
  final bool isVegetarian;
  final bool isVegan;

  MenuItemDraft copyWith({bool? isAvailable}) => MenuItemDraft(
    name: name,
    description: description,
    priceCents: priceCents,
    isAvailable: isAvailable ?? this.isAvailable,
    isHalal: isHalal,
    isVegetarian: isVegetarian,
    isVegan: isVegan,
  );

  Map<String, dynamic> toJson(int sortOrder) => <String, dynamic>{
    'name': name.trim(),
    'description': description?.trim(),
    'price_cents': priceCents,
    'is_available': isAvailable,
    'is_halal': isHalal,
    // The server requires vegan items to be vegetarian as well.
    'is_vegetarian': isVegetarian || isVegan,
    'is_vegan': isVegan,
    'sort_order': sortOrder,
  };
}

@immutable
class MenuSectionDraft {
  const MenuSectionDraft({required this.name, this.items = const []});

  factory MenuSectionDraft.fromJson(Map<String, dynamic> json) =>
      MenuSectionDraft(
        name: json['name']! as String,
        items: [
          for (final item in json['items'] as List? ?? const <Object>[])
            MenuItemDraft.fromJson(Map<String, dynamic>.from(item as Map)),
        ],
      );

  final String name;
  final List<MenuItemDraft> items;

  MenuSectionDraft copyWith({String? name, List<MenuItemDraft>? items}) =>
      MenuSectionDraft(name: name ?? this.name, items: items ?? this.items);

  Map<String, dynamic> toJson(int sortOrder) => <String, dynamic>{
    'name': name.trim(),
    'sort_order': sortOrder,
    'items': [for (final (index, item) in items.indexed) item.toJson(index)],
  };
}

/// Everything the owner screens show (`get_my_directory_onboarding`).
@immutable
class DirectoryOnboarding {
  const DirectoryOnboarding({
    required this.seller,
    required this.isVerified,
    required this.requiredDocumentKinds,
    required this.documents,
    required this.profile,
    required this.hours,
    required this.menu,
  });

  factory DirectoryOnboarding.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> rows(String key) => [
      for (final row in json[key] as List? ?? const <Object>[])
        Map<String, dynamic>.from(row as Map),
    ];
    final seller = json['seller'];
    final profile = json['profile'];
    return DirectoryOnboarding(
      seller: seller is Map
          ? DirectorySeller.fromJson(Map<String, dynamic>.from(seller))
          : null,
      isVerified: json['is_verified'] as bool? ?? false,
      requiredDocumentKinds: [
        for (final kind in json['required_document_kinds'] as List? ?? [])
          ?SellerDocumentKind.fromDatabase(kind),
      ],
      documents: rows('documents').map(SellerDocument.fromJson).toList(),
      profile: profile is Map
          ? DirectoryProfile.fromJson(Map<String, dynamic>.from(profile))
          : null,
      hours: rows('hours').map(OpeningInterval.fromJson).toList(),
      menu: rows('menu').map(MenuSectionDraft.fromJson).toList(),
    );
  }

  static const empty = DirectoryOnboarding(
    seller: null,
    isVerified: false,
    requiredDocumentKinds: <SellerDocumentKind>[],
    documents: <SellerDocument>[],
    profile: null,
    hours: <OpeningInterval>[],
    menu: <MenuSectionDraft>[],
  );

  final DirectorySeller? seller;
  final bool isVerified;
  final List<SellerDocumentKind> requiredDocumentKinds;

  /// Newest first.
  final List<SellerDocument> documents;
  final DirectoryProfile? profile;
  final List<OpeningInterval> hours;
  final List<MenuSectionDraft> menu;

  DirectoryType? get directoryType => profile?.type ?? seller?.directoryType;

  bool get isPrivateSeller => seller != null && !seller!.isBusiness;

  /// The newest document of [kind], which decides what the owner sees.
  SellerDocument? latestDocument(SellerDocumentKind kind) =>
      documents.firstWhereOrNull((document) => document.kind == kind);

  int get approvedRequiredDocuments => requiredDocumentKinds
      .where(
        (kind) => latestDocument(kind)?.status == SellerDocumentStatus.approved,
      )
      .length;
}

/// A document file picked on the device, ready for the private bucket.
@immutable
class PickedDocumentFile {
  const PickedDocumentFile({
    required this.bytes,
    required this.mimeType,
    required this.extension,
  });

  /// The `seller-documents` bucket limit.
  static const maxBytes = 15 * 1024 * 1024;

  final Uint8List bytes;
  final String mimeType;
  final String extension;

  bool get isTooLarge => bytes.length > maxBytes;
}
