import 'package:flutter/material.dart';

import '../data/app_database.dart';

class ThemeController extends ChangeNotifier {
  static const _themeKey = 'is_dark_mode';

  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> load() async {
    _isDarkMode =
        AppDatabase.settingsBox.get(_themeKey, defaultValue: false) as bool;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await AppDatabase.settingsBox.put(_themeKey, _isDarkMode);
    notifyListeners();
  }
}
