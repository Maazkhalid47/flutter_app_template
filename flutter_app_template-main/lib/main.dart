import 'dart:async';

import 'package:flutter/material.dart';

import 'bootstrap.dart';
import 'dependency_injection/service_locator.dart';
import 'exceptions/global_error_handler.dart';

/// Application entry point.
///
/// Everything happens inside [runZonedGuarded] so that errors thrown outside
/// the widget tree — in a stray async callback, a stream with no error handler,
/// an isolate — are still reported instead of vanishing into the console.
/// `FlutterError.onError` and `PlatformDispatcher.onError` cover the other two
/// paths and are installed by [GlobalErrorHandler] during bootstrap.
///
/// Run it per environment:
/// ```
/// flutter run --dart-define=ENV=dev
/// flutter run --dart-define-from-file=env/staging.json
/// flutter build apk --release --dart-define-from-file=env/prod.json
/// ```
void main() {
  runZonedGuarded(
    () async {
      final app = await bootstrap();
      runApp(app);
    },
    (error, stackTrace) {
      // The locator may not exist yet if bootstrap itself failed, so this must
      // degrade gracefully rather than throw a second error.
      if (getIt.isRegistered<GlobalErrorHandler>()) {
        getIt<GlobalErrorHandler>().handle(
          error,
          stackTrace,
          context: 'runZonedGuarded',
          fatal: true,
        );
      } else {
        debugPrint(
          'Fatal error before bootstrap completed: $error\n$stackTrace',
        );
      }
    },
  );
}
