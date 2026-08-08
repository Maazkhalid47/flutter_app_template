# validators/

## Why it exists

Input rules as pure functions, separated from their wording. A validator answers
*what is wrong*; the UI decides *how to say it*, in the user's language.

That separation is why these are the cheapest tests in the codebase — no
`BuildContext`, no widget tree, no mocks.

## What belongs here

| File | Purpose |
| --- | --- |
| `validation_error.dart` | The enum of failure reasons |
| `validators.dart` | The rules themselves |

Localization of the reason lives in `mixins/form_validation_mixin.dart`
(`ValidationErrorX.localize`), because it needs the generated `AppLocalizations`.

## Naming conventions

- One function per rule, named after the field or constraint: `email`,
  `password`, `minLength`, `range`.
- Signature is always `ValidationError? Function(String?)` so rules compose.
- Return `null` for valid — matching Flutter's own `FormFieldValidator`.

## Example usage

In a form:

```dart
AppTextField.email(
  controller: _emailController,
  label: context.l10n.authEmailLabel,
  validator: fieldValidator(Validators.email),
);
```

With a parameter:

```dart
validator: fieldValidator((v) => Validators.minLength(v, 3)),
```

Composing:

```dart
Validators.combine(value, [Validators.required, Validators.email]);
```

## Best practices

- Report a blank field as `required`, not as "invalid format" — the first is a
  far better message for an untouched field. Every rule here starts with a
  `required` check for that reason.
- Keep the email pattern permissive. Rejecting valid-but-unusual addresses is a
  worse failure than accepting a typo; real verification is a confirmation email.
- Password rules are length-only by design. Symbol/digit requirements frustrate
  users more than they help; enforce strength server-side if you need it.
- Validate on the server too. Client validation is a UX affordance, never a
  security control.
- Add a rule in three steps: a `ValidationError` value, the function, and a case
  in `ValidationErrorX.localize` with its ARB key.
