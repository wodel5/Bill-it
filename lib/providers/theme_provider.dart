import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  final _storageKey = 'themeMode';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider() {
    loadTheme();
  }

  ThemeMode get themeMode => _themeMode;

  String get themeModeLabel {
    switch (_themeMode) {
      case ThemeMode.light:
        return '明亮模式';
      case ThemeMode.dark:
        return '黑暗模式';
      case ThemeMode.system:
        return '跟随系统';
    }
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_storageKey);
    if (value != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.name == value,
        orElse: () => ThemeMode.system,
      );
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, mode.name);
    notifyListeners();
  }

  void cycleTheme() {
    switch (_themeMode) {
      case ThemeMode.light:
        _themeMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        _themeMode = ThemeMode.system;
        break;
      case ThemeMode.system:
        _themeMode = ThemeMode.light;
        break;
    }
    _saveTheme();
    notifyListeners();
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, _themeMode.name);
  }
}
