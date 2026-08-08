import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../auth/auth_session.dart';
import '../models/app_user.dart';

/// Thin adapter over Supabase's auth client.
///
/// Its whole job is translation: Supabase types in, app types out. It performs
/// no error handling and no caching — the repository above owns both. Keeping
/// this layer dumb is what makes the repository testable with a fake data
/// source that has no SDK behind it.
abstract interface class SupabaseAuthDataSource {
  Stream<sb.AuthState> get onAuthStateChange;

  AuthSession? get currentSession;

  Future<AuthSession> signInWithPassword(String email, String password);

  Future<AuthSession> signUp(
    String email,
    String password,
    String? displayName,
  );

  Future<AuthSession> refresh();

  Future<void> resetPassword(String email);

  Future<void> signOut();

  Future<AppUser> updateUser({String? displayName, String? avatarUrl});
}

class SupabaseAuthDataSourceImpl implements SupabaseAuthDataSource {
  const SupabaseAuthDataSourceImpl(this._client);

  final sb.SupabaseClient _client;

  sb.GoTrueClient get _auth => _client.auth;

  @override
  Stream<sb.AuthState> get onAuthStateChange => _auth.onAuthStateChange;

  @override
  AuthSession? get currentSession => _toSession(_auth.currentSession);

  @override
  Future<AuthSession> signInWithPassword(String email, String password) async {
    final response = await _auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    return _requireSession(response.session);
  }

  @override
  Future<AuthSession> signUp(
    String email,
    String password,
    String? displayName,
  ) async {
    final response = await _auth.signUp(
      email: email.trim(),
      password: password,
      data: displayName == null ? null : {'display_name': displayName},
    );
    // With email confirmation enabled, Supabase returns a user but no session.
    // Surfacing that as a clear error beats a silent "signed in" state.
    final session = response.session;
    if (session == null) {
      throw const sb.AuthException(
        'Account created. Confirm your email address to sign in.',
      );
    }
    return _requireSession(session);
  }

  @override
  Future<AuthSession> refresh() async {
    final response = await _auth.refreshSession();
    return _requireSession(response.session);
  }

  @override
  Future<void> resetPassword(String email) =>
      _auth.resetPasswordForEmail(email.trim());

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<AppUser> updateUser({String? displayName, String? avatarUrl}) async {
    final response = await _auth.updateUser(
      sb.UserAttributes(
        data: {'display_name': ?displayName, 'avatar_url': ?avatarUrl},
      ),
    );
    final user = response.user;
    if (user == null) {
      throw const sb.AuthException('Profile update returned no user.');
    }
    return _toUser(user);
  }

  AuthSession _requireSession(sb.Session? session) {
    final mapped = _toSession(session);
    if (mapped == null) {
      throw const sb.AuthException('Authentication returned no session.');
    }
    return mapped;
  }

  AuthSession? _toSession(sb.Session? session) {
    if (session == null) return null;
    final expiresAt = session.expiresAt;
    return AuthSession(
      user: _toUser(session.user),
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      expiresAt: expiresAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000),
    );
  }

  /// Supabase keeps custom fields in `userMetadata`; the app's own shape hides
  /// that detail from every caller.
  AppUser _toUser(sb.User user) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      displayName:
          metadata['display_name'] as String? ??
          metadata['full_name'] as String?,
      avatarUrl: metadata['avatar_url'] as String?,
      phone: user.phone,
      emailVerified: user.emailConfirmedAt != null,
      createdAt: DateTime.tryParse(user.createdAt),
      metadata: metadata,
    );
  }
}
