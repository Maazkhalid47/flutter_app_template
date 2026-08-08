import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/typedefs.dart';

/// Generic table access for Supabase (Postgrest).
///
/// Repositories call this instead of touching `SupabaseClient` directly, so the
/// query API stays in one file and can be faked in tests. Like the auth data
/// source, it throws on failure — the repository maps to `Result`.
///
/// Note: it returns raw [Json], not models. Decoding is the repository's job,
/// because only the repository knows which model a table maps to.
class SupabaseDatabaseService {
  const SupabaseDatabaseService(this._client);

  final SupabaseClient _client;

  /// Selects rows with optional equality filters, ordering and pagination.
  ///
  /// [filters] uses `column: value` equality — anything more complex should get
  /// its own named method here rather than a query-builder leaking upward.
  Future<JsonList> select(
    String table, {
    String columns = '*',
    Json filters = const {},
    String? orderBy,
    bool ascending = false,
    int? limit,
    int? offset,
  }) async {
    var query = _client.from(table).select(columns);

    for (final entry in filters.entries) {
      query = query.eq(entry.key, entry.value as Object);
    }

    final ordered = orderBy == null
        ? query
        : query.order(orderBy, ascending: ascending);

    final ranged = (limit != null)
        ? ordered.range(offset ?? 0, (offset ?? 0) + limit - 1)
        : ordered;

    final rows = await ranged;
    return rows.map<Json>(Map<String, dynamic>.from).toList();
  }

  /// Fetches a single row by primary key, or `null` when it does not exist.
  Future<Json?> findById(
    String table,
    Object id, {
    String idColumn = 'id',
    String columns = '*',
  }) async {
    final row = await _client
        .from(table)
        .select(columns)
        .eq(idColumn, id)
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  Future<Json> insert(String table, Json values) async {
    final row = await _client.from(table).insert(values).select().single();
    return Map<String, dynamic>.from(row);
  }

  Future<Json> update(
    String table,
    Object id,
    Json values, {
    String idColumn = 'id',
  }) async {
    final row = await _client
        .from(table)
        .update(values)
        .eq(idColumn, id)
        .select()
        .single();
    return Map<String, dynamic>.from(row);
  }

  /// Insert-or-update. Requires a unique constraint on the conflict target.
  Future<Json> upsert(String table, Json values, {String? onConflict}) async {
    final row = await _client
        .from(table)
        .upsert(values, onConflict: onConflict)
        .select()
        .single();
    return Map<String, dynamic>.from(row);
  }

  Future<void> delete(String table, Object id, {String idColumn = 'id'}) =>
      _client.from(table).delete().eq(idColumn, id);

  /// Live rows over a websocket. Remember to cancel the subscription —
  /// `SubscriptionMixin` in a view model does this for you.
  Stream<JsonList> watch(
    String table, {
    required List<String> primaryKey,
    String? orderBy,
  }) {
    final stream = _client.from(table).stream(primaryKey: primaryKey);
    final ordered = orderBy == null ? stream : stream.order(orderBy);
    return ordered.map(
      (rows) => rows.map<Json>(Map<String, dynamic>.from).toList(),
    );
  }

  /// Calls a Postgres function (RPC). The right place for logic that must run
  /// server-side, such as anything a client must not be trusted to compute.
  Future<dynamic> callFunction(String name, {Json? params}) =>
      _client.rpc<dynamic>(name, params: params);
}
