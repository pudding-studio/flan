import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat/chat_model.dart';
import '../models/chat/custom_model.dart';
import '../models/chat/custom_provider.dart';
import '../models/chat/unified_model.dart';

class ChatModelSettingsProvider extends ChangeNotifier {
  static const String _providerKey = 'chat_model_provider';
  static const String _modelKey = 'chat_model';

  ChatModelProvider _selectedProvider = ChatModelProvider.all;
  UnifiedModel _selectedModel =
      UnifiedModel.fromChatModel(ChatModel.geminiPro31Preview);
  List<CustomModel> _customModels = [];
  List<CustomProvider> _customProviders = [];

  ChatModelProvider get selectedProvider => _selectedProvider;
  UnifiedModel get selectedModel => _selectedModel;
  List<CustomModel> get customModels => _customModels;
  List<CustomProvider> get customProviders => _customProviders;

  List<UnifiedModel> get availableModels =>
      UnifiedModel.getByProvider(_selectedProvider, _customModels, _customProviders);

  ChatModelSettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _customProviders = await CustomProviderRepository.loadAll();
    _customModels = await CustomModelRepository.loadAll();
    await _migrateOrphanedModels();

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
          final cp = custom.first.providerId != null
              ? _customProviders
                  .where((p) => p.id == custom.first.providerId)
                  .firstOrNull
              : null;
          _selectedModel =
              UnifiedModel.fromCustomModel(custom.first, provider: cp);
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

  /// Migrate legacy custom models (no providerId) by grouping them
  /// into auto-created CustomProviders based on (baseUrl, apiKey, apiFormat).
  Future<void> _migrateOrphanedModels() async {
    final orphans = _customModels.where((m) => m.providerId == null).toList();
    if (orphans.isEmpty) return;

    final groups = <String, List<CustomModel>>{};
    for (final m in orphans) {
      final key = '${m.baseUrl}|${m.apiKey}|${m.apiFormat.name}';
      groups.putIfAbsent(key, () => []).add(m);
    }

    for (final entry in groups.entries) {
      final sample = entry.value.first;
      final host = Uri.tryParse(sample.baseUrl)?.host ?? sample.baseUrl;
      final provider = CustomProvider(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: host.isNotEmpty ? host : 'Custom',
        baseUrl: sample.baseUrl,
        apiKey: sample.apiKey,
        apiFormat: sample.apiFormat,
      );
      _customProviders.add(provider);

      for (final m in entry.value) {
        final index = _customModels.indexWhere((cm) => cm.id == m.id);
        if (index != -1) {
          _customModels[index] = m.copyWith(providerId: provider.id);
        }
      }
    }

    await CustomProviderRepository.saveAll(_customProviders);
    await CustomModelRepository.saveAll(_customModels);
  }

  Future<void> setProvider(ChatModelProvider provider) async {
    _selectedProvider = provider;

    final models =
        UnifiedModel.getByProvider(provider, _customModels, _customProviders);
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
      _selectedModel = UnifiedModel.fromChatModel(ChatModel.geminiPro31Preview);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_modelKey, _selectedModel.id);
    }

    await CustomModelRepository.delete(id);
    _customModels = await CustomModelRepository.loadAll();
    notifyListeners();
  }

  Future<void> addCustomProvider(CustomProvider provider) async {
    await CustomProviderRepository.add(provider);
    _customProviders = await CustomProviderRepository.loadAll();
    notifyListeners();
  }

  Future<void> updateCustomProvider(CustomProvider provider) async {
    await CustomProviderRepository.update(provider);
    _customProviders = await CustomProviderRepository.loadAll();
    notifyListeners();
  }

  Future<void> deleteCustomProvider(String id) async {
    // Reset selected model if it belongs to this provider
    final childIds = _customModels
        .where((m) => m.providerId == id)
        .map((m) => 'custom:${m.id}')
        .toSet();
    if (childIds.contains(_selectedModel.id)) {
      _selectedModel = UnifiedModel.fromChatModel(ChatModel.geminiPro31Preview);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_modelKey, _selectedModel.id);
    }

    // Delete all child models
    final remaining = _customModels.where((m) => m.providerId != id).toList();
    await CustomModelRepository.saveAll(remaining);
    _customModels = remaining;

    await CustomProviderRepository.delete(id);
    _customProviders = await CustomProviderRepository.loadAll();
    notifyListeners();
  }

  List<CustomModel> getModelsByProvider(String providerId) =>
      _customModels.where((m) => m.providerId == providerId).toList();
}
