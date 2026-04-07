import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat/chat_model.dart';
import '../models/chat/custom_model.dart';
import '../models/chat/custom_provider.dart';
import '../models/chat/unified_model.dart';

class ChatModelSettingsProvider extends ChangeNotifier {
  static const String _providerKey = 'chat_model_provider';
  static const String _modelKey = 'chat_model';
  static const String _customProviderIdKey = 'chat_model_custom_provider_id';

  static const String _subProviderKey = 'sub_model_provider';
  static const String _subModelKey = 'sub_model';
  static const String _subCustomProviderIdKey = 'sub_model_custom_provider_id';

  ChatModelProvider _selectedProvider = ChatModelProvider.googleAIStudio;
  String? _selectedCustomProviderId;
  UnifiedModel _selectedModel =
      UnifiedModel.fromChatModel(ChatModel.geminiPro31Preview);

  ChatModelProvider _subProvider = ChatModelProvider.googleAIStudio;
  String? _subCustomProviderId;
  UnifiedModel _subModel =
      UnifiedModel.fromChatModel(ChatModel.geminiFlash25);

  List<CustomModel> _customModels = [];
  List<CustomProvider> _customProviders = [];

  final Completer<void> _initCompleter = Completer<void>();
  Future<void> get initialized => _initCompleter.future;

  ChatModelProvider get selectedProvider => _selectedProvider;
  String? get selectedCustomProviderId => _selectedCustomProviderId;
  UnifiedModel get selectedModel => _selectedModel;

  ChatModelProvider get subProvider => _subProvider;
  String? get subCustomProviderId => _subCustomProviderId;
  UnifiedModel get subModel => _subModel;

  List<CustomModel> get customModels => _customModels;
  List<CustomProvider> get customProviders => _customProviders;

  /// Returns "{provider name} > {model name}" for the primary model.
  String get primaryModelLabel {
    final providerName = _selectedProvider == ChatModelProvider.custom &&
            _selectedCustomProviderId != null
        ? _customProviders
                .where((p) => p.id == _selectedCustomProviderId)
                .firstOrNull
                ?.name ??
            'Custom'
        : _selectedProvider.displayName;
    return '$providerName > ${_selectedModel.displayName}';
  }

  /// Returns "{provider name} > {model name}" for the secondary model.
  String get subModelLabel {
    final providerName = _subProvider == ChatModelProvider.custom &&
            _subCustomProviderId != null
        ? _customProviders
                .where((p) => p.id == _subCustomProviderId)
                .firstOrNull
                ?.name ??
            'Custom'
        : _subProvider.displayName;
    return '$providerName > ${_subModel.displayName}';
  }

  List<UnifiedModel> get availableModels {
    if (_selectedProvider == ChatModelProvider.custom &&
        _selectedCustomProviderId != null) {
      return UnifiedModel.getByCustomProvider(
          _selectedCustomProviderId!, _customModels, _customProviders);
    }
    return UnifiedModel.getByProvider(
        _selectedProvider, _customModels, _customProviders);
  }

  List<UnifiedModel> get availableSubModels {
    if (_subProvider == ChatModelProvider.custom &&
        _subCustomProviderId != null) {
      return UnifiedModel.getByCustomProvider(
          _subCustomProviderId!, _customModels, _customProviders);
    }
    return UnifiedModel.getByProvider(
        _subProvider, _customModels, _customProviders);
  }

  ChatModelSettingsProvider() {
    _loadSettings().then((_) {
      if (!_initCompleter.isCompleted) _initCompleter.complete();
    }).catchError((e) {
      if (!_initCompleter.isCompleted) _initCompleter.complete();
    });
  }

  void _refreshSelectedModels() {
    _selectedModel = _resolveModel(_selectedModel.id);
    _subModel = _resolveModel(_subModel.id);
  }

