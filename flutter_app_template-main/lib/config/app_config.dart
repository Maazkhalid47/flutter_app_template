import '../enums/app_environment.dart';
import '../enums/log_level.dart';

/// Immutable, build-time application configuration.
///
/// Every value comes from `--dart-define`, so nothing secret is ever committed
/// and a single binary is never reconfigured at runtime. Read it through
/// [AppConfig.instance] after calling [AppConfig.initialize] in `bootstrap.dart`.
class AppConfig {
  const AppConfig._({
    required this.environment,
    required this.appName,
    required this.apiBaseUrl,
    required this.apiTimeout,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.stripePublishableKey,
    required this.stripeMerchantIdentifier,
    required this.minimumLogLevel,
    required this.enableAnalytics,
    required this.enableCrashReporting,
  });

  static AppConfig? _instance;

  /// The active configuration. Throws if read before [initialize].
  static AppConfig get instance {
    final config = _instance;
    if (config == null) {
      throw StateError(
        'AppConfig.initialize() must be called before AppConfig.instance. '
        'See bootstrap.dart.',
      );
    }
    return config;
  }

  /// Reads every `--dart-define` and freezes the result.
  ///
  /// Safe to call more than once (later calls are ignored) so tests and
  /// multiple entry points cannot fight over the singleton.
  static AppConfig initialize() {
    final existing = _instance;
    if (existing != null) return existing;

    const envKey = String.fromEnvironment('ENV', defaultValue: 'dev');
    final environment = AppEnvironment.fromKey(envKey);

    final config = AppConfig._(
      environment: environment,
      appName: const String.fromEnvironment(
        'APP_NAME',
        defaultValue: 'App Template',
      ),
      apiBaseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://jsonplaceholder.typicode.com',
      ),
      apiTimeout: const Duration(
        milliseconds: int.fromEnvironment(
          'API_TIMEOUT_MS',
          defaultValue: 30000,
        ),
      ),
      supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
      supabaseAnonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
      stripePublishableKey: const String.fromEnvironment(
        'STRIPE_PUBLISHABLE_KEY',
      ),
      stripeMerchantIdentifier: const String.fromEnvironment(
        'STRIPE_MERCHANT_ID',
        defaultValue: 'merchant.com.example.app',
      ),
      minimumLogLevel: environment.isProd ? LogLevel.warning : LogLevel.debug,
      enableAnalytics: !environment.isDev,
      enableCrashReporting: !environment.isDev,
    );
    _instance = config;
    return config;
  }

  /// Replaces the configuration. Test-only — never call from app code.
  static void overrideForTesting(AppConfig config) => _instance = config;

  /// Clears the configuration. Test-only.
  static void resetForTesting() => _instance = null;

  final AppEnvironment environment;
  final String appName;
  final String apiBaseUrl;
  final Duration apiTimeout;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String stripePublishableKey;
  final String stripeMerchantIdentifier;
  final LogLevel minimumLogLevel;
  final bool enableAnalytics;
  final bool enableCrashReporting;

  /// Whether Supabase was configured for this build. Features guard on this so
  /// a developer without credentials can still run the app.
  bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Whether Stripe was configured for this build.
  bool get isStripeConfigured => stripePublishableKey.isNotEmpty;

  /// Human-readable summary for debug banners and diagnostics screens.
  /// Never includes secrets.
  Map<String, Object?> get diagnostics => {
    'environment': environment.key,
    'appName': appName,
    'apiBaseUrl': apiBaseUrl,
    'supabaseConfigured': isSupabaseConfigured,
    'stripeConfigured': isStripeConfigured,
    'analytics': enableAnalytics,
  };
}
