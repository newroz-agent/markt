import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
import 'package:zerin_marketplace/features/business/domain/business_models.dart';
import 'package:zerin_marketplace/features/business/domain/business_repository.dart';
import 'package:zerin_marketplace/features/business/presentation/controllers/business_controller.dart';
import 'package:zerin_marketplace/features/settings/presentation/controllers/app_settings_controller.dart';

// Accounts from supabase/snippets/step_e2_local_seed.sql (local-only constants)
// and the admin account from the admin-expansion harness.
const _ownerPassword = 'ZerinStepE2!2026';
const _newOwner = 'step-e2-ios-new@example.invalid';
const _doctor = 'step-e2-ios-doctor@example.invalid';
const _restaurant = 'step-e2-ios-restaurant@example.invalid';
const _adminEmail = 'step-b-ios-admin@example.invalid';
const _adminPassword = 'ZerinStepB!2026';

/// The native document picker cannot be driven from a test, so the harness
/// hands the real upload path a generated PDF. Everything after picking (the
/// private bucket, the document row, the admin queue) is real.
class _HarnessDocumentFiles implements DocumentFileService {
  static final _pdf = Uint8List.fromList(
    utf8.encode(
      '%PDF-1.4\n1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\n'
      '2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj\n'
      '3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 595 842]>>endobj\n'
      'trailer<</Root 1 0 R>>\n%%EOF\n',
    ),
  );

  @override
  Future<PickedDocumentFile?> pickPdf() async => PickedDocumentFile(
    bytes: _pdf,
    mimeType: 'application/pdf',
    extension: 'pdf',
  );

  @override
  Future<PickedDocumentFile?> takePhoto() async => null;

  @override
  Future<PickedDocumentFile?> pickImage() async => null;

