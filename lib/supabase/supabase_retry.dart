import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../network/api_retry_service.dart';

/// HTTP-style status codes that can show up as [PostgrestException.code]
/// when PostgREST returns an error body without its own Postgres error code
/// (postgrest-dart falls back to the HTTP status there). Anything else in
/// `code` is a Postgres/PostgREST error code, not a transient failure, so
/// it's deliberately left out.
const _retryablePostgrestCodes = {'408', '429', '500', '502', '503', '504'};

/// True for failures from a Supabase call that are safe to retry blindly:
/// gotrue's own transient-network signal, a bare timeout, or a PostgREST
/// error that's really an HTTP 408/429/5xx underneath. Everything else —
/// including [AuthException] (bad credentials, expired/invalid session,
/// RLS/permission failures all surface through gotrue's own exception
/// types) and other [PostgrestException] codes — is left alone: those are
/// not transient, and retrying them (especially on INSERT/UPDATE) risks
/// creating duplicate rows.
bool isRetryableSupabaseError(Object error) {
  if (error is AuthRetryableFetchException) return true;
  if (error is TimeoutException) return true;
  if (error is PostgrestException) return _retryablePostgrestCodes.contains(error.code);
  return false;
}

/// Retry wrapper for Supabase calls — a thin [retryApiCall] preset that
/// knows which Supabase errors are safe to retry.
///
/// Only wrap read-only or genuinely idempotent operations (a `select`, an
/// `upsert` keyed on a stable conflict column, a retryable RPC). Do not wrap
/// a plain `insert` or a one-shot RPC that creates a row/side effect (order,
/// booking, proposal, payment record, ...) unless the table/RPC is known to
/// be idempotent — a retried insert after a dropped response can create a
/// duplicate row.
Future<T> retrySupabaseCall<T>(Future<T> Function() action) {
  return retryApiCall(action, isRetryable: isRetryableSupabaseError);
}
