/// A minimal key/value persistence contract.
///
/// Two implementations exist and they are not interchangeable:
/// * `PreferencesStore` — fast, plaintext, for app state (theme, locale, flags).
/// * `SecureStore` — Keychain/Keystore backed, for credentials only.
///
/// Everything is async so a future migration to a different backend
/// (Hive, Isar, sqflite) does not change a single call site.
abstract interface class KeyValueStore {
  Future<String?> readString(String key);

  Future<void> writeString(String key, String value);

  Future<bool?> readBool(String key);

  Future<void> writeBool(String key, {required bool value});

  Future<int?> readInt(String key);

  Future<void> writeInt(String key, int value);

  Future<void> delete(String key);

  Future<bool> containsKey(String key);

  /// Wipes everything this store owns. Used on sign-out and on "reset app".
  Future<void> clear();
}
