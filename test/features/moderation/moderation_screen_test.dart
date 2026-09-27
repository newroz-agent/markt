import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/features/moderation/domain/moderation_models.dart';
import 'package:zerin_marketplace/features/moderation/domain/moderation_repository.dart';
import 'package:zerin_marketplace/features/moderation/presentation/controllers/moderation_controller.dart';
import 'package:zerin_marketplace/features/moderation/presentation/moderation_screen.dart';
import 'package:zerin_marketplace/l10n/app_localizations.dart';

final _item = ModerationItem(
  id: 'listing-id',
  title: 'Zu prüfende Kamera',
  description: 'Vollständige Beschreibung für die Moderation.',
  condition: 'used',
  priceCents: 9900,
  currency: 'EUR',
  city: 'Hamburg',
  specifications: <String, dynamic>{},
  createdAt: DateTime.utc(2026, 9, 14),
  sellerName: 'Test Verkäufer',
  sellerKind: 'private',
  categoryNames: <String, String>{'de': 'Elektronik'},
  imageUrls: <String>[],
);

final _dashboard = ModerationDashboard(
  counts: ModerationCounts(pending: 1, approvedToday: 2, rejectedToday: 3),
  items: <ModerationItem>[_item],
);

final _document = SellerDocumentItem(
  id: 'document-id',
  sellerId: 'seller-id',
  kind: 'medical_professional_registration',
  mimeType: 'image/jpeg',
  createdAt: DateTime.utc(2026, 9, 24),
  shopName: 'Test Shop',
  sellerKind: 'business',
  signedUrl: null,
);

final _verificationQueue = SellerVerificationQueue(
  items: <SellerDocumentItem>[_document],
  pending: 1,
);

final _report = ModerationReport(
  id: 'report-id',
  productId: 'product-id',
  sellerId: null,
  reviewId: null,
  messageId: null,
  reporterId: null,
  reason: 'spam',
  details: 'Verdächtiges Angebot',
  status: 'pending',
  createdAt: DateTime.utc(2026, 9, 24),
  targetType: 'product',
  title: 'Gemeldete Kamera',
  productStatus: 'active',
  shopName: 'Test Shop',
  messageKind: null,
  messageBody: null,
  messageMediaPath: null,
  messageProductId: null,
);

final _reportsQueue = ModerationReportsQueue(
  items: <ModerationReport>[_report],
  open: 1,
);

class _DecisionCall {
  const _DecisionCall(this.productId, this.decision, this.reason);

  final String productId;
  final ModerationDecision decision;
  final String? reason;
}

class _DocumentCall {
  const _DocumentCall(this.documentId, this.decision, this.note);

  final String documentId;
  final SellerDocumentDecision decision;
  final String? note;
}

class _ReportCall {
  const _ReportCall(this.reportId, this.action, this.reason);

  final String reportId;
  final ReportAction action;
  final String? reason;
}

class _FakeModerationRepository implements ModerationRepository {
  final calls = <_DecisionCall>[];
  final documentCalls = <_DocumentCall>[];
  final reportCalls = <_ReportCall>[];

  @override
  Future<ModerationDashboard> fetchDashboard() async => _dashboard;

  @override
  Future<bool> isAdmin() async => true;

  @override
  Future<void> moderate({
    required String productId,
    required ModerationDecision decision,
    String? reason,
  }) async {
    calls.add(_DecisionCall(productId, decision, reason));
  }

  @override
  Future<SellerVerificationQueue> fetchSellerVerificationQueue() async =>
      _verificationQueue;

  @override
  Future<ModerationReportsQueue> fetchReportsQueue() async => _reportsQueue;

  @override
  Future<void> moderateSellerDocument({
    required String documentId,
    required SellerDocumentDecision decision,
    String? note,
  }) async {
    documentCalls.add(_DocumentCall(documentId, decision, note));
  }

  @override
  Future<void> resolveReport({
    required String reportId,
    required ReportAction action,
    String? reason,
  }) async {
    reportCalls.add(_ReportCall(reportId, action, reason));
  }
}

Widget _app({
  required bool admin,
  required _FakeModerationRepository repository,
}) => ProviderScope(
  overrides: <Override>[
    moderationRepositoryProvider.overrideWithValue(repository),
    currentUserIsAdminProvider.overrideWith((ref) async => admin),
    moderationDashboardProvider.overrideWith((ref) async => _dashboard),
    sellerVerificationQueueProvider.overrideWith(
      (ref) async => _verificationQueue,
    ),
    moderationReportsQueueProvider.overrideWith((ref) async => _reportsQueue),
  ],
  child: MaterialApp(
    locale: const Locale('de'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: AppTheme.light,
    home: const ModerationScreen(),
  ),
);

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 150));
}

