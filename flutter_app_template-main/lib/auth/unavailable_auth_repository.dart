import 'dart:async';

import '../core/result.dart';
import '../core/typedefs.dart';
import '../enums/auth_status.dart';
import '../exceptions/app_exception.dart';
import '../models/app_user.dart';
import '../utils/logger.dart';
import 'auth_repository.dart';
import 'auth_session.dart';

/// The [AuthRepository] used when no auth backend is configured.
///
/// Why it exists: a developer who clones the repo and runs it without Supabase
/// credentials should get a working app with a clear message on the login
/// screen — not a null-pointer crash on the first frame. Every method fails
/// with the same explicit [AuthException] rather than pretending to work.
///
/// The Null Object pattern, doing real work: it keeps the "not configured"
/// branch out of every caller.
class UnavailableAuthRepository implements AuthRepository {
  UnavailableAuthRepository(this._logger) {
    _logger.warning(
      'Auth is unavailable: Supabase is not configured for this build.',
    );
  }

  final AppLogger _logger;

  static const AuthException _unavailable = AuthException(
    message:
        'Authentication is not configured for this build. '
        'Set SUPABASE_URL and SUPABASE_ANON_KEY.',
  );

  @override
  Stream<AuthStatus> get authStatusChanges =>
      Stream<AuthStatus>.value(AuthStatus.unauthenticated);

  @override
  AuthStatus get currentStatus => AuthStatus.unauthenticated;

  @override
  AppUser? get currentUser => null;

  /// Succeeds with no session: "there is nobody signed in" is the truth here,
  /// and it lets the router settle on the login screen instead of hanging.
  @override
  AsyncResult<AuthSession?> restoreSession() async =>
      const Result<AuthSession?>.success(null);

  @override
  AsyncResult<AuthSession> signInWithEmail({
    required String email,
    required String password,
  }) async => const Result.failure(_unavailable);

  @override
  AsyncResult<AuthSession> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async => const Result.failure(_unavailable);

  @override
  AsyncResult<void> sendPasswordReset(String email) async =>
      const Result.failure(_unavailable);

  @override
  AsyncResult<AuthSession> refreshSession() async =>
      const Result.failure(_unavailable);

  /// Signing out with nobody signed in is a no-op, not a failure.
  @override
  AsyncResult<void> signOut() async => const Result.success(null);

  @override
  AsyncResult<AppUser> updateProfile({
    String? displayName,
    String? avatarUrl,
  }) async => const Result.failure(_unavailable);

  @override
  AsyncResult<void> deleteAccount() async => const Result.failure(_unavailable);
}
