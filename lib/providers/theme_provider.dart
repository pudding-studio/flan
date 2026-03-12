import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeColor {
  orange(Color(0xFFFFBF3F), '기본'),
  blue(Color(0xFF2196F3), 'Blue'),
  purple(Color(0xFF9C27B0), 'Purple'),
  green(Color(0xFF4CAF50), 'Green'),
  pink(Color(0xFFE91E63), 'Pink'),
  red(Color(0xFFF44336), 'Red'),
  teal(Color(0xFF009688), 'Teal'),
  indigo(Color(0xFF3F51B5), 'Indigo');

  final Color color;
  final String displayName;

  const ThemeColor(this.color, this.displayName);
}

class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _themeColorKey = 'theme_color';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeColor _themeColor = ThemeColor.orange;

  ThemeMode get themeMode => _themeMode;
  ThemeColor get themeColor => _themeColor;
  Color get seedColor => _themeColor.color;

  ThemeProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final themeModeString = prefs.getString(_themeModeKey) ?? 'system';
    _themeMode = _themeModeFromString(themeModeString);

    final themeColorString = prefs.getString(_themeColorKey) ?? 'orange';
    _themeColor = _themeColorFromString(themeColorString);

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, _themeModeToString(mode));
  }

  Future<void> setThemeColor(ThemeColor color) async {
    _themeColor = color;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeColorKey, _themeColorToString(color));
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  ThemeMode _themeModeFromString(String modeString) {
    switch (modeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  String _themeColorToString(ThemeColor color) {
    return color.name;
  }

  ThemeColor _themeColorFromString(String colorString) {
    try {
      return ThemeColor.values.firstWhere((e) => e.name == colorString);
    } catch (_) {
      return ThemeColor.orange;
    }
  }
}
