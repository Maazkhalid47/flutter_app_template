import 'package:flutter/material.dart';

import '../constants/ui_constants.dart';
import '../utils/responsive.dart';

/// Picks a different widget per size class.
///
/// Use it when phone and tablet need genuinely different *structures* — a list
/// on mobile, list-plus-detail on tablet. For the same structure at different
/// sizes, use `context.responsive(...)` on the individual values instead;
/// building two near-identical trees doubles the maintenance.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    required this.mobile,
    this.tablet,
    this.desktop,
    super.key,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder, not MediaQuery: this then works correctly inside a split
    // view or a resizable desktop pane, where the window is wider than the slot.
    return LayoutBuilder(
      builder: (context, constraints) =>
          switch (Responsive.sizeForWidth(constraints.maxWidth)) {
            ScreenSize.mobile => mobile,
            ScreenSize.tablet => tablet ?? mobile,
            ScreenSize.desktop => desktop ?? tablet ?? mobile,
          },
    );
  }
}

/// Centres content and caps its width on large screens.
///
/// Full-width text on a desktop monitor is unreadable — this is the fix, and
/// wrapping a screen's body in it is usually all the desktop support a form or
/// article needs.
class ContentContainer extends StatelessWidget {
  const ContentContainer({
    required this.child,
    this.maxWidth = UiConstants.maxContentWidth,
    this.padding = UiConstants.screenPadding,
    super.key,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
