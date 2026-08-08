/// The root of every error the app raises across a layer boundary.
///
/// Rules:
/// * Services and data sources may throw anything (Dio, Supabase, platform).
/// * Repositories catch that and convert it into an [AppException] subtype
///   via `exceptions/exception_mapper.dart`, wrapped in a `Result`.
/// * View models and views only ever see [AppException].
///
/// [message] is a developer-facing description. Never show it to users —
/// resolve [messageKey] through localization instead.
sealed class AppException implements Exception {
  const AppException({
    required this.message,
    required this.messageKey,
    this.code,
    this.cause,
    this.stackTrace,
  });

  /// Developer-facing description. Goes to logs and crash reporting.
  final String message;

  /// Stable key the UI resolves through `AppLocalizations` to get user copy.
  /// See `exceptions/error_message_key.dart`.
  final String messageKey;

  /// Optional machine-readable code (HTTP status, Supabase/Stripe error code).
  final String? code;

  /// The original error this wraps, kept for diagnostics.
  final Object? cause;

  final StackTrace? stackTrace;

  /// Whether retrying the same operation could plausibly succeed.
  /// Drives whether the error UI shows a "Retry" button.
  bool get isRetryable => false;

  @override
  String toString() {
    final buffer = StringBuffer('$runtimeType: $message');
    if (code != null) buffer.write(' (code: $code)');
    if (cause != null) buffer.write(' <- $cause');
    return buffer.toString();
  }
}

/// A failure with no better classification. Always log the [cause].
final class UnknownException extends AppException {
  const UnknownException({
    super.message = 'An unexpected error occurred.',
    super.messageKey = 'errorGeneric',
    super.code,
    super.cause,
    super.stackTrace,
  });
}

/// The caller supplied invalid input. Not retryable without changing the input.
final class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.messageKey = 'errorGeneric',
    this.fieldErrors = const {},
    super.code,
    super.cause,
    super.stackTrace,
  });

  /// Field name to error message, for inline form errors.
  final Map<String, String> fieldErrors;
}

/// The device is offline or a request could not reach the server.
final class NetworkException extends AppException {
  const NetworkException({
    super.message = 'No internet connection.',
    super.messageKey = 'errorNetwork',
    super.code,
    super.cause,
    super.stackTrace,
  });

  @override
  bool get isRetryable => true;
}

/// The request exceeded its timeout budget.
final class TimeoutException extends AppException {
  const TimeoutException({
    super.message = 'The request timed out.',
    super.messageKey = 'errorTimeout',
    super.code,
    super.cause,
    super.stackTrace,
  });

  @override
  bool get isRetryable => true;
}

/// The server answered with 5xx.
final class ServerException extends AppException {
  const ServerException({
    super.message = 'The server failed to handle the request.',
    super.messageKey = 'errorServer',
    super.code,
    super.cause,
    super.stackTrace,
  });

  @override
  bool get isRetryable => true;
}

/// 401/403 — the session is missing, expired or insufficient.
///
/// The auth interceptor watches for this and triggers a refresh or sign-out.
final class UnauthorizedException extends AppException {
  const UnauthorizedException({
    super.message = 'Not authorized.',
    super.messageKey = 'errorUnauthorized',
    super.code,
    super.cause,
    super.stackTrace,
  });
}

/// 404 — the requested resource does not exist.
final class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'Resource not found.',
    super.messageKey = 'errorNotFound',
    super.code,
    super.cause,
    super.stackTrace,
  });
}

/// The request was cancelled deliberately (screen disposed, search superseded).
/// Views should ignore this rather than showing an error.
final class CancelledException extends AppException {
  const CancelledException({
    super.message = 'The request was cancelled.',
    super.messageKey = 'errorGeneric',
    super.code,
    super.cause,
    super.stackTrace,
  });
}

/// Sign-in, sign-up or session restoration failed.
final class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.messageKey = 'errorGeneric',
    super.code,
    super.cause,
    super.stackTrace,
  });
}

/// Reading from or writing to local storage / cache failed.
final class StorageException extends AppException {
  const StorageException({
    required super.message,
    super.messageKey = 'errorGeneric',
    super.code,
    super.cause,
    super.stackTrace,
  });
}

/// A payment could not be created, confirmed or captured.
final class PaymentException extends AppException {
  const PaymentException({
    required super.message,
    super.messageKey = 'errorGeneric',
    super.code,
    super.cause,
    super.stackTrace,
  });
}

/// A response body could not be parsed into the expected model.
/// Almost always a contract mismatch between app and backend — log loudly.
final class ParsingException extends AppException {
  const ParsingException({
    required super.message,
    super.messageKey = 'errorGeneric',
    super.code,
    super.cause,
    super.stackTrace,
  });
}

/// The user denied (or permanently denied) a required OS permission.
final class PermissionException extends AppException {
  const PermissionException({
    required super.message,
    super.messageKey = 'errorGeneric',
    this.isPermanentlyDenied = false,
    super.code,
    super.cause,
    super.stackTrace,
  });

  /// When true, the only path forward is the system settings screen.
  final bool isPermanentlyDenied;
}
