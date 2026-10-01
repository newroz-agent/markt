import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerin_marketplace/features/moderation/domain/moderation_models.dart';
import 'package:zerin_marketplace/features/moderation/domain/moderation_repository.dart';
import 'package:zerin_marketplace/features/moderation/presentation/controllers/moderation_controller.dart';

enum _ActionKind { listing, document, report }

void main() {
  for (final kind in _ActionKind.values) {
    test(
      'delayed ${kind.name} action remains single-flight without a listener',
      () async {
        final repository = _DelayedModerationRepository();
        final container = ProviderContainer(
          overrides: <Override>[
            moderationRepositoryProvider.overrideWithValue(repository),
          ],
        );
        addTearDown(container.dispose);

        final first = _invoke(
          kind,
          container.read(moderationActionProvider.notifier),
        );
        await container.pump();
        final second = _invoke(
          kind,
          container.read(moderationActionProvider.notifier),
        );
        await Future<void>.delayed(Duration.zero);

        repository.gate.complete();
        expect(await Future.wait<bool>(<Future<bool>>[first, second]), <bool>[
          true,
          false,
        ]);
        expect(repository.callsFor(kind), 1);
        expect(container.read(moderationActionProvider).hasValue, isTrue);
        expect(container.read(moderationActionProvider).hasError, isFalse);
      },
    );
  }

  test(
    'a delayed repository error is retained instead of double-completing',
    () async {
      final repository = _DelayedModerationRepository();
      final container = ProviderContainer(
        overrides: <Override>[
          moderationRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final action = container
          .read(moderationActionProvider.notifier)
          .decide(
            productId: 'listing-id',
            decision: ModerationDecision.approve,
          );
      await container.pump();
      final failure = StateError('network failed');
      repository.gate.completeError(failure, StackTrace.current);

      expect(await action, isFalse);
      final state = container.read(moderationActionProvider);
      expect(state.hasError, isTrue);
      expect(identical(state.error, failure), isTrue);
    },
  );
}

Future<bool> _invoke(_ActionKind kind, ModerationAction action) =>
    switch (kind) {
      _ActionKind.listing => action.decide(
        productId: 'listing-id',
        decision: ModerationDecision.approve,
      ),
      _ActionKind.document => action.decideDocument(
        documentId: 'document-id',
        decision: SellerDocumentDecision.approve,
      ),
      _ActionKind.report => action.decideReport(
        reportId: 'report-id',
        action: ReportAction.dismiss,
      ),
    };

class _DelayedModerationRepository implements ModerationRepository {
  final gate = Completer<void>();
  int listingCalls = 0;
  int documentCalls = 0;
  int reportCalls = 0;

  int callsFor(_ActionKind kind) => switch (kind) {
    _ActionKind.listing => listingCalls,
    _ActionKind.document => documentCalls,
    _ActionKind.report => reportCalls,
  };

  @override
  Future<void> moderate({
    required String productId,
    required ModerationDecision decision,
    String? reason,
  }) {
    listingCalls++;
    return gate.future;
  }

  @override
  Future<void> moderateSellerDocument({
    required String documentId,
    required SellerDocumentDecision decision,
    String? note,
  }) {
    documentCalls++;
    return gate.future;
  }

  @override
  Future<void> resolveReport({
    required String reportId,
    required ReportAction action,
    String? reason,
  }) {
    reportCalls++;
    return gate.future;
  }

  @override
  Future<ModerationDashboard> fetchDashboard() => throw UnimplementedError();

  @override
  Future<ModerationReportsQueue> fetchReportsQueue() =>
      throw UnimplementedError();

  @override
  Future<SellerVerificationQueue> fetchSellerVerificationQueue() =>
      throw UnimplementedError();

  @override
  Future<bool> isAdmin() => throw UnimplementedError();
}
