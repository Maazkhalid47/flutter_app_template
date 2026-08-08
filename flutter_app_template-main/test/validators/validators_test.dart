import 'package:flutter_app_template/validators/validation_error.dart';
import 'package:flutter_app_template/validators/validators.dart';
import 'package:flutter_test/flutter_test.dart';

/// Validators are pure functions, so they need no widget tree and no mocks —
/// which is exactly why input rules belong in `validators/` rather than inline
/// in a form.
void main() {
  group('Validators.required', () {
    test('rejects null, empty and whitespace-only values', () {
      expect(Validators.required(null), ValidationError.required);
      expect(Validators.required(''), ValidationError.required);
      expect(Validators.required('   '), ValidationError.required);
    });

    test('accepts any non-blank value', () {
      expect(Validators.required('a'), isNull);
    });
  });

  group('Validators.email', () {
    test('accepts ordinary addresses', () {
      for (final email in [
        'user@example.com',
        'first.last@sub.example.co.uk',
        'user+tag@example.io',
      ]) {
        expect(Validators.email(email), isNull, reason: email);
      }
    });

    test('rejects malformed addresses', () {
      for (final email in [
        'plainstring',
        'no-at-sign.com',
        'user@',
        '@example.com',
        'user@example',
        'user @example.com',
      ]) {
        expect(
          Validators.email(email),
          ValidationError.invalidEmail,
          reason: email,
        );
      }
    });

    test('reports a blank value as required, not as invalid', () {
      // The distinction matters: "this field is required" is a better message
      // than "enter a valid email" for an untouched field.
      expect(Validators.email(''), ValidationError.required);
    });
  });

  group('Validators.password', () {
    test('enforces the minimum length', () {
      expect(Validators.password('short'), ValidationError.passwordTooShort);
      expect(Validators.password('longenough1'), isNull);
    });

    test('honours a custom minimum', () {
      expect(Validators.password('abcd', minLength: 4), isNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('fails when the values differ', () {
      expect(
        Validators.confirmPassword('abc12345', 'abc12346'),
        ValidationError.passwordsDoNotMatch,
      );
    });

    test('passes when they match', () {
      expect(Validators.confirmPassword('abc12345', 'abc12345'), isNull);
    });
  });

  group('Validators.combine', () {
    test('returns the first failure and stops', () {
      final error = Validators.combine('', [
        Validators.required,
        Validators.email,
      ]);
      expect(error, ValidationError.required);
    });

    test('returns null when every rule passes', () {
      final error = Validators.combine('user@example.com', [
        Validators.required,
        Validators.email,
      ]);
      expect(error, isNull);
    });
  });

  group('Validators.range', () {
    test('rejects non-numeric input before checking bounds', () {
      expect(Validators.range('abc', min: 1), ValidationError.notANumber);
    });

    test('enforces both bounds', () {
      expect(Validators.range('5', min: 10), ValidationError.outOfRange);
      expect(Validators.range('50', max: 10), ValidationError.outOfRange);
      expect(Validators.range('5', min: 1, max: 10), isNull);
    });
  });
}
