import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../core/disposable.dart';

/// Tells the rest of the app whether the device has a usable connection.
///
/// Depended on as an interface so tests can force "offline" without a plugin,
/// and so the connectivity package can be swapped without touching callers.
abstract interface class NetworkInfo implements Disposable {
  /// A best-effort answer for right now.
  Future<bool> get isConnected;

  /// Emits on every transition. Distinct — no duplicate events for the same
  /// state, so UI does not rebuild for nothing.
  Stream<bool> get onConnectivityChanged;

  /// The last known value, available synchronously. Optimistically `true`
  /// before the first check: blocking the UI on an unknown is worse than
  /// letting one request fail.
  bool get lastKnownStatus;
}

class ConnectivityNetworkInfo implements NetworkInfo {
  ConnectivityNetworkInfo(this._connectivity) {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _emit(_isConnectedFrom(results));
    });
    unawaited(isConnected);
  }

  final Connectivity _connectivity;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _lastKnown = true;

  @override
  bool get lastKnownStatus => _lastKnown;

  @override
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    final connected = _isConnectedFrom(results);
    _emit(connected);
    return connected;
  }

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  void _emit(bool connected) {
    if (connected == _lastKnown) return;
    _lastKnown = connected;
    if (!_controller.isClosed) _controller.add(connected);
  }

  /// `ConnectivityResult.none` is the only reliable signal. A non-none result
  /// means a network interface exists — not that the internet is reachable —
  /// which is why request failures are still mapped to [NetworkException].
  bool _isConnectedFrom(List<ConnectivityResult> results) =>
      results.isNotEmpty &&
      results.any((result) => result != ConnectivityResult.none);

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
  }
}
