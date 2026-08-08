import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/responsive_layout.dart';
import '../../constants/ui_constants.dart';
import '../../extensions/context_extensions.dart';
import '../../helpers/feedback_helper.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../widgets/app_button.dart';

/// Settings: theme, language, sign out.
///
/// Shows the two app-wide providers in use, and the one place a destructive
/// action is confirmed before it runs.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settingsTitle),
        leading: BackButton(onPressed: context.pop),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            ContentContainer(
              padding: const EdgeInsets.symmetric(
                horizontal: UiConstants.spaceMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: UiConstants.spaceMd),
                  Text(
                    context.l10n.settingsTheme,
                    style: context.textTheme.titleSmall,
                  ),
                  const SizedBox(height: UiConstants.spaceSm),
                  SegmentedButton<ThemeMode>(
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text(context.l10n.themeSystem),
                        icon: const Icon(Icons.brightness_auto),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text(context.l10n.themeLight),
                        icon: const Icon(Icons.light_mode_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text(context.l10n.themeDark),
                        icon: const Icon(Icons.dark_mode_outlined),
                      ),
                    ],
                    selected: {themeProvider.themeMode},
                    onSelectionChanged: (selection) =>
                        themeProvider.setThemeMode(selection.first),
                  ),
                  const SizedBox(height: UiConstants.spaceLg),
                  Text(
                    context.l10n.settingsLanguage,
                    style: context.textTheme.titleSmall,
                  ),
                  const SizedBox(height: UiConstants.spaceSm),
                  DropdownButtonFormField<String>(
                    // An empty value means "follow the device"; DropdownButton
                    // cannot represent null as a selectable item.
                    initialValue: localeProvider.locale?.languageCode ?? '',
                    items: [
                      DropdownMenuItem(
                        value: '',
                        child: Text(context.l10n.themeSystem),
                      ),
                      ...localeProvider.supportedLocales.map(
                        (locale) => DropdownMenuItem(
                          value: locale.languageCode,
                          child: Text(locale.languageCode.toUpperCase()),
                        ),
                      ),
                    ],
                    onChanged: (code) => localeProvider.setLocale(
                      code == null || code.isEmpty ? null : Locale(code),
                    ),
                  ),
                  const SizedBox(height: UiConstants.spaceXl),
                  AppButton.destructive(
                    label: context.l10n.authSignOut,
                    icon: Icons.logout,
                    isLoading: authViewModel.isBusy,
                    onPressed: () => _confirmSignOut(context, authViewModel),
                  ),
                  const SizedBox(height: UiConstants.spaceXl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(
    BuildContext context,
    AuthViewModel viewModel,
  ) async {
    final confirmed = await FeedbackHelper.confirm(
      context,
      title: context.l10n.authSignOut,
      message: context.l10n.authSignOut,
      confirmLabel: context.l10n.authSignOut,
      isDestructive: true,
    );
    if (!confirmed) return;
    // No navigation here: RouteGuard sends the user to login when auth state
    // flips to unauthenticated.
    await viewModel.signOut();
  }
}
