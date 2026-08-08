# network/

## Why it exists

Transport policy: the cross-cutting rules applied to every request, and the
device's connectivity state. Separate from `api/` because these are decisions
*about* requests rather than the surface for making them.

## What belongs here

| File | Purpose |
| --- | --- |
| `network_info.dart` | Is the device online, now and as a stream |
| `interceptors/connectivity_interceptor.dart` | Reject requests when offline |
| `interceptors/auth_interceptor.dart` | Attach the token; refresh once on 401 |
| `interceptors/retry_interceptor.dart` | Exponential backoff for transient failures |
| `interceptors/logging_interceptor.dart` | Redacted request/response logging with timings |

## Interceptor order

Set in `dependency_injection/service_locator.dart`:

```
connectivity → auth → retry → logging
```

1. **connectivity** first — fail instantly offline instead of waiting 30s.
2. **auth** — attach the token, refresh on 401.
3. **retry** — after auth, so a retried request carries the refreshed token.
4. **logging** outermost, so it records the final outcome.

## Naming conventions

- `<Concern>Interceptor`, one concern per file.
- Use `QueuedInterceptor` (not `Interceptor`) when the handler awaits something
  shared, as `AuthInterceptor` does — it serialises the queue and prevents a
  refresh stampede.

## Example usage

```dart
if (!await networkInfo.isConnected) return;

networkInfo.onConnectivityChanged.listen((online) {
  if (online) viewModel.refresh();
});
```

## Best practices

- Only retry idempotent verbs. Replaying a POST can double-charge a card.
- The 401 refresh is single-flight: five parallel 401s must trigger one
  refresh, not five. See `_refreshOperation` in `auth_interceptor.dart`.
- Mark a replayed request in `options.extra` so a second 401 does not loop.
- `ConnectivityResult != none` means an interface exists, not that the internet
  works — request failures are still mapped to `NetworkException`.
- Never log with Dio's built-in `LogInterceptor`: it prints `Authorization`
  headers verbatim.
