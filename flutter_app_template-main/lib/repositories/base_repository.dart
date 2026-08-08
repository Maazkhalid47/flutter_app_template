import '../cache/cache_manager.dart';
import '../core/result.dart';
import '../exceptions/app_exception.dart';
import '../exceptions/exception_mapper.dart';
import '../utils/logger.dart';

/// Shared machinery for every repository.
///
/// Two things live here because otherwise they get re-implemented — slightly
/// differently — in each repository:
///
/// * [guard] — the single try/catch that converts thrown errors into `Result`.
///   This is the boundary where exceptions stop propagating upward.
/// * [cachedFetch] — the read-through cache + offline fallback policy.
///
/// Repositories extend this class; they never catch exceptions themselves.
abstract class BaseRepository {
  const BaseRepository({required AppLogger logger, CacheManager? cache})
    : _logger = logger,
      _cache = cache;

  final AppLogger _logger;
  final CacheManager? _cache;

  AppLogger get logger => _logger;

  /// Runs [operation], converting any error into a typed [Result].
  Future<Result<T>> guard<T>(
    Future<T> Function() operation, {
    String? context,
  }) async {
    try {
      return Result<T>.success(await operation());
    } catch (error, stackTrace) {
      final exception = ExceptionMapper.map(error, stackTrace);
      // Cancellations are expected control flow, not something to warn about.
      if (exception is! CancelledException) {
        _logger.warning(
          '${context ?? runtimeType.toString()} failed: ${exception.message}',
        );
      }
      return Result<T>.failure(exception);
    }
  }

  /// Cache-then-network with an offline fallback.
  ///
  /// Order of preference:
  /// 1. A fresh cache entry (no request at all).
  /// 2. The network, whose result is cached.
  /// 3. A *stale* cache entry, if the network failed — this is what makes the
  ///    app usable on a train. Only used for retryable failures; a 404 should
  ///    not resurrect deleted data.
  ///
  /// [decode] converts the cached/fetched JSON-compatible payload into [T],
  /// and [encode] turns a fresh value into something JSON-serializable.
  Future<Result<T>> cachedFetch<T>({
    required String cacheKey,
    required Future<T> Function() fetch,
    required T Function(Object? cached) decode,
    required Object? Function(T value) encode,
    Duration? ttl,
    bool forceRefresh = false,
  }) async {
    final cache = _cache;

    if (cache != null && !forceRefresh) {
      final entry = await cache.read(cacheKey);
      if (entry != null) {
        try {
          return Result<T>.success(decode(entry.value));
        } catch (error) {
          _logger.warning('Cache decode failed for $cacheKey; refetching.');
          await cache.invalidate(cacheKey);
        }
      }
    }

    final result = await guard(fetch, context: cacheKey);

    return result.when<Future<Result<T>>>(
      success: (value) async {
        if (cache != null) {
          await cache.write(cacheKey, encode(value), ttl: ttl ?? _defaultTtl);
        }
        return Result<T>.success(value);
      },
      failure: (exception) async {
        if (cache == null || !exception.isRetryable) {
          return Result<T>.failure(exception);
        }
        final stale = await cache.read(cacheKey, allowExpired: true);
        if (stale == null) return Result<T>.failure(exception);
        try {
          _logger.info('Serving stale cache for $cacheKey after failure.');
          return Result<T>.success(decode(stale.value));
        } catch (_) {
          return Result<T>.failure(exception);
        }
      },
    );
  }

  Duration get _defaultTtl => const Duration(minutes: 5);

  /// Drops every cache entry under [prefix]. Call after a mutation.
  Future<void> invalidateCache(String prefix) async =>
      _cache?.invalidatePrefix(prefix);
}
