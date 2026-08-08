# viewmodels/

## Why it exists

The VM in MVVM. A view model holds a screen's state and the operations that
change it, with no reference to Flutter widgets. That constraint is what makes
screen behaviour unit-testable in milliseconds instead of via `pumpWidget`.

## What belongs here

- `base_view_model.dart` — `ViewState` machine, `isBusy`, `runGuarded`, and a
  disposal-safe `notify()`.
- One view model per screen (or per screen family): `auth_view_model.dart`,
  `article_list_view_model.dart`, `onboarding_view_model.dart`.

## Hard rules

A view model **must not**:

- import `package:flutter/material.dart` (only `foundation.dart`, for
  `ChangeNotifier`),
- hold a `BuildContext`,
- navigate, show a snackbar, or open a dialog,
- call a service or an HTTP client directly — go through a repository.

If a view model needs to "navigate on success", it should instead expose the
result and let the view decide.

## Naming conventions

- Type: `<Screen>ViewModel`. File: `<screen>_view_model.dart`.
- State getters read as nouns (`articles`, `searchQuery`); commands as verbs
  (`load`, `refresh`, `loadMore`, `signIn`).
- Mutating state goes through `setState`/`setBusy`/`setError` from the base
  class, never a raw `notifyListeners()`.

## Example usage

```dart
class ProfileViewModel extends BaseViewModel {
  ProfileViewModel(this._repository);
  final ProfileRepository _repository;

  Profile? _profile;
  Profile? get profile => _profile;

  Future<void> load() => runGuarded<Profile>(
        _repository.fetchProfile,
        onSuccess: (value) {
          _profile = value;
          return true; // false ⇒ ViewState.empty
        },
      );

  Future<bool> save(String name) async {
    final updated = await runGuarded<Profile>(
      () => _repository.updateName(name),
      asBusy: true, // keeps existing data on screen
    );
    return updated != null;
  }
}
```

## `state` vs `isBusy`

- `ViewState.loading` — nothing to show yet; the screen renders a spinner.
- `isBusy` — data is already on screen and a secondary action is running
  (submitting, refreshing). The list stays visible.

Getting this wrong is why lists flash empty on pull-to-refresh.

## Best practices

- Use `runGuarded` rather than hand-rolling try/loading/error per method.
- Cancel in-flight requests in `dispose()` (`CancellationToken`), and use
  `SubscriptionMixin` for any stream you listen to.
- A failed *additional* page must not clear the pages already loaded — see
  `loadMore` in `article_list_view_model.dart`.
- Ignore `CancelledException`; it means the user moved on, not that anything
  broke. `runGuarded` already does this for you.
- Screen-scoped view models are created by the route or the screen so they are
  disposed with it. Only genuinely app-wide state (auth) lives at the root.
