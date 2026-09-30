import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/features/auth/domain/auth_repository.dart';
import 'package:zerin_marketplace/features/auth/domain/auth_user.dart';
import 'package:zerin_marketplace/features/auth/presentation/controllers/auth_controller.dart';
import 'package:zerin_marketplace/features/categories/domain/marketplace_category.dart';
import 'package:zerin_marketplace/features/categories/presentation/controllers/category_controller.dart';
import 'package:zerin_marketplace/features/identity/data/active_identity_store.dart';
import 'package:zerin_marketplace/features/identity/domain/identity.dart';
import 'package:zerin_marketplace/features/identity/domain/identity_repository.dart';
import 'package:zerin_marketplace/features/identity/presentation/controllers/identity_controller.dart';
import 'package:zerin_marketplace/features/sell/domain/sell_image_service.dart';
import 'package:zerin_marketplace/features/sell/domain/sell_models.dart';
import 'package:zerin_marketplace/features/sell/domain/sell_repository.dart';
import 'package:zerin_marketplace/features/sell/presentation/controllers/sell_controller.dart';
import 'package:zerin_marketplace/features/sell/presentation/sell_foundation_screen.dart';
import 'package:zerin_marketplace/l10n/app_localizations.dart';

const _category = MarketplaceCategory(
  id: 'category-id',
  parentId: null,
  slug: 'elektronik',
  nameDe: 'Elektronik',
  nameEn: 'Electronics',
  nameAr: 'إلكترونيات',
  nameTr: 'Elektronik',
  nameKu: 'Elektronîk',
  iconKey: 'devices',
  imageUrl: '',
  sortOrder: 1,
);

final _photo = SellPhoto(
  bytes: base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
    '+A8AAQUBAScY42YAAAAASUVORK5CYII=',
  ),
  name: 'listing.webp',
);

const _user = AuthUser(id: 'sell-user', email: 'sell@example.invalid');
const _person = MarketplaceIdentity(
  type: MarketplaceIdentityType.person,
  sellerId: null,
  sellerKind: 'private',
  sellerStatus: null,
  label: 'Test Verkäufer',
  avatarUrl: null,
  username: 'test',
);
const _business = MarketplaceIdentity(
  type: MarketplaceIdentityType.business,
  sellerId: '22222222-2222-4222-8222-222222222222',
  sellerKind: 'business',
  sellerStatus: 'approved',
  label: 'Test Geschäft',
  avatarUrl: null,
  username: null,
);

class _FakeSellRepository implements SellRepository {
  final queries = <String>[];
  SellListingDraft? submittedDraft;

  @override
  Future<List<MyListing>> fetchMyListings(IdentityCatalog catalog) async =>
      const <MyListing>[];

  @override
  Future<List<ListingTemplate>> searchTemplates(String query) async {
    queries.add(query);
    return const <ListingTemplate>[
      ListingTemplate(
        id: 'template-id',
        title: 'Katalog Kamera',
        categoryId: 'category-id',
        condition: SellCondition.used,
        specifications: <String, dynamic>{'brand': 'Zêrîn'},
        imageUrl: 'https://example.invalid/template.webp',
      ),
    ];
  }

  @override
  Future<MyListing> submitListing(SellListingDraft draft) async {
    submittedDraft = draft;
    return MyListing(
      identity: draft.identity,
      id: 'listing-id',
      title: draft.title,
      priceCents: draft.priceCents,
      currency: 'EUR',
      city: draft.city,
      condition: draft.condition.databaseValue,
      status: ListingStatus.pendingReview,
      createdAt: DateTime.utc(2026, 9, 14),
      imageUrls: const <String>[],
    );
  }
}

class _AuthRepository implements AuthRepository {
  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthUser?> get authStateChanges => Stream.value(_user);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _IdentityRepository implements IdentityCatalogRepository {
  const _IdentityRepository(this.catalog);

  final IdentityCatalog catalog;

  @override
  Future<IdentityCatalog> fetchMyIdentityCatalog() async => catalog;
}

class _IdentityStore implements ActiveIdentityStore {
  _IdentityStore(this.selection);

  String? selection;

  @override
  String? read(String userId) => selection;

  @override
  Future<void> remove(String userId) async => selection = null;

  @override
  Future<void> write(String userId, String selectionKey) async =>
      selection = selectionKey;
}

class _FakeImageService implements SellImageService {
  @override
  Future<SellPhoto?> importTemplateImage(String imageUrl) async => _photo;

  @override
  Future<List<SellPhoto>> pickFromGallery() async => <SellPhoto>[_photo];

