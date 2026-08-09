import 'package:flutter/material.dart';

import 'package:zerin_marketplace/core/theme/app_colors.dart';

/// Colors with meaning beyond Material's base [ColorScheme].
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.info,
    required this.onInfo,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.canvas,
    required this.surfaceMuted,
    required this.surfaceRaised,
    required this.divider,
    required this.accent,
    required this.onAccent,
    required this.accentGradientStart,
    required this.accentGradientEnd,
    required this.accentDisabled,
  });

  factory AppSemanticColors.light() => const AppSemanticColors(
    success: AppColors.success700,
    onSuccess: AppColors.berf0,
    successContainer: AppColors.success50,
    onSuccessContainer: AppColors.success900,
    warning: AppColors.warning700,
    onWarning: AppColors.berf0,
    warningContainer: AppColors.warning50,
    onWarningContainer: AppColors.warning900,
    info: AppColors.info700,
    onInfo: AppColors.berf0,
    infoContainer: AppColors.info50,
    onInfoContainer: AppColors.info900,
    canvas: AppColors.berf100,
    surfaceMuted: AppColors.berf200,
    surfaceRaised: AppColors.berf0,
    divider: AppColors.berf300,
    accent: AppColors.gold400,
    onAccent: AppColors.ink,
    accentGradientStart: AppColors.gold300,
    accentGradientEnd: AppColors.gold500,
    accentDisabled: AppColors.berf300,
  );

  factory AppSemanticColors.dark() => const AppSemanticColors(
    success: AppColors.success500,
    onSuccess: AppColors.petrol950,
    successContainer: AppColors.success800,
    onSuccessContainer: AppColors.success100,
    warning: AppColors.warning200,
    onWarning: AppColors.warning900,
    warningContainer: AppColors.warning800,
    onWarningContainer: AppColors.warning100,
    info: AppColors.info200,
    onInfo: AppColors.info900,
    infoContainer: AppColors.info800,
    onInfoContainer: AppColors.info100,
    canvas: AppColors.petrol950,
    surfaceMuted: AppColors.petrol900,
    surfaceRaised: AppColors.petrol800,
    divider: AppColors.petrol700,
    accent: AppColors.gold400,
    onAccent: AppColors.ink,
    accentGradientStart: AppColors.gold300,
    accentGradientEnd: AppColors.gold500,
    accentDisabled: AppColors.petrol700,
  );

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color info;
  final Color onInfo;
  final Color infoContainer;
  final Color onInfoContainer;
  final Color canvas;
  final Color surfaceMuted;
  final Color surfaceRaised;
  final Color divider;

  /// `zer`. Reserved for a single call to action per screen; see [AppColors].
  final Color accent;
  final Color onAccent;
  final Color accentGradientStart;
  final Color accentGradientEnd;

  /// Surface for a disabled accent button — the gradient is dropped entirely
  /// rather than faded, so gold never reads as "available but greyed out".
  final Color accentDisabled;

  /// The accent sweep, for the one gold element a screen is allowed.
  LinearGradient get accentGradient => LinearGradient(
    colors: <Color>[accentGradientStart, accentGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? info,
    Color? onInfo,
    Color? infoContainer,
    Color? onInfoContainer,
    Color? canvas,
    Color? surfaceMuted,
    Color? surfaceRaised,
    Color? divider,
    Color? accent,
    Color? onAccent,
    Color? accentGradientStart,
    Color? accentGradientEnd,
    Color? accentDisabled,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      canvas: canvas ?? this.canvas,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      divider: divider ?? this.divider,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentGradientStart: accentGradientStart ?? this.accentGradientStart,
      accentGradientEnd: accentGradientEnd ?? this.accentGradientEnd,
      accentDisabled: accentDisabled ?? this.accentDisabled,
    );
  }

  @override
  AppSemanticColors lerp(covariant AppSemanticColors? other, double t) {
    if (other == null) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      accentGradientStart: Color.lerp(
        accentGradientStart,
        other.accentGradientStart,
        t,
      )!,
      accentGradientEnd: Color.lerp(
        accentGradientEnd,
        other.accentGradientEnd,
        t,
      )!,
      accentDisabled: Color.lerp(accentDisabled, other.accentDisabled, t)!,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSemanticColors &&
        other.success == success &&
        other.onSuccess == onSuccess &&
        other.successContainer == successContainer &&
        other.onSuccessContainer == onSuccessContainer &&
        other.warning == warning &&
        other.onWarning == onWarning &&
        other.warningContainer == warningContainer &&
        other.onWarningContainer == onWarningContainer &&
        other.info == info &&
        other.onInfo == onInfo &&
        other.infoContainer == infoContainer &&
        other.onInfoContainer == onInfoContainer &&
        other.canvas == canvas &&
        other.surfaceMuted == surfaceMuted &&
        other.surfaceRaised == surfaceRaised &&
        other.divider == divider &&
        other.accent == accent &&
        other.onAccent == onAccent &&
        other.accentGradientStart == accentGradientStart &&
        other.accentGradientEnd == accentGradientEnd &&
        other.accentDisabled == accentDisabled;
  }

  @override
  int get hashCode => Object.hashAll(<Object>[
    success,
    onSuccess,
    successContainer,
    onSuccessContainer,
    warning,
    onWarning,
    warningContainer,
    onWarningContainer,
    info,
    onInfo,
    infoContainer,
    onInfoContainer,
    canvas,
    surfaceMuted,
    surfaceRaised,
    divider,
    accent,
    onAccent,
    accentGradientStart,
    accentGradientEnd,
    accentDisabled,
  ]);
}

extension AppThemeContext on BuildContext {
  AppSemanticColors get semanticColors {
    return Theme.of(this).extension<AppSemanticColors>() ??
        (Theme.of(this).brightness == Brightness.dark
            ? AppSemanticColors.dark()
            : AppSemanticColors.light());
  }
}
