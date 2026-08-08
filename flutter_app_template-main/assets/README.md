# assets/

## Why it exists

Bundled files — images, icons, and later fonts or JSON. Everything here ships
inside the app binary, so what you add has a direct cost in download size.

## Structure

```
assets/
  images/    illustrations, logos, placeholders
  icons/     small square marks (brand icons for social sign-in, etc.)
```

Both folders are declared in `pubspec.yaml` as directories, so adding a file
needs no pubspec edit — only a constant.

## Adding an asset

1. Drop the file into `assets/images/` or `assets/icons/`.
2. Add a constant to `lib/constants/asset_paths.dart`.
3. Reference the constant, never the raw string.

```dart
Image.asset(AssetPaths.logo);
```

A misspelled string fails at runtime, in front of a user. A misspelled constant
fails at compile time.

## Naming conventions

- `snake_case` file names: `onboarding_1.png`, `empty_state.png`.
- Resolution variants go in `2.0x/` and `3.0x/` subfolders with the *same*
  file name — Flutter picks the right one automatically.

## Best practices

- Prefer SVG-derived or vector-first artwork where you can; otherwise ship
  `2.0x` and `3.0x` variants so images are not blurry on modern screens.
- Compress before committing. A 2 MB PNG is 2 MB in every install, forever.
- Always give a decorative image `excludeFromSemantics: true`, and a meaningful
  one a `semanticLabel`.
- Provide an `errorBuilder` for anything that might be missing — the onboarding
  screens do this so the flow is presentable before the artwork exists.
- Do not put user-generated or downloaded content here; that belongs in the
  cache or the file system at runtime.
