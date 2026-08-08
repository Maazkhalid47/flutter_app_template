import '../constants/storage_keys.dart';
import '../storage/key_value_store.dart';
import 'auth_session.dart';

/// Persists credentials, and nothing else.
///
/// A narrow interface on purpose: the auth interceptor needs to read a token
/// but has no business touching the rest of storage.
abstract interface class TokenStorage {
  Future<String?> readAccessToken();

  Future<String?> readRefreshToken();

  Future<DateTime?> readExpiry();

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    DateTime? expiresAt,
  });

  /// Removes every stored credential. Must be called on sign-out and whenever
  /// a refresh fails.
  Future<void> clear();
}

/// [TokenStorage] on top of the encrypted [KeyValueStore].
///
/// Caches the access token in memory: the interceptor reads it on every single
/// request, and a keychain round-trip per request is measurable.
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage(this._store);

  final KeyValueStore _store;
  String? _cachedAccessToken;

  @override
  Future<String?> readAccessToken() async =>
      _cachedAccessToken ??= await _store.readString(StorageKeys.accessToken);

  @override
  Future<String?> readRefreshToken() =>
      _store.readString(StorageKeys.refreshToken);

  @override
  Future<DateTime?> readExpiry() async {
    final millis = await _store.readInt(StorageKeys.tokenExpiry);
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    DateTime? expiresAt,
  }) async {
    _cachedAccessToken = accessToken;
    await _store.writeString(StorageKeys.accessToken, accessToken);
    if (refreshToken != null) {
      await _store.writeString(StorageKeys.refreshToken, refreshToken);
    }
    if (expiresAt != null) {
      await _store.writeInt(
        StorageKeys.tokenExpiry,
        expiresAt.millisecondsSinceEpoch,
      );
    }
  }

  /// Convenience wrapper used by the auth repository after a successful
  /// sign-in or refresh.
  Future<void> saveSession(AuthSession session) => saveTokens(
    accessToken: session.accessToken,
    refreshToken: session.refreshToken,
    expiresAt: session.expiresAt,
  );

  @override
  Future<void> clear() async {
    _cachedAccessToken = null;
    await _store.delete(StorageKeys.accessToken);
    await _store.delete(StorageKeys.refreshToken);
    await _store.delete(StorageKeys.tokenExpiry);
  }
}
