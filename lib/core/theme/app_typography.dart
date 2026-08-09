import 'package:flutter/material.dart';

/// Bundled brand typography.
///
/// - **Display** — Bricolage Grotesque, for headlines and numerals.
/// - **Body** — Figtree, for everything else.
/// - **Arabic** — IBM Plex Sans Arabic, reached through [fallbackFamilies].
///
/// All three are bundled as static instances in `assets/fonts/`, so text
/// renders identically offline and on first frame. Nothing is fetched at
/// runtime.
///
/// The Latin families cover the full Kurmanji set (ê î û ç ş) plus German and
/// Turkish diacritics, so `ku`, `de` and `tr` all shape from the primary font
/// and only Arabic falls through. The Arabic face lacks `ş` and `ğ`, which is
/// why it is a fallback and never the primary family.
abstract final class AppTypography {
  static const displayFamily = 'BricolageGrotesque';
  static const bodyFamily = 'Figtree';
  static const arabicFamily = 'IBMPlexSansArabic';

  /// Arabic shaping for text that is otherwise Latin-first. Order matters:
  /// the Latin families are tried first, so Kurmanji and Turkish diacritics
  /// never fall through to the Arabic face.
  static const List<String> fallbackFamilies = <String>[arabicFamily];

  static TextTheme textTheme(Color foreground) {
    return TextTheme(
      displayLarge: _display(48, FontWeight.w800, 1.06, -0.5, foreground),
      displayMedium: _display(40, FontWeight.w800, 1.08, -0.4, foreground),
      displaySmall: _display(34, FontWeight.w700, 1.12, -0.3, foreground),
      headlineLarge: _display(30, FontWeight.w700, 1.16, -0.2, foreground),
      headlineMedium: _display(26, FontWeight.w700, 1.2, -0.2, foreground),
      headlineSmall: _display(22, FontWeight.w700, 1.24, 0, foreground),
      titleLarge: _display(20, FontWeight.w600, 1.28, 0, foreground),
      titleMedium: _body(17, FontWeight.w600, 1.35, 0, foreground),
      titleSmall: _body(15, FontWeight.w600, 1.35, 0, foreground),
      bodyLarge: _body(17, FontWeight.w400, 1.5, 0, foreground),
      bodyMedium: _body(15, FontWeight.w400, 1.5, 0, foreground),
      bodySmall: _body(13, FontWeight.w400, 1.45, 0, foreground),
      labelLarge: _body(15, FontWeight.w600, 1.3, 0.1, foreground),
      labelMedium: _body(13, FontWeight.w600, 1.3, 0.1, foreground),
      labelSmall: _body(11, FontWeight.w600, 1.3, 0.2, foreground),
    );
  }

  static TextStyle _display(
    double size,
    FontWeight weight,
    double height,
    double letterSpacing,
    Color color,
  ) {
    return TextStyle(
      fontFamily: displayFamily,
      fontFamilyFallback: fallbackFamilies,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  static TextStyle _body(
    double size,
    FontWeight weight,
    double height,
    double letterSpacing,
    Color color,
  ) {
    return TextStyle(
      fontFamily: bodyFamily,
      fontFamilyFallback: fallbackFamilies,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }
}
