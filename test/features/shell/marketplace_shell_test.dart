import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerin_marketplace/core/providers/infrastructure_providers.dart';
import 'package:zerin_marketplace/features/auth/domain/auth_repository.dart';
import 'package:zerin_marketplace/features/auth/domain/auth_user.dart';
import 'package:zerin_marketplace/features/auth/presentation/controllers/auth_controller.dart';
import 'package:zerin_marketplace/features/chat/domain/chat.dart';
import 'package:zerin_marketplace/features/chat/domain/chat_repository.dart';
import 'package:zerin_marketplace/features/chat/presentation/controllers/chat_controller.dart';
import 'package:zerin_marketplace/features/shell/presentation/marketplace_shell.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'signed-in shell replaces Cart with Chat and shows unread badge',
    (tester) async {
      final user = const AuthUser(id: 'user', email: 'user@example.com');
      final router = await _pumpShell(
        tester,
        authRepository: _AuthRepository(user),
        chatRepository: _ChatRepository(unreadCount: 7),
      );
      addTearDown(router.dispose);

      final navigation = find.byType(BottomAppBar);
      expect(
        find.descendant(of: navigation, matching: find.text('Messages')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: navigation, matching: find.text('Cart')),
        findsNothing,
      );
      expect(
        find.descendant(of: navigation, matching: find.text('7')),
        findsOneWidget,
      );

      await tester.tap(
        find.descendant(of: navigation, matching: find.text('Messages')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Seller'), findsOneWidget);
    },
  );

  testWidgets('signed-out Chat tab redirects to auth and preserves tab', (
    tester,
  ) async {
    final router = await _pumpShell(
      tester,
      authRepository: const _AuthRepository(null),
      chatRepository: const _ChatRepository(),
    );
    addTearDown(router.dispose);

    await tester.tap(find.byIcon(Icons.forum_outlined).hitTestable());
    await tester.pumpAndSettle();

    expect(find.text('auth redirect: /?tab=3'), findsOneWidget);
  });
}

Future<GoRouter> _pumpShell(
  WidgetTester tester, {
  required AuthRepository authRepository,
  required ChatRepository chatRepository,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final preferences = await SharedPreferences.getInstance();
  final router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) => const MarketplaceShell(initialIndex: 0),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => Scaffold(
          body: Text(
            'auth redirect: ${state.uri.queryParameters['redirect-to']}',
          ),
        ),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(preferences),
        authRepositoryProvider.overrideWithValue(authRepository),
        chatRepositoryProvider.overrideWithValue(chatRepository),
      ],
      child: MaterialApp.router(
        locale: AppLocale.english,
        supportedLocales: AppLocale.supportedLocales,
        localizationsDelegates: AppLocale.localizationsDelegates,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

class _AuthRepository implements AuthRepository {
  const _AuthRepository(this.user);

  final AuthUser? user;

  @override
  Stream<AuthUser?> get authStateChanges => Stream<AuthUser?>.value(user);

  @override
  AuthUser? get currentUser => user;

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<void> signInWithSocialProvider(SocialAuthProvider provider) =>
      throw UnimplementedError();

  @override
  Future<AuthUser?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) => throw UnimplementedError();

  @override
  Future<void> signOut() => throw UnimplementedError();
}

class _ChatRepository implements ChatRepository {
  const _ChatRepository({this.unreadCount = 0});

  final int unreadCount;

  List<ChatConversation> get _conversations => <ChatConversation>[
    ChatConversation(
      chatId: 'chat',
      buyerId: 'user',
      sellerId: 'seller',
      sellerUserId: 'seller-user',
      shopName: 'Seller',
      shopSlug: 'seller',
      shopAvatarUrl: null,
      productId: null,
      productTitle: null,
      productImageUrl: null,
      productPriceCents: 0,
      productCurrency: 'EUR',
      lastMessageAt: null,
      lastMessagePreview: 'Hello',
      unreadCount: unreadCount,
    ),
  ];

  @override
  Future<ChatConversation> fetchConversation(String chatId) async =>
      _conversations.single;

  @override
  Future<List<ChatConversation>> fetchConversations() async => _conversations;

  @override
  Future<List<ChatMessage>> fetchMessages(
    String chatId, {
    ChatMessage? before,
  }) async => <ChatMessage>[];

  @override
  Future<int> markChatRead(String chatId) async => 0;

  @override
  Future<ChatConversation> openChatWithProduct({
    required String sellerId,
    required String productId,
  }) async => _conversations.single;

  @override
  Future<ChatConversation> openChatWithSeller(String sellerId) async =>
      _conversations.single;

  @override
  Future<ChatMessage> sendTextMessage({
    required String chatId,
    required String body,
  }) => throw UnimplementedError();

  @override
  Stream<List<ChatConversation>> watchConversations() =>
      Stream<List<ChatConversation>>.value(_conversations);

  @override
  Stream<List<ChatMessage>> watchMessages(String chatId) =>
      Stream<List<ChatMessage>>.value(<ChatMessage>[]);
}
