# core/

## Why it exists

The smallest set of types that every other layer depends on, and that depend on
nothing themselves. If a type is imported by both `repositories/` and `views/`,
it probably belongs here.

Nothing in `core/` may import Flutter, Dio, Supabase, or any feature folder. If
you find yourself adding such an import, the type belongs somewhere else.

## What belongs here

- `Result<T>` — the success/failure union every repository returns.
- `typedefs.dart` — `Json`, `JsonList`, `AsyncResult<T>`.
- `Disposable` — the teardown contract the service locator honours.

## What does NOT belong here

- Anything with a `build` method (→ `widgets/`).
- App-specific constants (→ `constants/`).
- Exception classes (→ `exceptions/`).
- "Miscellaneous helpers" — `core/` is not a junk drawer. Put helpers in
  `utils/` or `helpers/`.

## Naming conventions

| Thing | Convention | Example |
| --- | --- | --- |
| File | `snake_case.dart` | `result.dart` |
| Sealed union | `PascalCase` + `final class` variants | `Result` → `Success`, `Failure` |
| Typedef | `PascalCase` | `AsyncResult<T>` |

## Example usage

```dart
Future<Result<User>> loadUser(String id) async { ... }

final result = await loadUser('42');
result.when(
  success: (user) => showProfile(user),
  failure: (error) => showError(error),
);
```

## Best practices

- Prefer `when()` over `if (result.isSuccess)` — the compiler then forces you
  to handle the failure branch.
- Keep `Result` free of business meaning; specificity lives in the
  `AppException` subtype it carries.
- Adding a variant to a sealed class is a breaking change on purpose: every
  exhaustive `switch` will fail to compile until it is handled.
