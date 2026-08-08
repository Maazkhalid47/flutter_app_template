import '../auth/auth_repository.dart';
import '../enums/auth_status.dart';
import '../enums/view_state.dart';
import '../mixins/subscription_mixin.dart';
import '../models/app_user.dart';
import 'base_view_model.dart';

/// Owns authentication state for the whole app.
///
/// Registered once at the root (not per screen) because the router and several
/// screens all read from it. Login, sign-up and profile screens attach to this
/// same instance.
class AuthViewModel extends BaseViewModel with SubscriptionMixin {
  AuthViewModel(this._repository) {
    _status = _repository.currentStatus;
    _user = _repository.currentUser;
    listenTo(_repository.authStatusChanges, _onStatusChanged);
  }

  final AuthRepository _repository;

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;
  bool _obscurePassword = true;

  AuthStatus get status => _status;

  AppUser? get user => _user;

  bool get isAuthenticated => _status.isAuthenticated;

  /// True until the stored session has been checked. The splash screen waits
  /// on this so a returning user never sees the login screen flash by.
  bool get isResolving => !_status.isKnown;

  bool get obscurePassword => _obscurePassword;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notify();
  }

  /// Restores a persisted session. Called once during bootstrap.
  Future<void> restoreSession() async {
    await runGuarded(_repository.restoreSession);
    // Absence of a session is a valid outcome, not an error state.
    if (state == ViewState.empty) setState(ViewState.success);
  }

  Future<bool> signIn({required String email, required String password}) async {
    final session = await runGuarded(
      () => _repository.signInWithEmail(email: email, password: password),
      asBusy: true,
    );
    return session != null;
  }

  Future<bool> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final session = await runGuarded(
      () => _repository.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      ),
      asBusy: true,
    );
    return session != null;
  }

  /// A `void` result carries no value, so success is "no error was recorded".
  Future<bool> sendPasswordReset(String email) async {
    await runGuarded<void>(
      () => _repository.sendPasswordReset(email),
      asBusy: true,
    );
    return exception == null;
  }

  Future<void> signOut() async {
    await runGuarded<void>(_repository.signOut, asBusy: true);
  }

  Future<bool> updateProfile({String? displayName, String? avatarUrl}) async {
    final updated = await runGuarded(
      () => _repository.updateProfile(
        displayName: displayName,
        avatarUrl: avatarUrl,
      ),
      asBusy: true,
    );
    if (updated == null) return false;
    _user = updated;
    notify();
    return true;
  }

  void _onStatusChanged(AuthStatus status) {
    _status = status;
    _user = _repository.currentUser;
    notify();
  }
}
