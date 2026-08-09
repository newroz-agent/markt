import 'package:flutter/material.dart';

/// The complete brand and neutral palette.
///
/// Widgets should normally consume [ColorScheme] from the active theme, or the
/// `AppSemanticColors` theme extension, rather than referencing these values
/// directly. These constants are the source of truth used to construct the
/// light and dark schemes.
///
/// Brand anchors, by their Kurdish names:
/// - `sevin` [petrol950] — the dark canvas
/// - `petrol` [petrol800] — the dark surface
/// - `zer` [gold400] — the single accent
/// - `berf` [berf100] — the light canvas
/// - `kevir` [kevir400] — muted text
///
/// Two rules the palette encodes:
/// 1. **Gold is accent only.** At most one gold call to action per screen. Gold
///    never carries body text and never fills a whole surface. It reads as
///    1.86:1 against [berf100], so it is a filled shape with [ink] on top, not
///    a text color on light backgrounds.
/// 2. **Never pure black, never orange.** The darkest value is [petrol950];
///    the warm ramp stops at gold and never crosses into orange.
abstract final class AppColors {
  // The five brand anchors under their Kurdish names. Aliases, not extra
  // colors — each points at its step in the ramp below.

  /// `sevin` — the dark canvas.
  static const sevin = petrol950;

  /// `petrol` — the dark surface.
  static const petrol = petrol800;

  /// `zer` — the gold accent.
  static const zer = gold400;

  /// `berf` — the light canvas.
  static const berf = berf100;

  /// `kevir` — muted text.
  static const kevir = kevir400;

  // Petrol — the cool brand family. `sevin` is the floor, `petrol` the surface.
  static const petrol50 = Color(0xFFE7F2F3);
  static const petrol100 = Color(0xFFC8E0E3);
  static const petrol200 = Color(0xFF9CC6CC);
  static const petrol300 = Color(0xFF6FA9B2);
  static const petrol400 = Color(0xFF418C99);
  static const petrol500 = Color(0xFF316F7B);
  static const petrol600 = Color(0xFF275A64);

  /// `raised` — the elevated dark surface.
  static const petrol700 = Color(0xFF1E464E);

  /// `petrol` — the dark surface.
  static const petrol800 = Color(0xFF17383E);
  static const petrol900 = Color(0xFF122C32);

  /// `sevin` — the dark canvas. The darkest value in the system; never black.
  static const petrol950 = Color(0xFF0E2226);

  // Zer — the gold accent. Accent only; see the class doc.
  static const gold50 = Color(0xFFFEF8EA);
  static const gold100 = Color(0xFFFBEBC7);
  static const gold200 = Color(0xFFF7D68E);

  /// Gradient start for the accent sweep.
  static const gold300 = Color(0xFFF2C15C);

  /// `zer` — the accent itself.
  static const gold400 = Color(0xFFE3A93C);

  /// Gradient end for the accent sweep.
  static const gold500 = Color(0xFFC9922E);
  static const gold600 = Color(0xFFA8781F);
  static const gold700 = Color(0xFF855E17);
  static const gold800 = Color(0xFF6A4A14);
  static const gold900 = Color(0xFF4E360F);

  /// The accent sweep, light to dark. Used for at most one element per screen.
  static const goldGradient = <Color>[gold300, gold500];

  // Berf — the warm light family.
  static const berf0 = Color(0xFFFFFFFF);
  static const berf50 = Color(0xFFFCFAF4);

  /// `berf` — the light canvas.
  static const berf100 = Color(0xFFF6F1E6);
  static const berf200 = Color(0xFFEBE4D3);
  static const berf300 = Color(0xFFDBD1BB);

  // Kevir — muted text and hairlines.
  static const kevir200 = Color(0xFFB9C2C3);
  static const kevir300 = Color(0xFF9BA7A8);

  /// `kevir` — muted text. Reaches 4.60:1 on [petrol950], so it is the
  /// dark-mode secondary text color. On [berf100] it only reaches 3.17:1, so
  /// light mode uses [kevir600] for body-sized secondary text instead.
  static const kevir400 = Color(0xFF7C8A8C);
  static const kevir500 = Color(0xFF6B797B);

  /// Light-mode secondary text. 4.72:1 on [berf100].
  static const kevir600 = Color(0xFF5F6E70);
  static const kevir700 = Color(0xFF4A585A);

  /// Ink on light surfaces, and the label on top of a gold accent (7.17:1).
  static const ink = Color(0xFF132A2E);

  // Semantic palette. The brand values sit at the `500` step; the `700` steps
  // are the darkened siblings light mode needs to clear 4.5:1 for text.
  static const success50 = Color(0xFFEAF7F0);
  static const success100 = Color(0xFFC6EAD8);
  static const success200 = Color(0xFF8FD5B4);

