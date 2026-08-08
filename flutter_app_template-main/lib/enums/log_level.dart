/// Severity levels used by `utils/logger.dart`.
///
/// Ordered by [severity] so the logger can filter everything below the
/// configured minimum level for the current environment.
enum LogLevel {
  debug(0, 'DEBUG'),
  info(1, 'INFO'),
  warning(2, 'WARN'),
  error(3, 'ERROR'),
  fatal(4, 'FATAL');

  const LogLevel(this.severity, this.label);

  final int severity;
  final String label;
}
