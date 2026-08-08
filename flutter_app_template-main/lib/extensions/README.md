# extensions/

## Why it exists

Extension methods that shorten the code you write dozens of times a day, mostly
in build methods. `context.colors.primary` instead of
`Theme.of(context).colorScheme.primary` is not cosmetic — it is the difference
between a readable widget tree and a noisy one.

## What belongs here

| File | Extends |
| --- | --- |
| `context_extensions.dart` | `BuildContext` — theme, l10n, media, responsive |
| `string_extensions.dart` | `String` and `String?` |
| `datetime_extensions.dart` | `DateTime` comparisons and arithmetic |
| `widget_extensions.dart` | `Widget` composition, `num` → spacing |

## What does NOT belong here

- Anything with real logic. An extension is sugar over an existing API; if it
  makes a decision or a network call, write a proper class.
- Extensions on your own models — put the method on the model.
- Formatting for display (→ `utils/formatters.dart`).

## Naming conventions

- Extension name: `<Type>X` — `BuildContextX`, `StringX`.
- One extension per type per file.
- Prefer getters for derived values (`isBlank`), methods when they take
  arguments (`truncate(20)`).

## Example usage

```dart
Text(user.name.capitalized, style: context.textTheme.titleMedium);

if (email.isNotBlank && date.isToday) { ... }

Column(
  children: [
    const Text('Title'),
    UiConstants.spaceMd.verticalSpace,
    const Text('Body').paddedAll(),
  ],
);
```

## Best practices

- Extensions are resolved statically: two extensions defining the same member
  on the same type is an ambiguity error. Keep names distinctive.
- Do not chain more than two or three widget extensions — past that, a named
  widget is clearer than `.paddedAll().rounded().expanded`.
- Null-safe variants belong in a separate `NullableStringX`-style extension so
  the non-null one stays clean.
