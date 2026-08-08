/// Normalized error shape surfaced by [ApiClient] so UI/viewmodel code never
/// has to branch on Dio-specific error types.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException({required this.message, this.statusCode, this.data});

  factory ApiException.network() =>
      const ApiException(message: 'No internet connection. Please check your network.');

  factory ApiException.timeout() =>
      const ApiException(message: 'The request timed out. Please try again.');

  factory ApiException.cancelled() =>
      const ApiException(message: 'The request was cancelled.');

  factory ApiException.unauthorized() =>
      const ApiException(message: 'Your session has expired. Please sign in again.', statusCode: 401);

  factory ApiException.unknown([String? message]) =>
      ApiException(message: message ?? 'Something went wrong. Please try again.');

  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message)';
}
