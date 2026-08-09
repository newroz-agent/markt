import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/app_button.dart';

Widget _host(Widget child, {Brightness brightness = Brightness.light}) {
  return MaterialApp(
    theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
    home: Scaffold(body: Center(child: child)),
  );
}

/// The gradient painted behind the single accent button.
Gradient? _accentGradient(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byType(AppButton),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  return (box.decoration as BoxDecoration).gradient;
}

void main() {
  group('AppButton.accent', () {
    testWidgets('paints the gold sweep when enabled', (tester) async {
      await tester.pumpWidget(
        _host(AppButton.accent(label: 'Weiter', onPressed: () {})),
      );

      final gradient = _accentGradient(tester);
      expect(gradient, isNotNull);
      expect(gradient!.colors.first, AppColors.gold300);
      expect(gradient.colors.last, AppColors.gold500);
    });

    testWidgets('drops the gradient entirely when disabled', (tester) async {
      await tester.pumpWidget(
        _host(const AppButton.accent(label: 'Weiter', onPressed: null)),
      );

      // Gold never reads as "available but greyed out": the sweep is removed,
      // not faded.
      expect(_accentGradient(tester), isNull);
    });

    testWidgets('labels itself as a button for assistive tech', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          AppButton.accent(
            label: 'Weiter',
            onPressed: () {},
            semanticLabel: 'Zur Kasse',
          ),
        ),
      );

      // One node, not two: the button publishes its own semantics and the
      // override label rides along on it.
      expect(
        tester.getSemantics(find.byType(AppButton)),
        isSemantics(scopesRoute: true),
        reason: 'AppButton must not add a semantics node of its own; the '
            'nearest node above it should be the route scope',
      );
      expect(
        tester.getSemantics(find.byType(ElevatedButton)),
        isSemantics(
          label: 'Zur Kasse',
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
          isFocusable: true,
        ),
      );
      expect(find.bySemanticsLabel('Weiter'), findsNothing);
    });

    testWidgets('meets the minimum touch target', (tester) async {
      await tester.pumpWidget(
        _host(AppButton.accent(label: 'Weiter', onPressed: () {})),
      );

      final size = tester.getSize(find.byType(AppButton));
      expect(size.height, greaterThanOrEqualTo(AppSizes.minimumTouchTarget));
    });

    testWidgets('a second gold CTA on one screen is reported', (tester) async {
      await tester.pumpWidget(
        _host(
          Column(
            children: <Widget>[
              AppButton.accent(label: 'Kaufen', onPressed: () {}),
              AppButton.accent(label: 'Merken', onPressed: () {}),
            ],
          ),
        ),
      );

      final error = tester.takeException();
      expect(error, isA<FlutterError>());
      expect(
        error.toString(),
        contains('mounts 2 AppButtonVariant.accent buttons'),
      );
    });

    testWidgets('one gold CTA per route survives a transition', (tester) async {
      // Both screens are mounted at once mid-push. Each owns exactly one gold
      // CTA, so neither may be flagged.
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          navigatorKey: navigator,
          home: Scaffold(
            body: AppButton.accent(label: 'Erste', onPressed: () {}),
          ),
        ),
      );

      unawaited(
        navigator.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              body: AppButton.accent(label: 'Zweite', onPressed: () {}),
            ),
          ),
        ),
      );
      await tester.pump();
      // Mid-animation: both routes are on screen.
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('a route releases its slot when popped', (tester) async {
      // Guards the bookkeeping: if the counter leaked on dispose, the second
      // visit to an identical screen would be flagged.
      for (var visit = 0; visit < 3; visit++) {
        await tester.pumpWidget(
          _host(AppButton.accent(label: 'Besuch $visit', onPressed: () {})),
        );
        await tester.pumpWidget(_host(const SizedBox.shrink()));
        expect(tester.takeException(), isNull, reason: 'visit $visit');
      }
    });
  });

  group('AppButton other variants', () {
    testWidgets('carry no gold and stay unrestricted in number', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Column(
            children: <Widget>[
              AppButton.primary(label: 'Primär', onPressed: () {}),
              AppButton.secondary(label: 'Sekundär', onPressed: () {}),
              AppButton.ghost(label: 'Ghost', onPressed: () {}),
              AppButton.destructive(label: 'Löschen', onPressed: () {}),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(DecoratedBox), findsNothing);
    });

    testWidgets('loading replaces the leading slot and blocks the tap', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          AppButton.primary(
            label: 'Speichern',
            onPressed: () => taps++,
            loading: true,
            leading: const Icon(Icons.save),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.save), findsNothing);
      await tester.tap(find.byType(AppButton));
      expect(taps, 0);
    });
  });
}
