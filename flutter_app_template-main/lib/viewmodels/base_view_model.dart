import 'package:flutter/foundation.dart';

import '../core/result.dart';
import '../enums/view_state.dart';
import '../exceptions/app_exception.dart';

/// The base class for every view model.
///
/// A view model owns screen state and calls repositories. It must never import
/// `material.dart`, hold a `BuildContext`, or navigate — those are the view's
/// job. Keeping that rule is what makes view models unit-testable without a
/// widget tree.
///
/// It provides three things every screen needs:
/// * a [state] machine the UI can render generically (`StateView`),
/// * [runGuarded], which handles loading flags and failures uniformly,
/// * [notify], which is safe to call after disposal.
abstract class BaseViewModel extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  AppException? _exception;
  bool _isBusy = false;
  bool _isDisposed = false;

  /// The main data state, driving loading/empty/error/success UI.
  ViewState get state => _state;

  /// The last failure, for the error UI. Cleared on every new attempt.
  AppException? get exception => _exception;

  /// A secondary operation is running (submit, refresh, delete) while data is
  /// already on screen. Distinct from [ViewState.loading], which means "there
  /// is nothing to show yet".
  bool get isBusy => _isBusy;

  bool get isDisposed => _isDisposed;

  @protected
  void setState(ViewState value) {
    if (_state == value) return;
    _state = value;
    notify();
  }

  @protected
  void setBusy({required bool value}) {
    if (_isBusy == value) return;
    _isBusy = value;
    notify();
  }

  @protected
  void setError(AppException? value) {
    _exception = value;
    if (value != null) _state = ViewState.error;
    notify();
  }

  /// Clears the error without changing data. Call when the user dismisses it.
  void clearError() {
    if (_exception == null) return;
    _exception = null;
    notify();
  }

  /// `notifyListeners` that cannot throw after disposal.
  ///
  /// An async callback completing after the user navigated away is normal, not
  /// a bug to crash on.
  @protected
  void notify() {
    if (_isDisposed) return;
    notifyListeners();
  }

  /// Runs a repository call and folds the result into view-model state.
  ///
  /// Every screen otherwise re-writes this same try/flag/assign block, and each
  /// copy forgets a different edge case.
  ///
  /// * [asBusy] — set when data is already on screen, so the list is not
  ///   replaced by a full-screen spinner.
  /// * [onSuccess] — receives the value; returning `false` marks the state
  ///   empty rather than success.
  @protected
  Future<T?> runGuarded<T>(
    Future<Result<T>> Function() operation, {
    bool asBusy = false,
    bool Function(T value)? onSuccess,
  }) async {
    if (asBusy) {
      setBusy(value: true);
    } else {
      _exception = null;
      setState(ViewState.loading);
    }

    final result = await operation();

    if (_isDisposed) return null;

    return result.when<T?>(
      success: (value) {
        _exception = null;
        final hasContent = onSuccess?.call(value) ?? true;
        if (asBusy) {
          setBusy(value: false);
        } else {
          setState(hasContent ? ViewState.success : ViewState.empty);
        }
        // A busy operation may have changed data without changing state.
        if (asBusy) notify();
        return value;
      },
      failure: (failure) {
        // A cancelled request means the caller moved on; showing an error for
        // it would be noise.
        if (failure is CancelledException) {
          if (asBusy) setBusy(value: false);
          return null;
        }
        _isBusy = false;
        setError(failure);
        return null;
      },
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
