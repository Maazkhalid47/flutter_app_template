import 'dart:convert';

import '../core/typedefs.dart';

/// A cached value plus the metadata needed to decide whether it is still good.
///
/// Stored as JSON so any [KeyValueStore] can hold it without knowing the
/// payload type.
class CacheEntry {
  const CacheEntry({
    required this.value,
    required this.storedAt,
    required this.ttl,
  });

  factory CacheEntry.fromJson(Json json) => CacheEntry(
    value: json['value'],
    storedAt: DateTime.fromMillisecondsSinceEpoch(json['storedAt'] as int),
    ttl: Duration(milliseconds: json['ttlMs'] as int),
  );

  /// Decodes a raw stored string. Returns `null` on any corruption rather than
  /// throwing — a bad cache entry must never break the app, only miss.
  static CacheEntry? tryDecode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return CacheEntry.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  /// The decoded payload: a `Json`, a `List`, or a primitive.
  final Object? value;
  final DateTime storedAt;
  final Duration ttl;

  DateTime get expiresAt => storedAt.add(ttl);

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get isFresh => !isExpired;

  /// How stale the entry is. Useful for a "last updated 5m ago" label when
  /// serving expired data offline.
  Duration get age => DateTime.now().difference(storedAt);

  Json toJson() => {
    'value': value,
    'storedAt': storedAt.millisecondsSinceEpoch,
    'ttlMs': ttl.inMilliseconds,
  };

  String encode() => jsonEncode(toJson());
}
