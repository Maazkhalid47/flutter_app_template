import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../constants/storage_keys.dart';
import '../generated/l10n/app_localizations.dart';
import '../storage/key_value_store.dart';

/// Owns the app's language.
///
/// `null` means "follow the device", which is the right default — an app that
/// forces English on a device set to Urdu is a bug, not a preference.
///
/// Changing the locale also updates the API client's `Accept-Language`, so
/// server-generated messages arrive in the same language as the UI.
class LocaleProvider extends ChangeNotifier {
  LocaleProvider({required KeyValueStore store, required ApiClient apiClient})
    : _store = store,
      _apiClient = apiClient;

  final KeyValueStore _store;
  final ApiClient _apiClient;

  Locale? _locale;

  /// `null` = follow the system locale.
  Locale? get locale => _locale;

  /// The locales this app actually ships, from the generated l10n class.
  List<Locale> get supportedLocales => AppLocalizations.supportedLocales;

  bool get isSystemLocale => _locale == null;

  Future<void> load() async {
    final code = await _store.readString(StorageKeys.localeCode);
    if (code != null && code.isNotEmpty) {
      _locale = Locale(code);
      _apiClient.setLanguage(code);
    }
    notifyListeners();
  }

  /// Sets the language. Pass `null` to go back to the device setting.
  Future<void> setLocale(Locale? locale) async {
    if (_locale == locale) return;
    // Guard against a locale the app has no translations for — Flutter would
    // silently fall back and the preference would be a lie.
    if (locale != null && !_isSupported(locale)) return;

    _locale = locale;
    notifyListeners();

    if (locale == null) {
      await _store.delete(StorageKeys.localeCode);
    } else {
      await _store.writeString(StorageKeys.localeCode, locale.languageCode);
      _apiClient.setLanguage(locale.languageCode);
    }
  }

  bool _isSupported(Locale locale) => supportedLocales.any(
    (supported) => supported.languageCode == locale.languageCode,
  );
}
