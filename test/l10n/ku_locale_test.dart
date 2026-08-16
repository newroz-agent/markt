import 'package:flutter/cupertino.dart' show CupertinoLocalizations;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerin_marketplace/l10n/ku_localizations.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

/// Mirrors the delegate list in `ZerinApp` so a regression there is caught here.
const List<LocalizationsDelegate<dynamic>> _delegates =
    <LocalizationsDelegate<dynamic>>[
      ...kuFallbackDelegates,
      ...AppLocalizations.localizationsDelegates,
    ];

/// Renders the date the way `privacy_screen.dart` and `legal_screen.dart` do.
class _FormatsADate extends StatelessWidget {
  const _FormatsADate();

  @override
  Widget build(BuildContext context) {
    return Text(
      MaterialLocalizations.of(context).formatFullDate(DateTime(2026, 3, 14)),
    );
  }
}

Future<void> _pumpAt(WidgetTester tester, Locale locale) {
  return tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: AppLocale.supportedLocales,
      localizationsDelegates: _delegates,
      home: const Scaffold(body: _FormatsADate()),
    ),
  );
}

void main() {
  group('ku locale', () {
    // The bug this guards: Flutter ships no Kurdish translations, so without
    // the fallback delegates `MaterialLocalizations.of` returns null and its
    // `!` throws on every screen that formats a date.
    //
    // This group runs first on purpose. A `ku` launch must stand on its own —
    // when another locale renders first it primes `intl`'s date symbols as a
    // side effect, which masked a missing `initializeDateFormatting` here.
    testWidgets('formats dates with Kurmanji month and weekday names', (
      tester,
    ) async {
      await _pumpAt(tester, AppLocale.kurdish);

      expect(tester.takeException(), isNull);
      final formattedDate = tester.widget<Text>(find.byType(Text)).data!;
      expect(formattedDate, contains('Adar'));
      expect(formattedDate, contains('Şemî'));

      for (final englishName in <String>[
        'Sunday',
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ]) {
        expect(formattedDate, isNot(contains(englishName)));
      }
    });

    testWidgets('uses Kurmanji for common framework labels', (tester) async {
      await _pumpAt(tester, AppLocale.kurdish);

      final context = tester.element(find.byType(_FormatsADate));
      final material = MaterialLocalizations.of(context);
      final cupertino = CupertinoLocalizations.of(context);

      expect(material.okButtonLabel, 'Temam');
      expect(material.cancelButtonLabel, 'Betal bike');
      expect(material.closeButtonLabel, 'Bigire');
      expect(material.backButtonTooltip, 'Vegere');
      expect(material.searchFieldLabel, 'Bigere');
      expect(material.copyButtonLabel, 'Kopî bike');
      expect(material.pasteButtonLabel, 'Pêve bike');
      expect(cupertino.cancelButtonLabel, 'Betal bike');
      expect(cupertino.backButtonLabel, 'Vegere');
      expect(cupertino.searchTextFieldPlaceholderLabel, 'Bigere');
      expect(cupertino.copyButtonLabel, 'Kopî bike');
      expect(cupertino.pasteButtonLabel, 'Pêve bike');
    });

    testWidgets('resolves our own Kurdish strings, not English', (
      tester,
    ) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          locale: AppLocale.kurdish,
          supportedLocales: AppLocale.supportedLocales,
          localizationsDelegates: _delegates,
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(l10n.localeName, 'ku');
      expect(l10n.navigationHome, 'Destpêk');
    });

    testWidgets('stays left-to-right', (tester) async {
      await _pumpAt(tester, AppLocale.kurdish);

      final context = tester.element(find.byType(_FormatsADate));
      expect(Directionality.of(context), TextDirection.ltr);
      expect(AppLocale.isRtl(AppLocale.kurdish), isFalse);
    });

    testWidgets('the switcher labels it with the endonym', (tester) async {
      for (final locale in AppLocale.supportedLocales) {
        late AppLocalizations l10n;
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            supportedLocales: AppLocale.supportedLocales,
            localizationsDelegates: _delegates,
            home: Builder(
              builder: (context) {
                l10n = AppLocalizations.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(
          AppLocale.kurdish.localizedDisplayName(l10n),
          startsWith('Kurdî'),
          reason:
              'Kurdish should read as its own endonym under ${locale.languageCode}',
        );
      }
    });
  });

  group('every supported locale', () {
    // ku is not the only locale that could lose a framework delegate; this
    // catches the same class of breakage for any locale added later.
    for (final locale in AppLocale.supportedLocales) {
      testWidgets('${locale.languageCode} formats a date', (tester) async {
        await _pumpAt(tester, locale);

        expect(tester.takeException(), isNull);
        expect(find.byType(Text), findsOneWidget);
      });
    }

    testWidgets('ar is right-to-left', (tester) async {
      await _pumpAt(tester, AppLocale.arabic);

      final context = tester.element(find.byType(_FormatsADate));
      expect(Directionality.of(context), TextDirection.rtl);
    });

    testWidgets('an unsupported locale normalizes to German', (tester) async {
      expect(AppLocale.normalize(const Locale('fr')), AppLocale.german);
      expect(AppLocale.normalize(const Locale('ku', 'IQ')), AppLocale.kurdish);
      expect(AppLocale.normalize(const Locale('de', 'AT')), AppLocale.german);
    });
  });
}
