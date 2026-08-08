import 'package:flutter/widgets.dart';

import '../constants/ui_constants.dart';

/// The size class of the current window.
///
/// Layout decisions branch on this instead of on raw pixel widths, so the
/// breakpoints live in exactly one place.
enum ScreenSize {
  mobile,
  tablet,
  desktop;

  bool get isMobile => this == ScreenSize.mobile;
  bool get isTablet => this == ScreenSize.tablet;
  bool get isDesktop => this == ScreenSize.desktop;

  /// True for tablet and desktop — the common "wide layout" check.
  bool get isWide => this != ScreenSize.mobile;
}

/// Window-size helpers.
///
/// Prefer `context.screenSize` from `extensions/context_extensions.dart` at
/// call sites; this class holds the logic those extensions delegate to.
abstract final class Responsive {
  /// Classifies a raw width. Exposed separately so it can be unit-tested
  /// without a `BuildContext`.
  static ScreenSize sizeForWidth(double width) {
    if (width < UiConstants.mobileBreakpoint) return ScreenSize.mobile;
    if (width < UiConstants.tabletBreakpoint) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }

  static ScreenSize of(BuildContext context) =>
      sizeForWidth(MediaQuery.sizeOf(context).width);

  /// Picks one of three values for the current size class, falling back to the
  /// next smaller one when a value is not supplied.
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) => switch (of(context)) {
    ScreenSize.mobile => mobile,
    ScreenSize.tablet => tablet ?? mobile,
    ScreenSize.desktop => desktop ?? tablet ?? mobile,
  };

  /// Number of grid columns appropriate for the current width.
  static int gridColumns(BuildContext context) =>
      value(context, mobile: 1, tablet: 2, desktop: 3);
}
