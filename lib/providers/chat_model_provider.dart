import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat/chat_model.dart';

class ChatModelSettingsProvider extends ChangeNotifier {
  static const String _providerKey = 'chat_model_provider';
  static const String _modelKey = 'chat_model';

  ChatModelProvider _selectedProvider = ChatModelProvider.all;
  ChatModel _selectedModel = ChatModel.geminiPro3Preview;

  ChatModelProvider get selectedProvider => _selectedProvider;
  ChatModel get selectedModel => _selectedModel;

  ChatModelSettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final providerString = prefs.getString(_providerKey);
    final modelString = prefs.getString(_modelKey);

    if (providerString != null) {
      _selectedProvider = ChatModelProvider.values.firstWhere(
        (p) => p.name == providerString,
        orElse: () => ChatModelProvider.all,
      );
    }

    if (modelString != null) {
      _selectedModel = ChatModel.values.firstWhere(
        (m) => m.name == modelString,
        orElse: () => ChatModel.geminiPro3Preview,
      );
    }

    notifyListeners();
  }

  Future<void> setProvider(ChatModelProvider provider) async {
    _selectedProvider = provider;

    final availableModels = ChatModel.getModelsByProvider(provider);
    if (!availableModels.contains(_selectedModel)) {
      _selectedModel = availableModels.first;
    }

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_providerKey, provider.name);
    await prefs.setString(_modelKey, _selectedModel.name);
  }

  Future<void> setModel(ChatModel model) async {
    _selectedModel = model;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelKey, model.name);
  }

  String getModelId() {
    return _selectedModel.modelId;
  }
}
