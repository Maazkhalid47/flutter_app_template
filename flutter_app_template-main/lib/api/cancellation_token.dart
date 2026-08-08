import 'dart:async';

/// Lets a caller abandon an in-flight request.
///
/// This is the app's own token rather than Dio's `CancelToken`, so a view model
/// can cancel a request without importing an HTTP package. `DioApiClient`
/// bridges it to the transport.
///
/// Typical use: a search field cancels the previous query before issuing the
/// next one, and a view model cancels everything in `dispose()`.
class CancellationToken {
  final Completer<String> _completer = Completer<String>();

  bool get isCancelled => _completer.isCompleted;

  /// Completes when [cancel] is called. Never completes with an error.
  Future<String> get onCancelled => _completer.future;

  /// Cancels the operation. Calling twice is a no-op, so callers do not need
  /// to track whether they already cancelled.
  void cancel([String reason = 'Cancelled by caller']) {
    if (_completer.isCompleted) return;
    _completer.complete(reason);
  }
}
