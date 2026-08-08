import 'package:flutter/material.dart';

import '../constants/ui_constants.dart';

/// Composition helpers that cut nesting out of build methods.
///
/// Use sparingly: they are for wrapping, never for hiding logic. If an
/// extension would need a parameter list longer than two or three arguments,
/// write a real widget in `widgets/` instead.
extension WidgetX on Widget {
  /// Wraps in [Padding] with the same inset on every side.
  Widget paddedAll([double value = UiConstants.spaceMd]) =>
      Padding(padding: EdgeInsets.all(value), child: this);

  /// Wraps in [Padding] with symmetric insets.
  Widget paddedSymmetric({double horizontal = 0, double vertical = 0}) =>
      Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontal,
          vertical: vertical,
        ),
        child: this,
      );

  Widget get expanded => Expanded(child: this);

  Widget flexible({int flex = 1}) => Flexible(flex: flex, child: this);

  Widget get centered => Center(child: this);

  /// Rounds the widget's corners by clipping.
  Widget rounded([double radius = UiConstants.radiusMd]) =>
      ClipRRect(borderRadius: BorderRadius.circular(radius), child: this);

  /// Keeps the widget in the tree but hides it, preserving layout space when
  /// [maintainSize] is true.
  Widget visible(bool isVisible, {bool maintainSize = false}) => Visibility(
    visible: isVisible,
    maintainSize: maintainSize,
    maintainAnimation: maintainSize,
    maintainState: maintainSize,
    child: this,
  );

  /// Constrains content width on large screens so text lines stay readable.
  Widget get constrainedToContent => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: UiConstants.maxContentWidth),
      child: this,
    ),
  );

  /// Adds a tap target without the visual weight of a button.
  Widget onTap(VoidCallback? callback, {double? radius}) => InkWell(
    onTap: callback,
    borderRadius: BorderRadius.circular(radius ?? UiConstants.radiusMd),
    child: this,
  );
}

/// Vertical/horizontal gaps that read better than `SizedBox(height: 16)`.
extension SpacingX on num {
  Widget get verticalSpace => SizedBox(height: toDouble());

  Widget get horizontalSpace => SizedBox(width: toDouble());
}
