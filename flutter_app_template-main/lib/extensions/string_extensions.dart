/// String helpers used by validators, formatters and UI copy.
///
/// Keep these pure and side-effect free — they are unit-tested directly.
extension StringX on String {
  /// True when the string is empty or only whitespace.
  bool get isBlank => trim().isEmpty;

  bool get isNotBlank => !isBlank;

  /// `hello world` -> `Hello world`
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// `hello world` -> `Hello World`
  String get titleCased => split(
    ' ',
  ).map((word) => word.isEmpty ? word : word.capitalized).join(' ');

  /// First letters of the first two words: `Maaz Khalid` -> `MK`.
  /// Used for avatar fallbacks.
  String get initials {
    final words = trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return '';
    return words.take(2).map((w) => w[0].toUpperCase()).join();
  }

  /// Cuts the string to [max] characters, appending an ellipsis when cut.
  String truncate(int max, {String ellipsis = '…'}) =>
      length <= max ? this : '${substring(0, max).trimRight()}$ellipsis';

  /// Collapses runs of whitespace into single spaces.
  String get normalizedWhitespace => trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Masks all but the last [visible] characters. For displaying a stored card
  /// or token without revealing it.
  String masked({int visible = 4, String maskChar = '•'}) {
    if (length <= visible) return maskChar * length;
    return maskChar * (length - visible) + substring(length - visible);
  }

  /// `a@b.com` -> `a***@b.com`
  String get maskedEmail {
    final at = indexOf('@');
    if (at <= 1) return this;
    return '${substring(0, 1)}***${substring(at)}';
  }
}

/// Null-safe variants so callers do not need a null check first.
extension NullableStringX on String? {
  bool get isNullOrBlank => this == null || this!.isBlank;

  bool get isNotNullOrBlank => !isNullOrBlank;

  /// Returns [fallback] when the string is null or blank.
  String orDefault(String fallback) => isNullOrBlank ? fallback : this!;
}
