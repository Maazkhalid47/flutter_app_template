import '../models/app_user.dart';

/// A signed-in session: who the user is and the tokens that prove it.
///
/// Kept separate from [AppUser] because their lifetimes differ — tokens rotate
/// on every refresh while the user identity stays put.
class AuthSession {
  const AuthSession({
    required this.user,
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
  });

  final AppUser user;
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;

  /// Treated as expired one minute early, so a request is never sent with a
  /// token that dies in flight.
  bool get isExpired {
    final expiry = expiresAt;
    if (expiry == null) return false;
    return DateTime.now().isAfter(expiry.subtract(const Duration(minutes: 1)));
  }

  bool get isValid => accessToken.isNotEmpty && !isExpired;

  AuthSession copyWith({
    AppUser? user,
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
  }) => AuthSession(
    user: user ?? this.user,
    accessToken: accessToken ?? this.accessToken,
    refreshToken: refreshToken ?? this.refreshToken,
    expiresAt: expiresAt ?? this.expiresAt,
  );

  @override
  String toString() => 'AuthSession(user: ${user.id}, expiresAt: $expiresAt)';
}
