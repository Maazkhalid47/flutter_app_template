import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../exception/auth_exception.dart';

/// Wraps Sign in with Apple. Returns only the identity token Supabase needs
/// (`supabase.auth.signInWithIdToken`) so [AuthRepository] never touches
/// `sign_in_with_apple` types directly.
class AppleAuthService {
  AppleAuthService._();

  /// Returns the Apple identity token for the signed-in user, or throws
  /// [AuthFailure] if the user cancels or the SDK isn't configured.
  static Future<String> signIn() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: Platform.isIOS || Platform.isMacOS
            ? null
            : WebAuthenticationOptions(
                clientId: dotenv.env['APPLE_SERVICE_ID'] ?? '',
                redirectUri: Uri.parse(dotenv.env['APPLE_REDIRECT_URI'] ?? ''),
              ),
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw AuthFailure.unknown('Apple did not return an identity token.');
      }
      return idToken;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw AuthFailure.cancelled();
      }
      throw AuthFailure.unknown(e.message);
    }
  }
}
