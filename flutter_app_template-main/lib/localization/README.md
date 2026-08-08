# localization/

## Why it exists

This folder documents the localization workflow. The moving parts live in three
places, and this is the map:

| Location | Contents |
| --- | --- |
| `lib/l10n/*.arb` | Source strings — **edit these** |
| `l10n.yaml` | Generator configuration |
| `lib/generated/l10n/` | Generated Dart — never edit |
| `lib/providers/locale_provider.dart` | The user's language preference |

Put any hand-written localization helper here (plural helpers, RTL utilities,
a language-name lookup). Keeping it out of `lib/l10n/` avoids mixing sources
with tooling input.

## Workflow

1. Add the key to `lib/l10n/app_en.arb` (the template file).
2. Add a translation to every other `app_*.arb`. A missing key falls back to
   English rather than crashing.
3. Run `flutter gen-l10n`.
4. Use it: `context.l10n.myNewKey`.

## Naming conventions

- Keys are `lowerCamelCase`, prefixed by feature: `authLoginTitle`,
  `settingsTheme`, `errorNetwork`, `validationEmail`.
- Placeholders are named and typed:

```json
"validationPasswordShort": "Password must be at least {min} characters",
"@validationPasswordShort": {
  "placeholders": { "min": { "type": "int" } }
}
```

## Example usage

```dart
Text(context.l10n.authLoginTitle);
Text(context.l10n.validationPasswordShort(8));
```

Switching language:

```dart
context.read<LocaleProvider>().setLocale(const Locale('ur'));
context.read<LocaleProvider>().setLocale(null); // follow the device
```

## Best practices

- No user-visible string literal anywhere outside an ARB file.
- Never concatenate translated fragments — word order differs between
  languages. Use one key with placeholders.
- The generated output is committed so imports resolve in every IDE and string
  changes are visible in review. Re-generate in the same commit as an ARB edit.
- Urdu is included as a second locale specifically to keep RTL honest. Use
  `EdgeInsetsDirectional` and `AlignmentDirectional`, not `left`/`right`.
- Test with the longest translation you have; German and Urdu overflow layouts
  that English fits comfortably.
