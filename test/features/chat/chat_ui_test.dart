import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerin_marketplace/app/router/app_router.dart';
import 'package:zerin_marketplace/core/providers/infrastructure_providers.dart';
import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/features/account/presentation/account_screen.dart';
import 'package:zerin_marketplace/features/auth/domain/auth_repository.dart';
import 'package:zerin_marketplace/features/auth/domain/auth_user.dart';
import 'package:zerin_marketplace/features/auth/presentation/controllers/auth_controller.dart';
import 'package:zerin_marketplace/features/chat/domain/chat.dart';
import 'package:zerin_marketplace/features/chat/domain/chat_repository.dart';
import 'package:zerin_marketplace/features/chat/presentation/chat_conversation_screen.dart';
import 'package:zerin_marketplace/features/chat/presentation/chat_inbox_screen.dart';
import 'package:zerin_marketplace/features/chat/presentation/controllers/chat_controller.dart';
import 'package:zerin_marketplace/features/products/presentation/contact_seller_button.dart';
import 'package:zerin_marketplace/features/settings/presentation/controllers/app_settings_controller.dart';
import 'package:zerin_marketplace/l10n/app_localizations.dart';

const _buyer = AuthUser(id: 'buyer', email: 'buyer@example.test');
const _seller = AuthUser(id: 'seller-user', email: 'seller@example.test');

ChatConversation _conversation({bool product = false}) => ChatConversation(
  chatId: 'real-chat-id',
  buyerId: _buyer.id,
  sellerId: 'seller',
  sellerUserId: _seller.id,
  shopName: 'Test shop',
  shopSlug: 'test-shop',
  shopAvatarUrl: null,
  buyerName: 'Buyer name',
  productId: product ? 'product' : null,
  productTitle: product ? 'Pinned product' : null,
  productImageUrl: null,
  productPriceCents: 1250,
  productCurrency: 'EUR',
  lastMessageAt: null,
  lastMessagePreview: 'Latest preview',
  unreadCount: 3,
);

ChatMessage _message(
  int index, {
  String? sender = 'buyer',
  MessageKind kind = MessageKind.text,
}) => ChatMessage(
  id: 'message-$index',
  chatId: 'real-chat-id',
  senderId: sender,
  kind: kind,
  body: 'Message $index',
  productId: kind == MessageKind.product ? 'product' : null,
  productTitle: kind == MessageKind.product ? 'History product' : null,
  productPriceCents: 1250,
  productCurrency: 'EUR',
  readAt: null,
  createdAt: DateTime(2026).add(Duration(minutes: index)),
);

class _AuthRepository implements AuthRepository {
  _AuthRepository([this.currentUser = _buyer]);

  @override
  AuthUser? currentUser;
  final changes = StreamController<AuthUser?>.broadcast();

  @override
  Stream<AuthUser?> get authStateChanges async* {
    yield currentUser;
    yield* changes.stream;
  }

