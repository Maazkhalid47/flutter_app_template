// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'App Template';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Get Started';

  @override
  String get authLoginTitle => 'Welcome back';

  @override
  String get authSignUpTitle => 'Create an account';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authLoginButton => 'Sign in';

  @override
  String get authSignUpButton => 'Sign up';

  @override
  String get authNoAccount => 'Don\'t have an account?';

  @override
  String get authHaveAccount => 'Already have an account?';

  @override
  String get authSignOut => 'Sign out';

  @override
  String get homeTitle => 'Home';

  @override
  String get articlesTitle => 'Articles';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonEmpty => 'Nothing here yet';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonOk => 'OK';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNetwork => 'No internet connection.';

  @override
  String get errorTimeout => 'The request timed out.';

  @override
  String get errorUnauthorized =>
      'Your session has expired. Please sign in again.';

  @override
  String get errorNotFound => 'We couldn\'t find what you were looking for.';

  @override
  String get errorServer =>
      'Our servers are having trouble. Please try again later.';

  @override
  String get validationRequired => 'This field is required';

  @override
  String get validationEmail => 'Enter a valid email address';

  @override
  String validationPasswordShort(int min) {
    return 'Password must be at least $min characters';
  }

  @override
  String get routeNotFound => 'Page not found';
}
