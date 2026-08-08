import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps [FlutterSecureStorage] for the handful of values the app must not
/// keep in plain prefs (auth tokens, refresh tokens).
class SecureStorageService {
  SecureStorageService._();

  static const _storage = FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  static Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  static Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  static Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  static Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  static Future<void> clearTokens() => Future.wait([
        _storage.delete(key: _accessTokenKey),
        _storage.delete(key: _refreshTokenKey),
      ]);
}
