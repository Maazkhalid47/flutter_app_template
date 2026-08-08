import '../enums/auth_status.dart';
import '../onboarding/onboarding_repository.dart';
import 'app_routes.dart';

/// The redirect rules, as one pure function.
///
/// Extracted from the router so the rules can be unit-tested exhaustively
/// without building a widget tree — routing bugs (a redirect loop, a screen a
/// signed-out user can reach) are expensive to find by hand.
///
/// Order is the whole design:
/// 1. Unknown auth → hold on splash. Never guess.
/// 2. Onboarding incomplete → onboarding, whatever else was asked for.
/// 3. Signed out on a private route → login.
/// 4. Signed in on an auth route → home.
class RouteGuard {
  const RouteGuard({
    required AuthStatus Function() authStatus,
    required OnboardingRepository onboarding,
  }) : _authStatus = authStatus,
       _onboarding = onboarding;

  final AuthStatus Function() _authStatus;
  final OnboardingRepository _onboarding;

  /// Returns the path to redirect to, or `null` to allow [location].
  String? redirect(String location) {
    final status = _authStatus();

    // 1. Session not resolved yet: stay on splash, redirect away from nothing.
    if (!status.isKnown) {
      return location == AppRoutes.splash ? null : AppRoutes.splash;
    }

    final isAuthenticated = status.isAuthenticated;
    final needsOnboarding = !_onboarding.hasCompletedOnboarding;

    // 2. Onboarding gates everything, including the login screen.
    if (needsOnboarding) {
      return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
    }
    if (location == AppRoutes.onboarding) {
      return isAuthenticated ? AppRoutes.home : AppRoutes.login;
    }

    // 3. Splash has nothing left to do once the session is known.
    if (location == AppRoutes.splash) {
      return isAuthenticated ? AppRoutes.home : AppRoutes.login;
    }

    final isPublic = AppRoutes.publicPaths.contains(location);

    // 4. Private route without a session.
    if (!isAuthenticated && !isPublic) return AppRoutes.login;

    // 5. Already signed in; the login/sign-up screens are pointless.
    if (isAuthenticated && isPublic) return AppRoutes.home;

    return null;
  }
}
