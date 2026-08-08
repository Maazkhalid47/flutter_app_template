import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../exceptions/app_exception.dart';
import 'key_value_store.dart';

/// [KeyValueStore] backed by the platform keychain / keystore.
///
/// Use for access tokens, refresh tokens and nothing else — every read is a
/// platform channel call, so it is far slower than preferences.
///
/// A note on the web: `flutter_secure_storage` falls back to encrypted local
/// storage there, which is weaker than a native keychain. If you ship web with
/// real credentials, prefer httpOnly cookies issued by your backend.
class SecureStore implements KeyValueStore {
  const SecureStore(this._storage);

  final FlutterSecureStorage _storage;

  /// `first_unlock` accessibility is deliberate: it allows a background token
  /// refresh to read the keychain before the user has unlocked the device,
  /// while still keeping the value off a locked, powered-down phone.
  ///
  /// Android needs no options here — v11 of the plugin uses the encrypted
  /// backend by default.
  static const SecureStore defaults = SecureStore(
    FlutterSecureStorage(
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    ),
  );

  @override
  Future<String?> readString(String key) =>
      _guard(() => _storage.read(key: key));

  @override
  Future<void> writeString(String key, String value) =>
      _guard(() => _storage.write(key: key, value: value));

  @override
  Future<bool?> readBool(String key) async {
    final value = await readString(key);
    return value == null ? null : value == 'true';
  }

  @override
  Future<void> writeBool(String key, {required bool value}) =>
      writeString(key, value.toString());

  @override
  Future<int?> readInt(String key) async {
    final value = await readString(key);
    return value == null ? null : int.tryParse(value);
  }

  @override
  Future<void> writeInt(String key, int value) =>
      writeString(key, value.toString());

  @override
  Future<void> delete(String key) => _guard(() => _storage.delete(key: key));

  @override
  Future<bool> containsKey(String key) =>
      _guard(() => _storage.containsKey(key: key));

  @override
  Future<void> clear() => _guard(_storage.deleteAll);

  /// Keychain access genuinely fails sometimes — a locked device, a corrupted
  /// keystore after an OS upgrade. Converting to [StorageException] here means
  /// callers get one error type instead of a raw `PlatformException`.
  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      throw StorageException(
        message: 'Secure storage operation failed.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }
}
