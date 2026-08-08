/// Whether the current user is known to be signed in.
///
/// [unknown] exists so the router can hold the splash screen while the stored
/// session is restored, instead of flashing the login screen to a signed-in
/// user.
enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated;

  bool get isKnown => this != AuthStatus.unknown;
  bool get isAuthenticated => this == AuthStatus.authenticated;
}
