import '../constants/storage_keys.dart';
import '../core/result.dart';
import '../core/typedefs.dart';
import '../storage/key_value_store.dart';

/// Remembers whether the user has finished onboarding.
///
/// A repository rather than a direct preferences read, because the router
/// consults it on every navigation and the storage backend should be free to
/// change (a server-side flag, once accounts sync across devices).
abstract interface class OnboardingRepository {
  /// Read synchronously by the route guard — hydrate it during bootstrap with
  /// [load] so the first navigation does not have to await disk.
  bool get hasCompletedOnboarding;

  Future<bool> load();

  AsyncResult<void> markCompleted();

  /// Test/debug affordance: lets you replay onboarding without reinstalling.
  AsyncResult<void> reset();
}

class OnboardingRepositoryImpl implements OnboardingRepository {
  OnboardingRepositoryImpl(this._store);

  final KeyValueStore _store;
  bool _completed = false;

  @override
  bool get hasCompletedOnboarding => _completed;

  @override
  Future<bool> load() async {
    _completed = await _store.readBool(StorageKeys.onboardingSeen) ?? false;
    return _completed;
  }

  @override
  AsyncResult<void> markCompleted() async {
    _completed = true;
    await _store.writeBool(StorageKeys.onboardingSeen, value: true);
    return const Result.success(null);
  }

  @override
  AsyncResult<void> reset() async {
    _completed = false;
    await _store.delete(StorageKeys.onboardingSeen);
    return const Result.success(null);
  }
}
