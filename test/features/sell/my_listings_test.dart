import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/features/sell/domain/sell_models.dart';
import 'package:zerin_marketplace/features/sell/presentation/controllers/sell_controller.dart';
import 'package:zerin_marketplace/features/sell/presentation/my_listings_screen.dart';
import 'package:zerin_marketplace/l10n/app_localizations.dart';

MyListing _listing({
  required String id,
  required String title,
  required ListingStatus status,
  String? reason,
}) => MyListing(
  id: id,
  title: title,
  priceCents: 4200,
  currency: 'EUR',
  city: 'Berlin',
  condition: 'used',
  status: status,
  moderationReason: reason,
  createdAt: DateTime.utc(2026, 9, 14),
  imageUrls: const <String>[],
);

void main() {
  testWidgets('owner sees pending and rejected states including reason', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          myListingsProvider.overrideWith(
            (ref) async => <MyListing>[
              _listing(
                id: 'pending-id',
                title: 'Noch in Prüfung',
                status: ListingStatus.pendingReview,
              ),
              _listing(
                id: 'rejected-id',
                title: 'Abgelehntes Angebot',
                status: ListingStatus.rejected,
                reason: 'Foto zeigt den Artikel nicht klar.',
              ),
            ],
          ),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.light,
          home: const MyListingsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Noch in Prüfung'), findsOneWidget);
    expect(find.text('Wird geprüft'), findsOneWidget);
    expect(find.text('Abgelehntes Angebot'), findsOneWidget);
    expect(find.text('Abgelehnt'), findsOneWidget);
    expect(
      find.textContaining('Foto zeigt den Artikel nicht klar.'),
      findsOneWidget,
    );
  });
}
