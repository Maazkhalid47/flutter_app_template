# enums/

## Why it exists

Closed sets of values, so the compiler can prove you handled every case. A
`switch` expression over an enum fails to compile when a value is added — which
is exactly the reminder you want six months later.

## What belongs here

| File | Represents |
| --- | --- |
| `app_environment.dart` | dev / staging / prod |
| `view_state.dart` | idle / loading / success / empty / error |
| `auth_status.dart` | unknown / authenticated / unauthenticated |
| `payment_status.dart` | Provider-agnostic payment outcome |
| `log_level.dart` | debug → fatal, with severity ordering |
| `http_method.dart` | GET / POST / PUT / PATCH / DELETE |

## What does NOT belong here

- Enums used by exactly one class — declare them in that class's file
  (`AppButtonVariant` lives with `AppButton`).
- Values that come from a server and can grow. Parse those into an enum with an
  explicit unknown fallback, or keep them as strings.

## Naming conventions

- Type: `PascalCase` singular — `AuthStatus`, not `AuthStatuses`.
- Values: `lowerCamelCase`.
- Add `is`-getters for readability: `status.isAuthenticated`.
- Enhanced enums carry their wire value: `get('GET')`.

## Example usage

```dart
enum PaymentStatus {
  succeeded,
  failed;

  bool get isTerminal => this == succeeded || this == failed;
}

final label = switch (state) {
  ViewState.loading => 'Loading…',
  ViewState.error   => 'Failed',
  _                 => 'Ready',
};
```

Parsing an external value:

```dart
static AppEnvironment fromKey(String value) {
  for (final env in values) {
    if (env.key == value) return env;
  }
  return AppEnvironment.dev; // never throw on unknown input
}
```

## Best practices

- Prefer an exhaustive `switch` with no `default`. A `default` silently absorbs
  new values and hides the place you needed to update.
- Never persist `Enum.index` — it changes when values are reordered. Persist
  `name` or an explicit key.
- Map provider vocabularies (Stripe, Supabase) onto your own enum at the
  boundary, so their strings never reach the UI.
