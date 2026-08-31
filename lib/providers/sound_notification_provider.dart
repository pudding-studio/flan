import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundNotificationProvider extends ChangeNotifier {
  static const String _enabledKey = 'sound_notification_on_ai_reply';

  bool _enabled = false;

  bool get enabled => _enabled;

  SoundNotificationProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_enabledKey) ?? false;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
  }
}
