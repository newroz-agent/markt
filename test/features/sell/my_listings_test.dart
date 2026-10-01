import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/features/identity/domain/identity.dart';
import 'package:zerin_marketplace/features/sell/domain/sell_models.dart';
import 'package:zerin_marketplace/features/sell/presentation/controllers/sell_controller.dart';
import 'package:zerin_marketplace/features/sell/presentation/my_listings_screen.dart';
import 'package:zerin_marketplace/l10n/app_localizations.dart';

const _privateIdentity = MarketplaceIdentity(
  type: MarketplaceIdentityType.person,
  sellerId: '11111111-1111-4111-8111-111111111111',
  sellerKind: 'private',
  sellerStatus: 'approved',
  label: 'Alice Privat',
  avatarUrl: null,
  username: 'alice',
);
const _businessIdentity = MarketplaceIdentity(
  type: MarketplaceIdentityType.business,
  sellerId: '22222222-2222-4222-8222-222222222222',
  sellerKind: 'business',
  sellerStatus: 'approved',
  label: 'Alice Geschäft',
  avatarUrl: null,
  username: null,
);

MyListing _listing({
  required MarketplaceIdentity identity,
  required String id,
  required String title,
  required ListingStatus status,
  String? reason,
}) => MyListing(
  identity: identity,
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

final _items = <MyListing>[
  _listing(
    identity: _privateIdentity,
    id: 'pending-id',
    title: 'Noch in Prüfung',
    status: ListingStatus.pendingReview,
  ),
  _listing(
    identity: _businessIdentity,
    id: 'rejected-id',
    title: 'Abgelehntes Angebot',
    status: ListingStatus.rejected,
    reason: 'Foto zeigt den Artikel nicht klar.',
  ),
];

Widget _app(Locale locale) => ProviderScope(
  overrides: <Override>[myListingsProvider.overrideWith((ref) async => _items)],
  child: MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: AppTheme.light,
    home: const MyListingsScreen(),
  ),
);

void main() {
  testWidgets('owner sees identity sections and moderation states', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(const Locale('de')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Privat'), findsOneWidget);
    expect(find.text('Geschäft'), findsOneWidget);
    expect(find.text('Alice Privat'), findsOneWidget);
    expect(find.text('Alice Geschäft'), findsOneWidget);
    expect(find.text('Noch in Prüfung'), findsOneWidget);
    expect(find.text('Wird geprüft'), findsOneWidget);
    expect(find.text('Abgelehntes Angebot'), findsOneWidget);
    expect(find.text('Abgelehnt'), findsOneWidget);
    expect(
      find.textContaining('Foto zeigt den Artikel nicht klar.'),
      findsOneWidget,
    );
  });

  testWidgets('Arabic My Listings identity sections are right-to-left', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(const Locale('ar')));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(MyListingsScreen));
    expect(Directionality.of(context), TextDirection.rtl);
    expect(find.text('خاص'), findsOneWidget);
    expect(find.text('نشاط تجاري'), findsOneWidget);
    expect(find.text('Alice Privat'), findsOneWidget);
    expect(find.text('Alice Geschäft'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
