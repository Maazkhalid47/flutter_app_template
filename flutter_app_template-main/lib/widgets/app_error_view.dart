import 'package:flutter/material.dart';

import '../constants/ui_constants.dart';
import '../exceptions/app_exception.dart';
import '../extensions/context_extensions.dart';
import '../helpers/exception_message_resolver.dart';
import 'app_button.dart';

/// Full-screen error state.
///
/// Takes the [AppException] rather than a string so it can decide for itself
/// whether to offer a retry (`exception.isRetryable`) and which icon fits the
/// failure. Screens therefore cannot get that decision wrong.
class AppErrorView extends StatelessWidget {
  const AppErrorView({required this.exception, this.onRetry, super.key});

  final AppException exception;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final canRetry = exception.isRetryable && onRetry != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(UiConstants.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_iconFor(exception), size: 56, color: context.colors.error),
            const SizedBox(height: UiConstants.spaceMd),
            Text(
              ExceptionMessageResolver.resolve(context, exception),
              style: context.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (canRetry) ...[
              const SizedBox(height: UiConstants.spaceLg),
              AppButton.secondary(
                label: context.l10n.commonRetry,
                icon: Icons.refresh,
                expand: false,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconFor(AppException exception) => switch (exception) {
    NetworkException() => Icons.wifi_off,
    TimeoutException() => Icons.timer_off_outlined,
    UnauthorizedException() => Icons.lock_outline,
    NotFoundException() => Icons.search_off,
    ServerException() => Icons.cloud_off,
    _ => Icons.error_outline,
  };
}

/// Full-screen empty state, for "the request worked and there is nothing here".
///
/// Kept separate from the error view because conflating the two is how users
/// end up seeing "Something went wrong" on a brand new, legitimately empty
/// account.
class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(UiConstants.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: context.colors.onSurfaceVariant),
            const SizedBox(height: UiConstants.spaceMd),
            Text(
              message ?? context.l10n.commonEmpty,
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: UiConstants.spaceLg),
              AppButton.secondary(
                label: actionLabel!,
                expand: false,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
