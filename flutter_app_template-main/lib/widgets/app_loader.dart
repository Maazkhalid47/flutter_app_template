import 'package:flutter/material.dart';

import '../constants/ui_constants.dart';

/// The app's loading indicator.
///
/// One widget so every spinner is the same size and platform-appropriate
/// (`.adaptive` gives a Cupertino spinner on iOS at no extra cost).
class AppLoader extends StatelessWidget {
  const AppLoader({this.message, this.size = 32, super.key});

  /// Fills the available space and centres itself.
  const AppLoader.fullscreen({this.message, super.key}) : size = 40;

  final String? message;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: size,
            width: size,
            child: const CircularProgressIndicator.adaptive(),
          ),
          if (message != null) ...[
            const SizedBox(height: UiConstants.spaceMd),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// A translucent scrim with a spinner, laid over existing content.
///
/// Preferred over a blocking dialog for in-place operations: the user keeps
/// their context, and there is no dialog left behind if an error is thrown.
class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({
    required this.isLoading,
    required this.child,
    this.message,
    super.key,
  });

  final bool isLoading;
  final String? message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            // AbsorbPointer is what actually blocks input; the colour alone
            // would let taps through to the content underneath.
            child: AbsorbPointer(
              child: ColoredBox(
                color: Theme.of(
                  context,
                ).colorScheme.scrim.withValues(alpha: 0.32),
                child: AppLoader(message: message),
              ),
            ),
          ),
      ],
    );
  }
}
