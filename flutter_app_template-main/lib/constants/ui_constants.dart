import 'package:flutter/widgets.dart';

/// Layout primitives shared by every widget: spacing, radii, durations and
/// responsive breakpoints.
///
/// Colours and text styles do NOT belong here — they live in `theme/`, because
/// they change with the active `ThemeData`.
abstract final class UiConstants {
  // --- Spacing scale (4pt grid). Use these instead of raw numbers. ---
  static const double spaceXxs = 2;
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;
  static const double spaceXxl = 48;

  // --- Corner radii ---
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 20;
  static const double radiusPill = 999;

  // --- Component sizing ---
  static const double buttonHeight = 52;
  static const double inputHeight = 56;
  static const double iconSm = 16;
  static const double iconMd = 24;
  static const double iconLg = 32;
  static const double maxContentWidth = 720;

  // --- Motion ---
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 400);
  static const Curve defaultCurve = Curves.easeInOut;

  // --- Responsive breakpoints (logical pixels, width) ---
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  // --- Common paddings ---
  static const EdgeInsets screenPadding = EdgeInsets.all(spaceMd);
  static const EdgeInsets cardPadding = EdgeInsets.all(spaceMd);
  static const EdgeInsets listPadding = EdgeInsets.symmetric(
    horizontal: spaceMd,
    vertical: spaceSm,
  );
}
