import 'package:flutter/material.dart';
import 'package:zerin_marketplace/core/theme/app_spacing.dart';

/// Soft, low-contrast elevation tokens.
abstract final class AppElevation {
  static const double none = 0;
  static const double low = 1;
  static const double medium = 2;
  static const double high = 4;
  static const double sellFab = 6;

  static List<BoxShadow> lowShadow(Color shadowColor) => <BoxShadow>[
    BoxShadow(
      color: shadowColor.withValues(alpha: AppOpacity.faint),
      blurRadius: 12,
      offset: const Offset(0, 3),
    ),
  ];

  static List<BoxShadow> mediumShadow(Color shadowColor) => <BoxShadow>[
    BoxShadow(
      color: shadowColor.withValues(alpha: AppOpacity.subtle),
      blurRadius: 20,
      offset: const Offset(0, 7),
    ),
  ];

  static List<BoxShadow> highShadow(Color shadowColor) => <BoxShadow>[
    BoxShadow(
      color: shadowColor.withValues(alpha: AppOpacity.shadowHigh),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
  ];
}
