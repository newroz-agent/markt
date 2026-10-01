import 'dart:io';

import 'package:flutter/foundation.dart';
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
import 'package:zerin_marketplace/features/identity/data/active_identity_store.dart';
import 'package:zerin_marketplace/features/identity/presentation/controllers/identity_controller.dart';
import 'package:zerin_marketplace/features/settings/presentation/controllers/app_settings_controller.dart';

const _email = 'step-f2c-dual@example.invalid';
const _password = 'ZerinStepF!2026';
const _userId = 'f2c10000-0000-4000-8000-000000000001';
const _sellerIds = <String>[
  'f2c20000-0000-4000-8000-000000000001',
  'f2c20000-0000-4000-8000-000000000002',
  'f2c20000-0000-4000-8000-000000000003',
];
const _productIds = <String>[
  'f2c30000-0000-4000-8000-000000000001',
  'f2c30000-0000-4000-8000-000000000002',
];
const _chatIds = <String>[
  'f2c40000-0000-4000-8000-000000000001',
  'f2c40000-0000-4000-8000-000000000002',
  'f2c40000-0000-4000-8000-000000000003',
];
const _messageIds = <String>[
  'f2c50000-0000-4000-8000-000000000001',
  'f2c50000-0000-4000-8000-000000000002',
  'f2c50000-0000-4000-8000-000000000003',
];

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late SupabaseClient client;
  late SharedPreferences preferences;
  late GoRouter router;
  late Map<String, int> beforeState;
  final checks = <String, String>{};
  final evidence = <String, Object?>{};
  bool? previousOnboarding;
  String? previousLocale;
  String? previousIdentity;
  var preferencesRestored = false;

  Future<void> until(
    WidgetTester tester,
    bool Function() condition,
    String reason,
  ) async {
    final deadline = DateTime.now().add(const Duration(seconds: 60));
    while (!condition() && DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(condition(), isTrue, reason: reason);
    await tester.pump(const Duration(milliseconds: 500));
  }

  bool shows(String text) => find.textContaining(text).evaluate().isNotEmpty;

  Future<void> screenshot(WidgetTester tester, String name) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    final bytes = await binding.takeScreenshot('step_f_$name');
    expect(bytes.length, greaterThan(1000));
    checks[name] = 'PASS';
  }

  Future<Map<String, int>> fixtureState() async {
    final sellers = await client
        .from('sellers')
        .select('id')
        .inFilter('id', _sellerIds);
    final products = await client
        .from('products')
        .select('id')
        .inFilter('id', _productIds);
    final chats = await client
        .from('chats')
        .select('id')
        .inFilter('id', _chatIds);
    final messages = await client
        .from('messages')
        .select('id, read_at')
        .inFilter('id', _messageIds);
    return <String, int>{
      'sellers': sellers.length,
      'products': products.length,
      'chats': chats.length,
      'messages': messages.length,
      'unread_seed_messages': messages
          .where((message) => message['read_at'] == null)
          .length,
    };
  }

  Future<void> restorePreferences() async {
    final identityKey =
        '${SharedPreferencesActiveIdentityStore.keyPrefix}$_userId';
    final restoredIdentity = previousIdentity == null
        ? await preferences.remove(identityKey)
        : await preferences.setString(identityKey, previousIdentity!);
    final restoredOnboarding = previousOnboarding == null
        ? await preferences.remove(SettingsStorageKeys.onboardingComplete)
        : await preferences.setBool(
            SettingsStorageKeys.onboardingComplete,
            previousOnboarding!,
          );
    final restoredLocale = previousLocale == null
        ? await preferences.remove(SettingsStorageKeys.locale)
        : await preferences.setString(
            SettingsStorageKeys.locale,
            previousLocale!,
          );
    if (!restoredIdentity || !restoredOnboarding || !restoredLocale) {
      throw StateError('Step F could not restore device preferences.');
    }
    preferencesRestored = true;
  }

  setUpAll(() async {
    expect(AppEnvironment.isSupabaseConfigured, isTrue);
    expect(
      <String>['localhost', '127.0.0.1', '::1'],
      contains(Uri.parse(AppEnvironment.supabaseUrl).host),
      reason: 'Step F acceptance is restricted to local Supabase',
    );
    client = SupabaseClient(
      AppEnvironment.supabaseUrl,
      AppEnvironment.supabaseAnonKey,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    final response = await client.auth.signInWithPassword(
      email: _email,
      password: _password,
    );
    expect(response.user?.id, _userId);

    preferences = await SharedPreferences.getInstance();
    previousOnboarding = preferences.getBool(
      SettingsStorageKeys.onboardingComplete,
    );
    previousLocale = preferences.getString(SettingsStorageKeys.locale);
    final identityKey =
        '${SharedPreferencesActiveIdentityStore.keyPrefix}$_userId';
    previousIdentity = preferences.getString(identityKey);
    expect(
      await preferences.setBool(SettingsStorageKeys.onboardingComplete, true),
      isTrue,
    );
    expect(
      await preferences.setString(SettingsStorageKeys.locale, 'de'),
      isTrue,
    );
    beforeState = await fixtureState();
    expect(beforeState, <String, int>{
      'sellers': 3,
      'products': 2,
      'chats': 3,
      'messages': 3,
      'unread_seed_messages': 3,
    });
  });

  tearDownAll(() async {
    Object? cleanupError;
    Map<String, int>? afterState;
    try {
      afterState = await fixtureState();
      if (!mapEquals(beforeState, afterState)) {
        throw StateError(
          'Step F fixture state changed: before=$beforeState after=$afterState',
        );
      }
      await restorePreferences();
    } catch (error) {
      cleanupError = error;
    }

    binding.reportData ??= <String, dynamic>{};
    binding.reportData!['checks'] = checks;
    binding.reportData!['evidence'] = evidence;
    binding.reportData!['counts'] = <String, Object?>{
      'before': beforeState,
      'after': afterState,
    };
    binding.reportData!['cleanup'] = <String, Object?>{
      'created_rows': 0,
      'uploaded_objects': 0,
      'before_after_match':
          afterState != null && mapEquals(beforeState, afterState),
      'preferences_restored': preferencesRestored,
      'error': cleanupError?.toString(),
    };
    binding.reportData!['tests'] = <String, String>{
      for (final entry in binding.results.entries)
        entry.key: entry.value == 'success' ? 'PASS' : 'FAIL',
    };
    binding.reportData!['runtime'] = <String, String>{
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'device': const String.fromEnvironment(
        'STEP_F_DEVICE',
        defaultValue: 'unknown',
      ),
    };
    await client.auth.signOut();
    await client.dispose();
    if (cleanupError != null) throw cleanupError;
  });

  testWidgets('real iOS Step F identity surfaces', (tester) async {
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
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ZerinApp)),
    );
    router = container.read(appRouterProvider);

    router.go(const MarketplaceRoute(tab: 4).location);
    await until(
      tester,
      () =>
          shows('Deine Verkaufsprofile') &&
          shows('Rojin Demir') &&
          shows('Rojin Atelier') &&
          shows('Verifiziert'),
      'Account shows both seeded identities',
    );
    await tester.tap(find.byKey(const ValueKey('account-business-identity')));
    await until(
      tester,
      () =>
          container
              .read(activeIdentityControllerProvider)
              .valueOrNull
              ?.activeIdentity
              ?.sellerId ==
          'f2c20000-0000-4000-8000-000000000002',
      'Business identity becomes the active preference',
    );
    evidence['switcher'] = <String, Object?>{
      'person': 'f2c20000-0000-4000-8000-000000000001',
      'business': 'f2c20000-0000-4000-8000-000000000002',
      'active': 'business',
    };
    await screenshot(tester, 'identity_switcher');

    router.go(const MarketplaceRoute(tab: 2).location);
    await until(
      tester,
      () => shows('Als Privatperson') && shows('Als Geschäft'),
      'Sell asks for identity before the form',
    );
    final businessChoice = tester.widget<ListTile>(
      find.byKey(const ValueKey('sell-identity-business')),
    );
    expect(businessChoice.selected, isTrue);
    evidence['sell_choice'] = <String, Object?>{
      'person_present': true,
      'business_present': true,
      'active_preselected': 'business',
    };
    await screenshot(tester, 'sell_identity_choice');

    router.go(const MyListingsRoute().location);
    await until(
      tester,
      () =>
          shows('Privat') &&
          shows('Geschäft') &&
          shows('Private Vintage Kamera') &&
          shows('Geschäftliche Keramikserie'),
      'My Listings shows both identity sections and their listing',
    );
    evidence['my_listings'] = <String, Object?>{
      'private_listing': 'f2c30000-0000-4000-8000-000000000001',
      'business_listing': 'f2c30000-0000-4000-8000-000000000002',
    };
    await screenshot(tester, 'my_listings_sections');

    router.go(const ChatInboxRoute().location);
    await until(
      tester,
      () =>
          find.text('Als Rojin Demir').evaluate().length == 2 &&
          shows('Als Rojin Atelier') &&
          shows('Dilan Kaya') &&
          shows('Mina Market'),
      'Inbox labels exact person/private/business chat identities',
    );
    final inbox = await client.rpc<List<dynamic>>(
      'get_chat_inbox',
      params: const <String, dynamic>{'p_chat_id': null},
    );
    final seeded = inbox
        .whereType<Map<Object?, Object?>>()
        .where((item) => _chatIds.contains(item['id']))
        .toList(growable: false);
    final unread = seeded.fold<int>(
      0,
      (sum, item) => sum + ((item['unread_count'] as num?)?.toInt() ?? 0),
    );
    expect(seeded, hasLength(3));
    expect(unread, 3);
    evidence['inbox'] = <String, Object?>{
      'chat_count': seeded.length,
      'unread_total': unread,
      'bindings': <Map<String, Object?>>[
        for (final item in seeded)
          <String, Object?>{
            'chat_id': item['id'],
            'viewer_role': item['viewer_role'],
            'viewer_identity_type': item['viewer_identity_type'],
            'viewer_seller_id': item['viewer_seller_id'],
            'viewer_identity_name': item['viewer_identity_name'],
          },
      ],
    };
    await screenshot(tester, 'inbox_identity_labels');

    expect(checks, hasLength(4));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
