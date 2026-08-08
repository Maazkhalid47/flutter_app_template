/// Keys for every persisted value.
///
/// Centralised so a key is never duplicated with a typo, and so a future
/// migration can see the full surface of what the app stores. The prefix tells
/// you which store owns the key.
abstract final class StorageKeys {
  // --- Secure storage (encrypted; credentials only) ---
  static const String accessToken = 'secure.access_token';
  static const String refreshToken = 'secure.refresh_token';
  static const String tokenExpiry = 'secure.token_expiry';

  // --- Shared preferences (non-sensitive app state) ---
  static const String onboardingSeen = 'prefs.onboarding_seen';
  static const String themeMode = 'prefs.theme_mode';
  static const String localeCode = 'prefs.locale_code';
  static const String lastSyncedAt = 'prefs.last_synced_at';
  static const String pushToken = 'prefs.push_token';
  static const String pushPermissionAsked = 'prefs.push_permission_asked';

  // --- Cache namespace prefix ---
  static const String cachePrefix = 'cache.';
}
