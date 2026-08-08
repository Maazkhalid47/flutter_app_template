import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
// get_it exports its own `Disposable`; the app's version is the one meant here.
import 'package:get_it/get_it.dart' hide Disposable;

import '../api/api_client.dart';
import '../api/dio_api_client.dart';
import '../auth/auth_repository.dart';
import '../auth/supabase_auth_repository.dart';
import '../auth/token_storage.dart';
import '../auth/unavailable_auth_repository.dart';
import '../cache/cache_manager.dart';
import '../config/app_config.dart';
import '../core/disposable.dart';
import '../exceptions/global_error_handler.dart';
import '../network/interceptors/auth_interceptor.dart';
import '../network/interceptors/connectivity_interceptor.dart';
import '../network/interceptors/logging_interceptor.dart';
import '../network/interceptors/retry_interceptor.dart';
import '../network/network_info.dart';
import '../notifications/notification_router.dart';
import '../notifications/push_notification_service.dart';
import '../onboarding/onboarding_repository.dart';
import '../permissions/permission_service.dart';
import '../repositories/article_repository.dart';
import '../services/analytics_service.dart';
import '../services/article_api_service.dart';
import '../storage/key_value_store.dart';
import '../storage/preferences_store.dart';
import '../storage/secure_store.dart';
import '../stripe/payment_service.dart';
import '../stripe/stripe_payment_service.dart';
import '../supabase/supabase_auth_data_source.dart';
import '../supabase/supabase_database_service.dart';
import '../supabase/supabase_initializer.dart';
import '../utils/logger.dart';

/// The application's single composition root.
///
/// Every dependency is created here and nowhere else. That is what makes the
/// object graph reviewable in one file, and it is why no class in this codebase
/// calls `getIt<T>()` internally — they receive what they need through their
/// constructor. Only the widget layer and `bootstrap.dart` resolve from the
/// locator.
///
/// Registration style:
/// * `registerSingleton` — already-constructed, needed immediately.
/// * `registerLazySingleton` — one instance, built on first use.
/// * `registerFactory` — a fresh instance per call (view models).
final GetIt getIt = GetIt.instance;

/// Named instance keys, so string typos cannot silently resolve the wrong
/// object.
abstract final class DiTokens {
  /// The Dio instance used only for replaying a request after a token refresh.
  /// Separate so it cannot recurse through [AuthInterceptor].
  static const String retryDio = 'retry_dio';
}

