import 'dart:async';

import 'package:flutter/foundation.dart';

/// Tracks stream subscriptions and cancels them on dispose.
///
/// Leaked subscriptions are the most common cause of "setState called after
/// dispose" crashes and of memory that never comes back. Mix this into any
/// [ChangeNotifier] that listens to something, register with [listenTo], and
/// the cleanup is guaranteed.
///
/// ```dart
/// class AuthViewModel extends BaseViewModel with SubscriptionMixin {
///   AuthViewModel(this._repo) {
///     listenTo(_repo.authStateChanges, _onAuthChanged);
///   }
/// }
/// ```
mixin SubscriptionMixin on ChangeNotifier {
  final List<StreamSubscription<Object?>> _subscriptions = [];
  final List<Timer> _timers = [];

  /// Subscribes to [stream] and remembers the subscription for disposal.
  StreamSubscription<T> listenTo<T>(
    Stream<T> stream,
    void Function(T event) onData, {
    void Function(Object error, StackTrace stackTrace)? onError,
    bool cancelOnError = false,
  }) {
    final subscription = stream.listen(
      onData,
      onError: onError,
      cancelOnError: cancelOnError,
    );
    _subscriptions.add(subscription);
    return subscription;
  }

  /// Registers a periodic timer for automatic cancellation.
  Timer registerTimer(Timer timer) {
    _timers.add(timer);
    return timer;
  }

  /// Cancels everything without disposing the notifier. Useful when a screen
  /// is re-initialised with different arguments.
  Future<void> cancelSubscriptions() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
  }

  @override
  void dispose() {
    // Fire-and-forget is correct here: `dispose` is synchronous by contract and
    // `cancel()` on an already-closed stream cannot fail meaningfully.
    unawaited(cancelSubscriptions());
    super.dispose();
  }
}
