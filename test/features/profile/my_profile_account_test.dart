import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerin_marketplace/core/providers/infrastructure_providers.dart';
import 'package:zerin_marketplace/features/account/presentation/account_screen.dart';
import 'package:zerin_marketplace/features/auth/domain/auth_repository.dart';
import 'package:zerin_marketplace/features/auth/domain/auth_user.dart';
import 'package:zerin_marketplace/features/auth/presentation/controllers/auth_controller.dart';
import 'package:zerin_marketplace/features/chat/presentation/controllers/chat_controller.dart';
import 'package:zerin_marketplace/features/identity/data/active_identity_store.dart';
import 'package:zerin_marketplace/features/identity/domain/identity.dart';
import 'package:zerin_marketplace/features/identity/domain/identity_repository.dart';
import 'package:zerin_marketplace/features/identity/presentation/controllers/identity_controller.dart';
import 'package:zerin_marketplace/features/moderation/presentation/controllers/moderation_controller.dart';
import 'package:zerin_marketplace/features/profile/domain/profile.dart';
import 'package:zerin_marketplace/features/profile/presentation/controllers/profile_controller.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

const _user = AuthUser(
  id: 'account-user',
  email: 'private@example.invalid',
  displayName: 'Auth Name',
);
const _privateSellerId = '11111111-1111-4111-8111-111111111111';
const _businessSellerId = '22222222-2222-4222-8222-222222222222';

const _profile = MyProfile(
  displayName: 'Alice Public',
  username: 'alice_name',
  city: 'Berlin',
  bio: 'A public biography.',
  avatarUrl: null,
  listingCount: 4,
  seller: null,
);

MarketplaceIdentity _person({String? sellerId}) => MarketplaceIdentity(
  type: MarketplaceIdentityType.person,
  sellerId: sellerId,
  sellerKind: 'private',
  sellerStatus: sellerId == null ? null : 'approved',
  label: 'Alice Person',
  avatarUrl: null,
  username: 'alice_name',
);

MarketplaceIdentity _business({bool verified = false, String? status}) =>
    MarketplaceIdentity(
      type: MarketplaceIdentityType.business,
      sellerId: _businessSellerId,
      sellerKind: 'business',
      sellerStatus: status ?? (verified ? 'approved' : 'pending'),
      label: 'Zagros Store',
      avatarUrl: null,
      username: null,
    );

class _AuthRepository implements AuthRepository {
  const _AuthRepository();

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthUser?> get authStateChanges => Stream<AuthUser?>.value(_user);

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

Future<SharedPreferences> _pumpAccount(
  WidgetTester tester,
  Locale locale, {
  MyProfile profile = _profile,
  required IdentityCatalog catalog,
  String? storedSelection,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    '${SharedPreferencesActiveIdentityStore.keyPrefix}${_user.id}':
        ?storedSelection,
  });
  final preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(preferences),
        authRepositoryProvider.overrideWithValue(const _AuthRepository()),
        authStateProvider.overrideWith((ref) => Stream.value(_user)),
        identityCatalogRepositoryProvider.overrideWithValue(
          _IdentityRepository(catalog),
        ),
        myProfileProvider.overrideWith((ref) async => profile),
        unreadChatCountProvider.overrideWith((ref) async => 2),
        currentUserIsAdminProvider.overrideWith((ref) async => false),
      ],
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppLocale.supportedLocales,
        localizationsDelegates: AppLocale.localizationsDelegates,
        home: const AccountScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return preferences;
}

