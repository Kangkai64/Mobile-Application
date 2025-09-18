import 'package:flutter/material.dart';
import '../utils/local_storage.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _keyThemeMode = 'settings_theme_mode'; // 'light' | 'dark' | 'system'
  static const String _keyNotifications = 'settings_notifications'; // 'true' | 'false'

  ThemeMode _themeMode = ThemeMode.system;
  bool _notificationsEnabled = true;

  ThemeMode get themeMode => _themeMode;
  bool get notificationsEnabled => _notificationsEnabled;

  Future<void> load() async {
    await LocalStorage.initialize();
    final String? theme = LocalStorage.getString(_keyThemeMode);
    final String? notif = LocalStorage.getString(_keyNotifications);
    _themeMode = _parseTheme(theme);
    _notificationsEnabled = notif == null ? true : (notif.toLowerCase() == 'true');
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    await LocalStorage.setString(_keyThemeMode, _themeToString(mode));
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    if (_notificationsEnabled == enabled) return;
    _notificationsEnabled = enabled;
    await LocalStorage.setString(_keyNotifications, enabled.toString());
    notifyListeners();
  }

  ThemeMode _parseTheme(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  String _themeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
      default:
        return 'system';
    }
  }
}


