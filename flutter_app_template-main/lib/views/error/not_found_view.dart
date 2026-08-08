import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/ui_constants.dart';
import '../../extensions/context_extensions.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_button.dart';

/// Shown for an unmatched route.
///
/// Worth having even on mobile: a malformed deep link or a stale push
/// notification payload lands here instead of crashing, and the user gets a way
/// back rather than a dead end.
class NotFoundView extends StatelessWidget {
  const NotFoundView({this.location, super.key});

  /// The path that failed to match. Shown so a tester can report it.
  final String? location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(UiConstants.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.explore_off_outlined,
                size: 56,
                color: context.colors.onSurfaceVariant,
              ),
              const SizedBox(height: UiConstants.spaceMd),
              Text(
                context.l10n.routeNotFound,
                style: context.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (location != null) ...[
                const SizedBox(height: UiConstants.spaceXs),
                Text(
                  location!,
                  style: context.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: UiConstants.spaceLg),
              AppButton.secondary(
                label: context.l10n.homeTitle,
                expand: false,
                onPressed: () => context.goNamed(AppRoutes.homeName),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
