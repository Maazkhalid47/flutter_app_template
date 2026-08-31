import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../cache/secure_storage_service.dart';
import '../exception/api_exception.dart';
import 'token_refresh_interceptor.dart';

/// Dio-based HTTP client for the custom backend (kept separate from
/// Supabase's own client). Attaches the stored access token, transparently
/// retries a single 401 after a token refresh (see
/// [TokenRefreshInterceptor]), and normalizes every failure into
/// [ApiException] so callers never touch [DioException] directly.
///
/// Nothing is retried on transient failures automatically. Wrap a call with
/// `retryApiCall(() => ApiClient.instance.get(...))` (see
/// lib/network/api_retry_service.dart) where you explicitly want that.
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: dotenv.env['API_BASE_URL'] ?? '',
        connectTimeout: Duration(
          milliseconds: int.tryParse(dotenv.env['API_TIMEOUT_MS'] ?? '') ?? 15000,
        ),
        receiveTimeout: Duration(
          milliseconds: int.tryParse(dotenv.env['API_TIMEOUT_MS'] ?? '') ?? 15000,
        ),
      ),
    );

    _dio.interceptors.addAll([
      InterceptorsWrapper(onRequest: _onRequest),
      TokenRefreshInterceptor(_dio),
      if (const bool.fromEnvironment('dart.vm.product') == false)
        // requestHeader is off so a debug console never prints the
        // Authorization bearer token.
        PrettyDioLogger(requestHeader: false, requestBody: true, responseBody: true),
    ]);
  }

  static final ApiClient instance = ApiClient._internal();

  late final Dio _dio;

  Future<void> _onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: ApiException.network(),
        ),
      );
    }

    final token = await SecureStorageService.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  ApiException _mapError(DioException error) {
    if (error.error is ApiException) return error.error as ApiException;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException.timeout();
      case DioExceptionType.cancel:
        return ApiException.cancelled();
      case DioExceptionType.connectionError:
        return ApiException.network();
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        if (status == 401) return ApiException.unauthorized();
        return ApiException(
          message: error.response?.data is Map
              ? (error.response?.data['message']?.toString() ?? 'Request failed')
              : 'Request failed',
          statusCode: status,
          data: error.response?.data,
        );
      case DioExceptionType.unknown:
      case DioExceptionType.badCertificate:
      default:
        return ApiException.unknown(error.message);
    }
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) =>
      _guard(() => _dio.get<T>(path, queryParameters: query, cancelToken: cancelToken));

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    CancelToken? cancelToken,
  }) =>
      _guard(() => _dio.post<T>(path, data: data, cancelToken: cancelToken));

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    CancelToken? cancelToken,
  }) =>
      _guard(() => _dio.put<T>(path, data: data, cancelToken: cancelToken));

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    CancelToken? cancelToken,
  }) =>
      _guard(() => _dio.patch<T>(path, data: data, cancelToken: cancelToken));

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    CancelToken? cancelToken,
  }) =>
      _guard(() => _dio.delete<T>(path, data: data, cancelToken: cancelToken));

  Future<Response<T>> _guard<T>(Future<Response<T>> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }
}