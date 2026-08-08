import '../utils/logger.dart';

/// Product analytics and crash reporting, behind one interface.
///
/// The app is analytics-ready without being tied to a vendor: swap
/// [NoopAnalyticsService] for a Firebase/Amplitude/PostHog implementation in the
/// service locator and nothing else changes.
///
/// Event names are defined in [AnalyticsEvent] rather than passed as free
/// strings, because typo'd event names produce dashboards that quietly lie.
abstract interface class AnalyticsService {
  Future<void> initialize();

  /// Logs a product event. Never include PII in [parameters].
  Future<void> logEvent(String name, {Map<String, Object?> parameters});

  /// Logs a screen view. Called from a router observer, not from each screen.
  Future<void> logScreenView(String screenName);

  /// Associates subsequent events with a user. Pass `null` on sign-out.
  Future<void> setUserId(String? userId);

  /// Sets a user property (plan tier, locale, cohort).
  Future<void> setUserProperty(String name, String? value);

  /// Reports a handled or unhandled error to crash reporting.
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? context,
    bool fatal = false,
  });
}

/// Canonical event names. Add to this list instead of inlining strings.
abstract final class AnalyticsEvent {
  static const String appOpened = 'app_opened';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String signUpCompleted = 'sign_up_completed';
  static const String signInCompleted = 'sign_in_completed';
  static const String signOut = 'sign_out';
  static const String paymentStarted = 'payment_started';
  static const String paymentSucceeded = 'payment_succeeded';
  static const String paymentFailed = 'payment_failed';
  static const String notificationOpened = 'notification_opened';
}

/// The default implementation: logs locally, sends nothing.
///
/// Registered in dev so no analytics noise is generated during development, and
/// used as the fallback when analytics are disabled by configuration.
class NoopAnalyticsService implements AnalyticsService {
  const NoopAnalyticsService(this._logger);

  final AppLogger _logger;

  @override
  Future<void> initialize() async =>
      _logger.debug('Analytics disabled (NoopAnalyticsService).');

  @override
  Future<void> logEvent(
    String name, {
    Map<String, Object?> parameters = const {},
  }) async => _logger.debug('analytics.event: $name', data: parameters);

  @override
  Future<void> logScreenView(String screenName) async =>
      _logger.debug('analytics.screen: $screenName');

  @override
  Future<void> setUserId(String? userId) async =>
      _logger.debug('analytics.userId: ${userId ?? 'cleared'}');

  @override
  Future<void> setUserProperty(String name, String? value) async =>
      _logger.debug('analytics.property: $name');

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? context,
    bool fatal = false,
  }) async =>
      _logger.debug('analytics.error${fatal ? ' (fatal)' : ''}: $error');
}
