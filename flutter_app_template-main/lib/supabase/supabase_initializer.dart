import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../utils/logger.dart';

/// Brings the Supabase SDK up during bootstrap.
///
/// Kept out of `main.dart` so the entry point stays readable, and so the
/// "not configured" path is explicit: a developer without credentials still
/// gets a running app, with Supabase-backed features disabled rather than a
/// crash on the first frame.
class SupabaseInitializer {
  const SupabaseInitializer({
    required AppConfig config,
    required AppLogger logger,
  }) : _config = config,
       _logger = logger;

  final AppConfig _config;
  final AppLogger _logger;

  /// Returns `true` when Supabase is ready to use.
  Future<bool> initialize() async {
    if (!_config.isSupabaseConfigured) {
      _logger.warning(
        'Supabase is not configured; auth and database features are disabled. '
        'Pass --dart-define=SUPABASE_URL=... and SUPABASE_ANON_KEY=...',
      );
      return false;
    }

    try {
      await Supabase.initialize(
        url: _config.supabaseUrl,
        // Supabase renamed the anon key to the "publishable" key; the value
        // passed via SUPABASE_ANON_KEY is the same one.
        publishableKey: _config.supabaseAnonKey,
        debug: !_config.environment.isProd,
        authOptions: const FlutterAuthClientOptions(
          // Sessions are persisted by the SDK in secure storage and refreshed
          // automatically; the app's TokenStorage mirrors the access token so
          // the API interceptor can attach it to non-Supabase calls.
          authFlowType: AuthFlowType.pkce,
        ),
      );
      _logger.info('Supabase initialized.');
      return true;
    } catch (error, stackTrace) {
      _logger.error(
        'Supabase initialization failed.',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// The client. Only `supabase/` should call this — everything else goes
  /// through a repository.
  static SupabaseClient get client => Supabase.instance.client;
}