  @override
  Future<void> signOut() async {
    currentUser = null;
    changes.add(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ChatRepository implements ChatRepository {
  int opens = 0;
  int watches = 0;
  int reads = 0;
  int olderLoads = 0;
  bool failOpen = false;
  bool failHistory = false;
  bool failOlder = false;
  bool failSend = false;
  final sent = <String>[];
  ChatConversation details = _conversation();
  List<ChatConversation> inbox = [_conversation()];
  List<ChatMessage> messages = [];
  List<ChatMessage> older = [];
  Completer<ChatConversation>? opening;
  Completer<ChatMessage>? sending;
  final updates = StreamController<List<ChatMessage>>.broadcast();
  String? openedSeller;
  String? openedProduct;

  @override
  Future<ChatConversation> openChatWithProduct({
    required String sellerId,
    required String productId,
  }) async {
    opens++;
    openedSeller = sellerId;
    openedProduct = productId;
    if (failOpen) throw StateError('open failed');
    return opening == null ? details : opening!.future;
  }

  @override
  Future<ChatConversation> openChatWithSeller(String sellerId) async {
    opens++;
    openedSeller = sellerId;
    openedProduct = null;
    if (failOpen) throw StateError('open failed');
    return opening == null ? details : opening!.future;
  }

  @override
  Future<ChatConversation> fetchConversation(String chatId) async => details;

  @override
  Future<List<ChatConversation>> fetchConversations() async => inbox;

  @override
  Stream<List<ChatConversation>> watchConversations() => Stream.value(inbox);

  @override
  Stream<List<ChatMessage>> watchMessages(String chatId) async* {
    watches++;
    if (failHistory) throw StateError('history failed');
    yield messages;
    yield* updates.stream;
  }

  @override
  Future<List<ChatMessage>> fetchMessages(
    String chatId, {
    ChatMessage? before,
  }) async {
    olderLoads++;
    if (failOlder) throw StateError('older failed');
    return older;
  }

  @override
  Future<ChatMessage> sendTextMessage({
    required String chatId,
    required String body,
  }) async {
    sent.add(body);
    if (failSend) throw StateError('send failed');
    return sending == null ? _message(999) : sending!.future;
  }

  @override
  Future<int> markChatRead(String chatId) async {
    reads++;
    return 1;
  }
}

Future<GoRouter> _pump(
  WidgetTester tester,
  _ChatRepository repository, {
  Widget home = const ChatConversationScreen(chatId: 'real-chat-id'),
  _AuthRepository? auth,
}) async {
  final authRepository = auth ?? _AuthRepository();
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final router = GoRouter(
    observers: [chatRouteObserver],
    routes: [
      GoRoute(path: '/', builder: (_, _) => home),
      GoRoute(
        path: '/chat/:chatId',
        builder: (_, state) =>
            Scaffold(body: Text('Opened ${state.pathParameters['chatId']}')),
      ),
      GoRoute(
        path: '/inbox',
        builder: (_, _) => const Scaffold(body: Text('Inbox destination')),
      ),
      GoRoute(
        path: '/auth',
        builder: (_, _) => const Scaffold(body: Text('Auth destination')),
      ),
      GoRoute(
        path: '/cover',
        builder: (_, _) => const Scaffold(body: Text('Covered')),
      ),
    ],
  );
  addTearDown(router.dispose);
  addTearDown(authRepository.changes.close);
  addTearDown(repository.updates.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        chatRepositoryProvider.overrideWithValue(repository),
        sharedPreferencesProvider.overrideWithValue(preferences),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  const contact = Scaffold(
    body: ContactSellerButton(sellerId: 'seller', productId: 'product'),
  );

  testWidgets(
    'contact opens only on tap, guards pending taps and uses real ID',
    (tester) async {
      final repository = _ChatRepository()..opening = Completer();
      await _pump(tester, repository, home: contact);
      expect(repository.opens, 0);
      await tester.tap(find.text('Contact seller'));
      await tester.pump();
      await tester.tap(find.text('Contact seller'));
      expect(repository.opens, 1);
      expect(repository.openedSeller, 'seller');
      expect(repository.openedProduct, 'product');
      repository.opening!.complete(_conversation());
      await tester.pumpAndSettle();
      expect(find.text('Opened real-chat-id'), findsOneWidget);
    },
  );

  testWidgets('contact failure allows a fresh tap retry', (tester) async {
    final repository = _ChatRepository()..failOpen = true;
    await _pump(tester, repository, home: contact);
    await tester.tap(find.text('Contact seller'));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
    repository.failOpen = false;
    await tester.tap(find.text('Contact seller'));
    await tester.pumpAndSettle();
    expect(repository.opens, 2);
    expect(find.text('Opened real-chat-id'), findsOneWidget);
  });

  testWidgets('guest contact routes to auth without opening', (tester) async {
    final repository = _ChatRepository();
    await _pump(tester, repository, home: contact, auth: _AuthRepository(null));
    await tester.tap(find.text('Contact seller'));
    await tester.pumpAndSettle();
    expect(repository.opens, 0);
    expect(find.text('Auth destination'), findsOneWidget);
  });

  testWidgets(
    'empty conversation, send pending guard and draft kept on failure',
    (tester) async {
      final repository = _ChatRepository()..sending = Completer();
      await _pump(tester, repository);
      expect(find.text('No messages yet'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is IconButton && widget.tooltip == 'Send message',
              ),
            )
            .onPressed,
        isNull,
      );
      await tester.enterText(find.byType(TextField), '  Keep my draft  ');
      await tester.tap(find.byTooltip('Send message'));
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(repository.sent, ['Keep my draft']);
      repository.sending!.completeError(StateError('failed'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '  Keep my draft  ',
      );
      repository.sending = null;
      ScaffoldMessenger.of(
        tester.element(find.byType(TextField)),
      ).removeCurrentSnackBar();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Send message'));
      await tester.pumpAndSettle();
      expect(repository.sent, ['Keep my draft', 'Keep my draft']);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    },
  );

  testWidgets('send success does not clear a newer draft typed while pending', (
    tester,
  ) async {
    final repository = _ChatRepository()..sending = Completer();
    await _pump(tester, repository);
    await tester.enterText(find.byType(TextField), 'First draft');
    await tester.tap(find.byTooltip('Send message'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Next draft');
    repository.sending!.complete(_message(1));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Next draft',
    );
  });

  testWidgets(
    'bubbles use authenticated sender identity and center system notices',
    (tester) async {
      final repository = _ChatRepository()
        ..messages = [
          _message(1),
          _message(2, sender: 'seller-user'),
          _message(3, sender: null, kind: MessageKind.system),
          _message(4, sender: null, kind: MessageKind.product),
        ];
      await _pump(tester, repository);
      final mine = tester.widget<Align>(
        find
            .ancestor(of: find.text('Message 1'), matching: find.byType(Align))
            .first,
      );
      final theirs = tester.widget<Align>(
        find
            .ancestor(of: find.text('Message 2'), matching: find.byType(Align))
            .first,
      );
      expect(mine.alignment, Alignment.centerRight);
      expect(theirs.alignment, Alignment.centerLeft);
      expect(
        tester.widget<Text>(find.text('Message 3')).textAlign,
        TextAlign.center,
      );
      expect(find.text('History product'), findsOneWidget);
      expect(find.text('Pinned product'), findsNothing);
    },
  );

  testWidgets('separate details pins product even outside the message page', (
    tester,
  ) async {
    final repository = _ChatRepository()
      ..details = _conversation(product: true)
      ..messages = [_message(1)];
    await _pump(tester, repository);
    expect(find.text('Pinned product'), findsOneWidget);
    expect(find.text('History product'), findsNothing);
  });

  testWidgets('conversation error retries history', (tester) async {
    final repository = _ChatRepository();
    await _pump(tester, repository);
    repository.updates.addError(StateError('history failed'));
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(repository.watches, greaterThan(1));
    expect(find.text('No messages yet'), findsOneWidget);
  });

  testWidgets(
    'reads only visible foreground conversation and resumes on uncover',
    (tester) async {
      final repository = _ChatRepository()..messages = [_message(1)];
      final router = await _pump(tester, repository);
      expect(repository.reads, greaterThan(0));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      final pausedReads = repository.reads;
      repository.updates.add([_message(2)]);
      await tester.pumpAndSettle();
      expect(repository.reads, pausedReads);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(repository.reads, greaterThan(pausedReads));
      unawaited(router.push<void>('/cover'));
      await tester.pumpAndSettle();
      final coveredReads = repository.reads;
      repository.updates.add([_message(3)]);
      await tester.pumpAndSettle();
      expect(repository.reads, coveredReads);
      router.pop();
      await tester.pumpAndSettle();
      expect(repository.reads, greaterThan(coveredReads));
    },
  );

  testWidgets(
    'history loading can retry and incoming messages do not snap to bottom',
    (tester) async {
      final repository = _ChatRepository()
        ..messages = List.generate(100, (index) => _message(index + 100))
        ..older = [_message(1)]
        ..failOlder = true;
      await _pump(tester, repository);
      final scrollable = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Load earlier messages'));
      await tester.pumpAndSettle();
      expect(repository.olderLoads, 1);
      repository.failOlder = false;
      await tester.tap(find.text('Load earlier messages'));
      await tester.pumpAndSettle();
      expect(repository.olderLoads, 2);
      expect(find.text('Load earlier messages'), findsNothing);
      expect(scrollable.position.pixels, greaterThan(100));
      repository.updates.add([_message(300, sender: 'seller-user')]);
      await tester.pumpAndSettle();
      expect(scrollable.position.pixels, greaterThan(100));
      expect(find.text('Message 300'), findsNothing);
    },
  );

  testWidgets(
    'seller inbox names buyer, shows badge and opens typed conversation',
    (tester) async {
      await _pump(
        tester,
        _ChatRepository(),
        home: const ChatInboxScreen(),
        auth: _AuthRepository(_seller),
      );
      expect(find.text('Buyer name'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Test shop'), findsNothing);
      await tester.tap(find.text('Buyer name'));
      await tester.pumpAndSettle();
      expect(find.text('Opened real-chat-id'), findsOneWidget);
    },
  );

  testWidgets('account exposes inbox entry with unread badge', (tester) async {
    await _pump(tester, _ChatRepository(), home: const AccountScreen());
    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    await tester.tap(find.text('Messages'));
    await tester.pumpAndSettle();
    expect(find.text('Inbox destination'), findsOneWidget);
  });

  testWidgets('production routes guard deep links and refresh on logout', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      SettingsStorageKeys.onboardingComplete: true,
    });
    final preferences = await SharedPreferences.getInstance();
    final auth = _AuthRepository(null);
    final repository = _ChatRepository();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        authRepositoryProvider.overrideWithValue(auth),
        chatRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(auth.changes.close);
    addTearDown(repository.updates.close);
    final router = container.read(appRouterProvider);
    router.go(const ChatConversationRoute(chatId: 'real-chat-id').location);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/auth');
    expect(
      router.routeInformationProvider.value.uri.queryParameters['redirect-to'],
      '/chat/real-chat-id',
    );
    expect(repository.watches, 0);
    auth.currentUser = _buyer;
    auth.changes.add(_buyer);
    await tester.pumpAndSettle();
    router.go(const ChatInboxRoute().location);
    await tester.pumpAndSettle();
    expect(find.byType(ChatInboxScreen), findsOneWidget);
    await auth.signOut();
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/auth');
    expect(find.byType(ChatInboxScreen), findsNothing);
    router.go(const ChatInboxRoute().location);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/auth');
  });
}
