# storage/

## Why it exists

Persistence behind one interface, with a hard separation between data that is
merely private and data that is secret.

## Two stores, and they are not interchangeable

| | `PreferencesStore` | `SecureStore` |
| --- | --- | --- |
| Backend | SharedPreferences | Keychain / Keystore |
| Encrypted | No | Yes |
| Speed | Fast (in-memory after load) | Slow (platform channel per call) |
| Use for | Theme, locale, flags, cache | Access and refresh tokens |

Putting a token in preferences is a real vulnerability on a rooted device.
Putting the theme mode in the keychain is a performance bug. Neither is
theoretical.

## What belongs here

| File | Purpose |
| --- | --- |
| `key_value_store.dart` | The shared interface |
| `preferences_store.dart` | SharedPreferences implementation |
| `secure_store.dart` | Encrypted implementation, errors mapped to `StorageException` |

## Naming conventions

- Every key is declared in `constants/storage_keys.dart`, prefixed by its
  store: `secure.`, `prefs.`, `cache.`.
- Methods are typed: `readString`, `writeBool(key, value: true)`.

## Example usage

```dart
await _store.writeBool(StorageKeys.onboardingSeen, value: true);
final seen = await _store.readBool(StorageKeys.onboardingSeen) ?? false;
```

## Best practices

- Never invent a key inline. One typo is one silently lost setting.
- Never repurpose a key: old installs still hold the old value. Add a new key.
- Read once at startup and keep the value in a provider; do not hit disk in
  `build`.
- `SecureTokenStorage` caches the access token in memory because the auth
  interceptor reads it on every request.
- On web, `flutter_secure_storage` degrades to encrypted local storage. If you
  ship web with real credentials, prefer httpOnly cookies from your backend.
- Clear both stores on sign-out — see `AuthRepository.signOut` and
  `CacheManager.clear`.