  @override
  Future<Uint8List?> pickCoverImage() async => null;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late SupabaseClient client;
  late SharedPreferences preferences;
  late GoRouter router;
  final checks = <String, String>{};
  final evidence = <String, Object?>{};

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
    final bytes = await binding.takeScreenshot('step_e2_$name');
    expect(bytes.length, greaterThan(1000));
    checks[name] = 'PASS';
  }

  Future<void> signIn(String email, String password) async {
    await client.auth.signOut();
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    expect(response.session, isNotNull, reason: 'sign in $email');
  }

  setUpAll(() async {
    expect(AppEnvironment.isSupabaseConfigured, isTrue);
    expect(
      <String>['localhost', '127.0.0.1', '::1'],
      contains(Uri.parse(AppEnvironment.supabaseUrl).host),
      reason: 'Step E2 acceptance is restricted to local Supabase',
    );
    client = SupabaseClient(
      AppEnvironment.supabaseUrl,
      AppEnvironment.supabaseAnonKey,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    preferences = await SharedPreferences.getInstance();
    await preferences.setBool(SettingsStorageKeys.onboardingComplete, true);
  });

  tearDownAll(() async {
    binding.reportData ??= <String, dynamic>{};
    binding.reportData!['checks'] = checks;
    binding.reportData!['evidence'] = evidence;
    binding.reportData!['tests'] = <String, String>{
      for (final entry in binding.results.entries)
        entry.key: entry.value == 'success' ? 'PASS' : 'FAIL',
    };
    binding.reportData!['runtime'] = <String, String>{
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'device': const String.fromEnvironment(
        'STEP_E2_DEVICE',
        defaultValue: 'unknown',
      ),
    };
    await client.auth.signOut();
    await client.dispose();
  });

  testWidgets('real iOS owner onboarding, documents, admin queue, editors', (
    tester,
  ) async {
    await signIn(_newOwner, _ownerPassword);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(preferences),
          supabaseClientProvider.overrideWithValue(client),
          documentFileServiceProvider.overrideWithValue(
            _HarnessDocumentFiles(),
          ),
        ],
        child: const ZerinApp(),
      ),
    );
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ZerinApp)),
    );
    await container
        .read(appSettingsControllerProvider.notifier)
        .setLocale('de');
    router = container.read(appRouterProvider);

    // 1. A user without a seller picks the type first.
    router.go(const BusinessHubRoute().location);
    await until(
      tester,
      () => shows('Unternehmen eintragen') && shows('Arztpraxis'),
      'Start card offers the directory types',
    );
    await tester.tap(find.text('Arztpraxis'));
    await tester.enterText(find.byType(TextField).first, 'Praxis Dr. Neu');
    await screenshot(tester, 'start');

    // 2. Doctor: identity approved, medical proof rejected with a note.
    await signIn(_doctor, _ownerPassword);
    router.go(const BusinessDocumentsRoute().location);
    await until(
      tester,
      () =>
          shows('Approbation / Kammernachweis') &&
          shows('Abgelehnt') &&
          shows('Die Approbationsurkunde ist abgeschnitten'),
      'Doctor sees the medical requirement, its rejection and the note',
    );
    await screenshot(tester, 'documents_rejected');

    // 3. Re-upload the medical proof as a PDF into the private bucket.
    await tester.ensureVisible(find.text('Neu hochladen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Neu hochladen'));
    await until(tester, () => shows('PDF auswählen'), 'Upload sources shown');
    await tester.tap(find.text('PDF auswählen'));
    await until(
      tester,
      () => shows('In Prüfung') && !shows('Abgelehnt'),
      'The uploaded medical proof is now in review',
    );
    final onboarding = DirectoryOnboarding.fromJson(
      await client.rpc<Map<String, dynamic>>('get_my_directory_onboarding'),
    );
    final uploaded = onboarding.latestDocument(
      SellerDocumentKind.medicalProfessionalRegistration,
    )!;
    expect(uploaded.status, SellerDocumentStatus.pending);
    expect(uploaded.isPdf, isTrue);
    final objects = await client.storage
        .from('seller-documents')
        .list(
          path: '${onboarding.seller!.id}/medical_professional_registration',
        );
    expect(
      objects.map((object) => object.name),
      contains(uploaded.storagePath.split('/').last),
    );
    evidence['uploaded_document'] = <String, Object?>{
      'kind': 'medical_professional_registration',
      'status': uploaded.status.name,
      'mime_type': uploaded.mimeType,
      'stored_in_private_bucket': true,
    };
    await screenshot(tester, 'documents_uploaded');

    // 4. The admin verification queue receives the upload.
    await signIn(_adminEmail, _adminPassword);
    router.go(const ModerationRoute().location);
    await until(
      tester,
      () => find.byType(ChoiceChip).evaluate().length > 2,
      'Admin hub loaded',
    );
    await tester.tap(find.byType(ChoiceChip).at(2));
    await until(
      tester,
      () =>
          shows('Praxis Dr. Ava Rahimi') &&
          shows('Approbation / Kammernachweis'),
      'Admin queue lists the doctor\'s medical proof',
    );
    await screenshot(tester, 'admin_queue');

    // 5. Verified restaurant: hub and the three editors.
    await signIn(_restaurant, _ownerPassword);
    router.go(const BusinessHubRoute().location);
    await until(
      tester,
      () => shows('Zagros Grill') && shows('Verifiziert'),
      'Verified restaurant hub',
    );
    await screenshot(tester, 'hub');

    router.go(const BusinessProfileRoute().location);
    await until(
      tester,
      () => shows('Kurdische Grillküche') && shows('Küche'),
      'Profile editor shows the restaurant fields',
    );
    await screenshot(tester, 'profile');

    router.go(const BusinessHoursRoute().location);
    await until(
      tester,
      () => shows('Samstag') && shows('(nächster Tag)'),
      'Hours editor shows the overnight Saturday slot',
    );
    await screenshot(tester, 'hours');

    router.go(const BusinessMenuRoute().location);
    await until(
      tester,
      () => shows('Kebab Duhok') && shows('Nicht verfügbar'),
      'Menu editor shows sections, dishes and availability',
    );
    await screenshot(tester, 'menu');

    expect(checks, hasLength(8));
  });
}
