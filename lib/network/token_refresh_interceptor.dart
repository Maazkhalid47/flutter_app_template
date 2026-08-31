import 'package:dio/dio.dart';

import '../cache/secure_storage_service.dart';
import '../utils/app_logger.dart';
import 'api_endpoints.dart';

/// Handles 401s the way the rest of the app's error handling expects:
/// refresh the access token once and retry the original request, instead of
/// surfacing an [ApiException.unauthorized] the caller has to work around.
///
/// - 401/403 are never blindly retried (a stale token won't become valid by
///   trying again) — this interceptor is the *only* place a 401 gets a
///   second attempt, and it does so at most once per original request via
///   [_authRetriedKey], so `401 -> refresh -> 401 -> refresh -> ...` can't
///   happen.
/// - Concurrent 401s from multiple in-flight requests share a single
///   refresh call ([_refreshing]) instead of each firing their own.
/// - Token accessors are injected (defaulting to [SecureStorageService]) so
///   this can be unit tested without the secure-storage platform channel.
class TokenRefreshInterceptor extends Interceptor {
  TokenRefreshInterceptor(
    this._dio, {
    Future<String?> Function() getRefreshToken = SecureStorageService.getRefreshToken,
    Future<String?> Function() getAccessToken = SecureStorageService.getAccessToken,
    Future<void> Function(String) saveAccessToken = SecureStorageService.saveAccessToken,
    Future<void> Function(String) saveRefreshToken = SecureStorageService.saveRefreshToken,
    Future<void> Function() clearTokens = SecureStorageService.clearTokens,
  })  : _getRefreshToken = getRefreshToken,
        _getAccessToken = getAccessToken,
        _saveAccessToken = saveAccessToken,
        _saveRefreshToken = saveRefreshToken,
        _clearTokens = clearTokens;

  static const _authRetriedKey = 'x_auth_retried';

  final Dio _dio;
  final Future<String?> Function() _getRefreshToken;
  final Future<String?> Function() _getAccessToken;
  final Future<void> Function(String) _saveAccessToken;
  final Future<void> Function(String) _saveRefreshToken;
  final Future<void> Function() _clearTokens;

  Future<bool>? _refreshing;

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final isUnauthorized = err.response?.statusCode == 401;
    final alreadyRetried = options.extra[_authRetriedKey] == true;
    final isRefreshCall = options.path == ApiEndpoints.refreshToken;

    if (!isUnauthorized || alreadyRetried || isRefreshCall) {
      return handler.next(err);
    }

    final refreshed = await _refreshTokenOnce();
    if (!refreshed) {
      await _clearTokens();
      return handler.next(err);
    }

    options.extra[_authRetriedKey] = true;
    final token = await _getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    try {
      AppLogger.d('Retrying request after token refresh: ${options.method} ${options.path}');
      final response = await _dio.fetch(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _clearTokens();
      }
      return handler.next(e);
    }
  }

  Future<bool> _refreshTokenOnce() {
    return _refreshing ??= _performRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _performRefresh() async {
    final refreshToken = await _getRefreshToken();
    if (refreshToken == null) return false;

    try {
      AppLogger.d('Access token expired, refreshing...');
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.refreshToken,
        data: {'refresh_token': refreshToken},
      );

      final data = response.data;
      final newAccessToken = data?['access_token']?.toString();
      final newRefreshToken = data?['refresh_token']?.toString();
      if (newAccessToken == null) return false;

      await _saveAccessToken(newAccessToken);
      if (newRefreshToken != null) {
        await _saveRefreshToken(newRefreshToken);
      }
      AppLogger.d('Token refresh succeeded');
      return true;
    } catch (_) {
      AppLogger.w('Token refresh failed');
      return false;
    }
  }
}
