import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundNotificationProvider extends ChangeNotifier {
  static const String _enabledKey = 'sound_notification_on_ai_reply';
  static const String _vibrationEnabledKey =
      'vibration_notification_on_ai_reply';

  bool _enabled = false;
  bool _vibrationEnabled = false;

  bool get enabled => _enabled;
  bool get vibrationEnabled => _vibrationEnabled;

  SoundNotificationProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_enabledKey) ?? false;
    _vibrationEnabled = prefs.getBool(_vibrationEnabledKey) ?? false;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
  }

  Future<void> setVibrationEnabled(bool value) async {
    if (_vibrationEnabled == value) return;
    _vibrationEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrationEnabledKey, value);
  }
}
