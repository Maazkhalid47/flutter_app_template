import '../api/api_client.dart';
import '../api/api_response.dart';
import '../api/cancellation_token.dart';
import '../constants/api_constants.dart';
import '../core/typedefs.dart';
import '../enums/http_method.dart';

/// EXAMPLE SERVICE — one endpoint group, no business rules.
///
/// A service knows *how to call* an API: paths, query parameters, the shape of
/// the payload. It does not decide what to do with failures, does not cache and
/// does not decode into models — those are the repository's decisions.
///
/// Copy this file's structure for each endpoint group you add.
class ArticleApiService {
  const ArticleApiService(this._client);

  final ApiClient _client;

  Future<ApiResponse<JsonList>> fetchArticles({
    required int page,
    required int pageSize,
    String? search,
    CancellationToken? cancellationToken,
  }) => _client.requestJsonList(
    HttpMethod.get,
    ApiConstants.articles,
    query: {
      ApiConstants.pageQuery: page,
      ApiConstants.limitQuery: pageSize,
      if (search != null && search.isNotEmpty) ApiConstants.searchQuery: search,
    },
    cancellationToken: cancellationToken,
  );

  Future<ApiResponse<Json>> fetchArticle(
    String id, {
    CancellationToken? cancellationToken,
  }) => _client.requestJson(
    HttpMethod.get,
    ApiConstants.articleById(id),
    cancellationToken: cancellationToken,
  );

  Future<ApiResponse<Json>> createArticle(Json payload) => _client.requestJson(
    HttpMethod.post,
    ApiConstants.articles,
    body: payload,
  );

  Future<ApiResponse<Json>> updateArticle(String id, Json payload) => _client
      .requestJson(HttpMethod.put, ApiConstants.articleById(id), body: payload);

  Future<ApiResponse<Json>> deleteArticle(String id) =>
      _client.requestJson(HttpMethod.delete, ApiConstants.articleById(id));
}
