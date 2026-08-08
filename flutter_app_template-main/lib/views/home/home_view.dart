import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/responsive_layout.dart';
import '../../constants/ui_constants.dart';
import '../../extensions/context_extensions.dart';
import '../../routes/app_routes.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../widgets/app_button.dart';

/// The signed-in landing screen.
///
/// Intentionally almost empty — this is a template, and the home screen is the
/// first thing you will replace. It exists to prove the authenticated route
/// works and to give the other example screens somewhere to be reached from.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthViewModel, String>(
      (viewModel) => viewModel.user?.displayLabel ?? '',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.homeTitle),
        actions: [
          IconButton(
            onPressed: () => context.pushNamed(AppRoutes.settingsName),
            icon: const Icon(Icons.settings_outlined),
            tooltip: context.l10n.settingsTitle,
          ),
        ],
      ),
      body: SafeArea(
        child: ContentContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (user.isNotEmpty)
                Text(
                  '${context.l10n.authLoginTitle}, $user',
                  style: context.textTheme.titleLarge,
                ),
              const SizedBox(height: UiConstants.spaceLg),
              AppButton(
                label: context.l10n.articlesTitle,
                icon: Icons.article_outlined,
                onPressed: () => context.pushNamed(AppRoutes.articlesName),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
