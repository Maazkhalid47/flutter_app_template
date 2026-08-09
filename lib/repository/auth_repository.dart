import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/apple_auth_service.dart';
import '../auth/google_auth_service.dart';
import '../exception/auth_exception.dart';
import '../models/app_user.dart';
import '../supabase/supabase_service.dart';

/// Single entry point for every auth operation. Wraps Supabase Auth (email
/// link, password, and third-party ID token sign-in) and normalizes every
/// failure into [AuthFailure] so viewmodels never see Supabase/Google/Apple
/// exception types directly.
class AuthRepository {
  AuthRepository._();
  static final instance = AuthRepository._();

  AppUser? get currentUser {
    final user = SupabaseService.currentUser;
    return user == null ? null : AppUser.fromSupabase(user);
  }

  bool get isAuthenticated => SupabaseService.isAuthenticated;

  Stream<AppUser?> get authStateChanges =>
      SupabaseService.onAuthStateChange.map((state) {
        final user = state.session?.user;
        return user == null ? null : AppUser.fromSupabase(user);
      });

  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final response = await SupabaseService.auth.signUp(
        email: email,
        password: password,
        data: fullName == null ? null : {'full_name': fullName},
      );
      final user = response.user;
      if (user == null) throw AuthFailure.unknown('Sign up failed.');
      return AppUser.fromSupabase(user);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await SupabaseService.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) throw AuthFailure.unknown('Sign in failed.');
      return AppUser.fromSupabase(user);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  Future<AppUser> signInWithGoogle() async {
    final idToken = await GoogleAuthService.signIn();
    try {
      final response = await SupabaseService.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
      final user = response.user;
      if (user == null) throw AuthFailure.unknown('Google sign-in failed.');
      return AppUser.fromSupabase(user);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  Future<AppUser> signInWithApple() async {
    final idToken = await AppleAuthService.signIn();
    try {
      final response = await SupabaseService.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
      );
      final user = response.user;
      if (user == null) throw AuthFailure.unknown('Apple sign-in failed.');
      return AppUser.fromSupabase(user);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  Future<void> signOut() async {
    await SupabaseService.auth.signOut();
    await GoogleAuthService.signOut();
  }
}
