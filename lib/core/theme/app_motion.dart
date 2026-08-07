import 'package:flutter/animation.dart';

/// Duration tokens. Keep routine feedback inside the 200-300ms range.
abstract final class AppDurations {
  static const Duration quick = Duration(milliseconds: 160);
  static const Duration standard = Duration(milliseconds: 240);
  static const Duration emphasized = Duration(milliseconds: 300);
  static const Duration skeleton = Duration(milliseconds: 1400);
  static const Duration snackBar = Duration(seconds: 4);
}

/// Curves and interaction motion values.
abstract final class AppMotion {
  static const Duration quick = AppDurations.quick;
  static const Duration standard = AppDurations.standard;
  static const Duration emphasized = AppDurations.emphasized;
  static const Duration skeleton = AppDurations.skeleton;
  static const Duration snackBar = AppDurations.snackBar;

  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve emphasizedCurve = Curves.easeInOutCubicEmphasized;
  static const Curve exitCurve = Curves.easeInCubic;

  static const double pressedScale = 0.975;
}
