import 'package:dio/dio.dart';

import '../../constants/api_constants.dart';
import '../../utils/logger.dart';

/// Logs requests, responses and errors with timings.
///
/// Uses [AppLogger] (which redacts credentials) rather than Dio's built-in
/// `LogInterceptor`, which prints authorization headers verbatim — fine in
/// debug, a credential leak in any build that ships.
class LoggingInterceptor extends Interceptor {
  LoggingInterceptor({
    required AppLogger logger,
    this.logRequestBody = true,
    this.logResponseBody = false,
  }) : _logger = logger;

  final AppLogger _logger;

  /// Response bodies are off by default: they are large, and the interesting
  /// part is almost always the status code plus the timing.
  final bool logRequestBody;
  final bool logResponseBody;

  static const String _startKey = 'request_start_ms';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startKey] = DateTime.now().millisecondsSinceEpoch;
    _logger.debug(
      '--> ${options.method} ${options.uri}',
      data: {
        if (options.queryParameters.isNotEmpty)
          'query': options.queryParameters,
        if (logRequestBody && options.data != null) 'body': options.data,
        'headers': options.headers,
      },
    );
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _logger.debug(
      '<-- ${response.statusCode} ${response.requestOptions.method} '
      '${response.requestOptions.uri} (${_elapsedMs(response.requestOptions)}ms)',
      data: {
        if (logResponseBody) 'body': response.data,
        'requestId':
            response.requestOptions.headers[ApiConstants.requestIdHeader],
      },
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.warning(
      'xxx ${err.response?.statusCode ?? err.type.name} '
      '${err.requestOptions.method} ${err.requestOptions.uri} '
      '(${_elapsedMs(err.requestOptions)}ms)',
      data: {
        'message': err.message,
        'body': err.response?.data,
        'requestId': err.requestOptions.headers[ApiConstants.requestIdHeader],
      },
    );
    handler.next(err);
  }

  int _elapsedMs(RequestOptions options) {
    final start = options.extra[_startKey];
    if (start is! int) return -1;
    return DateTime.now().millisecondsSinceEpoch - start;
  }
}
