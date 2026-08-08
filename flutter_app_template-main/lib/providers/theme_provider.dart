import 'package:flutter/material.dart';

import '../constants/storage_keys.dart';
import '../storage/key_value_store.dart';

/// Owns the user's theme preference and persists it.
///
/// A provider rather than a view model: it is app-wide state with no screen of
/// its own, and it has no repository behind it. See `providers/README.md` for
/// where that line falls.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._store);

  final KeyValueStore _store;

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isSystem => _themeMode == ThemeMode.system;

  /// Reads the stored preference. Called during bootstrap so the first frame
  /// is already in the right theme — loading it later causes a visible flash.
  Future<void> load() async {
    final stored = await _store.readString(StorageKeys.themeMode);
    _themeMode = _parse(stored);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _store.writeString(StorageKeys.themeMode, mode.name);
  }

  /// Cycles system → light → dark → system, for a single toggle button.
  Future<void> cycle() => setThemeMode(switch (_themeMode) {
    ThemeMode.system => ThemeMode.light,
    ThemeMode.light => ThemeMode.dark,
    ThemeMode.dark => ThemeMode.system,
  });

  ThemeMode _parse(String? value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}