void main() {
  testWidgets('non-admin never receives the moderation queue', (tester) async {
    final repository = _FakeModerationRepository();
    await tester.pumpWidget(_app(admin: false, repository: repository));
    await _settle(tester);

    expect(find.byIcon(Icons.admin_panel_settings_outlined), findsOneWidget);
    expect(find.text('Zu prüfende Kamera'), findsNothing);
  });

  testWidgets('admin overview links into each queue', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeModerationRepository();
    await tester.pumpWidget(_app(admin: true, repository: repository));
    await _settle(tester);

    expect(find.text('Offene Angebote'), findsOneWidget);
    expect(find.text('Offene Verkäuferdokumente'), findsOneWidget);
    expect(find.text('Offene Meldungen'), findsOneWidget);
  });

  testWidgets('admin sees counts and can approve a pending listing', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeModerationRepository();
    await tester.pumpWidget(_app(admin: true, repository: repository));
    await _settle(tester);

    await tester.tap(find.byType(ChoiceChip).at(1));
    await _settle(tester);

    expect(find.text('Zu prüfende Kamera'), findsOneWidget);
    expect(find.textContaining('Test Verkäufer'), findsOneWidget);
    expect(find.textContaining('Elektronik'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('moderation-approve-listing-id')),
    );
    await _settle(tester);

    expect(repository.calls, hasLength(1));
    expect(repository.calls.single.productId, 'listing-id');
    expect(repository.calls.single.decision, ModerationDecision.approve);
    expect(repository.calls.single.reason, isNull);
  });

  testWidgets('admin rejection passes the optional reason', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeModerationRepository();
    await tester.pumpWidget(_app(admin: true, repository: repository));
    await _settle(tester);

    await tester.tap(find.byType(ChoiceChip).at(1));
    await _settle(tester);

    await tester.tap(
      find.byKey(const ValueKey('moderation-reject-listing-id')),
    );
    await _settle(tester);
    await tester.enterText(find.byType(TextField).last, 'Unscharfes Foto');
    await tester.tap(find.text('Ablehnen').last);
    await _settle(tester);

    expect(repository.calls, hasLength(1));
    expect(repository.calls.single.productId, 'listing-id');
    expect(repository.calls.single.decision, ModerationDecision.reject);
    expect(repository.calls.single.reason, 'Unscharfes Foto');
  });

  testWidgets('admin can approve a seller document', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeModerationRepository();
    await tester.pumpWidget(_app(admin: true, repository: repository));
    await _settle(tester);

    await tester.tap(find.byType(ChoiceChip).at(2));
    await _settle(tester);

    expect(find.text('Test Shop'), findsOneWidget);
    expect(find.textContaining('Approbation / Kammernachweis'), findsOneWidget);
    expect(find.text('Freigeben'), findsOneWidget);

    await tester.tap(find.text('Freigeben'));
    await _settle(tester);

    expect(repository.documentCalls, hasLength(1));
    expect(repository.documentCalls.single.documentId, 'document-id');
    expect(
      repository.documentCalls.single.decision,
      SellerDocumentDecision.approve,
    );
  });

  testWidgets('admin rejection of a document passes the note', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeModerationRepository();
    await tester.pumpWidget(_app(admin: true, repository: repository));
    await _settle(tester);

    await tester.tap(find.byType(ChoiceChip).at(2));
    await _settle(tester);

    await tester.tap(find.text('Ablehnen'));
    await _settle(tester);
    await tester.enterText(find.byType(TextField).last, 'Unleserlich');
    await tester.tap(find.text('Ablehnen').last);
    await _settle(tester);

    expect(repository.documentCalls, hasLength(1));
    expect(repository.documentCalls.single.documentId, 'document-id');
    expect(
      repository.documentCalls.single.decision,
      SellerDocumentDecision.reject,
    );
    expect(repository.documentCalls.single.note, 'Unleserlich');
  });

  testWidgets('admin can dismiss and block from the reports queue', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeModerationRepository();
    await tester.pumpWidget(_app(admin: true, repository: repository));
    await _settle(tester);

    await tester.tap(find.byType(ChoiceChip).at(3));
    await _settle(tester);

    expect(find.text('product: Gemeldete Kamera'), findsOneWidget);
    expect(find.text('Verwerfen'), findsOneWidget);
    expect(find.text('Angebot sperren'), findsOneWidget);

    await tester.tap(find.text('Verwerfen'));
    await _settle(tester);

    expect(repository.reportCalls, hasLength(1));
    expect(repository.reportCalls.single.reportId, 'report-id');
    expect(repository.reportCalls.single.action, ReportAction.dismiss);

    await tester.tap(find.text('Angebot sperren'));
    await _settle(tester);
    await tester.tap(find.text('Sperren').last);
    await _settle(tester);

    expect(repository.reportCalls, hasLength(2));
    expect(repository.reportCalls.last.action, ReportAction.blockListing);
  });
}
