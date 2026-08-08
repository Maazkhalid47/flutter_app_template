# config/

## Why it exists

Everything that differs between dev, staging and production, in one immutable
object resolved at build time. Without this, environment checks leak into
widgets (`if (kDebugMode) url = ...`) and secrets end up committed.

## What belongs here

- `AppConfig` — every `--dart-define` value, frozen at startup.
- `AppConfigValidator` — fails a release build fast when a required key is
  missing, rather than at the first network call.

## What does NOT belong here

- Values that are the same in every environment (→ `constants/`).
- Actual secret values. Nothing in this folder should contain a key; it only
  reads them from the build.
- Runtime user preferences such as theme or language (→ `providers/`).

## Naming conventions

- `--dart-define` keys are `SCREAMING_SNAKE_CASE`: `SUPABASE_URL`.
- The matching Dart field is `lowerCamelCase`: `supabaseUrl`.
- Booleans read as questions: `isSupabaseConfigured`, `enableAnalytics`.

## Example usage

```bash
flutter run --dart-define-from-file=env/dev.json
```

```dart
final config = AppConfig.instance;
if (config.environment.isProd) { ... }
```

In a test:

```dart
AppConfig.overrideForTesting(testConfig);
addTearDown(AppConfig.resetForTesting);
```

## Best practices

- Add a new setting in three places: the field + constructor in `AppConfig`,
  the `env/*.json` files, and `docs/conventions.md`.
- Never read `String.fromEnvironment` outside this folder — one place to look
  when a value is wrong.
- Guard features on `isXConfigured` so a developer without credentials can
  still run the app.
- `diagnostics` must never expose a key. Assume it will end up in a bug report.
