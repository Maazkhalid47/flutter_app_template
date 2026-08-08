/// The reason a value failed validation, independent of language.
///
/// Validators return this rather than a display string so the same rule can be
/// unit-tested without a `BuildContext` and rendered in any locale. The UI
/// converts it to text with `ValidationErrorX.localize` from
/// `mixins/form_validation_mixin.dart`.
enum ValidationError {
  required,
  invalidEmail,
  passwordTooShort,
  passwordsDoNotMatch,
  invalidPhone,
  invalidUrl,
  tooShort,
  tooLong,
  notANumber,
  outOfRange,
}
