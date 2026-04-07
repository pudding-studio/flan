import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat/chat_model.dart';
import '../models/chat/custom_model.dart';
import '../models/chat/custom_provider.dart';
import '../models/chat/unified_model.dart';

class CommunityModelProvider extends ChangeNotifier {
  static const String _providerKey = 'community_selected_provider';
  static const String _modelIdKey = 'community_selected_model_id';

  ChatModelProvider _selectedProvider = ChatModelProvider.googleAIStudio;
  UnifiedModel _selectedModel = UnifiedModel.fromChatModel(ChatModel.geminiPro31Preview);
  List<CustomModel> _customModels = [];
  List<CustomProvider> _customProviders = [];
  late final Future<void> initialized;

  ChatModelProvider get selectedProvider => _selectedProvider;
  UnifiedModel get selectedModel => _selectedModel;

  List<UnifiedModel> get availableModels => UnifiedModel.getByProvider(
        _selectedProvider,
        _customModels,
        _customProviders,
      );

  CommunityModelProvider() {
    initialized = _load();
  }

  Future<void> _load() async {
    _customProviders = await CustomProviderRepository.loadAll();
    _customModels = await CustomModelRepository.loadAll();

    final prefs = await SharedPreferences.getInstance();

    final providerStr = prefs.getString(_providerKey);
    if (providerStr != null) {
      _selectedProvider = ChatModelProvider.values.firstWhere(
        (p) => p.name == providerStr,
        orElse: () => ChatModelProvider.googleAIStudio,
      );
    }

    final savedId = prefs.getString(_modelIdKey);
    if (savedId != null) {
      final match = availableModels.where((m) => m.id == savedId);
      if (match.isNotEmpty) _selectedModel = match.first;
    }

    notifyListeners();
  }

  Future<void> setProvider(ChatModelProvider provider) async {
    _selectedProvider = provider;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_providerKey, provider.name);
    // Reset model to first available for new provider
    final models = availableModels;
    if (models.isNotEmpty && !models.any((m) => m.id == _selectedModel.id)) {
      _selectedModel = models.first;
      await prefs.setString(_modelIdKey, _selectedModel.id);
    }
    notifyListeners();
  }

  Future<void> setModel(UnifiedModel model) async {
    _selectedModel = model;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelIdKey, model.id);
    notifyListeners();
  }
}
