# env/

Per-environment build configuration, consumed by Flutter's
`--dart-define-from-file`.

## Files

| File | Committed | Purpose |
| --- | --- | --- |
| `dev.json.example` | Yes | Template — copy it |
| `prod.json.example` | Yes | Template — copy it |
| `dev.json`, `staging.json`, `prod.json` | **No** | Your real values |

`env/*.json` is gitignored. The `.example` files are the contract: when you add
a key, add it to both examples so nobody's build breaks with a missing define.

## Setup

```bash
cp env/dev.json.example env/dev.json
# fill in your Supabase and Stripe values
flutter run --dart-define-from-file=env/dev.json
```

## Building

```bash
flutter build apk    --release --dart-define-from-file=env/prod.json
flutter build appbundle --release --dart-define-from-file=env/prod.json
flutter build ipa    --release --dart-define-from-file=env/prod.json
flutter build web    --release --dart-define-from-file=env/prod.json
```

## Why `--dart-define` and not a `.env` file

A `.env` file read at runtime is bundled as an asset, which means it can be
extracted from the app package with a zip tool. `--dart-define` values are
compiled in, and unused branches are tree-shaken. Neither approach makes a
secret safe on a client — which is exactly why nothing here is a secret.

## What must never appear in these files

- Stripe **secret** keys (`sk_...`)
- Supabase **service-role** keys
- Any private key, admin token or database password

Those belong on your backend. The values here (publishable key, anon key) are
public by design; what protects your data is row-level security and
server-side authorization.

For CI, inject the same keys from your provider's secret store rather than
committing a file.

## Adding a key

1. Add the field and its `String.fromEnvironment` read to
   `lib/config/app_config.dart`.
2. Add it to both `.example` files.
3. If a release build cannot work without it, add a check to
   `AppConfigValidator`.
4. Document it in `docs/conventions.md`.
