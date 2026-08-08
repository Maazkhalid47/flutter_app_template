import 'package:flutter/widgets.dart';

import '../exceptions/app_exception.dart';
import '../generated/l10n/app_localizations.dart';

/// Turns an [AppException] into user-facing text.
///
/// `AppException.message` is written for developers and may contain server
/// internals — showing it to a user is both confusing and a small information
/// leak. Every exception carries a `messageKey` instead, and this is the only
/// place that maps keys to localized copy.
///
/// Adding a new key: add it to `lib/l10n/app_en.arb`, then add a case here.
abstract final class ExceptionMessageResolver {
  static String resolve(BuildContext context, AppException exception) =>
      resolveWith(AppLocalizations.of(context), exception);

  /// Context-free variant, for view models and tests.
  static String resolveWith(AppLocalizations l10n, AppException exception) =>
      switch (exception.messageKey) {
        'errorNetwork' => l10n.errorNetwork,
        'errorTimeout' => l10n.errorTimeout,
        'errorUnauthorized' => l10n.errorUnauthorized,
        'errorNotFound' => l10n.errorNotFound,
        'errorServer' => l10n.errorServer,
        _ => l10n.errorGeneric,
      };
}
