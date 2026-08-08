import '../constants/app_constants.dart';
import '../extensions/string_extensions.dart';
import 'validation_error.dart';

/// Pure, locale-independent input rules.
///
/// Every function returns `null` when the value is acceptable, or the
/// [ValidationError] that describes the problem. Because nothing here touches
/// Flutter, these are the cheapest things in the codebase to unit-test — and
/// the same rule is reused by forms, view models and API request builders.
abstract final class Validators {
  /// Deliberately permissive: it rejects obvious typos without rejecting valid
  /// but unusual addresses. Real verification is a confirmation email.
  static final RegExp _emailPattern = RegExp(
    r'^[\w.!#$%&*+/=?^`{|}~-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$',
  );

  /// E.164-ish: optional +, 7–15 digits, separators tolerated.
  static final RegExp _phonePattern = RegExp(r'^\+?[\d\s()-]{7,20}$');

  static ValidationError? required(String? value) =>
      value.isNullOrBlank ? ValidationError.required : null;

  static ValidationError? email(String? value) {
    final missing = required(value);
    if (missing != null) return missing;
    return _emailPattern.hasMatch(value!.trim())
        ? null
        : ValidationError.invalidEmail;
  }

  /// Length-only by design. Composition rules (symbols, digits) frustrate users
  /// more than they help; enforce strength server-side if you need it.
  static ValidationError? password(
    String? value, {
    int minLength = AppConstants.minPasswordLength,
  }) {
    final missing = required(value);
    if (missing != null) return missing;
    return value!.length < minLength ? ValidationError.passwordTooShort : null;
  }

  static ValidationError? confirmPassword(String? value, String? original) {
    final missing = required(value);
    if (missing != null) return missing;
    return value == original ? null : ValidationError.passwordsDoNotMatch;
  }

  static ValidationError? phone(String? value) {
    final missing = required(value);
    if (missing != null) return missing;
    final digits = value!.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7 || digits.length > 15) {
      return ValidationError.invalidPhone;
    }
    return _phonePattern.hasMatch(value.trim())
        ? null
        : ValidationError.invalidPhone;
  }

  static ValidationError? url(String? value) {
    final missing = required(value);
    if (missing != null) return missing;
    final uri = Uri.tryParse(value!.trim());
    final isValid = uri != null && uri.hasScheme && uri.host.isNotEmpty;
    return isValid ? null : ValidationError.invalidUrl;
  }

  static ValidationError? minLength(String? value, int min) {
    final missing = required(value);
    if (missing != null) return missing;
    return value!.trim().length < min ? ValidationError.tooShort : null;
  }

  static ValidationError? maxLength(String? value, int max) {
    if (value == null) return null;
    return value.trim().length > max ? ValidationError.tooLong : null;
  }

  static ValidationError? numeric(String? value) {
    final missing = required(value);
    if (missing != null) return missing;
    return num.tryParse(value!.trim()) == null
        ? ValidationError.notANumber
        : null;
  }

  static ValidationError? range(String? value, {num? min, num? max}) {
    final notNumeric = numeric(value);
    if (notNumeric != null) return notNumeric;
    final parsed = num.parse(value!.trim());
    if (min != null && parsed < min) return ValidationError.outOfRange;
    if (max != null && parsed > max) return ValidationError.outOfRange;
    return null;
  }

  /// Runs rules in order and returns the first failure.
  ///
  /// ```dart
  /// Validators.combine(value, [Validators.required, Validators.email]);
  /// ```
  static ValidationError? combine(
    String? value,
    List<ValidationError? Function(String?)> rules,
  ) {
    for (final rule in rules) {
      final error = rule(value);
      if (error != null) return error;
    }
    return null;
  }
}
