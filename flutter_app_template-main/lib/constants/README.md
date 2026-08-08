# constants/

## Why it exists

Compile-time values that are identical in every environment. Centralising them
means a value is defined once, a typo is a compile error, and finding every use
is a "find references" away.

## What belongs here

| File | Holds |
| --- | --- |
| `app_constants.dart` | App-level values: page size, TTLs, support email |
| `api_constants.dart` | Relative paths, header names, query keys |
| `storage_keys.dart` | Every persisted key, prefixed by its store |
| `asset_paths.dart` | Typed references to bundled assets |
| `ui_constants.dart` | Spacing, radii, sizes, durations, breakpoints |

## What does NOT belong here

- Anything environment-specific (→ `config/`).
- Colours and text styles (→ `theme/`).
- User-visible strings (→ `lib/l10n/*.arb`).

## Naming conventions

- Container class: `abstract final class` + `static const` members. `abstract
  final` makes it impossible to instantiate or extend.
- Members are `lowerCamelCase` and grouped by comment blocks.
- Storage keys carry their store as a prefix: `secure.`, `prefs.`, `cache.`.

## Example usage

```dart
Padding(padding: const EdgeInsets.all(UiConstants.spaceMd));
await _store.writeBool(StorageKeys.onboardingSeen, value: true);
_client.requestJson(HttpMethod.get, ApiConstants.articleById(id));
```

## Best practices

- If a value appears twice anywhere in the codebase, it belongs here.
- Use the spacing scale (`spaceSm`, `spaceMd`, …) rather than raw numbers —
  that is what keeps the layout on a consistent grid.
- Add an asset to `asset_paths.dart` *and* `pubspec.yaml` in the same commit.
- Never repurpose a storage key. Old installs still have the old value under
  it; add a new key and migrate.
