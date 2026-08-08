# generated/

## Why it exists

Tool output, kept apart from hand-written code so the boundary is obvious: if a
file is under `generated/`, editing it is pointless — the next build overwrites
it.

## What belongs here

| Path | Produced by | Command |
| --- | --- | --- |
| `l10n/app_localizations*.dart` | Flutter's gen-l10n | `flutter gen-l10n` |

Add other generators here as you adopt them (`build_runner` output for JSON
serialization, assets, routes) by pointing their config at this folder.

## Why the output is committed

`l10n.yaml` writes to `lib/generated/l10n` rather than leaving the result in
`.dart_tool`. Two reasons:

- Imports resolve in every IDE and on a fresh clone before any build runs.
- String changes are visible in code review, where a wrong translation is
  cheapest to catch.

The trade-off is that you must re-run the generator in the same commit as an ARB
edit. `flutter analyze` will not catch a stale generated file — a missing key
will.

## Naming conventions

- Never edit anything here. If output is wrong, fix the source
  (`lib/l10n/*.arb`) or the config (`l10n.yaml`).
- `analysis_options.yaml` excludes `*.g.dart` and `*.freezed.dart` from lint
  rules, since generated code follows the generator's style, not yours.

## Example usage

```bash
flutter gen-l10n     # after editing any .arb file
```

```dart
import '../generated/l10n/app_localizations.dart';

Text(AppLocalizations.of(context).appName);
// or, preferred:
Text(context.l10n.appName);
```

## Best practices

- Regenerate and commit together with the source change.
- If a merge conflicts inside `generated/`, resolve the *source* file and
  regenerate rather than hand-merging the output.
- Prefer `context.l10n` over `AppLocalizations.of(context)` at call sites — one
  extension, defined in `extensions/context_extensions.dart`.