  /// Brand success. 4.85:1 on [petrol950]; dark-mode success text.
  static const success500 = Color(0xFF3E9C6E);

  /// Light-mode success text. 5.43:1 on [berf100].
  static const success700 = Color(0xFF2A6E4D);
  static const success800 = Color(0xFF1D4F37);
  static const success900 = Color(0xFF123322);

  static const warning50 = Color(0xFFFDF4E3);
  static const warning100 = Color(0xFFF8E4BC);
  static const warning200 = Color(0xFFEFCB86);
  static const warning500 = Color(0xFFB9822A);
  static const warning700 = Color(0xFF8A5F1B);
  static const warning800 = Color(0xFF5E4012);
  static const warning900 = Color(0xFF3D2A0C);

  static const error50 = Color(0xFFFCECE9);
  static const error100 = Color(0xFFF8D3CD);
  static const error200 = Color(0xFFF0ABA0);

  /// Brand error. A fill or an icon, never text: 3.95:1 on [berf100] and
  /// 3.70:1 on [petrol950], so it misses 4.5:1 on both canvases. Error *text*
  /// uses [error700] in light mode and [error200] in dark mode.
  static const error500 = Color(0xFFCF4B37);

  /// Light-mode error text and filled destructive surfaces. 5.35:1 on
  /// [berf100], and white on it reaches 6.03:1.
  static const error700 = Color(0xFFB03A28);
  static const error800 = Color(0xFF82291C);
  static const error900 = Color(0xFF551A11);

  static const info50 = Color(0xFFE9F1F8);
  static const info100 = Color(0xFFCADDEE);
  static const info200 = Color(0xFF95BCDA);
  static const info500 = Color(0xFF3D7CA8);
  static const info700 = Color(0xFF2A5A7C);
  static const info800 = Color(0xFF1C3E56);
  static const info900 = Color(0xFF122938);

  static const ColorScheme lightScheme = ColorScheme.light(
    primary: petrol800,
    primaryContainer: petrol100,
    onPrimaryContainer: petrol950,
    primaryFixed: petrol100,
    primaryFixedDim: petrol200,
    onPrimaryFixed: petrol950,
    onPrimaryFixedVariant: petrol700,
    // Gold. `onSecondary` is ink, never white — see the class doc.
    secondary: gold400,
    onSecondary: ink,
    secondaryContainer: gold100,
    onSecondaryContainer: gold900,
    secondaryFixed: gold100,
    secondaryFixedDim: gold200,
    onSecondaryFixed: gold900,
    onSecondaryFixedVariant: gold700,
    tertiary: info700,
    onTertiary: berf0,
    tertiaryContainer: info50,
    onTertiaryContainer: info900,
    tertiaryFixed: info50,
    tertiaryFixedDim: info200,
    onTertiaryFixed: info900,
    onTertiaryFixedVariant: info700,
    error: error700,
    errorContainer: error50,
    onErrorContainer: error900,
    surface: berf100,
    surfaceDim: berf200,
    surfaceBright: berf0,
    surfaceContainerLowest: berf0,
    surfaceContainerLow: berf50,
    surfaceContainer: berf100,
    surfaceContainerHigh: berf200,
    surfaceContainerHighest: berf300,
    onSurface: ink,
    onSurfaceVariant: kevir600,
    outline: kevir500,
    outlineVariant: berf300,
    shadow: petrol950,
    scrim: petrol950,
    inverseSurface: petrol900,
    onInverseSurface: berf100,
    inversePrimary: petrol200,
    surfaceTint: petrol800,
  );

  static const ColorScheme darkScheme = ColorScheme.dark(
    primary: petrol300,
    onPrimary: petrol950,
    primaryContainer: petrol700,
    onPrimaryContainer: petrol100,
    primaryFixed: petrol100,
    primaryFixedDim: petrol300,
    onPrimaryFixed: petrol950,
    onPrimaryFixedVariant: petrol700,
    secondary: gold400,
    onSecondary: ink,
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
    surface: petrol950,
    surfaceDim: petrol950,
    surfaceBright: petrol700,
    surfaceContainerLowest: petrol950,
    surfaceContainerLow: petrol900,
    surfaceContainer: petrol800,
    surfaceContainerHigh: petrol700,
    surfaceContainerHighest: petrol600,
    onSurface: berf100,
    onSurfaceVariant: kevir400,
    outline: kevir500,
    outlineVariant: petrol700,
    // Deliberately petrol, not black: the brand has no pure black.
    shadow: petrol950,
    scrim: petrol950,
    inverseSurface: berf100,
    onInverseSurface: ink,
    inversePrimary: petrol800,
    surfaceTint: petrol300,
  );
}
