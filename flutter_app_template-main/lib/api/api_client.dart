import '../core/typedefs.dart';
import '../enums/http_method.dart';
import 'api_response.dart';
import 'cancellation_token.dart';

/// The contract every HTTP call in the app goes through.
///
/// Nothing above this interface knows which package performs the request.
/// Services depend on [ApiClient]; only `dio_api_client.dart` imports Dio.
/// A fake implementation of this interface is all a test needs.
///
/// Implementations throw on failure (a `DioException`, a socket error).
/// Repositories catch and convert via `ExceptionMapper` — that boundary is
/// where throwing stops and `Result` begins.
abstract interface class ApiClient {
  /// Single JSON object response.
  Future<ApiResponse<Json>> requestJson(
    HttpMethod method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    Map<String, String>? headers,
    CancellationToken? cancellationToken,
  });

  /// JSON array response.
  Future<ApiResponse<JsonList>> requestJsonList(
    HttpMethod method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    Map<String, String>? headers,
    CancellationToken? cancellationToken,
  });

  /// Raw bytes — file downloads, images, PDFs.
  Future<ApiResponse<List<int>>> requestBytes(
    HttpMethod method,
    String path, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    CancellationToken? cancellationToken,
  });

  /// Multipart upload. [files] maps a field name to a local file path.
  Future<ApiResponse<Json>> upload(
    String path, {
    required Map<String, String> files,
    Map<String, dynamic>? fields,
    void Function(int sent, int total)? onProgress,
    CancellationToken? cancellationToken,
  });

  /// Sets the language sent as `Accept-Language`. Called when the user changes
  /// locale so server-rendered errors arrive translated.
  void setLanguage(String languageCode);
}