  UnifiedModel _resolveModel(String modelString) {
    if (modelString.startsWith('custom:')) {
      final customId = modelString.substring(7);
      final custom = _customModels.where((m) => m.id == customId);
      if (custom.isNotEmpty) {
        final cp = custom.first.providerId != null
            ? _customProviders
                .where((p) => p.id == custom.first.providerId)
                .firstOrNull
            : null;
        return UnifiedModel.fromCustomModel(custom.first, provider: cp);
      }
    } else {
      final builtIn = ChatModel.values.where((m) => m.name == modelString);
      if (builtIn.isNotEmpty) {
        return UnifiedModel.fromChatModel(builtIn.first);
      }
    }
    return UnifiedModel.fromChatModel(ChatModel.geminiPro31Preview);
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
        orElse: () => ChatModelProvider.googleAIStudio,
      );
    }

    if (_selectedProvider == ChatModelProvider.custom) {
      _selectedCustomProviderId = prefs.getString(_customProviderIdKey);
    }

    if (modelString != null) {
      _selectedModel = _resolveModel(modelString);
    }

    // Load sub model settings
    final subProviderString = prefs.getString(_subProviderKey);
    final subModelString = prefs.getString(_subModelKey);

    if (subProviderString != null) {
      _subProvider = ChatModelProvider.values.firstWhere(
        (p) => p.name == subProviderString,
        orElse: () => ChatModelProvider.googleAIStudio,
      );
    }

    if (_subProvider == ChatModelProvider.custom) {
      _subCustomProviderId = prefs.getString(_subCustomProviderIdKey);
    }

    if (subModelString != null) {
      _subModel = _resolveModel(subModelString);
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
    _selectedCustomProviderId = null;

    final models =
        UnifiedModel.getByProvider(provider, _customModels, _customProviders);
    if (!models.contains(_selectedModel) && models.isNotEmpty) {
      _selectedModel = models.first;
    }

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_providerKey, provider.name);
    await prefs.remove(_customProviderIdKey);
    await prefs.setString(_modelKey, _selectedModel.id);
  }

  Future<void> setCustomProviderSelection(String customProviderId) async {
    _selectedProvider = ChatModelProvider.custom;
    _selectedCustomProviderId = customProviderId;

    final models = UnifiedModel.getByCustomProvider(
        customProviderId, _customModels, _customProviders);
    if (!models.contains(_selectedModel) && models.isNotEmpty) {
      _selectedModel = models.first;
    }

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_providerKey, ChatModelProvider.custom.name);
    await prefs.setString(_customProviderIdKey, customProviderId);
    await prefs.setString(_modelKey, _selectedModel.id);
  }

  Future<void> setModel(UnifiedModel model) async {
    _selectedModel = model;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelKey, model.id);
  }

  String getModelId() => _selectedModel.modelId;

  Future<void> setSubProvider(ChatModelProvider provider) async {
    _subProvider = provider;
    _subCustomProviderId = null;

    final models =
        UnifiedModel.getByProvider(provider, _customModels, _customProviders);
    if (!models.contains(_subModel) && models.isNotEmpty) {
      _subModel = models.first;
    }

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subProviderKey, provider.name);
    await prefs.remove(_subCustomProviderIdKey);
    await prefs.setString(_subModelKey, _subModel.id);
  }

  Future<void> setSubCustomProviderSelection(String customProviderId) async {
    _subProvider = ChatModelProvider.custom;
    _subCustomProviderId = customProviderId;

    final models = UnifiedModel.getByCustomProvider(
        customProviderId, _customModels, _customProviders);
    if (!models.contains(_subModel) && models.isNotEmpty) {
      _subModel = models.first;
    }

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subProviderKey, ChatModelProvider.custom.name);
    await prefs.setString(_subCustomProviderIdKey, customProviderId);
    await prefs.setString(_subModelKey, _subModel.id);
  }

  Future<void> setSubModel(UnifiedModel model) async {
    _subModel = model;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subModelKey, model.id);
  }

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
    _refreshSelectedModels();
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
