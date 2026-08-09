import 'package:flutter/foundation.dart';

import '../exception/auth_exception.dart';
import '../models/app_user.dart';
import '../repository/auth_repository.dart';

enum AuthStatus { idle, loading, success, error }

/// Holds auth UI state (loading/error) and delegates every action to
/// [AuthRepository]. Views only read [status]/[errorMessage] and call the
/// action methods here — they never touch the repository directly.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel({AuthRepository? repository})
      : _repository = repository ?? AuthRepository.instance;

  final AuthRepository _repository;

  AuthStatus status = AuthStatus.idle;
  String? errorMessage;
  AppUser? user;

  bool get isLoading => status == AuthStatus.loading;

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) => _run(() => _repository.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
      ));

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) => _run(() => _repository.signInWithEmail(email: email, password: password));

  Future<bool> signInWithGoogle() => _run(_repository.signInWithGoogle);

  Future<bool> signInWithApple() => _run(_repository.signInWithApple);

  Future<bool> _run(Future<AppUser> Function() action) async {
    status = AuthStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      user = await action();
      status = AuthStatus.success;
      notifyListeners();
      return true;
    } on AuthFailure catch (e) {
      status = AuthStatus.error;
      errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      status = AuthStatus.error;
      errorMessage = 'Something went wrong. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    user = null;
    status = AuthStatus.idle;
    notifyListeners();
  }
}
