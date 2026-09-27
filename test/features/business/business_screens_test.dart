import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerin_marketplace/features/business/domain/business_models.dart';

import 'business_test_support.dart';

void main() {
  group('hub', () {
    testWidgets('a user without a seller picks the type first, then name '
        'and city, and lands on the documents for that type', (tester) async {
      final repository = FakeBusinessRepository(onboarding());
      await pumpBusiness(tester, repository, location: '/business');

      expect(find.text('Unternehmen eintragen'), findsOneWidget);
      await tester.tap(find.text('Arztpraxis'));
      await tester.enterText(find.byType(TextField).first, 'Praxis Dr. Test');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Berlin').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Weiter zu den Nachweisen'));
      await tester.pumpAndSettle();

      expect(repository.calls, ['create']);
      expect(repository.startedType, DirectoryType.doctor);
      expect(repository.startedName, 'Praxis Dr. Test');
      expect(repository.startedCity, 'Berlin');
      expect(find.text('Personalausweis oder Reisepass'), findsOneWidget);
      expect(find.text('Approbation / Kammernachweis'), findsOneWidget);
      expect(
        find.text('Gewerbeanmeldung oder Handelsregisterauszug'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('an existing business seller only declares its type', (
      tester,
    ) async {
      final repository = FakeBusinessRepository(
        onboarding(seller: businessSeller(type: null)),
      );
      await pumpBusiness(tester, repository, location: '/business');

      expect(find.text('Name des Unternehmens'), findsNothing);
      await tester.tap(find.text('Café'));
      await tester.pump();
      await tester.tap(find.text('Weiter zu den Nachweisen'));
      await tester.pumpAndSettle();
      expect(repository.calls, ['setType']);
      expect(repository.startedType, DirectoryType.cafe);
    });

    testWidgets('private sellers are told the directory needs a business '
        'account', (tester) async {
      final repository = FakeBusinessRepository(
        onboarding(seller: businessSeller(type: null, kind: 'private')),
      );
      await pumpBusiness(tester, repository, location: '/business');

      expect(find.text('Privates Verkaufskonto'), findsOneWidget);
      expect(find.text('Weiter zu den Nachweisen'), findsNothing);
    });

    testWidgets('publishing is disabled until verified', (tester) async {
      final repository = FakeBusinessRepository(
        onboarding(
          seller: businessSeller(),
          profile: restaurantProfile,
          documents: [
            document(SellerDocumentKind.identity, SellerDocumentStatus.pending),
            document(
              SellerDocumentKind.businessRegistration,
              SellerDocumentStatus.pending,
            ),
          ],
        ),
      );
      await pumpBusiness(tester, repository, location: '/business');

      expect(find.text('In Prüfung'), findsOneWidget);
      expect(find.text('0 von 2 freigegeben'), findsOneWidget);
      expect(
        find.text(
          'Veröffentlichen ist möglich, sobald deine Nachweise freigegeben sind.',
        ),
        findsOneWidget,
      );
      final toggle = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(toggle.onChanged, isNull);
    });

    testWidgets('a verified owner publishes from the hub', (tester) async {
      final repository = FakeBusinessRepository(
        onboarding(
          seller: businessSeller(),
          isVerified: true,
          profile: restaurantProfile,
        ),
      );
      await pumpBusiness(tester, repository, location: '/business');

      expect(find.text('Verifiziert'), findsOneWidget);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(repository.savedProfile?.isPublished, isTrue);
      expect(
        repository.savedProfile?.description,
        restaurantProfile.description,
      );
    });
  });

  group('documents', () {
    testWidgets('shows status and the rejection note, and re-uploads a PDF '
        'for the rejected kind', (tester) async {
      final repository = FakeBusinessRepository(
        onboarding(
          seller: businessSeller(type: DirectoryType.doctor),
          documents: [
            document(
              SellerDocumentKind.identity,
              SellerDocumentStatus.approved,
            ),
            document(
              SellerDocumentKind.medicalProfessionalRegistration,
              SellerDocumentStatus.rejected,
              note: 'Bitte die Urkunde vollständig scannen.',
            ),
          ],
        ),
      );
      await pumpBusiness(tester, repository, location: '/business/documents');

      expect(find.text('Freigegeben'), findsOneWidget);
      expect(find.text('Abgelehnt'), findsOneWidget);
      expect(
        find.text('Hinweis des Teams: Bitte die Urkunde vollständig scannen.'),
        findsOneWidget,
      );

      await tester.ensureVisible(find.text('Neu hochladen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Neu hochladen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PDF auswählen'));
      await tester.pumpAndSettle();

      expect(
        repository.uploaded?.kind,
        SellerDocumentKind.medicalProfessionalRegistration,
      );
      expect(repository.uploaded?.file.mimeType, 'application/pdf');
      expect(
        find.text('Hochgeladen. Wir prüfen den Nachweis.'),
        findsOneWidget,
      );
    });

    testWidgets('restaurants need identity and business registration; a '
        'pending document can be withdrawn', (tester) async {
      final repository = FakeBusinessRepository(
        onboarding(
          seller: businessSeller(),
          documents: [
            document(SellerDocumentKind.identity, SellerDocumentStatus.pending),
          ],
        ),
      );
      await pumpBusiness(tester, repository, location: '/business/documents');

      expect(
        find.text('Gewerbeanmeldung oder Handelsregisterauszug'),
        findsOneWidget,
      );
      expect(find.text('Approbation / Kammernachweis'), findsNothing);
      expect(find.text('Fehlt'), findsOneWidget);
      await tester.tap(find.text('Zurückziehen'));
      await tester.pumpAndSettle();
      expect(repository.withdrawn?.kind, SellerDocumentKind.identity);
    });

    testWidgets('the type is fixed once a profile exists', (tester) async {
      final repository = FakeBusinessRepository(
        onboarding(seller: businessSeller(), profile: restaurantProfile),
      );
      await pumpBusiness(tester, repository, location: '/business/documents');

      expect(
        find.text('Die Art kannst du jetzt nur noch im Profil ändern.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Café'));
      await tester.pumpAndSettle();
      expect(repository.calls, isNot(contains('setType')));
    });
  });

  group('editors', () {
    testWidgets('profile editor is type-aware and validates before saving', (
      tester,
    ) async {
      final repository = FakeBusinessRepository(
        onboarding(seller: businessSeller(type: DirectoryType.doctor)),
      );
      await pumpBusiness(
        tester,
        repository,
        location: '/business/profile',
        logicalHeight: 2400,
      );

      expect(find.text('Fachrichtung'), findsWidgets);
      expect(find.text('Küche'), findsNothing);

      await tester.enterText(find.byType(TextField).at(0), 'Zu kurz');
      await tester.enterText(find.byType(TextField).at(1), '030 1234567');
      await tester.ensureVisible(find.text('Speichern'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
      expect(
        find.text('Die Beschreibung muss 20 bis 3000 Zeichen lang sein.'),
        findsOneWidget,
      );
      expect(repository.savedProfile, isNull);

      await tester.enterText(
        find.byType(TextField).at(0),
        'Hausarztpraxis mit kurdisch- und arabischsprachigem Team.',
      );
      await tester.tap(find.text('Kurdî'));
      await tester.tap(find.byType(DropdownButtonFormField<DoctorSpecialty>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Allgemeinmedizin').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gesetzlich und privat'));
      await tester.ensureVisible(find.text('Speichern'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      final saved = repository.savedProfile!;
      expect(saved.type, DirectoryType.doctor);
      expect(saved.specialty, DoctorSpecialty.generalMedicine);
      expect(saved.insurance, InsuranceAcceptance.both);
      expect(saved.languages, {SpokenLanguage.kurdish});
      expect(saved.isPublished, isFalse);
    });

    testWidgets('hours editor shows overnight slots, adds and removes slots', (
      tester,
    ) async {
      final repository = FakeBusinessRepository(
        onboarding(
          seller: businessSeller(),
          profile: restaurantProfile,
          hours: [
            OpeningInterval(
              weekday: 5,
              opensAt: DirectoryTime.parse('18:00'),
              closesAt: DirectoryTime.parse('02:00'),
            ),
          ],
        ),
      );
      await pumpBusiness(tester, repository, location: '/business/hours');

      expect(find.text('18:00 – 02:00 (nächster Tag)'), findsOneWidget);
      final overnight = tester.renderObject<RenderParagraph>(
        find.text('18:00 – 02:00 (nächster Tag)'),
      );
      expect(
        overnight.didExceedMaxLines,
        isFalse,
        reason: 'overnight label fits at phone width',
      );
      expect(find.text('Geschlossen'), findsNWidgets(6));

      await tester.tap(find.byTooltip('Zeitfenster hinzufügen').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('11:00 – 22:00'), findsOneWidget);

      await tester.tap(find.byTooltip('Zeitfenster entfernen').last);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Speichern'),
        ),
      );
      await tester.pumpAndSettle();

      final saved = repository.savedHours!;
      expect(saved, hasLength(1));
      expect(saved.single.weekday, 1, reason: 'Monday slot kept');
      expect(saved.single.opensAt.databaseValue, '11:00');
    });

    testWidgets('menu editor toggles availability, adds a dish and saves', (
      tester,
    ) async {
      final repository = FakeBusinessRepository(
        onboarding(
          seller: businessSeller(),
          profile: restaurantProfile,
          menu: const [
            MenuSectionDraft(
              name: 'Grill',
              items: [MenuItemDraft(name: 'Kebab Duhok', priceCents: 1450)],
            ),
          ],
        ),
      );
      await pumpBusiness(tester, repository, location: '/business/menu');

      expect(find.text('Grill'), findsOneWidget);
      expect(find.textContaining('14,50'), findsOneWidget);
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Nicht verfügbar'), findsOneWidget);

      await tester.tap(find.text('Gericht hinzufügen'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'Dolma');
      await tester.enterText(find.byType(TextField).at(2), '9,90');
      await tester.tap(find.text('Vegan'));
      await tester.tap(find.text('Fertig'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Speichern').first);
      await tester.pumpAndSettle();
      final items = repository.savedMenu!.single.items;
      expect(items.first.isAvailable, isFalse);
      expect(items.last.name, 'Dolma');
      expect(items.last.priceCents, 990);
      expect(items.last.isVegan, isTrue);
      expect(items.last.isVegetarian, isTrue);
    });
  });
}
