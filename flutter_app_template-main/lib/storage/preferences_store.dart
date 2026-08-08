import 'package:shared_preferences/shared_preferences.dart';

import 'key_value_store.dart';

/// [KeyValueStore] backed by `SharedPreferences`.
///
/// For non-sensitive state only — the data is plaintext and readable on a
/// rooted device. Tokens go to `SecureStore`.
///
/// The [SharedPreferences] instance is injected rather than resolved lazily so
/// the first read cannot block a frame and tests can pass a mock.
class PreferencesStore implements KeyValueStore {
  const PreferencesStore(this._prefs);

  final SharedPreferences _prefs;

  /// Loads the instance once, during bootstrap.
  static Future<PreferencesStore> create() async =>
      PreferencesStore(await SharedPreferences.getInstance());

  @override
  Future<String?> readString(String key) async => _prefs.getString(key);

  @override
  Future<void> writeString(String key, String value) =>
      _prefs.setString(key, value);

  @override
  Future<bool?> readBool(String key) async => _prefs.getBool(key);

  @override
  Future<void> writeBool(String key, {required bool value}) =>
      _prefs.setBool(key, value);

  @override
  Future<int?> readInt(String key) async => _prefs.getInt(key);

  @override
  Future<void> writeInt(String key, int value) => _prefs.setInt(key, value);

  @override
  Future<void> delete(String key) => _prefs.remove(key);

  @override
  Future<bool> containsKey(String key) async => _prefs.containsKey(key);

  @override
  Future<void> clear() => _prefs.clear();

  /// Every key currently stored. Used by the cache layer to sweep entries by
  /// prefix.
  Set<String> get keys => _prefs.getKeys();
}
