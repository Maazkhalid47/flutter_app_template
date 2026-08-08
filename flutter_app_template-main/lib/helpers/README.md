# helpers/

## Why it exists

UI-facing utilities that need a `BuildContext`. Keeping them here — rather than
in `utils/` — means `utils/` stays pure and testable without Flutter.

## What belongs here

| File | Purpose |
| --- | --- |
| `feedback_helper.dart` | Snackbars, confirmation dialogs, blocking progress |
| `exception_message_resolver.dart` | `AppException` → localized user copy |

## What does NOT belong here

- Anything reusable without a context (→ `utils/`).
- Widgets (→ `widgets/`). A helper *shows* UI; it does not *build* it.
- Navigation (→ `routes/`).

## Naming conventions

- `abstract final class` + static methods, named as verbs:
  `FeedbackHelper.showError(...)`, `FeedbackHelper.confirm(...)`.
- File names end in `_helper.dart` or describe the transform
  (`exception_message_resolver.dart`).

## Example usage

```dart
FeedbackHelper.showSuccess(context, 'Saved');

FeedbackHelper.showError(context, exception, onRetry: _submit);

final confirmed = await FeedbackHelper.confirm(
  context,
  title: 'Delete article',
  message: 'This cannot be undone.',
  isDestructive: true,
);
if (!confirmed) return;
```

## Best practices

- After any `await`, check `if (!mounted) return;` before using the context
  again. The user may have navigated away.
- Pass the `AppException`, not a string — `showError` reads `isRetryable` and
  `messageKey` to decide what to show.
- Never show `exception.message` directly to a user; it is developer copy and
  can contain server internals.
- Confirm before anything destructive, and pass `isDestructive: true` so the
  action is styled as a warning.
