import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../constants/api_constants.dart';
import '../core/typedefs.dart';
import '../enums/http_method.dart';
import '../exceptions/app_exception.dart';
import 'api_client.dart';
import 'api_response.dart';
import 'cancellation_token.dart';

/// The Dio-backed [ApiClient]. The only file in the app that imports Dio's
/// request API for making calls (interceptors aside).
///
/// It does not add interceptors itself — the service locator composes them, so
/// the ordering (connectivity → auth → retry → logging) is visible in one place
/// and a test can build this client with none of them.
class DioApiClient implements ApiClient {
  DioApiClient({required Dio dio, required AppConfig config})
    : _dio = dio,
      _config = config {
    _dio.options = _dio.options.copyWith(
      baseUrl: _config.apiBaseUrl,
      connectTimeout: _config.apiTimeout,
      receiveTimeout: _config.apiTimeout,
      sendTimeout: _config.apiTimeout,
      headers: {
        ApiConstants.acceptHeader: ApiConstants.jsonContentType,
        ApiConstants.contentTypeHeader: ApiConstants.jsonContentType,
        ..._dio.options.headers,
      },
      // Never let Dio throw on a status we want to inspect; the mapper decides.
      validateStatus: (status) => status != null && status < 400,
    );
  }

  final Dio _dio;
  final AppConfig _config;

  @override
  void setLanguage(String languageCode) {
    _dio.options.headers[ApiConstants.acceptLanguageHeader] = languageCode;
  }

  @override
  Future<ApiResponse<Json>> requestJson(
    HttpMethod method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    Map<String, String>? headers,
    CancellationToken? cancellationToken,
  }) async {
    final response = await _send<dynamic>(
      method,
      path,
      query: query,
      body: body,
      headers: headers,
      cancellationToken: cancellationToken,
    );
    return _wrap(response, _asJson(response.data, path));
  }

  @override
  Future<ApiResponse<JsonList>> requestJsonList(
    HttpMethod method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    Map<String, String>? headers,
    CancellationToken? cancellationToken,
  }) async {
    final response = await _send<dynamic>(
      method,
      path,
      query: query,
      body: body,
      headers: headers,
      cancellationToken: cancellationToken,
    );
    final data = response.data;
    if (data is! List) {
      throw ParsingException(
        message:
            'Expected a JSON array from $path but got ${data.runtimeType}.',
      );
    }
    return _wrap(
      response,
      data.map((dynamic item) => _asJson(item, path)).toList(),
    );
  }

  @override
  Future<ApiResponse<List<int>>> requestBytes(
    HttpMethod method,
    String path, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    CancellationToken? cancellationToken,
  }) async {
    final response = await _dio.request<List<int>>(
      path,
      queryParameters: query,
      cancelToken: _bridge(cancellationToken),
      options: Options(
        method: method.value,
        headers: headers,
        responseType: ResponseType.bytes,
      ),
    );
    return _wrap(response, response.data ?? const <int>[]);
  }

  @override
  Future<ApiResponse<Json>> upload(
    String path, {
    required Map<String, String> files,
    Map<String, dynamic>? fields,
    void Function(int sent, int total)? onProgress,
    CancellationToken? cancellationToken,
  }) async {
    final formData = FormData.fromMap({
      ...?fields,
      for (final entry in files.entries)
        entry.key: await MultipartFile.fromFile(entry.value),
    });

    final response = await _dio.post<dynamic>(
      path,
      data: formData,
      onSendProgress: onProgress,
      cancelToken: _bridge(cancellationToken),
      // Let Dio set the multipart boundary; forcing JSON here breaks the upload.
      options: Options(contentType: null),
    );
    return _wrap(response, _asJson(response.data, path));
  }

  Future<Response<T>> _send<T>(
    HttpMethod method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    Map<String, String>? headers,
    CancellationToken? cancellationToken,
  }) => _dio.request<T>(
    path,
    data: body,
    queryParameters: query,
    cancelToken: _bridge(cancellationToken),
    options: Options(method: method.value, headers: headers),
  );

  /// Connects the app-level token to Dio's, so callers never see [CancelToken].
  CancelToken? _bridge(CancellationToken? token) {
    if (token == null) return null;
    final dioToken = CancelToken();
    if (token.isCancelled) {
      dioToken.cancel();
      return dioToken;
    }
    token.onCancelled.then(dioToken.cancel);
    return dioToken;
  }

  Json _asJson(Object? data, String path) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    // 204 No Content and empty bodies are legitimate successes.
    if (data == null || (data is String && data.isEmpty)) return const {};
    throw ParsingException(
      message: 'Expected a JSON object from $path but got ${data.runtimeType}.',
    );
  }

  ApiResponse<T> _wrap<T>(Response<dynamic> response, T data) => ApiResponse<T>(
    data: data,
    statusCode: response.statusCode ?? 0,
    headers: response.headers.map,
  );
}
