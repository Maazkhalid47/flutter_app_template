# How to add a new Provider

First decide whether you actually want a provider or a view model.

| | Provider | ViewModel |
| --- | --- | --- |
| Scope | App-wide | One screen |
| Has a repository behind it | Usually not | Yes |
| Lifetime | Whole app | Route |
| Examples | `ThemeProvider`, `LocaleProvider` | `ArticleListViewModel` |

If it belongs to a screen, read [add-a-viewmodel.md](add-a-viewmodel.md) instead.

## 1. Write the notifier

```dart
// lib/providers/feature_flags_provider.dart
class FeatureFlagsProvider extends ChangeNotifier {
  FeatureFlagsProvider(this._store);

  final KeyValueStore _store;

  Set<String> _enabled = const {};
  bool isEnabled(String flag) => _enabled.contains(flag);

  /// Hydrated in bootstrap, before the first frame.
  Future<void> load() async {
    final raw = await _store.readString(StorageKeys.featureFlags);
    _enabled = raw == null ? const {} : raw.split(',').toSet();
    notifyListeners();
  }

  Future<void> setEnabled(String flag, {required bool value}) async {
    final next = {..._enabled};
    value ? next.add(flag) : next.remove(flag);
    if (setEquals(next, _enabled)) return;   // no pointless rebuilds
    _enabled = next;
    notifyListeners();
    await _store.writeString(StorageKeys.featureFlags, next.join(','));
  }
}
```

Notice: `notifyListeners()` fires *before* the write. The UI should not wait on
disk for a preference change.

## 2. Hydrate it in bootstrap

`lib/bootstrap.dart` — anything the first frame depends on is loaded here, in
parallel:

```dart
final flagsProvider = FeatureFlagsProvider(store);

await Future.wait([
  themeProvider.load(),
  localeProvider.load(),
  flagsProvider.load(),
]);
```

Loading a theme or locale *after* the first frame causes a visible flash.

## 3. Register it at the root

`lib/providers/app_providers.dart`:

```dart
static List<SingleChildWidget> root({
  required ThemeProvider themeProvider,
  required LocaleProvider localeProvider,
  required FeatureFlagsProvider flagsProvider,
}) =>
    [
      ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
      ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
      ChangeNotifierProvider<FeatureFlagsProvider>.value(value: flagsProvider),
      ...
    ];
```

`.value` does not dispose the notifier — correct here, because bootstrap owns
it. Use `create:` when the provider should own and dispose the object.

## 4. Read it

```dart
context.watch<FeatureFlagsProvider>();                        // whole object
context.select<FeatureFlagsProvider, bool>((p) => p.isEnabled('beta'));  // one field
context.read<FeatureFlagsProvider>().setEnabled('beta', value: true);    // callback
```

| Method | Use in | Rebuilds |
| --- | --- | --- |
| `watch` | `build` | On any change |
| `select` | `build` | Only when that value changes |
| `read` | callbacks, `initState` | Never |

`read` inside `build` means the UI never updates; `watch` inside a callback
rebuilds for nothing. Both are common bugs.

## Best practices

- Keep the root list short. Every notifier there lives for the whole app and is
  never disposed.
- Bail out early when the value has not actually changed — a `notifyListeners`
  with identical state is a wasted frame across the entire subtree.
- Prefer `select` for a single field of a large notifier.
- A provider that needs a repository and belongs to one screen is a view model
  in disguise.
