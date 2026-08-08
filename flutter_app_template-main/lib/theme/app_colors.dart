import 'package:flutter/material.dart';

/// The raw brand palette and the two [ColorScheme]s built from it.
///
/// Widgets must never reference [AppColors] directly — they read
/// `context.colors` (the active [ColorScheme]) or `context.semanticColors`.
/// That indirection is what makes dark mode work without touching a widget.
abstract final class AppColors {
  // --- Brand seed ---
  static const Color brandPrimary = Color(0xFF4F46E5);
  static const Color brandSecondary = Color(0xFF0EA5E9);
  static const Color brandTertiary = Color(0xFFF59E0B);

  // --- Fixed semantic hues (same intent in both themes) ---
  static const Color success = Color(0xFF16A34A);
  static const Color successDark = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFD97706);
  static const Color warningDark = Color(0xFFFBBF24);
  static const Color info = Color(0xFF2563EB);
  static const Color infoDark = Color(0xFF60A5FA);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerDark = Color(0xFFF87171);

  static const Color neutral0 = Color(0xFFFFFFFF);
  static const Color neutral900 = Color(0xFF0B0B0F);

  /// Generated from the brand seed so every Material component gets a
  /// harmonious, contrast-checked slot without hand-picking 30 colours.
  static final ColorScheme lightScheme = ColorScheme.fromSeed(
    seedColor: brandPrimary,
    secondary: brandSecondary,
    tertiary: brandTertiary,
    error: danger,
  );

  static final ColorScheme darkScheme = ColorScheme.fromSeed(
    seedColor: brandPrimary,
    brightness: Brightness.dark,
    secondary: brandSecondary,
    tertiary: brandTertiary,
    error: dangerDark,
  );
}

/// Colours Material's [ColorScheme] has no slot for.
///
/// Registered as a [ThemeExtension] so they travel with the theme and flip
/// automatically in dark mode. Read them with `context.semanticColors`.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.info,
    required this.onInfo,
  });

  static const AppSemanticColors light = AppSemanticColors(
    success: AppColors.success,
    onSuccess: AppColors.neutral0,
    warning: AppColors.warning,
    onWarning: AppColors.neutral0,
    info: AppColors.info,
    onInfo: AppColors.neutral0,
  );

  static const AppSemanticColors dark = AppSemanticColors(
    success: AppColors.successDark,
    onSuccess: AppColors.neutral900,
    warning: AppColors.warningDark,
    onWarning: AppColors.neutral900,
    info: AppColors.infoDark,
    onInfo: AppColors.neutral900,
  );

  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color info;
  final Color onInfo;

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? info,
    Color? onInfo,
  }) => AppSemanticColors(
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    warning: warning ?? this.warning,
    onWarning: onWarning ?? this.onWarning,
    info: info ?? this.info,
    onInfo: onInfo ?? this.onInfo,
  );

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
    );
  }
}
