/// Normalized error shape surfaced by [ApiClient] so UI/viewmodel code never
/// has to branch on Dio-specific error types.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  /// True when the request never got a response from the server (dropped
  /// connection, timeout) and so is safe to retry. False for everything
  /// else, including a cancelled request. Used by [retryApiCall] to decide
  /// whether a status-code-less failure is worth retrying.
  final bool isTransient;

  const ApiException({
    required this.message,
    this.statusCode,
    this.data,
    this.isTransient = false,
  });

  factory ApiException.network() => const ApiException(
        message: 'No internet connection. Please check your network.',
        isTransient: true,
      );

  factory ApiException.timeout() => const ApiException(
        message: 'The request timed out. Please try again.',
        isTransient: true,
      );

  factory ApiException.cancelled() =>
      const ApiException(message: 'The request was cancelled.');

  factory ApiException.unauthorized() =>
      const ApiException(message: 'Your session has expired. Please sign in again.', statusCode: 401);

  factory ApiException.unknown([String? message]) =>
      ApiException(message: message ?? 'Something went wrong. Please try again.');

  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message)';
}
