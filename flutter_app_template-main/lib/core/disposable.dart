/// Anything holding resources that must be released on app shutdown or when a
/// scope is torn down (stream subscriptions, timers, native handles).
///
/// The service locator disposes every registered [Disposable] in
/// `dependency_injection/service_locator.dart`.
abstract interface class Disposable {
  Future<void> dispose();
}
