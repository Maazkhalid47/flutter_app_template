# views/

## Why it exists

The screens. A view renders whatever its view model reports and forwards user
input back to it — nothing else.

## Structure

One folder per feature, one file per screen:

```
views/
  splash/     splash_view.dart
  auth/       login_view.dart, sign_up_view.dart, forgot_password_view.dart
  home/       home_view.dart
  articles/   article_list_view.dart, article_detail_view.dart
  settings/   settings_view.dart
  error/      not_found_view.dart
```

`onboarding/` sits at the top level instead, because it owns a repository and a
view model as well as its screen.

## What belongs in a view

- Layout and widget composition.
- Controllers that are genuinely UI-owned: `TextEditingController`,
  `ScrollController`, `PageController`, `FocusNode`.
- Calls into the view model, and navigation.

## What does NOT belong in a view

- `try/catch`, HTTP calls, or repository access (`ArticleDetailView` reads a
  repository through Provider because it has no view model — that is the one
  documented exception, and it still never catches).
- Business rules or validation logic (→ `validators/`, `viewmodels/`).
- Hardcoded colours, sizes or strings.

## Naming conventions

- Type: `<Feature>View`. File: `<feature>_view.dart`.
- Private sub-widgets in the same file are prefixed with `_`
  (`_ArticleBody`, `_PageIndicator`). Promote to `components/` when reused.

## Example usage

```dart
class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileViewModel>();

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.profileTitle)),
      body: StateView(
        viewModel: viewModel,
        onRetry: viewModel.load,
        builder: (context) => ProfileBody(profile: viewModel.profile!),
      ),
    );
  }
}
```

## Best practices

- Wrap the body in `StateView` — it makes forgetting the empty or error state a
  compile error rather than a support ticket.
- `context.watch` in `build`, `context.read` in callbacks, `context.select` when
  you only care about one field. Using `watch` in a callback rebuilds for
  nothing; using `read` in `build` means the UI never updates.
- After every `await` in a widget, `if (!mounted) return;`.
- Dispose every controller you create.
- Never navigate on auth changes from a view — the route guard owns that.
