/// Date arithmetic and comparison helpers.
///
/// Formatting lives in `utils/formatters.dart` — this file only answers
/// questions about dates, it never turns one into display text.
extension DateTimeX on DateTime {
  /// Midnight of the same day, in local time.
  DateTime get startOfDay => DateTime(year, month, day);

  /// The last representable instant of the same day.
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  bool isSameDayAs(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  bool get isToday => isSameDayAs(DateTime.now());

  bool get isYesterday =>
      isSameDayAs(DateTime.now().subtract(const Duration(days: 1)));

  bool get isTomorrow =>
      isSameDayAs(DateTime.now().add(const Duration(days: 1)));

  bool get isPast => isBefore(DateTime.now());

  bool get isFuture => isAfter(DateTime.now());

  /// Whole years elapsed since this date — the correct way to compute an age
  /// (dividing days by 365 drifts).
  int get yearsSince {
    final now = DateTime.now();
    var years = now.year - year;
    final hadBirthdayThisYear =
        now.month > month || (now.month == month && now.day >= day);
    if (!hadBirthdayThisYear) years--;
    return years;
  }

  /// True when the instant is older than [duration] — the freshness check the
  /// cache layer uses.
  bool isOlderThan(Duration duration) =>
      DateTime.now().difference(this) > duration;

  /// ISO-8601 in UTC. The only format that should ever go over the wire.
  String get toIsoUtc => toUtc().toIso8601String();
}
