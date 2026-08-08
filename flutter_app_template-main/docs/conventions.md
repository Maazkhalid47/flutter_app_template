# Conventions & coding standards

## Naming

| Thing | Convention | Example |
| --- | --- | --- |
| File | `snake_case.dart` | `article_list_view_model.dart` |
| Class / enum / typedef | `PascalCase` | `ArticleRepository` |
| Member / variable | `lowerCamelCase` | `fetchArticles` |
| Private | leading `_` | `_repository` |
| Constant | `lowerCamelCase` (not SCREAMING) | `defaultPageSize` |
| `--dart-define` key | `SCREAMING_SNAKE_CASE` | `SUPABASE_URL` |
| Type parameter | single letter or descriptive | `T`, `R` |

### Suffixes

| Suffix | Layer | Example |
| --- | --- | --- |
| `View` | Screen | `LoginView` |
| `ViewModel` | Screen state | `AuthViewModel` |
| `Repository` / `RepositoryImpl` | Domain | `ArticleRepositoryImpl` |
| `Service` / `ApiService` | Data | `ArticleApiService` |
| `DataSource` | SDK adapter | `SupabaseAuthDataSourceImpl` |
| `Provider` | App-wide notifier | `ThemeProvider` |
| `Exception` | Error | `NetworkException` |
| `Interceptor` | Transport policy | `AuthInterceptor` |
| `Mixin` | Shared behaviour | `SubscriptionMixin` |
| `App*` prefix | Generic widget | `AppButton` |

### Method names

- Repository: `fetchX`, `createX`, `updateX`, `deleteX`.
- View model commands: `load`, `refresh`, `loadMore`, `submit`, `signIn`.
- Booleans read as questions: `isBusy`, `hasMore`, `canRetry`.
- Async that persists returns `Future<void>`; async that can fail returns
  `AsyncResult<T>`.

## Language features to prefer

This project targets Dart 3.12 and uses modern language features deliberately.

```dart
// Sealed classes + exhaustive switch — the compiler catches missed cases
final label = switch (state) {
  ViewState.loading => 'Loading',
  ViewState.error   => 'Failed',
  ViewState.empty   => 'Nothing here',
  ViewState.idle || ViewState.success => 'Ready',
};

// Pattern matching over an is-check + cast
if (result.exceptionOrNull case final UnauthorizedException e) { ... }

// Null-aware elements
final data = {'display_name': ?displayName};
```

Avoid a `default:` clause on an enum switch — it silently absorbs new values.

## Formatting

- `dart format .` before every commit. 80 columns, non-negotiable.
- Trailing commas on every multi-line argument list; they are what make the
  formatter produce readable output and diffs.
- Import order (enforced by `directives_ordering`): `dart:`, then `package:`,
  then relative — each group alphabetised, blank line between groups.
- Relative imports within `lib/`. `avoid_relative_lib_imports` blocks the
  broken mixed form.

## Hard rules

These are the ones that keep the architecture intact:

1. No hardcoded colours, sizes, or user-visible strings. Use `theme/`,
   `constants/`, `l10n/`.
2. No `print`. Use `AppLogger` — it filters by level and redacts credentials.
3. No `try/catch` above the repository layer.
4. Repositories return `Result`, never `null`, to signal failure.
5. View models never import `material.dart` or hold a `BuildContext`.
6. Views never call a service or an HTTP client.
7. No `getIt<T>()` inside a class — inject through the constructor.
8. `if (!mounted) return;` after every `await` in a widget.
9. Dispose every controller, subscription and timer you create.
10. `const` constructors wherever possible.

## Comments

Comment the *why*, never the *what*. The code already says what it does.

```dart
// Bad — restates the code
// Set the timer to 400ms
_timer = Timer(const Duration(milliseconds: 400), action);

// Good — explains the decision
// Single-flight: five parallel 401s must trigger one refresh, not five, or
// four of them invalidate the token the fifth just obtained.
final refreshed = await (_refreshOperation ??= _runRefresh());
```

Public APIs get `///` doc comments explaining purpose and any non-obvious
constraint. Reference other types with `[Brackets]` so IDEs link them.

## Git

- Branches: `feature/<short-description>`, `fix/<short-description>`.
- Commits in the imperative mood: "Add order repository", not "Added…".
- A commit must leave `flutter analyze` clean and `flutter test` green.
- Regenerate localization in the same commit as an ARB edit.

## Before opening a pull request

```bash
dart format .
flutter analyze      # must print "No issues found!"
flutter test
```

## Adding a dependency

Ask first: is it maintained, does it support every platform we target, and does
it justify its size? Then wrap it behind an interface in the appropriate data
folder, so replacing it later is one file rather than fifty.
