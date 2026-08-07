import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium, highly legible typography with Arabic-capable fallbacks.
abstract final class AppTypography {
  static const List<String> fallbackFamilies = <String>[
    'IBMPlexSansArabic',
    'Noto Sans Arabic',
    'Arial',
  ];

  static TextTheme textTheme(Color foreground) {
    _loadArabicFallbackVariants();
    final base = GoogleFonts.interTextTheme().apply(
      bodyColor: foreground,
      displayColor: foreground,
      fontFamilyFallback: fallbackFamilies,
    );

    return base.copyWith(
      displayLarge: _style(base.displayLarge, 48, FontWeight.w700, 1.08, 0),
      displayMedium: _style(base.displayMedium, 40, FontWeight.w700, 1.1, 0),
      displaySmall: _style(base.displaySmall, 34, FontWeight.w700, 1.14, 0),
      headlineLarge: _style(base.headlineLarge, 30, FontWeight.w700, 1.18, 0),
      headlineMedium: _style(base.headlineMedium, 26, FontWeight.w700, 1.2, 0),
      headlineSmall: _style(base.headlineSmall, 22, FontWeight.w700, 1.24, 0),
      titleLarge: _style(base.titleLarge, 20, FontWeight.w600, 1.28, 0),
      titleMedium: _style(base.titleMedium, 17, FontWeight.w600, 1.35, 0),
      titleSmall: _style(base.titleSmall, 15, FontWeight.w600, 1.35, 0),
      bodyLarge: _style(base.bodyLarge, 17, FontWeight.w400, 1.5, 0),
      bodyMedium: _style(base.bodyMedium, 15, FontWeight.w400, 1.5, 0),
      bodySmall: _style(base.bodySmall, 13, FontWeight.w400, 1.45, 0),
      labelLarge: _style(base.labelLarge, 15, FontWeight.w600, 1.3, 0),
      labelMedium: _style(base.labelMedium, 13, FontWeight.w600, 1.3, 0),
      labelSmall: _style(base.labelSmall, 11, FontWeight.w600, 1.3, 0),
    );
  }

  static void _loadArabicFallbackVariants() {
    // Register the weights used by this type scale with the Google Fonts
    // loader. Merely naming a family in fontFamilyFallback does not load it.
    GoogleFonts.ibmPlexSansArabic();
    GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w600);
    GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w700);
  }

  static TextStyle _style(
    TextStyle? base,
    double size,
    FontWeight weight,
    double height,
    double letterSpacing,
  ) {
    return (base ?? const TextStyle()).copyWith(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      fontFamilyFallback: fallbackFamilies,
    );
  }
}
