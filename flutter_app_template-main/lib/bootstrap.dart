import 'package:flutter/material.dart';

import 'api/api_client.dart';
import 'app.dart';
import 'auth/auth_repository.dart';
import 'cache/cache_manager.dart';
import 'config/app_config.dart';
import 'config/app_config_validator.dart';
import 'dependency_injection/service_locator.dart';
import 'exceptions/global_error_handler.dart';
import 'notifications/notification_router.dart';
import 'notifications/push_notification_service.dart';
import 'onboarding/onboarding_repository.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'services/analytics_service.dart';
import 'storage/key_value_store.dart';
import 'stripe/payment_service.dart';
import 'supabase/supabase_initializer.dart';
import 'utils/logger.dart';

/// Everything that must happen before the first frame, in order.
///
/// Kept out of `main.dart` so the entry point stays three lines and this
/// sequence — which is genuinely order-dependent — is readable and testable.
///
/// The rule for what belongs here: work whose absence would make the first
/// frame wrong (theme, locale, session) or unsafe (error handlers). Everything
/// else is started after the app is on screen, in [_warmUpInBackground].
Future<Widget> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Configuration first — everything below reads from it.
  final config = AppConfig.initialize();
  AppConfigValidator(config).validateOrThrow();

  // 2. Supabase before the locator, which registers auth differently depending
  //    on whether it came up.
  final logger = AppLogger(minimumLevel: config.minimumLogLevel);
  final isSupabaseReady = await SupabaseInitializer(
    config: config,
    logger: logger,
  ).initialize();

  // 3. The object graph.
  await ServiceLocator.setup(isSupabaseReady: isSupabaseReady);

  // 4. Crash handlers, as early as possible after the locator exists so
  //    failures in the remaining steps are still reported.
  getIt<GlobalErrorHandler>().install();

  final store = getIt<KeyValueStore>();

  // 5. State the first frame depends on. Loaded in parallel: they are
  //    independent, and each is a disk read.
  final themeProvider = ThemeProvider(store);
  final localeProvider = LocaleProvider(
    store: store,
    apiClient: getIt<ApiClient>(),
  );
  final onboardingRepository = getIt<OnboardingRepository>();

  await Future.wait([
    themeProvider.load(),
    localeProvider.load(),
    onboardingRepository.load(),
  ]);

  // 6. Restore the session before the first frame, so the router never shows
  //    login to a signed-in user. Done through the repository rather than the
  //    view model because AuthViewModel is created by the provider tree below
  //    and reads `currentStatus` at construction — by then this has resolved.
  await getIt<AuthRepository>().restoreSession();

  _warmUpInBackground(logger);

  return App(
    config: config,
    themeProvider: themeProvider,
    localeProvider: localeProvider,
    onboardingRepository: onboardingRepository,
    analytics: getIt<AnalyticsService>(),
    notificationRouter: getIt<NotificationRouter>(),
  );
}

/// Non-blocking startup work.
///
/// None of this changes what the first frame looks like, so making the user
/// wait for it is pure startup latency. Failures are logged and swallowed:
/// analytics or a cache sweep must never prevent the app from opening.
void _warmUpInBackground(AppLogger logger) {
  Future<void>(() async {
    try {
      await getIt<AnalyticsService>().initialize();
      await getIt<AnalyticsService>().logEvent(AnalyticsEvent.appOpened);
      await getIt<PaymentService>().initialize();
      await getIt<PushNotificationService>().initialize();
      await getIt<NotificationRouter>().start();
      await getIt<CacheManager>().evictExpired();
    } catch (error, stackTrace) {
      logger.error(
        'Background warm-up failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  });
}
