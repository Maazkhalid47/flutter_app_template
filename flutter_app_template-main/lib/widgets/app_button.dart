import 'package:flutter/material.dart';

import '../constants/ui_constants.dart';

/// Visual weight of a button, chosen by role rather than by colour.
///
/// A screen should have exactly one [AppButtonVariant.primary].
enum AppButtonVariant { primary, secondary, text, destructive }

/// The app's button.
///
/// Wrapping Material's buttons buys three things every screen needs and none of
/// them should be re-implemented per screen:
/// * a built-in [isLoading] state that keeps the button's size stable,
/// * automatic disabling while loading, so a double tap cannot submit twice,
/// * one place where sizing and shape are decided (with `AppTheme`).
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isEnabled = true,
    this.expand = true,
    super.key,
  });

  /// Named constructors so the variant reads as intent at the call site.
  const AppButton.secondary({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isEnabled = true,
    this.expand = true,
    super.key,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.text({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isEnabled = true,
    this.expand = false,
    super.key,
  }) : variant = AppButtonVariant.text;

  const AppButton.destructive({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isEnabled = true,
    this.expand = true,
    super.key,
  }) : variant = AppButtonVariant.destructive;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isEnabled;

  /// Fill the available width. Off for text buttons, which are usually inline.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final isInteractive = isEnabled && !isLoading && onPressed != null;
    final child = _buildChild(context);
    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
        onPressed: isInteractive ? onPressed : null,
        child: child,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: isInteractive ? onPressed : null,
        child: child,
      ),
      AppButtonVariant.text => TextButton(
        onPressed: isInteractive ? onPressed : null,
        child: child,
      ),
      AppButtonVariant.destructive => FilledButton(
        onPressed: isInteractive ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Theme.of(context).colorScheme.onError,
        ),
        child: child,
      ),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _buildChild(BuildContext context) {
    if (isLoading) {
      // Sized to the text height so the button does not resize mid-submit.
      return const SizedBox(
        height: UiConstants.iconMd,
        width: UiConstants.iconMd,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (icon == null) return Text(label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: UiConstants.iconSm),
        const SizedBox(width: UiConstants.spaceSm),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
