# theme/

## Why it exists

Every colour, text style and component default in one place, so dark mode works
without touching a widget and a rebrand is a two-file change.

## What belongs here

- `app_colors.dart` — the brand palette, both `ColorScheme`s, and
  `AppSemanticColors` (success/warning/info, which Material has no slot for).
- `app_typography.dart` — the type scale.
- `app_theme.dart` — `ThemeData` for light and dark, including component themes.

## What does NOT belong here

- Spacing, radii, durations, breakpoints (→ `constants/ui_constants.dart`).
  Those do not change with the theme.
- The user's current theme *preference* (→ `providers/theme_provider.dart`).

## Naming conventions

- Palette entries describe the brand, not the use: `brandPrimary`, not
  `loginButtonColor`.
- Semantic entries come in pairs: `success` / `onSuccess`.

## Example usage

```dart
// In a widget — always through the context, never AppColors directly:
Text('Hi', style: context.textTheme.titleMedium);
Container(color: context.colors.primaryContainer);
Icon(Icons.check, color: context.semanticColors.success);
```

Adding a semantic colour:

1. Add the `Color` pair to `AppSemanticColors` (both `light` and `dark`).
2. Extend `copyWith` and `lerp` — `lerp` is what animates a theme change.
3. Use it via `context.semanticColors`.

## Best practices

- Never write `Color(0xFF...)` outside this folder, and never `TextStyle(fontSize: 14)`
  in a widget. Both break dark mode and accessibility scaling.
- Prefer setting a component theme here over styling the same widget on ten
  screens.
- Both schemes come from `ColorScheme.fromSeed`, which produces contrast-checked
  pairs. If you hand-pick colours instead, verify the contrast ratios yourself.
- Test any new component theme in both light and dark before merging.
