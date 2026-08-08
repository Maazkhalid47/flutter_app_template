import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'generated/l10n/app_localizations.dart';
import 'notifications/notification_router.dart';
import 'onboarding/onboarding_repository.dart';
import 'providers/app_providers.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'routes/app_router.dart';
import 'services/analytics_service.dart';
import 'theme/app_theme.dart';
import 'viewmodels/auth_view_model.dart';

/// The root widget.
///
/// Deliberately thin: it installs providers, builds the router once, and hands
/// theme and locale to [MaterialApp]. Any logic here would run on every rebuild
/// of the entire app.
class App extends StatelessWidget {
  const App({
    required this.config,
    required this.themeProvider,
    required this.localeProvider,
    required this.onboardingRepository,
    required this.analytics,
    required this.notificationRouter,
    super.key,
  });

  final AppConfig config;
  final ThemeProvider themeProvider;
  final LocaleProvider localeProvider;
  final OnboardingRepository onboardingRepository;
  final AnalyticsService analytics;
  final NotificationRouter notificationRouter;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: AppProviders.root(
        themeProvider: themeProvider,
        localeProvider: localeProvider,
      ),
      // The router is built below the providers because it needs AuthViewModel,
      // and inside a Builder so it is created exactly once rather than on every
      // theme or locale change.
      child: Builder(
        builder: (context) => _AppRouterScope(
          onboardingRepository: onboardingRepository,
          analytics: analytics,
          notificationRouter: notificationRouter,
          config: config,
        ),
      ),
    );
  }
}

class _AppRouterScope extends StatefulWidget {
  const _AppRouterScope({
    required this.onboardingRepository,
    required this.analytics,
    required this.notificationRouter,
    required this.config,
  });

  final OnboardingRepository onboardingRepository;
  final AnalyticsService analytics;
  final NotificationRouter notificationRouter;
  final AppConfig config;

  @override
  State<_AppRouterScope> createState() => _AppRouterScopeState();
}

class _AppRouterScopeState extends State<_AppRouterScope> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.create(
      authViewModel: context.read<AuthViewModel>(),
      onboarding: widget.onboardingRepository,
      analytics: widget.analytics,
    );
    // Notification taps can now be turned into navigation. Anything that
    // arrived before this point was queued and is flushed here.
    widget.notificationRouter.attachNavigator(_router.go);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<ThemeProvider, ThemeMode>(
      (provider) => provider.themeMode,
    );
    final locale = context.select<LocaleProvider, Locale?>(
      (provider) => provider.locale,
    );

    return MaterialApp.router(
      title: widget.config.appName,
      debugShowCheckedModeBanner: !widget.config.environment.isProd,
      routerConfig: _router,
      themeMode: themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Caps text scaling: accessibility settings above ~1.4x break most
      // layouts outright, and a clipped screen helps nobody.
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(
              minScaleFactor: 0.8,
              maxScaleFactor: 1.4,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
