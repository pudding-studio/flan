import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ChatViewMode { novel, conversation, combination }

class ViewerSettingsProvider extends ChangeNotifier {
  static const String _fontSizeKey = 'viewer_font_size';
  static const String _lineHeightKey = 'viewer_line_height';
  static const String _paragraphSpacingKey = 'viewer_paragraph_spacing';
  static const String _paragraphWidthKey = 'viewer_paragraph_width';
  static const String _textAlignKey = 'viewer_text_align';
  static const String _viewModeKey = 'viewer_view_mode';

  double _fontSize = 14.0;
  double _lineHeight = 1.4;
  double _paragraphSpacing = 8.0;
  double _paragraphWidth = 0.0;
  bool _isJustified = false;
  ChatViewMode _viewMode = ChatViewMode.novel;

  double get fontSize => _fontSize;
  double get lineHeight => _lineHeight;
  double get paragraphSpacing => _paragraphSpacing;
  double get paragraphWidth => _paragraphWidth;
  bool get isJustified => _isJustified;
  TextAlign get textAlign => _isJustified ? TextAlign.justify : TextAlign.left;
  ChatViewMode get viewMode => _viewMode;

  ViewerSettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSize = prefs.getDouble(_fontSizeKey) ?? 14.0;
    _lineHeight = prefs.getDouble(_lineHeightKey) ?? 1.4;
    _paragraphSpacing = prefs.getDouble(_paragraphSpacingKey) ?? 8.0;
    _paragraphWidth = prefs.getDouble(_paragraphWidthKey) ?? 0.0;
    _isJustified = prefs.getBool(_textAlignKey) ?? false;
    final storedMode = prefs.getString(_viewModeKey);
    _viewMode = ChatViewMode.values.firstWhere(
      (m) => m.name == storedMode,
      orElse: () => ChatViewMode.novel,
    );
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, _fontSize);
    await prefs.setDouble(_lineHeightKey, _lineHeight);
    await prefs.setDouble(_paragraphSpacingKey, _paragraphSpacing);
    await prefs.setDouble(_paragraphWidthKey, _paragraphWidth);
    await prefs.setBool(_textAlignKey, _isJustified);
    await prefs.setString(_viewModeKey, _viewMode.name);
  }

  void adjustFontSize(double delta) {
    _fontSize = (_fontSize + delta).clamp(10.0, 24.0);
    notifyListeners();
    _save();
  }

  void adjustLineHeight(double delta) {
    _lineHeight = double.parse(((_lineHeight + delta).clamp(1.0, 3.0)).toStringAsFixed(1));
    notifyListeners();
    _save();
  }

  void adjustParagraphSpacing(double delta) {
    _paragraphSpacing = (_paragraphSpacing + delta).clamp(0.0, 32.0);
    notifyListeners();
    _save();
  }

  void adjustParagraphWidth(double delta) {
    _paragraphWidth = (_paragraphWidth + delta).clamp(0.0, 40.0);
    notifyListeners();
    _save();
  }

  void toggleTextAlign() {
    _isJustified = !_isJustified;
    notifyListeners();
    _save();
  }

  void setViewMode(ChatViewMode mode) {
    if (_viewMode == mode) return;
    _viewMode = mode;
    notifyListeners();
    _save();
  }
}