Semantics _semanticsWithin(WidgetTester tester, Key key) =>
    tester.widget<Semantics>(
      find
          .descendant(of: find.byKey(key), matching: find.byType(Semantics))
          .first,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('own profile header stays personal and never shows email', (
    tester,
  ) async {
    await _pumpAccount(
      tester,
      const Locale('en'),
      catalog: IdentityCatalog(<MarketplaceIdentity>[_person()]),
    );

    expect(find.text('Alice Public'), findsOneWidget);
    expect(find.text('@alice_name'), findsOneWidget);
    expect(find.text('Berlin'), findsOneWidget);
    expect(find.text('4 listings'), findsOneWidget);
    expect(find.text('A public biography.'), findsOneWidget);
    expect(find.textContaining('private@example'), findsNothing);
    expect(find.text('Edit profile'), findsOneWidget);
    expect(find.text('Public profile'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Messages'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Your selling profiles'), findsOneWidget);
    expect(find.text('Private person'), findsOneWidget);
    expect(find.text('Register a business'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Recently viewed'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('My listings'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Recently viewed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('legal area shows the OpenStreetMap ODbL attribution', (
    tester,
  ) async {
    await _pumpAccount(
      tester,
      const Locale('de'),
      catalog: IdentityCatalog(<MarketplaceIdentity>[_person()]),
    );

    await tester.scrollUntilVisible(
      find.text('Datenquellen'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text(
        'Karten- und Ortsdaten © OpenStreetMap-Mitwirkende, lizenziert unter '
        'der Open Database License (ODbL).',
      ),
      findsOneWidget,
    );
  });

  testWidgets('private-only user always sees business registration', (
    tester,
  ) async {
    await _pumpAccount(
      tester,
      const Locale('de'),
      profile: const MyProfile(
        displayName: 'Alice Public',
        username: 'alice_name',
        city: 'Berlin',
        bio: null,
        avatarUrl: null,
        listingCount: 1,
        seller: ProfileSeller(
          id: _privateSellerId,
          kind: 'private',
          verified: false,
        ),
      ),
      catalog: IdentityCatalog(<MarketplaceIdentity>[
        _person(sellerId: _privateSellerId),
      ]),
    );

    expect(
      find.byKey(const ValueKey('account-person-identity')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('account-register-business')),
      findsOneWidget,
    );
    expect(find.text('Geschäft registrieren'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('account-business-identity')),
      findsNothing,
    );
  });

  testWidgets(
    'dual user sees both identities, status and active highlighting',
    (tester) async {
      final person = _person(sellerId: _privateSellerId);
      final business = _business();
      final preferences = await _pumpAccount(
        tester,
        const Locale('de'),
        catalog: IdentityCatalog(<MarketplaceIdentity>[person, business]),
      );

      expect(find.text('Alice Person'), findsOneWidget);
      expect(find.text('Zagros Store'), findsOneWidget);
      expect(find.text('In Prüfung'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('account-register-business')),
        findsNothing,
      );
      expect(
        _semanticsWithin(
          tester,
          const ValueKey('account-person-identity'),
        ).properties.selected,
        isTrue,
      );

      await tester.tap(find.byKey(const ValueKey('account-business-identity')));
      await tester.pumpAndSettle();

      expect(
        _semanticsWithin(
          tester,
          const ValueKey('account-business-identity'),
        ).properties.selected,
        isTrue,
      );
      expect(
        preferences.getString(
          '${SharedPreferencesActiveIdentityStore.keyPrefix}${_user.id}',
        ),
        business.selectionKey,
      );
      await tester.scrollUntilVisible(
        find.text('Mein Unternehmen'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Mein Unternehmen'), findsOneWidget);
    },
  );

  testWidgets('approved business is labeled verified', (tester) async {
    await _pumpAccount(
      tester,
      const Locale('de'),
      catalog: IdentityCatalog(<MarketplaceIdentity>[
        _person(),
        _business(verified: true),
      ]),
      storedSelection: _business(verified: true).selectionKey,
    );

    expect(find.text('Verifiziert'), findsOneWidget);
  });

  testWidgets('restricted businesses are not mislabeled as in review', (
    tester,
  ) async {
    for (final entry in <String, String>{
      'rejected': 'Abgelehnt',
      'suspended': 'Gesperrt',
    }.entries) {
      await _pumpAccount(
        tester,
        const Locale('de'),
        catalog: IdentityCatalog(<MarketplaceIdentity>[
          _person(),
          _business(status: entry.key),
        ]),
      );
      expect(find.text(entry.value), findsOneWidget);
      expect(find.text('In Prüfung'), findsNothing);
    }
  });

  testWidgets('Arabic Account switcher is RTL and uses Arabic copy', (
    tester,
  ) async {
    await _pumpAccount(
      tester,
      const Locale('ar'),
      catalog: IdentityCatalog(<MarketplaceIdentity>[_person(), _business()]),
    );

    final context = tester.element(find.byType(AccountScreen));
    expect(Directionality.of(context), TextDirection.rtl);
    expect(find.text('ملفات البيع الخاصة بك'), findsOneWidget);
    expect(find.text('فرد'), findsOneWidget);
    expect(find.text('قيد المراجعة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
