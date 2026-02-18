import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../services/widget_sync_service.dart';

class ThemeController extends ChangeNotifier {
  static const _themeKey = 'is_dark_mode';

  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> load() async {
    final raw = AppDatabase.settingsBox.get(_themeKey, defaultValue: false);
    _isDarkMode = raw is bool
        ? raw
        : raw is String
        ? raw.toLowerCase() == 'true'
        : false;
    await WidgetSyncService.refreshTodayTasks();
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await AppDatabase.settingsBox.put(_themeKey, _isDarkMode);
    await WidgetSyncService.refreshTodayTasks();
    notifyListeners();
  }
}
