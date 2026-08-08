import 'package:dio/dio.dart';

import '../../constants/app_constants.dart';
import '../../utils/logger.dart';

/// Retries transient failures with exponential backoff.
///
/// Only idempotent verbs are retried. Replaying a POST can charge a card twice
/// or create two records — if a POST needs retrying, it needs an idempotency
/// key and an explicit decision, not a blanket rule.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required Dio dio,
    required AppLogger logger,
    this.maxRetries = AppConstants.maxRequestRetries,
    this.baseDelay = const Duration(milliseconds: 400),
  }) : _dio = dio,
       _logger = logger;

  final Dio _dio;
  final AppLogger _logger;
  final int maxRetries;
  final Duration baseDelay;

  static const String _attemptKey = 'retry_attempt';
  static const Set<String> _idempotentMethods = {
    'GET',
    'HEAD',
    'PUT',
    'DELETE',
  };

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final attempt = (err.requestOptions.extra[_attemptKey] as int?) ?? 0;

    if (!_shouldRetry(err) || attempt >= maxRetries) {
      handler.next(err);
      return;
    }

    final delay = baseDelay * (1 << attempt);
    _logger.debug(
      'Retrying ${err.requestOptions.method} ${err.requestOptions.path} '
      'in ${delay.inMilliseconds}ms (attempt ${attempt + 1}/$maxRetries)',
    );
    await Future<void>.delayed(delay);

    try {
      final response = await _dio.fetch<dynamic>(
        err.requestOptions..extra[_attemptKey] = attempt + 1,
      );
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  bool _shouldRetry(DioException err) {
    if (!_idempotentMethods.contains(err.requestOptions.method.toUpperCase())) {
      return false;
    }
    final status = err.response?.statusCode;
    return switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.connectionError => true,
      // 5xx and 429 are worth another attempt; 4xx will fail identically.
      DioExceptionType.badResponse =>
        status != null && (status >= 500 || status == 429),
      _ => false,
    };
  }
}