abstract final class ServiceLocator {
  /// Builds the graph. Call once from `bootstrap.dart`.
  ///
  /// [isSupabaseReady] comes from [SupabaseInitializer]: when Supabase could
  /// not start, auth is registered against a repository that fails cleanly
  /// instead of throwing on a null client.
  static Future<void> setup({required bool isSupabaseReady}) async {
    final config = AppConfig.instance;

    // ---------------------------------------------------------------- core --
    final logger = AppLogger(minimumLevel: config.minimumLogLevel);
    getIt
      ..registerSingleton<AppConfig>(config)
      ..registerSingleton<AppLogger>(logger);

    // ------------------------------------------------------------- storage --
    final preferences = await PreferencesStore.create();
    getIt
      ..registerSingleton<PreferencesStore>(preferences)
      ..registerSingleton<KeyValueStore>(preferences)
      ..registerSingleton<SecureStore>(SecureStore.defaults)
      ..registerLazySingleton<TokenStorage>(
        () => SecureTokenStorage(getIt<SecureStore>()),
      )
      ..registerLazySingleton<CacheManager>(
        () => CacheManager(store: getIt<PreferencesStore>(), logger: logger),
      );

    // ----------------------------------------------------------- analytics --
    // Swap NoopAnalyticsService for a real implementation here; nothing else
    // in the app needs to know.
    getIt
      ..registerLazySingleton<AnalyticsService>(
        () => NoopAnalyticsService(logger),
      )
      ..registerLazySingleton<GlobalErrorHandler>(
        () => GlobalErrorHandler(
          logger: logger,
          analytics: getIt<AnalyticsService>(),
        ),
      );

    // ------------------------------------------------------------- network --
    getIt
      ..registerSingleton<NetworkInfo>(ConnectivityNetworkInfo(Connectivity()))
      ..registerSingleton<Dio>(Dio(), instanceName: DiTokens.retryDio)
      // Options (base URL, timeouts, headers) are applied by DioApiClient.
      ..registerSingleton<Dio>(Dio());

    getIt.registerLazySingleton<ApiClient>(
      () => DioApiClient(dio: getIt<Dio>(), config: config),
    );

    // ------------------------------------------------------------ supabase --
    if (isSupabaseReady) {
      getIt
        ..registerLazySingleton<SupabaseAuthDataSource>(
          () => SupabaseAuthDataSourceImpl(SupabaseInitializer.client),
        )
        ..registerLazySingleton<SupabaseDatabaseService>(
          () => SupabaseDatabaseService(SupabaseInitializer.client),
        )
        ..registerLazySingleton<AuthRepository>(
          () => SupabaseAuthRepository(
            dataSource: getIt<SupabaseAuthDataSource>(),
            tokenStorage: getIt<TokenStorage>(),
            analytics: getIt<AnalyticsService>(),
            logger: logger,
          ),
        );
    } else {
      getIt.registerLazySingleton<AuthRepository>(
        () => UnavailableAuthRepository(logger),
      );
    }

    // --------------------------------------------------------- repositories --
    getIt
      ..registerLazySingleton<OnboardingRepository>(
        () => OnboardingRepositoryImpl(getIt<KeyValueStore>()),
      )
      ..registerLazySingleton<ArticleApiService>(
        () => ArticleApiService(getIt<ApiClient>()),
      )
      ..registerLazySingleton<ArticleRepository>(
        () => ArticleRepositoryImpl(
          service: getIt<ArticleApiService>(),
          cache: getIt<CacheManager>(),
          logger: logger,
        ),
      );

    // ------------------------------------------------------------ features --
    getIt
      ..registerLazySingleton<PermissionService>(
        () => PermissionServiceImpl(logger),
      )
      ..registerLazySingleton<PaymentService>(
        () => StripePaymentService(
          apiClient: getIt<ApiClient>(),
          config: config,
          analytics: getIt<AnalyticsService>(),
          logger: logger,
        ),
      )
      ..registerLazySingleton<PushNotificationService>(
        () => DefaultPushNotificationService(
          apiClient: getIt<ApiClient>(),
          store: getIt<KeyValueStore>(),
          analytics: getIt<AnalyticsService>(),
          logger: logger,
        ),
      )
      ..registerLazySingleton<NotificationRouter>(
        () => NotificationRouter(
          service: getIt<PushNotificationService>(),
          logger: logger,
        ),
      );

    // Interceptors are attached last: AuthInterceptor needs TokenStorage and
    // AuthRepository, both of which are registered above.
    _attachInterceptors(logger);
  }

  /// Order matters and is deliberate:
  /// 1. connectivity — fail fast offline, before anything else runs.
  /// 2. auth — attach the token, refresh on 401.
  /// 3. retry — back off on transient failures (after auth, so a retry carries
  ///    a refreshed token).
  /// 4. logging — outermost, so it observes the final outcome.
  static void _attachInterceptors(AppLogger logger) {
    final dio = getIt<Dio>();
    final authRepository = getIt<AuthRepository>();

    dio.interceptors.addAll([
      ConnectivityInterceptor(getIt<NetworkInfo>()),
      AuthInterceptor(
        tokenStorage: getIt<TokenStorage>(),
        retryClient: getIt<Dio>(instanceName: DiTokens.retryDio),
        onRefreshRequested: () async {
          final result = await authRepository.refreshSession();
          return result.isSuccess;
        },
        onSessionExpired: () async {
          await authRepository.signOut();
        },
      ),
      RetryInterceptor(dio: dio, logger: logger),
      LoggingInterceptor(logger: logger),
    ]);
  }

  /// Tears the graph down. Used by tests and by "restart app" flows.
  static Future<void> reset() async {
    final disposables = <Disposable>[
      if (getIt.isRegistered<NetworkInfo>()) getIt<NetworkInfo>(),
      if (getIt.isRegistered<PushNotificationService>())
        getIt<PushNotificationService>(),
    ];
    for (final disposable in disposables) {
      await disposable.dispose();
    }
    await getIt.reset();
  }
}
