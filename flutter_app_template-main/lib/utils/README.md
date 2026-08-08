# utils/

## Why it exists

Stateless, reusable machinery that belongs to no particular feature: logging,
formatting, timing, responsive maths.

## utils/ vs helpers/

The line is `BuildContext`:

- **`utils/`** — pure, context-free, unit-testable without Flutter.
- **`helpers/`** — needs a `BuildContext` (snackbars, dialogs, localization).

If you can test it without importing `flutter_test`, it goes in `utils/`.

## What belongs here

| File | Purpose |
| --- | --- |
| `logger.dart` | Levelled logging with credential redaction and pluggable sinks |
| `formatters.dart` | Locale-aware date, currency and number formatting |
| `debouncer.dart` | `Debouncer` and `Throttler` |
| `responsive.dart` | Width → `ScreenSize` classification |

## What does NOT belong here

- Business rules — a "util" that knows what an Order is, is a service.
- Extension methods (→ `extensions/`).
- Input validation (→ `validators/`).

## Naming conventions

- Stateless collections: `abstract final class` with static methods
  (`Formatters.date(...)`).
- Objects with lifetime: a normal class with a `dispose()` (`Debouncer`).

## Example usage

```dart
logger.info('Sync finished', data: {'count': items.length});
Formatters.currencyFromMinorUnits(1999, currencyCode: 'USD'); // $19.99
_debouncer.run(() => viewModel.search(query));
```

## Best practices

- Never use `print`. `AppLogger` filters by level and redacts tokens; `print`
  does neither and ships to production.
- Money is passed around in **minor units** (integer cents). Formatting is the
  only place it becomes a decimal.
- Always dispose a `Debouncer` — a pending timer holds its closure, and the
  closure holds your view model.
- If a util grows a field that changes over time, it is no longer a util.
