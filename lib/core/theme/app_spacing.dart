import 'package:flutter/widgets.dart';

/// Spacing tokens based on a four-point grid.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const EdgeInsets page = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets card = EdgeInsets.all(md);
  static const EdgeInsets field = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );
  static const EdgeInsets button = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: sm,
  );
}

/// Shared sizing tokens for controls and common content.
abstract final class AppSizes {
  static const double minimumTouchTarget = 44;
  static const double controlSmall = 44;
  static const double controlMedium = 48;
  static const double controlLarge = 56;
  static const double iconSmall = 16;
  static const double iconMedium = 20;
  static const double iconLarge = 24;
  static const double iconState = 40;
  static const double stateIllustration = 88;
  static const double contentMaxWidth = 720;
  static const double formMaxWidth = 520;
  static const double onboardingVisual = 220;
  static const double iconHero = 96;
  static const double brandIcon = 56;
  static const double pageIndicator = 8;
  static const double pageIndicatorSelected = 28;
  static const double bottomBarHeight = 76;
  static const double sellFabSize = 64;
  static const double avatarSmall = 32;
  static const double avatarMedium = 44;
  static const double productImageHeight = 188;
  static const double categoryImageHeight = 112;
  static const double dialogMaxWidth = 480;
  static const double bottomSheetMaxWidth = 640;
  static const double dragHandleWidth = 32;
  static const double dragHandleHeight = 4;
}

/// Line-width tokens for borders and progress indicators.
abstract final class AppStrokes {
  static const double thin = 1;
  static const double focused = 1.5;
  static const double progress = 2;
}

/// Common opacity values for state and elevation treatments.
abstract final class AppOpacity {
  static const double faint = 0.06;
  static const double subtle = 0.08;
  static const double shadowHigh = 0.1;
  static const double disabledSurface = 0.1;
  static const double destructiveDisabledSurface = 0.12;
  static const double disabledContent = 0.38;
  static const double half = 0.5;
  static const double muted = 0.6;
  static const double barrier = 0.56;
  static const double raised = 0.92;
}

abstract final class AppRatios {
  static const double square = 1;
}
