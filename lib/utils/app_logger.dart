import 'package:flutter/foundation.dart';

/// Minimal debug-only logger. Never prints in release builds and callers
/// must never pass tokens, Authorization headers, passwords, or other
/// secrets — see lib/network/RETRY.md for the logging rules the retry/auth
/// interceptors follow.
class AppLogger {
  AppLogger._();

  static void d(String message, {String tag = 'API'}) {
    if (kDebugMode) {
      debugPrint('[$tag] $message');
    }
  }

  static void w(String message, {String tag = 'API'}) {
    if (kDebugMode) {
      debugPrint('[$tag][WARN] $message');
    }
  }
}
