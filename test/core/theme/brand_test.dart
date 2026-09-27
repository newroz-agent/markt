import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zerin_marketplace/core/theme/theme.dart';

/// WCAG 2.1 relative luminance.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

/// WCAG 2.1 contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

/// Hue in degrees, 0 = red, 30..45 = orange.
double _hue(Color c) => HSLColor.fromColor(c).hue;

void main() {
  group('brand palette', () {
    test('never uses pure black or pure white as a brand surface', () {
      final surfaces = <String, Color>{
        'sevin': AppColors.sevin,
        'petrol800': AppColors.petrol800,
        'petrol700': AppColors.petrol700,
        'berf': AppColors.berf,
        'ink': AppColors.ink,
      };
      for (final entry in surfaces.entries) {
        expect(
          entry.value,
          isNot(const Color(0xFF000000)),
          reason: '${entry.key} must not be pure black',
        );
        expect(
          entry.value,
          isNot(const Color(0xFFFFFFFF)),
          reason: '${entry.key} must not be pure white',
        );
      }
    });

    test('gold reads as gold, not orange', () {
      // Orange sits around 30 deg. The accent ramp must stay above 38 deg so
      // it reads as gold in both themes.
      final golds = <String, Color>{
        'gold300': AppColors.gold300,
        'gold400': AppColors.zer,
        'gold500': AppColors.gold500,
      };
      for (final entry in golds.entries) {
        expect(
          _hue(entry.value),
          greaterThan(38.0),
          reason: '${entry.key} drifts into orange',
        );
        expect(
          _hue(entry.value),
          lessThan(56.0),
          reason: '${entry.key} drifts into yellow-green',
        );
      }
    });

    test('named brand tokens match the specified hex values', () {
      expect(AppColors.sevin, const Color(0xFF0E2226));
      expect(AppColors.petrol, const Color(0xFF17383E));
      expect(AppColors.petrol700, const Color(0xFF1E464E));
      expect(AppColors.zer, const Color(0xFFE3A93C));
      expect(AppColors.gold300, const Color(0xFFF2C15C));
      expect(AppColors.gold500, const Color(0xFFC9922E));
      expect(AppColors.berf, const Color(0xFFF6F1E6));
      expect(AppColors.kevir, const Color(0xFF7C8A8C));
      expect(AppColors.ink, const Color(0xFF132A2E));
      expect(AppColors.success500, const Color(0xFF3E9C6E));
      expect(AppColors.error500, const Color(0xFFCF4B37));
    });
  });

  group('contrast', () {
    test('body text pairs clear WCAG AA (4.5:1)', () {
      final pairs = <String, List<Color>>{
        'ink on berf': <Color>[AppColors.ink, AppColors.berf],
        'kevir on sevin': <Color>[AppColors.kevir, AppColors.sevin],
        'kevir700 on berf': <Color>[AppColors.kevir700, AppColors.berf],
        'berf0 on petrol800': <Color>[AppColors.berf0, AppColors.petrol800],
        'ink on gold400 (accent CTA)': <Color>[AppColors.ink, AppColors.zer],
        'ink on gold300 (gradient start)': <Color>[
          AppColors.ink,
          AppColors.gold300,
        ],
        'ink on gold500 (gradient end)': <Color>[
          AppColors.ink,
          AppColors.gold500,
        ],
        'success700 on berf': <Color>[AppColors.success700, AppColors.berf],
        'success500 on sevin': <Color>[AppColors.success500, AppColors.sevin],
        'error700 on berf': <Color>[AppColors.error700, AppColors.berf],
        'error200 on sevin': <Color>[AppColors.error200, AppColors.sevin],
        'berf0 on error700': <Color>[AppColors.berf0, AppColors.error700],
      };
      for (final entry in pairs.entries) {
        expect(
          _contrast(entry.value[0], entry.value[1]),
          greaterThanOrEqualTo(4.5),
          reason:
              '${entry.key} is '
              '${_contrast(entry.value[0], entry.value[1]).toStringAsFixed(2)}:1',
        );
      }
    });

    test('both ColorSchemes keep on-colours legible against their surface', () {
      for (final scheme in <ColorScheme>[
        AppColors.lightScheme,
        AppColors.darkScheme,
      ]) {
        final label = scheme.brightness.name;
        expect(
          _contrast(scheme.onSurface, scheme.surface),
          greaterThanOrEqualTo(4.5),
          reason: '$label onSurface/surface',
        );
        expect(
          _contrast(scheme.onSurfaceVariant, scheme.surface),
          greaterThanOrEqualTo(4.5),
          reason: '$label onSurfaceVariant/surface',
        );
        expect(
          _contrast(scheme.onPrimary, scheme.primary),
          greaterThanOrEqualTo(4.5),
          reason: '$label onPrimary/primary',
        );
        expect(
          _contrast(scheme.onSecondary, scheme.secondary),
          greaterThanOrEqualTo(4.5),
          reason: '$label onSecondary/secondary',
        );
        expect(
          _contrast(scheme.onError, scheme.error),
          greaterThanOrEqualTo(4.5),
          reason: '$label onError/error',
        );
      }
    });

    test('gold is never used as a text colour on a light surface', () {
      // Guards the accent rule: gold-on-light is ~1.9:1 and must stay a fill,
      // never a foreground.
      expect(_contrast(AppColors.zer, AppColors.berf), lessThan(3.0));
      expect(AppColors.lightScheme.onSurface, isNot(AppColors.zer));
      expect(AppColors.lightScheme.onSurfaceVariant, isNot(AppColors.zer));
      expect(AppColors.darkScheme.onSurface, isNot(AppColors.zer));
    });
  });

  group('semantic colours', () {
    test('lerp covers every field', () {
      final a = AppSemanticColors.light();
      final b = AppSemanticColors.dark();
      final mid = a.lerp(b, 0.5);
      expect(mid.canvas, Color.lerp(a.canvas, b.canvas, 0.5));
      expect(mid.accent, Color.lerp(a.accent, b.accent, 0.5));
      expect(
        mid.accentDisabled,
        Color.lerp(a.accentDisabled, b.accentDisabled, 0.5),
      );
      expect(a.lerp(b, 0.0), a);
      expect(a.lerp(b, 1.0), b);
    });

    test('accent gradient runs from the specified stops', () {
      for (final semantic in <AppSemanticColors>[
        AppSemanticColors.light(),
        AppSemanticColors.dark(),
      ]) {
        expect(semantic.accentGradient.colors.first, AppColors.gold300);
        expect(semantic.accentGradient.colors.last, AppColors.gold500);
        expect(semantic.accent, AppColors.zer);
        expect(semantic.onAccent, AppColors.ink);
      }
    });
  });

  group('themes', () {
    test('scaffold background uses the brand canvas, not a default grey', () {
      expect(AppTheme.light.scaffoldBackgroundColor, AppColors.berf);
      expect(AppTheme.dark.scaffoldBackgroundColor, AppColors.sevin);
    });

    test('semantic colours are registered as a theme extension', () {
      expect(
        AppTheme.light.extension<AppSemanticColors>(),
        isA<AppSemanticColors>(),
      );
      expect(
        AppTheme.dark.extension<AppSemanticColors>(),
        isA<AppSemanticColors>(),
      );
    });
  });
}
