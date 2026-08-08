import 'package:flutter/material.dart';

import '../constants/ui_constants.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Builds the light and dark [ThemeData].
///
/// Every component default lives here. The payoff: a widget written as
/// `FilledButton(onPressed: ..., child: Text('Save'))` already has the right
/// height, radius and typography — no per-screen styling, and a rebrand is a
/// change to this file plus `app_colors.dart`.
abstract final class AppTheme {
  static ThemeData get light =>
      _build(AppColors.lightScheme, AppSemanticColors.light);

  static ThemeData get dark =>
      _build(AppColors.darkScheme, AppSemanticColors.dark);

  static ThemeData _build(ColorScheme scheme, AppSemanticColors semantic) {
    final textTheme = AppTypography.textTheme(scheme);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(UiConstants.radiusMd),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      fontFamily: AppTypography.fontFamily,
      scaffoldBackgroundColor: scheme.surface,
      extensions: [semantic],
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        titleTextStyle: textTheme.titleLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(UiConstants.buttonHeight),
          shape: shape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(UiConstants.buttonHeight),
          shape: shape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: textTheme.labelLarge),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: UiConstants.spaceMd,
          vertical: UiConstants.spaceMd,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UiConstants.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UiConstants.radiusMd),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UiConstants.radiusMd),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UiConstants.radiusMd),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UiConstants.radiusMd),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UiConstants.radiusLg),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        color: scheme.surface,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UiConstants.radiusLg),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(UiConstants.radiusLg),
          ),
        ),
        backgroundColor: scheme.surface,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: DividerThemeData(
        space: 1,
        thickness: 1,
        color: scheme.outlineVariant,
      ),
      listTileTheme: ListTileThemeData(shape: shape),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UiConstants.radiusPill),
        ),
      ),
      // Page transitions are left at the framework defaults, which already
      // match each platform (predictive back on Android, the iOS slide, and
      // fade-upwards on desktop). Override here only if design asks for it.
    );
  }
}
