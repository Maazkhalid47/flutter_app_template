import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/analytics_service.dart';
import '../utils/logger.dart';
import 'app_exception.dart';
import 'exception_mapper.dart';

/// Installs the app-wide crash handlers.
///
/// Three escape hatches exist in Flutter and all three must be covered, or a
/// production crash will vanish silently:
/// * [FlutterError.onError] — errors thrown inside the widget/render pipeline.
/// * [PlatformDispatcher.instance.onError] — uncaught async errors.
/// * The [runZonedGuarded] zone in `main.dart` — everything else.
class GlobalErrorHandler {
  const GlobalErrorHandler({
    required AppLogger logger,
    required AnalyticsService analytics,
  }) : _logger = logger,
       _analytics = analytics;

  final AppLogger _logger;
  final AnalyticsService _analytics;

  /// Wires up the framework-level handlers. Call once, before `runApp`.
  void install() {
    FlutterError.onError = (details) {
      _logger.error(
        'Flutter framework error',
        error: details.exception,
        stackTrace: details.stack,
      );
      unawaited(
        _analytics.recordError(
          details.exception,
          details.stack,
          context: details.library,
          fatal: false,
        ),
      );
      if (kDebugMode) FlutterError.presentError(details);
    };

    PlatformDispatcher.instance.onError = (error, stackTrace) {
      handle(error, stackTrace, context: 'PlatformDispatcher');
      return true;
    };
  }

  /// Reports an error from anywhere in the app and returns the mapped
  /// [AppException] so callers can decide what to show.
  AppException handle(
    Object error,
    StackTrace? stackTrace, {
    String? context,
    bool fatal = false,
  }) {
    final exception = ExceptionMapper.map(error, stackTrace);

    // Cancellations are normal control flow, not failures worth reporting.
    if (exception is CancelledException) {
      _logger.debug('Cancelled: ${exception.message}');
      return exception;
    }

    _logger.error(
      context == null ? exception.message : '$context: ${exception.message}',
      error: exception.cause ?? exception,
      stackTrace: stackTrace ?? exception.stackTrace,
    );

    unawaited(
      _analytics.recordError(
        exception,
        stackTrace ?? exception.stackTrace,
        context: context,
        fatal: fatal,
      ),
    );

    return exception;
  }
}
