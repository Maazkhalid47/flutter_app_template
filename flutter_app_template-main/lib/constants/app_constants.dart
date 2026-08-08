/// Values that describe the application itself and never change at runtime.
///
/// Anything that differs per environment belongs in `config/app_config.dart`,
/// not here.
abstract final class AppConstants {
  /// Fallback name used before `AppConfig` is available (e.g. crash handlers).
  static const String fallbackAppName = 'App Template';

  static const String supportEmail = 'support@example.com';
  static const String privacyPolicyUrl = 'https://example.com/privacy';
  static const String termsOfServiceUrl = 'https://example.com/terms';

  /// Default page size for every paginated list in the app.
  static const int defaultPageSize = 20;

  /// How long a cached network response stays fresh by default.
  static const Duration defaultCacheTtl = Duration(minutes: 5);

  /// Delay applied to search-as-you-type inputs.
  static const Duration searchDebounce = Duration(milliseconds: 350);

  /// Maximum automatic retries for idempotent requests.
  static const int maxRequestRetries = 2;

  /// Minimum accepted password length. Used by the validator and by the
  /// sign-up copy so the two can never disagree.
  static const int minPasswordLength = 8;
}
