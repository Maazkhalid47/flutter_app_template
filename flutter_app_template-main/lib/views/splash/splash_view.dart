import 'package:flutter/material.dart';

import '../../constants/ui_constants.dart';
import '../../extensions/context_extensions.dart';

/// Shown while the stored session is being restored.
///
/// It navigates nowhere itself — `RouteGuard` moves the user on as soon as
/// [AuthStatus] resolves. A splash screen with its own timer and its own
/// `context.go` is how you get two competing navigations and a flicker.
class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bolt_rounded, size: 72, color: context.colors.primary),
            const SizedBox(height: UiConstants.spaceLg),
            Text(context.l10n.appName, style: context.textTheme.headlineSmall),
            const SizedBox(height: UiConstants.spaceXl),
            const SizedBox(
              height: UiConstants.iconMd,
              width: UiConstants.iconMd,
              child: CircularProgressIndicator.adaptive(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}
