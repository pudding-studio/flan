import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MessageSendKeyProvider extends ChangeNotifier {
  static const String _enterKey = 'message_send_on_enter';
  static const String _shiftEnterKey = 'message_send_on_shift_enter';

  bool _sendOnEnter = false;
  bool _sendOnShiftEnter = true;

  bool get sendOnEnter => _sendOnEnter;
  bool get sendOnShiftEnter => _sendOnShiftEnter;

  MessageSendKeyProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _sendOnEnter = prefs.getBool(_enterKey) ?? false;
    _sendOnShiftEnter = prefs.getBool(_shiftEnterKey) ?? true;
    notifyListeners();
  }

  Future<void> setSendOnEnter(bool value) async {
    if (_sendOnEnter == value) return;
    _sendOnEnter = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enterKey, value);
  }

  Future<void> setSendOnShiftEnter(bool value) async {
    if (_sendOnShiftEnter == value) return;
    _sendOnShiftEnter = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_shiftEnterKey, value);
  }
}
