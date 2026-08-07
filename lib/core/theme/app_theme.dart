import 'package:flutter/material.dart';

import 'package:zerin_marketplace/core/theme/app_colors.dart';
import 'package:zerin_marketplace/core/theme/app_elevation.dart';
import 'package:zerin_marketplace/core/theme/app_motion.dart';
import 'package:zerin_marketplace/core/theme/app_radius.dart';
import 'package:zerin_marketplace/core/theme/app_spacing.dart';
import 'package:zerin_marketplace/core/theme/app_theme_extensions.dart';
import 'package:zerin_marketplace/core/theme/app_typography.dart';

/// Application-level Material themes.
abstract final class AppTheme {
  static ThemeData get light => _build(
    scheme: AppColors.lightScheme,
    semanticColors: AppSemanticColors.light(),
  );

  static ThemeData get dark => _build(
    scheme: AppColors.darkScheme,
    semanticColors: AppSemanticColors.dark(),
  );

  static ThemeData _build({
    required ColorScheme scheme,
    required AppSemanticColors semanticColors,
  }) {
    final textTheme = AppTypography.textTheme(scheme.onSurface);
    final outlineBorder = OutlineInputBorder(
      borderRadius: AppRadius.medium,
      borderSide: BorderSide(color: scheme.outlineVariant),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: semanticColors.canvas,
      canvasColor: semanticColors.canvas,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashFactory: InkSparkle.splashFactory,
      extensions: <ThemeExtension<dynamic>>[semanticColors],
      appBarTheme: AppBarTheme(
        backgroundColor: semanticColors.canvas,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: AppElevation.none,
        scrolledUnderElevation: AppElevation.low,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: semanticColors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shadowColor: scheme.shadow.withValues(alpha: AppOpacity.subtle),
        elevation: AppElevation.low,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.large),
        clipBehavior: Clip.antiAlias,
      ),
      dividerTheme: DividerThemeData(
        color: semanticColors.divider,
        thickness: AppStrokes.thin,
        space: AppStrokes.thin,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: semanticColors.surfaceRaised,
        contentPadding: AppSpacing.field,
        constraints: const BoxConstraints(minHeight: AppSizes.controlLarge),
        border: outlineBorder,
        enabledBorder: outlineBorder,
        disabledBorder: outlineBorder.copyWith(
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: AppOpacity.muted),
          ),
        ),
        focusedBorder: outlineBorder.copyWith(
          borderSide: BorderSide(
            color: scheme.primary,
            width: AppStrokes.focused,
          ),
        ),
        errorBorder: outlineBorder.copyWith(
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: outlineBorder.copyWith(
          borderSide: BorderSide(
            color: scheme.error,
            width: AppStrokes.focused,
          ),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        helperStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: scheme.error),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(
            AppSizes.minimumTouchTarget,
            AppSizes.controlMedium,
          ),
          padding: AppSpacing.button,
          elevation: AppElevation.none,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.onSurface.withValues(
            alpha: AppOpacity.disabledSurface,
          ),
          disabledForegroundColor: scheme.onSurface.withValues(
            alpha: AppOpacity.disabledContent,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
          textStyle: textTheme.labelLarge,
          animationDuration: AppMotion.standard,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(
            AppSizes.minimumTouchTarget,
            AppSizes.controlMedium,
          ),
          padding: AppSpacing.button,
          foregroundColor: scheme.primary,
          disabledForegroundColor: scheme.onSurface.withValues(
            alpha: AppOpacity.disabledContent,
          ),
          side: BorderSide(color: scheme.outline),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
          textStyle: textTheme.labelLarge,
          animationDuration: AppMotion.standard,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(
            AppSizes.minimumTouchTarget,
            AppSizes.controlMedium,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          foregroundColor: scheme.primary,
          disabledForegroundColor: scheme.onSurface.withValues(
            alpha: AppOpacity.disabledContent,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
          textStyle: textTheme.labelLarge,
          animationDuration: AppMotion.standard,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(AppSizes.minimumTouchTarget),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: semanticColors.surfaceMuted,
        selectedColor: scheme.primaryContainer,
        secondarySelectedColor: scheme.primaryContainer,
        disabledColor: scheme.onSurface.withValues(alpha: AppOpacity.subtle),
        labelStyle: textTheme.labelMedium?.copyWith(color: scheme.onSurface),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onPrimaryContainer,
        ),
        side: BorderSide(color: scheme.outlineVariant),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pill),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
        iconTheme: IconThemeData(
          color: scheme.onSurfaceVariant,
          size: AppSizes.iconSmall,
        ),
        checkmarkColor: scheme.onPrimaryContainer,
        showCheckmark: true,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: semanticColors.surfaceRaised,
        modalBackgroundColor: semanticColors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: scheme.scrim.withValues(alpha: AppOpacity.barrier),
        elevation: AppElevation.high,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: semanticColors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.high,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.extraLarge),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        elevation: AppElevation.medium,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
        insetPadding: const EdgeInsets.all(AppSpacing.md),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: AppSizes.bottomBarHeight,
        elevation: AppElevation.medium,
        backgroundColor: semanticColors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            size: AppSizes.iconLarge,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.secondary,
        foregroundColor: scheme.onSecondary,
        elevation: AppElevation.medium,
        focusElevation: AppElevation.high,
        hoverElevation: AppElevation.high,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.large),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primaryContainer,
        circularTrackColor: scheme.primaryContainer,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: AppRadius.small,
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onInverseSurface,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        waitDuration: AppMotion.standard,
      ),
    );
  }
}
