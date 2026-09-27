import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zerin_marketplace/app/router/app_router.dart';
import 'package:zerin_marketplace/features/auth/domain/auth_user.dart';
import 'package:zerin_marketplace/features/auth/presentation/controllers/auth_controller.dart';
import 'package:zerin_marketplace/features/business/domain/business_models.dart';
import 'package:zerin_marketplace/features/business/domain/business_repository.dart';
import 'package:zerin_marketplace/features/business/presentation/controllers/business_controller.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

const testUser = AuthUser(id: 'owner', email: 'owner@example.invalid');
const testSellerId = '11111111-1111-4111-8111-111111111111';

DirectorySeller businessSeller({
  DirectoryType? type = DirectoryType.restaurant,
  String kind = 'business',
}) => DirectorySeller(
  id: testSellerId,
  kind: kind,
  status: 'pending',
  shopName: 'Zagros Grill',
  city: 'Berlin',
  directoryType: type,
);

SellerDocument document(
  SellerDocumentKind kind,
  SellerDocumentStatus status, {
  String? note,
}) => SellerDocument(
  id: 'doc-${kind.name}',
  kind: kind,
  status: status,
  adminNote: note,
  mimeType: 'application/pdf',
  storagePath: '$testSellerId/${kind.databaseValue}/1.pdf',
  createdAt: DateTime.utc(2026, 9, 27, 10),
);

const restaurantProfile = DirectoryProfile(
  type: DirectoryType.restaurant,
  description: 'Kurdische Küche mit Grillgerichten aus Duhok.',
  phone: '030 1234567',
  languages: {SpokenLanguage.german, SpokenLanguage.kurdish},
  cuisines: {DirectoryCuisine.kurdish},
  priceLevel: 2,
  hasHalal: true,
);

DirectoryOnboarding onboarding({
  DirectorySeller? seller,
  bool isVerified = false,
  List<SellerDocument> documents = const [],
  DirectoryProfile? profile,
  List<OpeningInterval> hours = const [],
  List<MenuSectionDraft> menu = const [],
}) {
  final type = profile?.type ?? seller?.directoryType;
  return DirectoryOnboarding(
    seller: seller,
    isVerified: isVerified,
    requiredDocumentKinds: type == null
        ? const []
        : type == DirectoryType.doctor
        ? const [
            SellerDocumentKind.identity,
            SellerDocumentKind.medicalProfessionalRegistration,
          ]
        : const [
            SellerDocumentKind.identity,
            SellerDocumentKind.businessRegistration,
          ],
    documents: documents,
    profile: profile,
    hours: hours,
    menu: menu,
  );
}

class FakeBusinessRepository implements BusinessRepository {
  FakeBusinessRepository(this.state);

  DirectoryOnboarding state;
  final calls = <String>[];
  DirectoryType? startedType;
  String? startedName;
  String? startedCity;
  ({SellerDocumentKind kind, PickedDocumentFile file})? uploaded;
  SellerDocument? withdrawn;
  DirectoryProfile? savedProfile;
  List<OpeningInterval>? savedHours;
  List<MenuSectionDraft>? savedMenu;

  @override
  Future<DirectoryOnboarding> fetchOnboarding() async => state;

  @override
  Future<DirectoryOnboarding> startDirectory({
    required DirectoryType type,
    String? shopName,
    String? city,
  }) async {
    calls.add('start');
    startedType = type;
    startedName = shopName;
    startedCity = city;
    state = onboarding(seller: businessSeller(type: type));
    return state;
  }

  @override
  Future<void> uploadDocument({
    required String sellerId,
    required SellerDocumentKind kind,
    required PickedDocumentFile file,
  }) async {
    calls.add('upload');
    uploaded = (kind: kind, file: file);
  }

  @override
  Future<void> withdrawDocument(SellerDocument document) async {
    calls.add('withdraw');
    withdrawn = document;
  }

  @override
  Future<void> saveProfile(DirectoryProfile profile) async {
    calls.add('profile');
    savedProfile = profile;
  }

  @override
  Future<String> uploadCover({
    required String sellerId,
    required Uint8List webpBytes,
  }) async => '$sellerId/cover.webp';

  @override
  String? coverUrl(String? storagePath) => null;

  @override
  Future<void> saveHours(List<OpeningInterval> intervals) async {
    calls.add('hours');
    savedHours = intervals;
  }

  @override
  Future<void> saveMenu(List<MenuSectionDraft> sections) async {
    calls.add('menu');
    savedMenu = sections;
  }
}

class FakeDocumentFileService implements DocumentFileService {
  static final pdf = PickedDocumentFile(
    bytes: Uint8List.fromList('%PDF-1.4 test'.codeUnits),
    mimeType: 'application/pdf',
    extension: 'pdf',
  );

  @override
  Future<PickedDocumentFile?> takePhoto() async => null;

  @override
  Future<PickedDocumentFile?> pickImage() async => null;

  @override
  Future<PickedDocumentFile?> pickPdf() async => pdf;

  @override
  Future<Uint8List?> pickCoverImage() async => null;
}

/// Pumps the real routes at [location] in German with fake owner data.
Future<GoRouter> pumpBusiness(
  WidgetTester tester,
  FakeBusinessRepository repository, {
  required String location,
  double logicalHeight = 844,
}) async {
  tester.view.physicalSize = Size(1170, logicalHeight * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final router = GoRouter(initialLocation: location, routes: $appRoutes);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        authStateProvider.overrideWith((ref) => Stream.value(testUser)),
        businessRepositoryProvider.overrideWithValue(repository),
        documentFileServiceProvider.overrideWithValue(
          FakeDocumentFileService(),
        ),
      ],
      child: MaterialApp.router(
        locale: const Locale('de'),
        supportedLocales: AppLocale.supportedLocales,
        localizationsDelegates: AppLocale.localizationsDelegates,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}
