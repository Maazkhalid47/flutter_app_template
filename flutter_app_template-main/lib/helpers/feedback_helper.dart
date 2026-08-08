import 'package:flutter/material.dart';

import '../constants/ui_constants.dart';
import '../exceptions/app_exception.dart';
import '../extensions/context_extensions.dart';
import 'exception_message_resolver.dart';

/// One place that decides how the app talks back to the user.
///
/// Without this, every screen invents its own snackbar styling and its own way
/// of showing an error, and the app stops feeling like one product. Views call
/// these helpers; they never build a [SnackBar] by hand.
abstract final class FeedbackHelper {
  /// Neutral confirmation ("Saved", "Copied").
  static void showMessage(BuildContext context, String message) => _show(
    context,
    message,
    background: context.colors.inverseSurface,
    foreground: context.colors.onInverseSurface,
  );

  static void showSuccess(BuildContext context, String message) => _show(
    context,
    message,
    background: context.semanticColors.success,
    foreground: context.semanticColors.onSuccess,
    icon: Icons.check_circle_outline,
  );

  /// Shows a failure using the exception's localized message, with a Retry
  /// action when the exception says retrying makes sense.
  static void showError(
    BuildContext context,
    AppException exception, {
    VoidCallback? onRetry,
  }) => _show(
    context,
    ExceptionMessageResolver.resolve(context, exception),
    background: context.colors.errorContainer,
    foreground: context.colors.onErrorContainer,
    icon: Icons.error_outline,
    action: exception.isRetryable && onRetry != null
        ? SnackBarAction(
            label: context.l10n.commonRetry,
            textColor: context.colors.onErrorContainer,
            onPressed: onRetry,
          )
        : null,
  );

  static void _show(
    BuildContext context,
    String message, {
    required Color background,
    required Color foreground,
    IconData? icon,
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UiConstants.radiusMd),
          ),
          margin: UiConstants.screenPadding,
          action: action,
          content: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: foreground, size: UiConstants.iconMd),
                const SizedBox(width: UiConstants.spaceSm),
              ],
              Expanded(
                child: Text(message, style: TextStyle(color: foreground)),
              ),
            ],
          ),
        ),
      );
  }

  /// A yes/no dialog. Returns `true` only when the user confirms.
  ///
  /// Returning a plain `bool` (never null) keeps call sites free of null
  /// checks: dismissing the dialog means "no".
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelLabel ?? dialogContext.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: isDestructive
                ? TextButton.styleFrom(
                    foregroundColor: dialogContext.colors.error,
                  )
                : null,
            child: Text(confirmLabel ?? dialogContext.l10n.commonOk),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Blocks interaction while [task] runs, then returns its value.
  ///
  /// The dialog is dismissed in a `finally`, so a thrown error cannot leave the
  /// user staring at a spinner forever.
  static Future<T> withBlockingProgress<T>(
    BuildContext context,
    Future<T> Function() task,
  ) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    unawaitedShowDialog(context);
    try {
      return await task();
    } finally {
      if (navigator.canPop()) navigator.pop();
    }
  }

  /// Separated out so [withBlockingProgress] reads linearly; the dialog future
  /// completes only when we pop it.
  static void unawaitedShowDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator.adaptive()),
      ),
    );
  }
}
