import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../exception/auth_exception.dart';

/// Wraps the Google Sign-In SDK. Returns only the ID token Supabase needs
/// (`supabase.auth.signInWithIdToken`) so [AuthRepository] never touches
/// `google_sign_in` types directly.
class GoogleAuthService {
  GoogleAuthService._();

  static bool _initialized = false;

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
    );
    _initialized = true;
  }

  /// Returns the Google ID token for the signed-in account, or throws
  /// [AuthFailure] if the user cancels or the SDK isn't configured.
  static Future<String> signIn() async {
    await _ensureInitialized();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw AuthFailure.unknown('Google did not return an ID token.');
      }
      return idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw AuthFailure.cancelled();
      }
      throw AuthFailure.unknown(e.description);
    }
  }

  static Future<void> signOut() => GoogleSignIn.instance.signOut();
}
