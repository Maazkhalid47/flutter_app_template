/// Normalized auth error so views/viewmodels never branch on
/// Supabase/Google/Apple-specific exception types.
class AuthFailure implements Exception {
  final String message;

  const AuthFailure(this.message);

  factory AuthFailure.cancelled() => const AuthFailure('Sign-in was cancelled.');

  factory AuthFailure.unknown([String? message]) =>
      AuthFailure(message ?? 'Something went wrong. Please try again.');

  @override
  String toString() => message;
}
