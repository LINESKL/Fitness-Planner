import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Настройки приложения в SharedPreferences. Базовый сценарий — на Provider.
class SettingsModel extends ChangeNotifier {
  SettingsModel(this._prefs);

  /// Варианты отдыха в секундах; 0 — таймер выключен.
  static const restOptions = [0, 60, 90, 120, 180];

  static const _themeKey = 'theme_mode';
  static const _restKey = 'rest_seconds';

  final SharedPreferences _prefs;

  ThemeMode get themeMode =>
      ThemeMode.values.asNameMap()[_prefs.getString(_themeKey)] ??
      ThemeMode.system;

  int get restSeconds => _prefs.getInt(_restKey) ?? 90;

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(_themeKey, mode.name);
    notifyListeners();
  }

  Future<void> setRestSeconds(int seconds) async {
    await _prefs.setInt(_restKey, seconds);
    notifyListeners();
  }
}
