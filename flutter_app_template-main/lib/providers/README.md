# providers/

## Why it exists

App-wide state that has no screen of its own, plus the wiring that puts state
into the widget tree.

## providers/ vs viewmodels/

| | `providers/` | `viewmodels/` |
| --- | --- | --- |
| Scope | Whole app | One screen |
| Backed by a repository | Usually not | Yes |
| Lifetime | App lifetime | Route lifetime |
| Examples | `ThemeProvider`, `LocaleProvider` | `ArticleListViewModel` |

`AuthViewModel` is deliberately a view model registered at the root: it *is*
backed by a repository, it just happens to be needed everywhere.

## What belongs here

- `theme_provider.dart` — theme mode preference, persisted.
- `locale_provider.dart` — language preference, persisted; also updates the
  API client's `Accept-Language`.
- `app_providers.dart` — the root provider list and screen-scoped factories.

## Naming conventions

- Type: `<Thing>Provider` extending `ChangeNotifier`.
- Async hydration is always a method called `load()`, called from `bootstrap.dart`.
- Setters are `set<Thing>` and return `Future<void>` when they persist.

## Example usage

Root registration (`app_providers.dart`):

```dart
ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
```

Screen-scoped (in the route builder, so it is disposed with the route):

```dart
ChangeNotifierProvider(
  create: AppProviders.articleList,
  child: const ArticleListView(),
)
```

Reading:

```dart
context.watch<ThemeProvider>().themeMode;                 // rebuild on change
context.read<AuthViewModel>().signOut();                  // one-off call
context.select<AuthViewModel, bool>((vm) => vm.isBusy);   // rebuild on one field
```

## Best practices

- Do not put screen view models in the root list. They would never be disposed,
  and the next visit to the screen would show the previous visit's state.
- Hydrate anything the first frame depends on in `bootstrap.dart`, before
  `runApp` — loading the theme afterwards causes a visible flash.
- Prefer `select` over `watch` when a widget depends on one field of a large
  notifier.
- `ChangeNotifierProvider.value` does **not** dispose the notifier; `create`
  does. Use `.value` only for objects owned elsewhere (as bootstrap does).
