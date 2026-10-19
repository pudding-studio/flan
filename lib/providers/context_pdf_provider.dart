import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat/chat_model.dart';
import '../models/chat/unified_model.dart';

class ContextPdfProvider extends ChangeNotifier {
  static const String _enabledKey = 'gemini_context_pdf_enabled';

  bool _enabled = false;

  bool get enabled => _enabled;

  ContextPdfProvider() {
    _load();
  }

  /// Limited to Google-hosted Gemini (AI Studio and Gemini Enterprise):
  /// custom Gemini-format proxies may reject inline PDFs or the
  /// mediaResolution field that makes the PDF cheap.
  bool appliesTo(UnifiedModel model) =>
      _enabled &&
      (model.provider == ChatModelProvider.googleAIStudio ||
          model.provider == ChatModelProvider.vertexAi);

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
