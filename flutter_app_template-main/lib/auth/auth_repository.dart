import '../core/result.dart';
import '../core/typedefs.dart';
import '../enums/auth_status.dart';
import '../models/app_user.dart';
import 'auth_session.dart';

/// Everything the app can do with authentication.
///
/// View models depend on this interface, never on Supabase. That is what lets
/// you replace the backend, or run the whole auth flow against a fake in tests,
/// without editing a screen.
///
/// Every method returns [Result] — the caller is forced to handle failure.
abstract interface class AuthRepository {
  /// Emits on sign-in, sign-out, token refresh and session restoration.
  /// The router listens to this to redirect.
  Stream<AuthStatus> get authStatusChanges;

  /// The current status, available synchronously for the initial route.
  AuthStatus get currentStatus;

  /// The signed-in user, or `null`.
  AppUser? get currentUser;

  /// Restores a persisted session at startup. Returns `null` when there is no
  /// valid session — that is a normal outcome, not a failure.
  AsyncResult<AuthSession?> restoreSession();

  AsyncResult<AuthSession> signInWithEmail({
    required String email,
    required String password,
  });

  AsyncResult<AuthSession> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  });

  /// Sends a password-reset email. Succeeds even for unknown addresses so the
  /// endpoint cannot be used to enumerate accounts.
  AsyncResult<void> sendPasswordReset(String email);

  /// Exchanges the refresh token for a new access token.
  AsyncResult<AuthSession> refreshSession();

  /// Signs out locally and remotely, and clears stored credentials.
  AsyncResult<void> signOut();

  AsyncResult<AppUser> updateProfile({String? displayName, String? avatarUrl});

  /// Permanently deletes the account. Requires a privileged backend endpoint —
  /// see `docs/integrations/supabase.md`.
  AsyncResult<void> deleteAccount();
}
