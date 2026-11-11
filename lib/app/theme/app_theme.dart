import 'package:flutter/material.dart';

import '../../core/helpers/colors.dart';

abstract final class AppTheme {
  static final light = _create(Brightness.light);
  static final dark = _create(Brightness.dark);

  /// Creates a consistent Material theme for the selected brightness.
  static ThemeData _create(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: brightness,
        ).copyWith(
          primary: isDark ? AppColors.darkPrimary : AppColors.primary,
          surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          onSurface: isDark ? AppColors.darkText : AppColors.lightText,
          onSurfaceVariant: isDark ? AppColors.darkMuted : AppColors.lightMuted,
          outlineVariant: isDark
              ? AppColors.darkOutline
              : AppColors.lightOutline,
        );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    return base.copyWith(
      scaffoldBackgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      textTheme: base.textTheme.copyWith(
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.5),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.5),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: scheme.surface,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    );
  }
}
