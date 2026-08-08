# exceptions/

## Why it exists

One error vocabulary for the whole app, one place that translates third-party
errors into it, and one place that catches whatever escapes.

## The flow

```
Dio / Supabase / platform throws
        │
        ▼
ExceptionMapper.map()          ← the only file that knows foreign error types
        │
        ▼
AppException subtype
        │
        ▼
BaseRepository.guard()  ⇒  Result.failure(exception)
        │
        ▼
BaseViewModel.runGuarded()  ⇒  ViewState.error
        │
        ▼
AppErrorView / FeedbackHelper  ⇒  localized copy via messageKey
```

Above the repository, nothing throws and nothing catches.

## What belongs here

| File | Purpose |
| --- | --- |
| `app_exception.dart` | The sealed hierarchy |
| `exception_mapper.dart` | Dio/Supabase/platform → `AppException` |
| `global_error_handler.dart` | `FlutterError.onError`, `PlatformDispatcher.onError`, reporting |

## The hierarchy

`NetworkException`, `TimeoutException`, `ServerException` — retryable.
`UnauthorizedException`, `NotFoundException`, `ValidationException`,
`AuthException`, `PaymentException`, `StorageException`, `ParsingException`,
`PermissionException`, `CancelledException`, `UnknownException` — not.

Each carries a developer-facing `message`, a `messageKey` for user copy, an
optional `code`, and the original `cause`.

## Naming conventions

- `<Concern>Exception`, all extending the sealed `AppException`.
- `messageKey` matches an ARB key; unknown keys fall back to `errorGeneric`.
- `isRetryable` is what drives whether the UI offers a Retry button.

## Example usage

```dart
if (result.exceptionOrNull case final UnauthorizedException e) {
  await authRepository.signOut();
}
```

Adding a type:

1. Add the `final class` to `app_exception.dart`.
2. Map to it in `ExceptionMapper`.
3. If it needs its own copy, add an ARB key and a case in
   `ExceptionMessageResolver`.

## Best practices

- Never show `exception.message` to a user — it is developer copy and can leak
  server internals. Always resolve `messageKey`.
- `CancelledException` is normal control flow. It is deliberately not logged or
  reported, and `runGuarded` ignores it.
- Set `isRetryable` honestly: it decides whether the user is offered a button
  that will just fail again.
- All three Flutter error escape hatches must be covered — the framework
  handler, the platform dispatcher, and the `runZonedGuarded` zone in `main.dart`.
  Missing one means production crashes that never reach you.
