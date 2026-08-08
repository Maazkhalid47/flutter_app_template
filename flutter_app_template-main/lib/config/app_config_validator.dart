import 'app_config.dart';

/// Fails fast when a release build is missing configuration it cannot work
/// without.
///
/// Called from `bootstrap.dart` before the first frame. In dev the problems are
/// only reported; in staging/prod they are fatal, because shipping a build with
/// an empty Supabase key is worse than not starting at all.
class AppConfigValidator {
  const AppConfigValidator(this._config);

  final AppConfig _config;

  /// Returns a list of human-readable configuration problems.
  List<String> validate() {
    final problems = <String>[];

    if (_config.apiBaseUrl.isEmpty) {
      problems.add('API_BASE_URL is not set.');
    } else if (Uri.tryParse(_config.apiBaseUrl)?.hasScheme != true) {
      problems.add('API_BASE_URL is not a valid absolute URL.');
    }

    if (!_config.environment.isDev) {
      if (!_config.isSupabaseConfigured) {
        problems.add('SUPABASE_URL / SUPABASE_ANON_KEY are required.');
      }
      if (!_config.isStripeConfigured) {
        problems.add('STRIPE_PUBLISHABLE_KEY is required.');
      }
      if (_config.apiBaseUrl.startsWith('http://')) {
        problems.add('API_BASE_URL must use https outside of dev.');
      }
    }

    return problems;
  }

  /// Throws [StateError] when a non-dev build is misconfigured.
  void validateOrThrow() {
    final problems = validate();
    if (problems.isEmpty || _config.environment.isDev) return;
    final details = problems.map((problem) => '  - $problem').join('\n');
    throw StateError(
      'Invalid configuration for ${_config.environment.key}:\n$details',
    );
  }
}
