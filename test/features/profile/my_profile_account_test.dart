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
import 'package:zerin_marketplace/features/moderation/presentation/controllers/moderation_controller.dart';
import 'package:zerin_marketplace/features/profile/domain/profile.dart';
import 'package:zerin_marketplace/features/profile/presentation/controllers/profile_controller.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

const _user = AuthUser(id: 'owner', email: 'private@example.invalid');
const _profile = MyProfile(
  displayName: 'Alice Public',
  username: 'alice_name',
  city: 'Berlin',
  bio: 'A public biography.',
  avatarUrl: null,
  listingCount: 4,
  seller: null,
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

Future<void> _pumpAccount(
  WidgetTester tester,
  Locale locale, {
  MyProfile profile = _profile,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(preferences),
        authRepositoryProvider.overrideWithValue(const _AuthRepository()),
        authStateProvider.overrideWith((ref) => Stream.value(_user)),
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
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('own profile header uses public identity and never email', (
    tester,
  ) async {
    await _pumpAccount(tester, const Locale('en'));

    expect(find.text('Alice Public'), findsOneWidget);
    expect(find.text('@alice_name'), findsOneWidget);
    expect(find.text('Berlin'), findsOneWidget);
    expect(find.text('4 listings'), findsOneWidget);
    expect(find.text('A public biography.'), findsOneWidget);
    expect(find.textContaining('private@example'), findsNothing);
    expect(find.text('Edit profile'), findsOneWidget);
    expect(find.text('Public profile'), findsOneWidget);
    expect(find.text('Messages'), findsOneWidget);

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
    await _pumpAccount(tester, const Locale('de'));

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
    expect(tester.takeException(), isNull);
  });

  testWidgets('business entry is offered to users without a seller', (
    tester,
  ) async {
    await _pumpAccount(tester, const Locale('de'));
    expect(find.text('Mein Unternehmen'), findsOneWidget);
  });

  testWidgets('business entry is hidden for private sellers', (tester) async {
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
        seller: ProfileSeller(id: 's1', kind: 'private', verified: false),
      ),
    );
    expect(find.text('Mein Unternehmen'), findsNothing);
  });
}
