import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../onboarding/onboarding_repository.dart';
import '../onboarding/onboarding_view.dart';
import '../providers/app_providers.dart';
import '../services/analytics_service.dart';
import '../viewmodels/auth_view_model.dart';
import '../views/articles/article_detail_view.dart';
import '../views/articles/article_list_view.dart';
import '../views/auth/forgot_password_view.dart';
import '../views/auth/login_view.dart';
import '../views/auth/sign_up_view.dart';
import '../views/error/not_found_view.dart';
import '../views/home/home_view.dart';
import '../views/settings/settings_view.dart';
import '../views/splash/splash_view.dart';
import 'app_routes.dart';
import 'route_guards.dart';

/// Builds the app's [GoRouter].
///
/// Declarative routing was chosen over imperative `Navigator.push` because auth
/// state decides what the user may see: with a central [redirect], signing out
/// anywhere in the app immediately moves every open screen to login. With
/// imperative navigation each screen would have to remember to check.
abstract final class AppRouter {
  static GoRouter create({
    required AuthViewModel authViewModel,
    required OnboardingRepository onboarding,
    required AnalyticsService analytics,
  }) {
    final guard = RouteGuard(
      authStatus: () => authViewModel.status,
      onboarding: onboarding,
    );

    return GoRouter(
      initialLocation: AppRoutes.splash,
      // Re-runs `redirect` whenever auth changes — this is what makes sign-out
      // navigate on its own.
      refreshListenable: authViewModel,
      redirect: (context, state) => guard.redirect(state.matchedLocation),
      observers: [_AnalyticsRouteObserver(analytics)],
      errorBuilder: (context, state) => NotFoundView(location: state.uri.path),
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          name: AppRoutes.splashName,
          builder: (context, state) => const SplashView(),
        ),
        GoRoute(
          path: AppRoutes.onboarding,
          name: AppRoutes.onboardingName,
          builder: (context, state) => const OnboardingView(),
        ),
        GoRoute(
          path: AppRoutes.login,
          name: AppRoutes.loginName,
          builder: (context, state) => const LoginView(),
        ),
        GoRoute(
          path: AppRoutes.signUp,
          name: AppRoutes.signUpName,
          builder: (context, state) => const SignUpView(),
        ),
        GoRoute(
          path: AppRoutes.forgotPassword,
          name: AppRoutes.forgotPasswordName,
          builder: (context, state) => const ForgotPasswordView(),
        ),
        GoRoute(
          path: AppRoutes.home,
          name: AppRoutes.homeName,
          builder: (context, state) => const HomeView(),
        ),
        GoRoute(
          path: AppRoutes.articles,
          name: AppRoutes.articlesName,
          // The view model is created here, not in the widget, so it is scoped
          // to the route and disposed when the user leaves.
          builder: (context, state) => ChangeNotifierProvider(
            create: AppProviders.articleList,
            child: const ArticleListView(),
          ),
          routes: [
            GoRoute(
              path: AppRoutes.articleDetail,
              name: AppRoutes.articleDetailName,
              builder: (context, state) => ArticleDetailView(
                articleId: state.pathParameters['id'] ?? '',
              ),
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.settings,
          name: AppRoutes.settingsName,
          builder: (context, state) => const SettingsView(),
        ),
      ],
    );
  }
}

/// Reports screen views to analytics.
///
/// One observer instead of a `logScreenView` call in every screen's
/// `initState` — screens get added, and those calls get forgotten.
class _AnalyticsRouteObserver extends NavigatorObserver {
  _AnalyticsRouteObserver(this._analytics);

  final AnalyticsService _analytics;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _log(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _log(previousRoute);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _log(newRoute);

  void _log(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name == null || name.isEmpty) return;
    unawaited(_analytics.logScreenView(name));
  }
}
