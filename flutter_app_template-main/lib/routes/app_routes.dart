/// Every route path and name in the app.
///
/// Two things are defined per screen: a [path] (what appears in the URL) and a
/// name (what code refers to). Navigating by name means a URL can change
/// without touching call sites, and a typo becomes a compile error instead of a
/// silent 404.
abstract final class AppRoutes {
  // --- Paths ---
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signUp = '/sign-up';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String articles = '/articles';

  /// Child of [articles]; the full path is `/articles/:id`.
  static const String articleDetail = ':id';
  static const String settings = '/settings';

  // --- Names ---
  static const String splashName = 'splash';
  static const String onboardingName = 'onboarding';
  static const String loginName = 'login';
  static const String signUpName = 'signUp';
  static const String forgotPasswordName = 'forgotPassword';
  static const String homeName = 'home';
  static const String articlesName = 'articles';
  static const String articleDetailName = 'articleDetail';
  static const String settingsName = 'settings';

  /// Builds the full path to an article, for deep links and notifications.
  static String articleDetailPath(String id) => '$articles/$id';

  /// Routes reachable while signed out. Everything else redirects to [login].
  static const Set<String> publicPaths = {
    splash,
    onboarding,
    login,
    signUp,
    forgotPassword,
  };
}
