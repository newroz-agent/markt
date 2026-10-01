import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerin_marketplace/app/app.dart';
import 'package:zerin_marketplace/app/router/app_router.dart';
import 'package:zerin_marketplace/core/config/app_environment.dart';
import 'package:zerin_marketplace/core/providers/infrastructure_providers.dart';
import 'package:zerin_marketplace/features/account/presentation/account_screen.dart';
import 'package:zerin_marketplace/features/chat/presentation/chat_conversation_screen.dart';
import 'package:zerin_marketplace/features/profile/presentation/edit_profile_screen.dart';
import 'package:zerin_marketplace/features/profile/presentation/public_profile_screen.dart';
import 'package:zerin_marketplace/features/settings/presentation/controllers/app_settings_controller.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

const _ownerEmail = 'step-b-ios-owner@example.invalid';
const _buyerEmail = 'step-b-ios-admin@example.invalid';
const _password = 'ZerinStepB!2026';
const _displayName = 'Aylin Kaya';
const _username = 'aylin_kaya';
const _city = 'Berlin';
const _bio = 'Private Verkäuferin aus Berlin. Nachhaltig und persönlich.';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late SupabaseClient client;
  late SharedPreferences preferences;
  late ProviderContainer container;
  late GoRouter router;
  late String sellerId;
  final checks = <String, String>{};

  Future<void> until(
    WidgetTester tester,
    bool Function() condition,
    String reason,
  ) async {
    final deadline = DateTime.now().add(const Duration(seconds: 45));
    while (!condition() && DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(condition(), isTrue, reason: reason);
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> screenshot(WidgetTester tester, String name) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 30),
    );
    expect(tester.takeException(), isNull);
    final bytes = await binding.takeScreenshot('step_c_$name');
    expect(bytes.length, greaterThan(1000));
    checks[name] = 'PASS';
  }

  AppLocalizations labels(WidgetTester tester) =>
      tester.element(find.byType(Scaffold).first).l10n;

  Future<void> signIn(String email) async {
    await client.auth.signOut();
    final response = await client.auth.signInWithPassword(
      email: email,
      password: _password,
    );
    expect(response.session, isNotNull);
  }

  setUpAll(() async {
    expect(AppEnvironment.isSupabaseConfigured, isTrue);
    expect(
      <String>['localhost', '127.0.0.1', '::1'],
      contains(Uri.parse(AppEnvironment.supabaseUrl).host),
      reason: 'Step C acceptance is intentionally restricted to local Supabase',
    );
    client = SupabaseClient(
      AppEnvironment.supabaseUrl,
      AppEnvironment.supabaseAnonKey,
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );
    preferences = await SharedPreferences.getInstance();
    await preferences.setBool(SettingsStorageKeys.onboardingComplete, true);

    await signIn(_ownerEmail);
    final seller = await client
        .from('sellers')
        .select('id, kind, status, country_code')
        .eq('user_id', client.auth.currentUser!.id)
        .single();
    expect(seller['kind'], 'private');
    expect(seller['status'], 'approved');
    expect(seller['country_code'], 'DE');
    sellerId = seller['id'] as String;
    await client.rpc<void>(
      'update_my_profile',
      params: <String, Object?>{
        'p_display_name': _displayName,
        'p_username': _username,
        'p_city': _city,
        'p_bio': _bio,
      },
    );
  });

  tearDownAll(() async {
    binding.reportData ??= <String, dynamic>{};
    binding.reportData!['checks'] = checks;
    binding.reportData!['tests'] = <String, String>{
      for (final entry in binding.results.entries)
        entry.key: entry.value == 'success' ? 'PASS' : 'FAIL',
    };
    binding.reportData!['runtime'] = <String, String>{
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'device': const String.fromEnvironment(
        'STEP_C_DEVICE',
        defaultValue: 'unknown',
      ),
    };
    await client.auth.signOut();
    await client.dispose();
  });

  testWidgets('real iOS profile edit, public view, and seller chat hand-off', (
    tester,
  ) async {
    await signIn(_ownerEmail);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(preferences),
          supabaseClientProvider.overrideWithValue(client),
        ],
        child: const ZerinApp(),
      ),
    );
    await tester.pump();
    container = ProviderScope.containerOf(
      tester.element(find.byType(ZerinApp)),
    );
    await container
        .read(appSettingsControllerProvider.notifier)
        .setLocale('de');
    router = container.read(appRouterProvider);

    router.go(const MarketplaceRoute(tab: 4).location);
    await until(
      tester,
      () =>
          find.byType(AccountScreen).evaluate().isNotEmpty &&
          find.text(_displayName).evaluate().isNotEmpty &&
          find.text('@$_username').evaluate().isNotEmpty &&
          find.text(_city).evaluate().isNotEmpty,
      'My Profile loads the public identity in Account',
    );
    expect(find.text(_ownerEmail), findsNothing);
    await screenshot(tester, 'my_profile');

    await tester.tap(find.text(labels(tester).accountEditProfile));
    await until(
      tester,
      () =>
          find.byType(EditProfileScreen).evaluate().isNotEmpty &&
          find.text(labels(tester).editProfileTitle).evaluate().isNotEmpty,
      'Edit Profile opens',
    );
    final fields = find.byType(EditableText);
    expect(fields, findsNWidgets(3));
    expect(
      tester.widget<EditableText>(fields.at(0)).controller.text,
      _displayName,
    );
    expect(
      tester.widget<EditableText>(fields.at(1)).controller.text,
      _username,
    );
    expect(tester.widget<EditableText>(fields.at(2)).controller.text, _bio);
    expect(find.text(_city), findsOneWidget);
    await screenshot(tester, 'edit_profile');

    await tester.tap(find.text(labels(tester).profileSave));
    await until(
      tester,
      () => find.text(labels(tester).profileSaved).evaluate().isNotEmpty,
      'Profile save completes through the live RPC',
    );
    ScaffoldMessenger.of(
      tester.element(find.byType(EditProfileScreen)),
    ).hideCurrentSnackBar();
    await tester.pumpAndSettle();
    expect(find.text(labels(tester).profileSaved), findsNothing);

    await signIn(_buyerEmail);
    router.go(const PublicProfileRoute(username: _username).location);
    await until(
      tester,
      () =>
          find.byType(PublicProfileScreen).evaluate().isNotEmpty &&
          find.text(_displayName).evaluate().isNotEmpty &&
          find.text('@$_username').evaluate().isNotEmpty &&
          find.text(labels(tester).profileSendMessage).evaluate().isNotEmpty,
      'A distinct authenticated user sees the public profile and message action',
    );
    expect(find.text(_ownerEmail), findsNothing);
    await screenshot(tester, 'public_profile');

    await tester.tap(find.text(labels(tester).profileSendMessage));
    await until(
      tester,
      () => find.byType(ChatConversationScreen).evaluate().isNotEmpty,
      'Message seller opens the existing chat conversation route',
    );
    final conversation = tester.widget<ChatConversationScreen>(
      find.byType(ChatConversationScreen),
    );
    final chatId = conversation.chatId;
    expect(ChatConversationRoute(chatId: chatId).location, '/chat/$chatId');
    final chat = await client
        .from('chats')
        .select('id, seller_id, buyer_id, product_id')
        .eq('id', chatId)
        .single();
    expect(chat['seller_id'], sellerId);
    expect(chat['buyer_id'], client.auth.currentUser!.id);
    expect(chat['product_id'], isNull);
    await until(
      tester,
      () =>
          find.text(labels(tester).chatNoMessagesYet).evaluate().isNotEmpty ||
          find.byType(TextField).evaluate().isNotEmpty,
      'Existing chat UI finishes loading',
    );
    await screenshot(tester, 'message_seller_chat_handoff');

    expect(checks, hasLength(4));
  });
}