  @override
  Future<SellPhoto?> takePhoto() async => _photo;
}

Widget _app(
  _FakeSellRepository repository, {
  IdentityCatalog? catalog,
  String? activeSelection,
}) {
  final identities = catalog ?? IdentityCatalog(<MarketplaceIdentity>[_person]);
  return ProviderScope(
    overrides: <Override>[
      authRepositoryProvider.overrideWithValue(_AuthRepository()),
      authStateProvider.overrideWith((ref) => Stream.value(_user)),
      identityCatalogRepositoryProvider.overrideWithValue(
        _IdentityRepository(identities),
      ),
      activeIdentityStoreProvider.overrideWithValue(
        _IdentityStore(activeSelection),
      ),
      sellRepositoryProvider.overrideWithValue(repository),
      sellImageServiceProvider.overrideWithValue(_FakeImageService()),
      activeCategoriesProvider.overrideWith((ref) async => const [_category]),
    ],
    child: MaterialApp(
      locale: const Locale('de'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light,
      home: const SellFoundationScreen(),
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 150));
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await _settle(tester);
}

void main() {
  setUp(() => TestWidgetsFlutterBinding.ensureInitialized());

  testWidgets(
    'dual identities require confirmation and preselect active business',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = _FakeSellRepository();
      await tester.pumpWidget(
        _app(
          repository,
          catalog: IdentityCatalog(<MarketplaceIdentity>[_person, _business]),
          activeSelection: _business.selectionKey,
        ),
      );
      await _settle(tester);

      expect(find.text('Als Privatperson'), findsOneWidget);
      expect(find.text('Als Geschäft'), findsOneWidget);
      expect(find.byKey(const ValueKey('sell-catalog-step')), findsNothing);
      expect(
        tester
            .widget<ListTile>(
              find.byKey(const ValueKey('sell-identity-business')),
            )
            .selected,
        isTrue,
      );

      await tester.tap(find.byKey(const ValueKey('sell-identity-confirm')));
      await _settle(tester);
      expect(find.byKey(const ValueKey('sell-catalog-step')), findsOneWidget);
    },
  );

  testWidgets('switching a confirmed identity resets the entire draft', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeSellRepository();
    await tester.pumpWidget(
      _app(
        repository,
        catalog: IdentityCatalog(<MarketplaceIdentity>[_person, _business]),
        activeSelection: _person.selectionKey,
      ),
    );
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('sell-identity-confirm')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('sell-free-form')));
    await _settle(tester);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('sell-title-field')),
        matching: find.byType(EditableText),
      ),
      'Must be cleared',
    );

    await tester.tap(find.byKey(const ValueKey('sell-change-identity')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('sell-identity-business')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('sell-identity-confirm')));
    await _settle(tester);
    expect(find.byKey(const ValueKey('sell-catalog-step')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('sell-free-form')));
    await _settle(tester);

    final title = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const ValueKey('sell-title-field')),
        matching: find.byType(EditableText),
      ),
    );
    expect(title.controller.text, isEmpty);
    expect(find.text('Test Geschäft'), findsOneWidget);
  });

  testWidgets('catalog search applies a template in the unified flow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeSellRepository();
    await tester.pumpWidget(_app(repository));
    await _settle(tester);

    expect(find.byKey(const ValueKey('sell-catalog-step')), findsOneWidget);
    expect(find.text('Katalog Kamera'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'kamera');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await _settle(tester);
    expect(repository.queries, contains('kamera'));

    await tester.tap(find.text('Vorlage verwenden'));
    await _settle(tester);

    expect(find.byKey(const ValueKey('sell-details-step')), findsOneWidget);
    final title = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const ValueKey('sell-title-field')),
        matching: find.byType(EditableText),
      ),
    );
    expect(title.controller.text, 'Katalog Kamera');
  });

  testWidgets(
    'free-form listing reaches photo review and pending confirmation',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = _FakeSellRepository();
      await tester.pumpWidget(_app(repository));
      await _settle(tester);

      await tester.tap(find.byKey(const ValueKey('sell-free-form')));
      await _settle(tester);
      expect(find.byKey(const ValueKey('sell-details-step')), findsOneWidget);

      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('sell-title-field')),
          matching: find.byType(EditableText),
        ),
        'Freie Kamera',
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('sell-price-field')),
          matching: find.byType(EditableText),
        ),
        '149,99',
      );

      final city = find.byKey(const ValueKey('sell-city-null'));
      await _tapVisible(tester, city);
      await tester.tap(find.text('Berlin').last);
      await _settle(tester);

      final category = find.byKey(const ValueKey('sell-category-null'));
      await _tapVisible(tester, category);
      await tester.tap(find.text('Elektronik').last);
      await _settle(tester);

      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('sell-description-field')),
          matching: find.byType(EditableText),
        ),
        'Eine ausführliche Beschreibung der freien Kamera.',
      );
      await _tapVisible(
        tester,
        find.byKey(const ValueKey('sell-details-next')),
      );

      expect(find.byKey(const ValueKey('sell-photos-step')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('sell-pick-photos')));
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('sell-photos-next')));
      await _settle(tester);

      expect(find.byKey(const ValueKey('sell-review-step')), findsOneWidget);
      expect(find.text('Freie Kamera'), findsOneWidget);
      expect(find.text('Berlin'), findsOneWidget);
      expect(find.text('Elektronik'), findsOneWidget);

      await _tapVisible(tester, find.byKey(const ValueKey('sell-submit')));

      expect(find.byKey(const ValueKey('sell-confirmation')), findsOneWidget);
      expect(find.text('Angebot wird geprüft'), findsOneWidget);
      expect(repository.submittedDraft, isNotNull);
      expect(repository.submittedDraft!.sellerKind, SellSellerKind.private);
      expect(repository.submittedDraft!.identity.sellerId, isNull);
      expect(repository.submittedDraft!.identity.selectionKey, 'person');
      expect(repository.submittedDraft!.priceCents, 14999);
      expect(repository.submittedDraft!.photos, hasLength(1));
      expect(repository.submittedDraft!.city, 'Berlin');
    },
  );

  testWidgets(
    'compare-at price passes to the draft and lower values are rejected',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = _FakeSellRepository();
      await tester.pumpWidget(_app(repository));
      await _settle(tester);

      await tester.tap(find.byKey(const ValueKey('sell-free-form')));
      await _settle(tester);
      expect(find.byKey(const ValueKey('sell-details-step')), findsOneWidget);

      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('sell-title-field')),
          matching: find.byType(EditableText),
        ),
        'Kamera mit Streichpreis',
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('sell-price-field')),
          matching: find.byType(EditableText),
        ),
        '99,00',
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('sell-compare-at-price-field')),
          matching: find.byType(EditableText),
        ),
        '129,00',
      );

      final city = find.byKey(const ValueKey('sell-city-null'));
      await _tapVisible(tester, city);
      await tester.tap(find.text('Berlin').last);
      await _settle(tester);

      final category = find.byKey(const ValueKey('sell-category-null'));
      await _tapVisible(tester, category);
      await tester.tap(find.text('Elektronik').last);
      await _settle(tester);

      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('sell-description-field')),
          matching: find.byType(EditableText),
        ),
        'Eine ausführliche Beschreibung der Kamera mit Streichpreis.',
      );
      await _tapVisible(
        tester,
        find.byKey(const ValueKey('sell-details-next')),
      );

      expect(find.byKey(const ValueKey('sell-photos-step')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('sell-pick-photos')));
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('sell-photos-next')));
      await _settle(tester);
      await _tapVisible(tester, find.byKey(const ValueKey('sell-submit')));

      expect(find.byKey(const ValueKey('sell-confirmation')), findsOneWidget);
      expect(repository.submittedDraft, isNotNull);
      expect(repository.submittedDraft!.priceCents, 9900);
      expect(repository.submittedDraft!.compareAtPriceCents, 12900);
    },
  );

  testWidgets('compare-at price below the price blocks details continue', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeSellRepository();
    await tester.pumpWidget(_app(repository));
    await _settle(tester);

    await tester.tap(find.byKey(const ValueKey('sell-free-form')));
    await _settle(tester);

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('sell-title-field')),
        matching: find.byType(EditableText),
      ),
      'Kamera mit falschem Streichpreis',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('sell-price-field')),
        matching: find.byType(EditableText),
      ),
      '99,00',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('sell-compare-at-price-field')),
        matching: find.byType(EditableText),
      ),
      '49,00',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('sell-description-field')),
        matching: find.byType(EditableText),
      ),
      'Eine ausführliche Beschreibung der Kamera mit falschem Preis.',
    );

    final city = find.byKey(const ValueKey('sell-city-null'));
    await _tapVisible(tester, city);
    await tester.tap(find.text('Berlin').last);
    await _settle(tester);

    final category = find.byKey(const ValueKey('sell-category-null'));
    await _tapVisible(tester, category);
    await tester.tap(find.text('Elektronik').last);
    await _settle(tester);

    await _tapVisible(tester, find.byKey(const ValueKey('sell-details-next')));

    expect(
      find.text('Der Originalpreis muss höher als dein Preis sein.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('sell-details-step')), findsOneWidget);
    expect(repository.submittedDraft, isNull);
  });
}
