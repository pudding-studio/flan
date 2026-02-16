import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat/chat_model.dart';
import '../models/chat/custom_model.dart';
import '../models/chat/unified_model.dart';

class ChatModelSettingsProvider extends ChangeNotifier {
  static const String _providerKey = 'chat_model_provider';
  static const String _modelKey = 'chat_model';

  ChatModelProvider _selectedProvider = ChatModelProvider.all;
  UnifiedModel _selectedModel =
      UnifiedModel.fromChatModel(ChatModel.geminiPro3Preview);
  List<CustomModel> _customModels = [];

  ChatModelProvider get selectedProvider => _selectedProvider;
  UnifiedModel get selectedModel => _selectedModel;
  List<CustomModel> get customModels => _customModels;

  List<UnifiedModel> get availableModels =>
      UnifiedModel.getByProvider(_selectedProvider, _customModels);

  ChatModelSettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _customModels = await CustomModelRepository.loadAll();

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
      if (modelString.startsWith('custom:')) {
        final customId = modelString.substring(7);
        final custom = _customModels.where((m) => m.id == customId);
        if (custom.isNotEmpty) {
          _selectedModel = UnifiedModel.fromCustomModel(custom.first);
        }
      } else {
        final builtIn = ChatModel.values.where((m) => m.name == modelString);
        if (builtIn.isNotEmpty) {
          _selectedModel = UnifiedModel.fromChatModel(builtIn.first);
        }
      }
    }

    notifyListeners();
  }

  Future<void> setProvider(ChatModelProvider provider) async {
    _selectedProvider = provider;

    final models = UnifiedModel.getByProvider(provider, _customModels);
    if (!models.contains(_selectedModel) && models.isNotEmpty) {
      _selectedModel = models.first;
    }

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_providerKey, provider.name);
    await prefs.setString(_modelKey, _selectedModel.id);
  }

  Future<void> setModel(UnifiedModel model) async {
    _selectedModel = model;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelKey, model.id);
  }

  String getModelId() => _selectedModel.modelId;

  Future<void> addCustomModel(CustomModel model) async {
    await CustomModelRepository.add(model);
    _customModels = await CustomModelRepository.loadAll();
    notifyListeners();
  }

  Future<void> updateCustomModel(CustomModel model) async {
    await CustomModelRepository.update(model);
    _customModels = await CustomModelRepository.loadAll();

    if (_selectedModel.isCustom &&
        _selectedModel.id == 'custom:${model.id}') {
      _selectedModel = UnifiedModel.fromCustomModel(model);
    }

    notifyListeners();
  }

  Future<void> deleteCustomModel(String id) async {
    if (_selectedModel.isCustom && _selectedModel.id == 'custom:$id') {
      _selectedModel = UnifiedModel.fromChatModel(ChatModel.geminiPro3Preview);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_modelKey, _selectedModel.id);
    }

    await CustomModelRepository.delete(id);
    _customModels = await CustomModelRepository.loadAll();
    notifyListeners();
  }
}
