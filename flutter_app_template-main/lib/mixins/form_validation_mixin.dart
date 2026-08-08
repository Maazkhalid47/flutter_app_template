import 'package:flutter/widgets.dart';

import '../constants/app_constants.dart';
import '../generated/l10n/app_localizations.dart';
import '../validators/validation_error.dart';

/// Turns a [ValidationError] into localized copy.
///
/// This is the bridge between the pure rules in `validators/` and the UI: the
/// rule says *what* is wrong, this says it in the user's language.
extension ValidationErrorX on ValidationError {
  String localize(AppLocalizations l10n) => switch (this) {
    ValidationError.required => l10n.validationRequired,
    ValidationError.invalidEmail => l10n.validationEmail,
    ValidationError.passwordTooShort => l10n.validationPasswordShort(
      AppConstants.minPasswordLength,
    ),
    // Extend the ARB file and add cases here as you add rules. Until then
    // the generic message is accurate, just not specific.
    ValidationError.passwordsDoNotMatch ||
    ValidationError.invalidPhone ||
    ValidationError.invalidUrl ||
    ValidationError.tooShort ||
    ValidationError.tooLong ||
    ValidationError.notANumber ||
    ValidationError.outOfRange => l10n.errorGeneric,
  };
}

/// Adds form plumbing to a [State] class.
///
/// Handles the two things every form needs and everyone re-implements: a
/// [GlobalKey] for the form and an autovalidate mode that stays quiet until the
/// user has tried once — validating on first keystroke is hostile.
///
/// ```dart
/// class _LoginViewState extends State<LoginView> with FormValidationMixin {
///   void _submit() {
///     if (!validateForm()) return;
///     context.read<AuthViewModel>().signIn(...);
///   }
/// }
/// ```
mixin FormValidationMixin<T extends StatefulWidget> on State<T> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  AutovalidateMode get autovalidateMode => _autovalidateMode;

  /// Validates the form. After the first failed attempt, switches to live
  /// validation so the user sees errors clear as they fix them.
  bool validateForm() {
    final isValid = formKey.currentState?.validate() ?? false;
    if (!isValid && _autovalidateMode == AutovalidateMode.disabled) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
    }
    return isValid;
  }

  /// Adapts a pure rule into the `String?` signature `TextFormField` expects.
  ///
  /// ```dart
  /// validator: fieldValidator(Validators.email),
  /// ```
  String? Function(String?) fieldValidator(
    ValidationError? Function(String?) rule,
  ) =>
      (value) => rule(value)?.localize(AppLocalizations.of(context));

  /// Resets both the fields and the autovalidate state.
  void resetForm() {
    formKey.currentState?.reset();
    setState(() => _autovalidateMode = AutovalidateMode.disabled);
  }
}
