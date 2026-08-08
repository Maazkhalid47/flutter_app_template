import 'dart:async';
import 'package:flutter/foundation.dart';

/// Delays an action until the caller stops firing it.
///
/// The canonical use is search-as-you-type: without this, every keystroke costs
/// a network request. Always [dispose] it from the owner's `dispose()`.
///
/// ```dart
/// final _search = Debouncer(AppConstants.searchDebounce);
/// void onQueryChanged(String q) => _search.run(() => viewModel.search(q));
/// ```
class Debouncer {
  Debouncer(this.delay);

  final Duration delay;
  Timer? _timer;

  /// True while an action is scheduled but not yet executed.
  bool get isPending => _timer?.isActive ?? false;

  /// Schedules [action], cancelling any previously scheduled one.
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Drops the pending action without running it.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => cancel();
}

/// Runs an action at most once per [interval], ignoring calls in between.
///
/// Use for things that must fire immediately but not repeatedly — button
/// double-tap protection, scroll-driven pagination triggers.
class Throttler {
  Throttler(this.interval);

  final Duration interval;
  DateTime? _lastRun;

  /// Runs [action] if the interval has elapsed. Returns whether it ran.
  bool run(VoidCallback action) {
    final now = DateTime.now();
    final last = _lastRun;
    if (last != null && now.difference(last) < interval) return false;
    _lastRun = now;
    action();
    return true;
  }

  void reset() => _lastRun = null;
}
