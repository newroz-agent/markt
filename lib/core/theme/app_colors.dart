import 'package:flutter/material.dart';

/// The complete brand and neutral palette.
///
/// Widgets should normally consume [ColorScheme] from the active theme rather
/// than referencing these values directly. These constants are the source of
/// truth used to construct the light and dark schemes.
abstract final class AppColors {
  // Petrol brand palette.
  static const petrol50 = Color(0xFFEAF8F7);
  static const petrol100 = Color(0xFFCDEDEA);
  static const petrol200 = Color(0xFF9EDCD8);
  static const petrol300 = Color(0xFF67C3BF);
  static const petrol400 = Color(0xFF38A5A3);
  static const petrol500 = Color(0xFF1D8788);
  static const petrol600 = Color(0xFF156C70);
  static const petrol700 = Color(0xFF12565B);
  static const petrol800 = Color(0xFF10454B);
  static const petrol900 = Color(0xFF0D3940);
  static const petrol950 = Color(0xFF061F24);

  // Warm gold accent palette.
  static const gold50 = Color(0xFFFFFAEB);
  static const gold100 = Color(0xFFFFF0BF);
  static const gold200 = Color(0xFFFFDF7A);
  static const gold300 = Color(0xFFF7C94E);
  static const gold400 = Color(0xFFE3AC2F);
  static const gold500 = Color(0xFFC58D1D);
  static const gold600 = Color(0xFFA46C15);
  static const gold700 = Color(0xFF805015);
  static const gold800 = Color(0xFF684018);
  static const gold900 = Color(0xFF573619);

  // Neutral palette. Dark surfaces intentionally stop short of pure black.
  static const neutral0 = Color(0xFFFFFFFF);
  static const neutral50 = Color(0xFFF7F8F7);
  static const neutral100 = Color(0xFFEDEFEF);
  static const neutral200 = Color(0xFFD8DCDB);
  static const neutral300 = Color(0xFFB7BEBC);
  static const neutral400 = Color(0xFF8C9693);
  static const neutral500 = Color(0xFF68736F);
  static const neutral600 = Color(0xFF4D5754);
  static const neutral700 = Color(0xFF37413E);
  static const neutral800 = Color(0xFF222A28);
  static const neutral900 = Color(0xFF171D1B);
  static const neutral950 = Color(0xFF0E1113);

  // Semantic palette.
  static const success50 = Color(0xFFEAF8EF);
  static const success100 = Color(0xFFB6F2CB);
  static const success200 = Color(0xFF6ED69A);
  static const success500 = Color(0xFF218A50);
  static const success700 = Color(0xFF17623A);
  static const success800 = Color(0xFF174D2D);
  static const success900 = Color(0xFF063D21);
  static const warning50 = Color(0xFFFFF5DE);
  static const warning100 = Color(0xFFFFE3AB);
  static const warning200 = Color(0xFFFFCD72);
  static const warning500 = Color(0xFFD98A12);
  static const warning700 = Color(0xFF955D0A);
  static const warning800 = Color(0xFF5F3B09);
  static const warning900 = Color(0xFF4B2D00);
  static const error50 = Color(0xFFFFECEB);
  static const error100 = Color(0xFFFFDAD6);
  static const error200 = Color(0xFFFFB4AB);
  static const error500 = Color(0xFFD94B45);
  static const error700 = Color(0xFF9F2F2B);
  static const error800 = Color(0xFF8C1D18);
  static const error900 = Color(0xFF690005);
  static const info50 = Color(0xFFEAF3FF);
  static const info100 = Color(0xFFD6E4FF);
  static const info200 = Color(0xFFA9C7FF);
  static const info500 = Color(0xFF3578D4);
  static const info700 = Color(0xFF2457A0);
  static const info800 = Color(0xFF153F72);
  static const info900 = Color(0xFF082C5A);

  static const ColorScheme lightScheme = ColorScheme.light(
    primary: petrol700,
    primaryContainer: petrol100,
    onPrimaryContainer: petrol950,
    primaryFixed: petrol100,
    primaryFixedDim: petrol200,
    onPrimaryFixed: petrol950,
    onPrimaryFixedVariant: petrol700,
    secondary: gold600,
    onSecondary: neutral950,
    secondaryContainer: gold100,
    onSecondaryContainer: gold900,
    secondaryFixed: gold100,
    secondaryFixedDim: gold200,
    onSecondaryFixed: gold900,
    onSecondaryFixedVariant: gold700,
    tertiary: info700,
    onTertiary: neutral0,
    tertiaryContainer: info50,
    onTertiaryContainer: info700,
    tertiaryFixed: info50,
    tertiaryFixedDim: info200,
    onTertiaryFixed: info900,
    onTertiaryFixedVariant: info700,
    error: error700,
    errorContainer: error50,
    onErrorContainer: error700,
    surfaceDim: neutral200,
    surfaceBright: neutral0,
    surfaceContainerLowest: neutral0,
    surfaceContainerLow: neutral50,
    surfaceContainer: neutral100,
    surfaceContainerHigh: neutral100,
    surfaceContainerHighest: neutral200,
    onSurface: neutral900,
    onSurfaceVariant: neutral600,
    outline: neutral400,
    outlineVariant: neutral200,
    shadow: neutral950,
    scrim: neutral950,
    inverseSurface: neutral900,
    onInverseSurface: neutral50,
    inversePrimary: petrol200,
    surfaceTint: petrol700,
  );

  static const ColorScheme darkScheme = ColorScheme.dark(
    primary: petrol300,
    onPrimary: petrol950,
    primaryContainer: petrol800,
    onPrimaryContainer: petrol100,
    primaryFixed: petrol100,
    primaryFixedDim: petrol300,
    onPrimaryFixed: petrol950,
    onPrimaryFixedVariant: petrol700,
    secondary: gold300,
    onSecondary: gold900,
    secondaryContainer: gold800,
    onSecondaryContainer: gold100,
    secondaryFixed: gold100,
    secondaryFixedDim: gold300,
    onSecondaryFixed: gold900,
    onSecondaryFixedVariant: gold700,
    tertiary: info200,
    onTertiary: info900,
    tertiaryContainer: info800,
    onTertiaryContainer: info100,
    tertiaryFixed: info100,
    tertiaryFixedDim: info200,
    onTertiaryFixed: info900,
    onTertiaryFixedVariant: info700,
    error: error200,
    onError: error900,
    errorContainer: error800,
    onErrorContainer: error50,
    surface: neutral950,
    surfaceDim: neutral950,
    surfaceBright: neutral800,
    surfaceContainerLowest: neutral950,
    surfaceContainerLow: neutral900,
    surfaceContainer: neutral900,
    surfaceContainerHigh: neutral800,
    surfaceContainerHighest: neutral700,
    onSurface: neutral100,
    onSurfaceVariant: neutral300,
    outline: neutral500,
    outlineVariant: neutral700,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: neutral100,
    onInverseSurface: neutral900,
    inversePrimary: petrol700,
    surfaceTint: petrol300,
  );
}
