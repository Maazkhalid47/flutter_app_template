import 'package:intl/intl.dart';

/// Locale-aware display formatting.
///
/// Formatting belongs here, not in widgets and not in models: a model holds a
/// `DateTime`, the UI asks this class how to render it. Every method takes an
/// explicit [locale] so the output follows the user's chosen language rather
/// than the device default.
abstract final class Formatters {
  /// `12 Aug 2026`
  static String date(DateTime value, {String? locale}) =>
      DateFormat.yMMMd(locale).format(value.toLocal());

  /// `12 Aug 2026, 4:05 PM`
  static String dateTime(DateTime value, {String? locale}) =>
      DateFormat.yMMMd(locale).add_jm().format(value.toLocal());

  /// `4:05 PM`
  static String time(DateTime value, {String? locale}) =>
      DateFormat.jm(locale).format(value.toLocal());

  /// Compact relative time: `now`, `5m`, `3h`, `2d`, then an absolute date.
  ///
  /// Deliberately not localized into full sentences — feed the unit through
  /// ARB strings if you need "5 minutes ago" in every language.
  static String relative(DateTime value, {DateTime? now, String? locale}) {
    final reference = now ?? DateTime.now();
    final diff = reference.difference(value);
    if (diff.inSeconds.abs() < 60) return 'now';
    if (diff.inMinutes.abs() < 60) return '${diff.inMinutes.abs()}m';
    if (diff.inHours.abs() < 24) return '${diff.inHours.abs()}h';
    if (diff.inDays.abs() < 7) return '${diff.inDays.abs()}d';
    return date(value, locale: locale);
  }

  /// Formats a **minor-unit** amount (cents) as currency.
  ///
  /// Payment providers, Stripe included, deal in minor units. Keeping the
  /// conversion in one place is what stops a 100x pricing bug.
  static String currencyFromMinorUnits(
    int minorUnits, {
    String currencyCode = 'USD',
    String? locale,
    int decimalDigits = 2,
  }) {
    final format = NumberFormat.simpleCurrency(
      locale: locale,
      name: currencyCode,
      decimalDigits: decimalDigits,
    );
    return format.format(minorUnits / _pow10(decimalDigits));
  }

  /// `1.2K`, `3.4M` — for counters, not for money.
  static String compactNumber(num value, {String? locale}) =>
      NumberFormat.compact(locale: locale).format(value);

  /// `1,234` with locale-appropriate grouping.
  static String number(num value, {String? locale}) =>
      NumberFormat.decimalPattern(locale).format(value);

  /// `1.4 MB`
  static String fileSize(int bytes, {int decimals = 1}) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var size = bytes.toDouble();
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    return '${size.toStringAsFixed(unit == 0 ? 0 : decimals)} ${units[unit]}';
  }

  static num _pow10(int exponent) {
    var result = 1;
    for (var i = 0; i < exponent; i++) {
      result *= 10;
    }
    return result;
  }
}
