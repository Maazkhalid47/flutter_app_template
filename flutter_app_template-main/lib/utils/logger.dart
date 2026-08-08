import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../enums/log_level.dart';

/// Structured application logger.
///
/// Why not `print`: `print` is stripped inconsistently, has no severity, no
/// tagging, and happily leaks tokens into release logs. This logger filters by
/// [minimumLevel], redacts known-sensitive keys, and gives crash reporting a
/// single hook to attach to.
///
/// Resolve it from the service locator; do not construct it in widgets.
class AppLogger {
  AppLogger({
    required LogLevel minimumLevel,
    String name = 'app',
    List<LogSink> sinks = const [],
  }) : _minimumLevel = minimumLevel,
       _name = name,
       _sinks = sinks;

  final LogLevel _minimumLevel;
  final String _name;
  final List<LogSink> _sinks;

  /// Values whose contents must never reach a log line.
  static const Set<String> _redactedKeys = {
    'password',
    'token',
    'access_token',
    'refresh_token',
    'authorization',
    'apikey',
    'api_key',
    'secret',
    'client_secret',
    'card',
    'cvc',
  };

  void debug(String message, {Object? data}) =>
      _log(LogLevel.debug, message, data: data);

  void info(String message, {Object? data}) =>
      _log(LogLevel.info, message, data: data);

  void warning(String message, {Object? data}) =>
      _log(LogLevel.warning, message, data: data);

  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.error, message, error: error, stackTrace: stackTrace);

  void fatal(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.fatal, message, error: error, stackTrace: stackTrace);

  void _log(
    LogLevel level,
    String message, {
    Object? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.severity < _minimumLevel.severity) return;

    final payload = data == null ? '' : ' ${redact(data)}';
    final line = '[${level.label}] $message$payload';

    // `developer.log` keeps severity and stack traces intact in DevTools and is
    // not stripped in profile mode, unlike print.
    developer.log(
      line,
      name: _name,
      level: _developerLevel(level),
      error: error,
      stackTrace: stackTrace,
    );

    for (final sink in _sinks) {
      sink.write(
        LogRecord(
          level: level,
          message: message,
          data: data,
          error: error,
          stackTrace: stackTrace,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Replaces sensitive values with `***` before anything is written.
  /// Recurses into maps and lists so nested payloads are covered too.
  @visibleForTesting
  static Object? redact(Object? value) {
    if (value is Map) {
      return value.map(
        (key, dynamic item) => MapEntry(
          key,
          _redactedKeys.contains(key.toString().toLowerCase())
              ? '***'
              : redact(item),
        ),
      );
    }
    if (value is List) return value.map<Object?>(redact).toList();
    return value;
  }

  static int _developerLevel(LogLevel level) => switch (level) {
    LogLevel.debug => 500,
    LogLevel.info => 800,
    LogLevel.warning => 900,
    LogLevel.error => 1000,
    LogLevel.fatal => 1200,
  };
}

/// A single log entry handed to every [LogSink].
class LogRecord {
  const LogRecord({
    required this.level,
    required this.message,
    required this.timestamp,
    this.data,
    this.error,
    this.stackTrace,
  });

  final LogLevel level;
  final String message;
  final DateTime timestamp;
  final Object? data;
  final Object? error;
  final StackTrace? stackTrace;
}

/// A destination for log records — console, file, Sentry, Crashlytics.
///
/// Implement this to forward production logs somewhere durable, then register
/// the sink when building [AppLogger] in the service locator.
abstract interface class LogSink {
  void write(LogRecord record);
}
