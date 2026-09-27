import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zerin_marketplace/features/auth/domain/auth_repository.dart';
import 'package:zerin_marketplace/features/auth/domain/auth_user.dart';
import 'package:zerin_marketplace/features/auth/presentation/controllers/auth_controller.dart';
import 'package:zerin_marketplace/features/chat/domain/chat.dart';
import 'package:zerin_marketplace/features/chat/domain/chat_repository.dart';
import 'package:zerin_marketplace/features/chat/presentation/controllers/chat_controller.dart';
import 'package:zerin_marketplace/features/home/domain/home_feed.dart';
import 'package:zerin_marketplace/features/home/presentation/controllers/home_controller.dart';
import 'package:zerin_marketplace/features/profile/domain/profile.dart';
import 'package:zerin_marketplace/features/profile/presentation/controllers/profile_controller.dart';
import 'package:zerin_marketplace/features/profile/presentation/public_profile_screen.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

PublicProfile _profile({
  bool isSelf = false,
  bool withSeller = true,
  String? status,
}) => PublicProfile(
  displayName: 'Alice Public',
  username: 'alice_name',
  city: 'Berlin',
  bio: 'Kurze Bio',
  avatarUrl: null,
  listingCount: 3,
  isSelf: isSelf,
  seller: withSeller
      ? ProfileSeller(
          id: 'seller-1',
          kind: 'private',
          status: status,
          verified: false,
        )
      : null,
);

class _StubAuth implements AuthRepository {
  _StubAuth(this._user);
  final AuthUser? _user;
  @override
  AuthUser? get currentUser => _user;
  @override
  Stream<AuthUser?> get authStateChanges => Stream<AuthUser?>.value(_user);
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _StubChat implements ChatRepository {
  String? openedSeller;
  @override
  Future<ChatConversation> openChatWithSeller(String sellerId) async {
    openedSeller = sellerId;
    return const ChatConversation(
      chatId: 'chat-1',
      buyerId: 'buyer',
      sellerId: 'seller-1',
      sellerUserId: null,
      shopName: 'Alice Public',
      shopSlug: '',
      shopAvatarUrl: null,
      productId: null,
      productTitle: null,
      productImageUrl: null,
      productPriceCents: 0,
      productCurrency: 'EUR',
      lastMessageAt: null,
      lastMessagePreview: null,
      unreadCount: 0,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

Future<void> _pump(
  WidgetTester tester, {
  required PublicProfile? profile,
  AuthUser? user,
  _StubChat? chat,
  Locale locale = const Locale('en'),
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const PublicProfileScreen(username: 'alice_name'),
      ),
      GoRoute(
        path: '/auth',
        builder: (_, state) => Scaffold(
          body: Text('Auth ${state.uri.queryParameters['redirect-to'] ?? ''}'),
        ),
      ),
      GoRoute(
        path: '/chat/:chatId',
        builder: (_, state) =>
            Scaffold(body: Text('Chat ${state.pathParameters['chatId']}')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_StubAuth(user)),
        authStateProvider.overrideWith((ref) => Stream<AuthUser?>.value(user)),
        if (chat != null) chatRepositoryProvider.overrideWithValue(chat),
        publicProfileProvider(
          username: 'alice_name',
        ).overrideWith((ref) async => profile),
        sellerProductsProvider(
          sellerId: 'seller-1',
        ).overrideWith((ref) async => const <HomeProduct>[]),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocale.localizationsDelegates,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  testWidgets('renders safe header fields and hides private data', (
    tester,
  ) async {
    await _pump(tester, profile: _profile());
    expect(find.text('Alice Public'), findsOneWidget);
    expect(find.text('@alice_name'), findsOneWidget);
    expect(find.text('Berlin'), findsOneWidget);
    expect(find.text('Kurze Bio'), findsOneWidget);
    expect(find.textContaining('3 listings'), findsOneWidget);
  });

  testWidgets('missing profile shows an empty state', (tester) async {
    await _pump(tester, profile: null);
    expect(find.text('Alice Public'), findsNothing);
    expect(find.byIcon(Icons.person_off_outlined), findsOneWidget);
  });

  testWidgets('anonymous message CTA redirects to auth with return url', (
    tester,
  ) async {
    await _pump(tester, profile: _profile());
    await tester.tap(find.text('Send message'));
    await tester.pumpAndSettle();
    expect(find.text('Auth /profile/alice_name'), findsOneWidget);
  });

  testWidgets('authenticated message CTA opens the productless seller chat', (
    tester,
  ) async {
    final chat = _StubChat();
    await _pump(
      tester,
      profile: _profile(),
      user: const AuthUser(id: 'buyer', email: 'buyer@example.test'),
      chat: chat,
    );
    await tester.tap(find.text('Send message'));
    await tester.pumpAndSettle();
    expect(chat.openedSeller, 'seller-1');
    expect(find.text('Chat chat-1'), findsOneWidget);
  });

  testWidgets('own profile hides the message CTA', (tester) async {
    await _pump(
      tester,
      profile: _profile(isSelf: true),
      user: const AuthUser(id: 'seller-user', email: 'me@example.test'),
    );
    expect(find.text('Send message'), findsNothing);
  });

  testWidgets('profile without a seller hides the message CTA', (tester) async {
    await _pump(tester, profile: _profile(withSeller: false));
    expect(find.text('Send message'), findsNothing);
  });
}
