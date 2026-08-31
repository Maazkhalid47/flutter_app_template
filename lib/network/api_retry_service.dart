import 'dart:async';
import 'dart:io';

import '../exception/api_exception.dart';
import '../utils/app_logger.dart';

/// Retries [apiCall] when it fails with a temporary error, waiting longer
/// between each attempt (1s, then 2s, then 4s, ...).
///
/// This is opt-in: nothing is retried automatically anywhere else in the
/// app. Wrap a call with this only where you actually want retries:
///
/// ```dart
/// final data = await retryApiCall(() => getUsers());
/// ```
///
/// - [maxRetries]: how many extra attempts to make after the first try
///   (default 3).
/// - [initialDelay]: how long to wait before the first retry; each later
///   retry waits twice as long as the one before it (default 1 second).
/// - [isRetryable]: decides which errors are worth retrying. Defaults to
///   [_isTemporaryError] (network errors, timeouts, 408/429/5xx). Pass your
///   own to customize this, e.g. for a non-HTTP call like Supabase.
Future<T> retryApiCall<T>(
  Future<T> Function() apiCall, {
  int maxRetries = 3,
  Duration initialDelay = const Duration(seconds: 1),
  bool Function(Object error)? isRetryable,
}) async {
  var attempt = 0;

  while (true) {
    try {
      // Just try the call. If it works, we're done.
      return await apiCall();
    } catch (error) {
      final canRetry = (isRetryable ?? _isTemporaryError)(error);

      // Out of retries, or this error isn't worth retrying: give up.
      if (attempt >= maxRetries || !canRetry) rethrow;

      final delay = initialDelay * (1 << attempt); // 1x, 2x, 4x, ...
      AppLogger.d(
        'Call failed: ${error.runtimeType}. '
        'Retry attempt: ${attempt + 1}/$maxRetries. '
        'Waiting: ${delay.inMilliseconds}ms',
      );
      attempt++;
      await Future.delayed(delay);
    }
  }
}

/// Default rule for "is this worth retrying?": temporary network/server
/// problems are, normal client errors (400, 401, 403, 404, 422, ...) aren't.
bool _isTemporaryError(Object error) {
  if (error is ApiException) {
    // A dropped connection or a timed-out request never reached the
    // server (or never got a response back) - safe to try again.
    if (error.isTransient) return true;

    // Otherwise only retry server errors (5xx), request timeout (408), and
    // rate limiting (429). Everything else is a normal client error and
    // will just fail the same way again.
    final status = error.statusCode;
    return status != null && (status == 408 || status == 429 || status >= 500);
  }

  // Fallback for calls that don't go through ApiClient/ApiException
  // (e.g. a raw Supabase call) - see lib/supabase/supabase_retry.dart.
  if (error is TimeoutException) return true;
  if (error is SocketException) return true;

  return false;
}
