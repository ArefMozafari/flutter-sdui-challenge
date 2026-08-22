import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// Builds [ThemeData] from the token layer. Every value below traces back to
/// a token — nothing here is a raw literal — so a token change reflows the
/// whole app without touching this file again.
///
/// Only a light theme exists today (the challenge doesn't call for dark
/// mode); `AppTheme.light` is named for what it is rather than `AppTheme.theme`
/// so adding `AppTheme.dark` later doesn't require a rename at every call site.
abstract final class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandSeed,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _textTheme(colorScheme),
      pageTransitionsTheme: _pageTransitions(),
      inputDecorationTheme: _inputDecorationTheme(colorScheme),
      filledButtonTheme: _filledButtonTheme(colorScheme),
      outlinedButtonTheme: _outlinedButtonTheme(colorScheme),
      snackBarTheme: _snackBarTheme(colorScheme),
      visualDensity: VisualDensity.standard,
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    const base = TextStyle(fontWeight: AppTypography.weightRegular);
    return TextTheme(
      titleLarge: base.copyWith(
        fontSize: AppTypography.sizeXxxl,
        fontWeight: AppTypography.weightSemibold,
      ),
      titleMedium: base.copyWith(
        fontSize: AppTypography.sizeXl,
        fontWeight: AppTypography.weightSemibold,
      ),
      titleSmall: base.copyWith(
        fontSize: AppTypography.sizeLg,
        fontWeight: AppTypography.weightMedium,
      ),
      bodyLarge: AppTypography.fieldTextLarge,
      bodyMedium: AppTypography.fieldTextMedium,
      bodySmall: AppTypography.fieldTextSmall,
      labelLarge: base.copyWith(
        fontSize: AppTypography.sizeMd,
        fontWeight: AppTypography.weightMedium,
      ),
      labelMedium: base.copyWith(
        fontSize: AppTypography.sizeSm,
        fontWeight: AppTypography.weightMedium,
      ),
      labelSmall: base.copyWith(
        fontSize: AppTypography.sizeXs,
        fontWeight: AppTypography.weightRegular,
        color: scheme.onSurfaceVariant,
      ),
    );
  }

  static PageTransitionsTheme _pageTransitions() {
    const builder = FadeForwardsPageTransitionsBuilder();
    return const PageTransitionsTheme(builders: {
      TargetPlatform.iOS: builder,
      TargetPlatform.android: builder,
    });
  }

  static InputDecorationTheme _inputDecorationTheme(ColorScheme scheme) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: color),
        );
    return InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      border: border(scheme.outline),
      enabledBorder: border(scheme.outline),
      focusedBorder: border(scheme.primary),
      errorBorder: border(scheme.error),
      focusedErrorBorder: border(scheme.error),
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      helperStyle: AppTypography.fieldTextSmall.copyWith(color: scheme.onSurfaceVariant),
      errorStyle: AppTypography.fieldTextSmall.copyWith(color: scheme.error),
    );
  }

  static FilledButtonThemeData _filledButtonTheme(ColorScheme scheme) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        animationDuration: AppMotion.fast,
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme(ColorScheme scheme) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }

  static SnackBarThemeData _snackBarTheme(ColorScheme scheme) {
    return SnackBarThemeData(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      behavior: SnackBarBehavior.floating,
    );
  }
}
