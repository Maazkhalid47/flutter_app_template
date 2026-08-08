import '../api/cancellation_token.dart';
import '../constants/app_constants.dart';
import '../core/typedefs.dart';
import '../models/article.dart';
import '../models/paginated_result.dart';
import '../services/article_api_service.dart';
import 'base_repository.dart';

/// EXAMPLE REPOSITORY — the contract a view model depends on.
///
/// Note what the interface exposes: domain types (`Article`,
/// `PaginatedResult`) and nothing about HTTP, JSON, caching or Supabase. That
/// is the whole point of the layer.
abstract interface class ArticleRepository {
  AsyncResult<PaginatedResult<Article>> fetchArticles({
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
    String? search,
    bool forceRefresh = false,
    CancellationToken? cancellationToken,
  });

  AsyncResult<Article> fetchArticle(String id, {bool forceRefresh = false});

  AsyncResult<Article> createArticle({
    required String title,
    required String body,
  });

  AsyncResult<void> deleteArticle(String id);
}

class ArticleRepositoryImpl extends BaseRepository
    implements ArticleRepository {
  const ArticleRepositoryImpl({
    required ArticleApiService service,
    required super.logger,
    super.cache,
  }) : _service = service;

  final ArticleApiService _service;

  /// Namespaced so a mutation can invalidate every article entry at once.
  static const String _cacheNamespace = 'articles';

  @override
  AsyncResult<PaginatedResult<Article>> fetchArticles({
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
    String? search,
    bool forceRefresh = false,
    CancellationToken? cancellationToken,
  }) => cachedFetch<PaginatedResult<Article>>(
    cacheKey: '$_cacheNamespace:list:$page:$pageSize:${search ?? ''}',
    // Searches are volatile and rarely revisited — skip the cache for them.
    forceRefresh: forceRefresh || (search != null && search.isNotEmpty),
    ttl: AppConstants.defaultCacheTtl,
    fetch: () async {
      final response = await _service.fetchArticles(
        page: page,
        pageSize: pageSize,
        search: search,
        cancellationToken: cancellationToken,
      );
      return PaginatedResult<Article>(
        items: response.data.map(Article.fromJson).toList(),
        page: page,
        pageSize: pageSize,
        totalCount: response.totalCount,
      );
    },
    decode: (cached) => PaginatedResult<Article>(
      items: (cached! as List)
          .map(
            (dynamic item) =>
                Article.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      page: page,
      pageSize: pageSize,
    ),
    encode: (value) => value.items.map((item) => item.toJson()).toList(),
  );

  @override
  AsyncResult<Article> fetchArticle(String id, {bool forceRefresh = false}) =>
      cachedFetch<Article>(
        cacheKey: '$_cacheNamespace:detail:$id',
        forceRefresh: forceRefresh,
        fetch: () async {
          final response = await _service.fetchArticle(id);
          return Article.fromJson(response.data);
        },
        decode: (cached) =>
            Article.fromJson(Map<String, dynamic>.from(cached! as Map)),
        encode: (value) => value.toJson(),
      );

  @override
  AsyncResult<Article> createArticle({
    required String title,
    required String body,
  }) => guard(() async {
    final response = await _service.createArticle({
      'title': title,
      'body': body,
    });
    // The list is now stale in every cached page.
    await invalidateCache(_cacheNamespace);
    return Article.fromJson(response.data);
  }, context: 'createArticle');

  @override
  AsyncResult<void> deleteArticle(String id) => guard(() async {
    await _service.deleteArticle(id);
    await invalidateCache(_cacheNamespace);
  }, context: 'deleteArticle');
}
