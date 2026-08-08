import 'package:flutter/material.dart';

/// The type scale.
///
/// Defined once against a [ColorScheme] so light and dark share the same
/// metrics and differ only in colour. Widgets read `context.textTheme.bodyLarge`
/// and friends — never construct a [TextStyle] with a hardcoded size inline.
abstract final class AppTypography {
  /// Set this to your bundled font family once you add one to `pubspec.yaml`.
  /// `null` keeps the platform default, which is the right choice until then.
  static const String? fontFamily = null;

  static TextTheme textTheme(ColorScheme scheme) {
    final onSurface = scheme.onSurface;
    final muted = scheme.onSurfaceVariant;

    return TextTheme(
      displayLarge: _style(57, FontWeight.w400, onSurface, height: 1.12),
      displayMedium: _style(45, FontWeight.w400, onSurface, height: 1.16),
      displaySmall: _style(36, FontWeight.w400, onSurface, height: 1.22),
      headlineLarge: _style(32, FontWeight.w600, onSurface, height: 1.25),
      headlineMedium: _style(28, FontWeight.w600, onSurface, height: 1.29),
      headlineSmall: _style(24, FontWeight.w600, onSurface, height: 1.33),
      titleLarge: _style(22, FontWeight.w600, onSurface, height: 1.27),
      titleMedium: _style(16, FontWeight.w600, onSurface, height: 1.5),
      titleSmall: _style(14, FontWeight.w600, onSurface, height: 1.43),
      bodyLarge: _style(16, FontWeight.w400, onSurface, height: 1.5),
      bodyMedium: _style(14, FontWeight.w400, onSurface, height: 1.43),
      bodySmall: _style(12, FontWeight.w400, muted, height: 1.33),
      labelLarge: _style(14, FontWeight.w600, onSurface, height: 1.43),
      labelMedium: _style(12, FontWeight.w500, muted, height: 1.33),
      labelSmall: _style(11, FontWeight.w500, muted, height: 1.45),
    );
  }

  static TextStyle _style(
    double size,
    FontWeight weight,
    Color color, {
    required double height,
  }) => TextStyle(
    fontFamily: fontFamily,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );
}
