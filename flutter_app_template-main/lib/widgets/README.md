# widgets/

## Why it exists

Generic, app-agnostic UI building blocks. A widget here could be lifted into a
different app unchanged — it knows nothing about your domain.

## widgets/ vs components/

| | `widgets/` | `components/` |
| --- | --- | --- |
| Knows your models | No | Yes |
| Example | `AppButton`, `AppTextField` | `ArticleCard`, `StateView` |
| Portable to another app | Yes | No |
| Depends on | theme + constants only | models, view models, widgets |

The test: if the file imports anything from `models/` or `viewmodels/`, it is a
component, not a widget.

## What belongs here

| File | Provides |
| --- | --- |
| `app_button.dart` | Four variants, built-in loading state, double-tap guard |
| `app_text_field.dart` | Styled input with `.email()` and `.password()` presets |
| `app_loader.dart` | `AppLoader`, `AppLoadingOverlay` |
| `app_error_view.dart` | `AppErrorView`, `AppEmptyView` |

## Naming conventions

- Prefix with `App` so it is obvious at a glance which button you are using:
  `AppButton`, not `PrimaryButton`.
- Variants as named constructors (`AppButton.secondary`) or factories
  (`AppTextField.email`), not as boolean flags.
- File name matches the primary type.

## Example usage

```dart
AppButton(
  label: context.l10n.authLoginButton,
  isLoading: viewModel.isBusy,
  onPressed: _submit,
);

AppTextField.password(
  controller: _passwordController,
  label: context.l10n.authPasswordLabel,
  obscureText: viewModel.obscurePassword,
  onToggleObscure: viewModel.togglePasswordVisibility,
  validator: fieldValidator(Validators.password),
);
```

## Best practices

- `const` constructors wherever possible — that is what lets Flutter skip
  rebuilding the subtree.
- Take data and callbacks; never reach into a provider from inside a widget
  here. It stops being reusable the moment it does.
- Read colours and text from `context`, never from `AppColors` directly.
- Give every icon-only control a `tooltip` and every image a semantic label.
- Widgets are where widget tests earn their keep — see
  `test/widgets/app_button_test.dart`.
