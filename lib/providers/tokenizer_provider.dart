import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TokenizerType {
  o200kBase('o200k_base', 'o200k_base (GPT-4o)'),
  o100kBase('o100k_base', 'o100k_base (GPT-4)'),
  p50kBase('p50k_base', 'p50k_base (GPT-3)'),
  cl100kBase('cl100k_base', 'cl100k_base (GPT-3.5)');

  final String id;
  final String displayName;

  const TokenizerType(this.id, this.displayName);
}

class TokenizerProvider extends ChangeNotifier {
  static const String _tokenizerKey = 'tokenizer_type';

  TokenizerType _selectedTokenizer = TokenizerType.o200kBase;

  TokenizerType get selectedTokenizer => _selectedTokenizer;

  TokenizerProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final tokenizerString = prefs.getString(_tokenizerKey);

    if (tokenizerString != null) {
      _selectedTokenizer = TokenizerType.values.firstWhere(
        (t) => t.id == tokenizerString,
        orElse: () => TokenizerType.o200kBase,
      );
    }

    notifyListeners();
  }

  Future<void> setTokenizer(TokenizerType tokenizer) async {
    _selectedTokenizer = tokenizer;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenizerKey, tokenizer.id);
  }

  String getTokenizerId() {
    return _selectedTokenizer.id;
  }
}
