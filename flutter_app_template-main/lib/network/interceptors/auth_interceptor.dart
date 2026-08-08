import 'dart:async';

import 'package:dio/dio.dart';

import '../../auth/token_storage.dart';
import '../../constants/api_constants.dart';

/// Attaches the access token to every request and recovers from a 401 once.
///
/// The single-flight [_refreshOperation] matters: when a screen fires five
/// requests and the token has expired, all five get a 401 at the same moment.
/// Without deduplication that is five refresh calls, and four of them invalidate
/// the token the fifth just obtained.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required TokenStorage tokenStorage,
    required Future<bool> Function() onRefreshRequested,
    required Future<void> Function() onSessionExpired,
    Dio? retryClient,
  }) : _tokenStorage = tokenStorage,
       _onRefreshRequested = onRefreshRequested,
       _onSessionExpired = onSessionExpired,
       _retryClient = retryClient;

  final TokenStorage _tokenStorage;
  final Future<bool> Function() _onRefreshRequested;
  final Future<void> Function() _onSessionExpired;
  final Dio? _retryClient;

  Future<bool>? _refreshOperation;

  /// Paths that must never carry a token (and must never trigger a refresh
  /// loop when they fail).
  static const Set<String> _publicPaths = {
    '/auth/login',
    '/auth/signup',
    '/auth/refresh',
  };

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_publicPaths.contains(options.path)) {
      final token = await _tokenStorage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers[ApiConstants.authorizationHeader] =
            '${ApiConstants.bearerPrefix}$token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isAuthFailure = err.response?.statusCode == 401;
    final isRetry = err.requestOptions.extra[_retriedFlag] == true;
    final isPublic = _publicPaths.contains(err.requestOptions.path);

    if (!isAuthFailure || isRetry || isPublic) {
      handler.next(err);
      return;
    }

    final refreshed = await (_refreshOperation ??= _runRefresh());

    if (!refreshed) {
      await _onSessionExpired();
      handler.next(err);
      return;
    }

    try {
      final response = await _replay(err.requestOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<bool> _runRefresh() async {
    try {
      return await _onRefreshRequested();
    } catch (_) {
      return false;
    } finally {
      // Clear immediately so the next 401 after this point starts a fresh
      // attempt instead of reusing a stale completed future.
      _refreshOperation = null;
    }
  }

  Future<Response<dynamic>> _replay(RequestOptions options) async {
    final token = await _tokenStorage.readAccessToken();
    final client = _retryClient ?? Dio(BaseOptions(baseUrl: options.baseUrl));
    return client.fetch<dynamic>(
      options.copyWith(
        headers: {
          ...options.headers,
          if (token != null)
            ApiConstants.authorizationHeader:
                '${ApiConstants.bearerPrefix}$token',
        },
        extra: {...options.extra, _retriedFlag: true},
      ),
    );
  }

  static const String _retriedFlag = 'auth_retry_attempted';
}
