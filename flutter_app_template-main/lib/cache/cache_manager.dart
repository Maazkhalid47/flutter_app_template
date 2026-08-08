import '../constants/app_constants.dart';
import '../constants/storage_keys.dart';
import '../core/typedefs.dart';
import '../storage/preferences_store.dart';
import '../utils/logger.dart';
import 'cache_entry.dart';

/// Read-through cache for network responses.
///
/// Two tiers on purpose: an in-memory map that survives navigation within a
/// session (instant, no disk I/O), and a disk tier that survives restarts and
/// makes the app usable offline.
///
/// The cache is deliberately dumb about types — it stores decoded JSON, and the
/// repository re-parses it into models. That keeps serialization knowledge in
/// the model layer where it belongs.
class CacheManager {
  CacheManager({required PreferencesStore store, required AppLogger logger})
    : _store = store,
      _logger = logger;

  final PreferencesStore _store;
  final AppLogger _logger;
  final Map<String, CacheEntry> _memory = {};

  String _storageKey(String key) => '${StorageKeys.cachePrefix}$key';

  /// Reads an entry. Returns `null` when missing, and when expired unless
  /// [allowExpired] is set.
  ///
  /// [allowExpired] is the offline story: the repository first asks for fresh
  /// data, and if the network fails it asks again with `allowExpired: true`
  /// rather than showing an empty screen.
  Future<CacheEntry?> read(String key, {bool allowExpired = false}) async {
    final entry = _memory[key] ?? await _readFromDisk(key);
    if (entry == null) return null;
    if (entry.isExpired && !allowExpired) return null;
    return entry;
  }

  /// Convenience read for a JSON object.
  Future<Json?> readJson(String key, {bool allowExpired = false}) async {
    final value = (await read(key, allowExpired: allowExpired))?.value;
    return value is Map<Object?, Object?>
        ? Map<String, dynamic>.from(value)
        : null;
  }

  /// Convenience read for a JSON array.
  Future<JsonList?> readJsonList(
    String key, {
    bool allowExpired = false,
  }) async {
    final value = (await read(key, allowExpired: allowExpired))?.value;
    if (value is! List) return null;
    return value
        .whereType<Map<Object?, Object?>>()
        .map<Json>(Map<String, dynamic>.from)
        .toList();
  }

  /// Stores [value] under [key]. Cache writes are best-effort: a failure here
  /// is logged, never propagated, because a caching problem must not fail an
  /// otherwise successful request.
  Future<void> write(
    String key,
    Object? value, {
    Duration ttl = AppConstants.defaultCacheTtl,
  }) async {
    final entry = CacheEntry(value: value, storedAt: DateTime.now(), ttl: ttl);
    _memory[key] = entry;
    try {
      await _store.writeString(_storageKey(key), entry.encode());
    } catch (error) {
      _logger.warning('Cache write failed for $key', data: {'error': '$error'});
    }
  }

  Future<void> invalidate(String key) async {
    _memory.remove(key);
    await _store.delete(_storageKey(key));
  }

  /// Drops every entry whose key starts with [prefix].
  ///
  /// Use it after a mutation: writing an article invalidates `articles:` so the
  /// list refetches, without needing to know every page key.
  Future<void> invalidatePrefix(String prefix) async {
    _memory.removeWhere((key, _) => key.startsWith(prefix));
    final storagePrefix = _storageKey(prefix);
    for (final key in _store.keys.where((k) => k.startsWith(storagePrefix))) {
      await _store.delete(key);
    }
  }

  /// Clears everything. Call on sign-out — cached data belongs to a user.
  Future<void> clear() async {
    _memory.clear();
    for (final key
        in _store.keys
            .where((k) => k.startsWith(StorageKeys.cachePrefix))
            .toList()) {
      await _store.delete(key);
    }
  }

  /// Removes expired entries from disk. Cheap to run at startup so the cache
  /// does not grow without bound.
  Future<void> evictExpired() async {
    for (final storageKey
        in _store.keys
            .where((k) => k.startsWith(StorageKeys.cachePrefix))
            .toList()) {
      final raw = await _store.readString(storageKey);
      final entry = raw == null ? null : CacheEntry.tryDecode(raw);
      if (entry == null || entry.isExpired) {
        await _store.delete(storageKey);
      }
    }
  }

  Future<CacheEntry?> _readFromDisk(String key) async {
    final raw = await _store.readString(_storageKey(key));
    if (raw == null) return null;
    final entry = CacheEntry.tryDecode(raw);
    if (entry == null) {
      _logger.warning('Discarding corrupt cache entry: $key');
      await _store.delete(_storageKey(key));
      return null;
    }
    _memory[key] = entry;
    return entry;
  }
}
