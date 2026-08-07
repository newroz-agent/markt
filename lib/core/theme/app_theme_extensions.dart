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
  });

  factory AppSemanticColors.light() => const AppSemanticColors(
    success: AppColors.success700,
    onSuccess: AppColors.neutral0,
    successContainer: AppColors.success50,
    onSuccessContainer: AppColors.success700,
    warning: AppColors.warning700,
    onWarning: AppColors.neutral0,
    warningContainer: AppColors.warning50,
    onWarningContainer: AppColors.warning700,
    info: AppColors.info700,
    onInfo: AppColors.neutral0,
    infoContainer: AppColors.info50,
    onInfoContainer: AppColors.info700,
    canvas: AppColors.neutral50,
    surfaceMuted: AppColors.neutral100,
    surfaceRaised: AppColors.neutral0,
    divider: AppColors.neutral200,
  );

  factory AppSemanticColors.dark() => const AppSemanticColors(
    success: AppColors.success200,
    onSuccess: AppColors.success900,
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
    canvas: AppColors.neutral950,
    surfaceMuted: AppColors.neutral900,
    surfaceRaised: AppColors.neutral800,
    divider: AppColors.neutral700,
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
    );
  }
}

extension AppThemeContext on BuildContext {
  AppSemanticColors get semanticColors {
    return Theme.of(this).extension<AppSemanticColors>() ??
        (Theme.of(this).brightness == Brightness.dark
            ? AppSemanticColors.dark()
            : AppSemanticColors.light());
  }
}
