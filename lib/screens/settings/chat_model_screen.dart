import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../models/chat/chat_model.dart';
import '../../models/chat/unified_model.dart';
import '../../providers/chat_model_provider.dart';
import '../../screens/settings/api_key_screen.dart';
import '../../services/ai_service.dart';
import '../../services/vertex_auth_service.dart';
import '../../utils/common_dialog.dart';
import '../../widgets/common/common_appbar.dart';
import '../../widgets/common/common_button.dart';
import '../../widgets/common/common_custom_text_field.dart';
import '../../widgets/common/common_title_medium.dart';
import 'custom_model_screen.dart';

class ChatModelScreen extends StatelessWidget {
  const ChatModelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: CommonAppBar(
          title: l10n.chatModelTitle,
          actions: [
            CommonAppBarIconButton(
              icon: Icons.add,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomModelScreen(),
                  ),
                );
              },
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.chatModelTabMain),
              Tab(text: l10n.chatModelTabSub),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ModelTab(isSubModel: false),
            _ModelTab(isSubModel: true),
          ],
        ),
      ),
    );
  }
}

class _ModelTab extends StatelessWidget {
  final bool isSubModel;
  const _ModelTab({required this.isSubModel});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Consumer<ChatModelSettingsProvider>(
      builder: (context, provider, child) {
        final currentProvider = isSubModel
            ? provider.subProvider
            : provider.selectedProvider;
        final currentCustomProviderId = isSubModel
            ? provider.subCustomProviderId
            : provider.selectedCustomProviderId;
        final currentModel = isSubModel
            ? provider.subModel
            : provider.selectedModel;
        final availableModels = isSubModel
            ? provider.availableSubModels
            : provider.availableModels;

        final dropdownItems = <DropdownMenuItem<String>>[];
        for (final p in ChatModelProvider.values) {
          if (p == ChatModelProvider.custom) continue;
          dropdownItems.add(DropdownMenuItem(
            value: p.name,
            child: Text(p.displayName),
          ));
        }
        for (final cp in provider.customProviders) {
          dropdownItems.add(DropdownMenuItem(
            value: 'custom:${cp.id}',
            child: Text(cp.name),
          ));
        }

        final selectedKey = currentProvider == ChatModelProvider.custom
            && currentCustomProviderId != null
            ? 'custom:$currentCustomProviderId'
            : currentProvider.name;

        // Determine API key type for current provider
        final apiKeyType = _getApiKeyType(currentProvider);

        return ListView(
          children: [
            if (isSubModel)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  l10n.chatModelSubInfo,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            _buildSectionHeader(context, l10n.chatModelProviderSection),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButton<String>(
                value: dropdownItems.any((i) => i.value == selectedKey)
                    ? selectedKey
                    : ChatModelProvider.googleAIStudio.name,
                isExpanded: true,
                underline: const SizedBox(),
                borderRadius: BorderRadius.circular(16),
                items: dropdownItems,
                onChanged: (value) {
                  if (value == null) return;
                  if (value.startsWith('custom:')) {
                    final cpId = value.substring(7);
                    if (isSubModel) {
                      provider.setSubCustomProviderSelection(cpId);
                    } else {
                      provider.setCustomProviderSelection(cpId);
                    }
                  } else {
                    final p = ChatModelProvider.values.firstWhere(
                      (e) => e.name == value,
                      orElse: () => ChatModelProvider.googleAIStudio,
                    );
                    if (isSubModel) {
                      provider.setSubProvider(p);
                    } else {
                      provider.setProvider(p);
                    }
                  }
                },
              ),
            ),
            const Divider(),
            _buildSectionHeader(context, l10n.chatModelUsedModelSection),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButton<UnifiedModel>(
                value: availableModels.contains(currentModel)
                    ? currentModel
                    : (availableModels.isNotEmpty ? availableModels.first : null),
                isExpanded: true,
                underline: const SizedBox(),
                borderRadius: BorderRadius.circular(16),
                items: availableModels
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(
                            m.displayName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    if (isSubModel) {
                      provider.setSubModel(value);
                    } else {
                      provider.setModel(value);
                    }
                  }
                },
              ),
            ),
            if (currentModel.isCustom) ...[
              const Divider(),
              _buildSectionHeader(context, l10n.chatModelInfoSection),
              _buildInfoTile(context, 'API', currentModel.apiFormat.displayName),
              if (currentModel.baseUrl != null)
                _buildInfoTile(context, 'Base URL', currentModel.baseUrl!),
              _buildInfoTile(context, 'Model ID', currentModel.modelId),
            ],
            if (provider.customModels.isNotEmpty) ...[
              const Divider(),
              _buildSectionHeader(context, l10n.chatModelManagement),
              ListTile(
                leading: const Icon(Icons.settings),
                title: Text(l10n.chatModelManagement),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CustomModelScreen(),
                    ),
                  );
                },
              ),
            ],
            // API key management section (only for built-in providers)
            if (apiKeyType != null) ...[
              const Divider(),
              _ApiKeySection(apiKeyType: apiKeyType),
            ],
          ],
        );
      },
    );
  }

  ApiKeyType? _getApiKeyType(ChatModelProvider provider) {
    switch (provider) {
      case ChatModelProvider.googleAIStudio:
        return ApiKeyType.googleAiStudio;
      case ChatModelProvider.vertexAi:
        return ApiKeyType.vertexAi;
      case ChatModelProvider.openai:
        return ApiKeyType.openai;
      case ChatModelProvider.anthropic:
        return ApiKeyType.anthropic;
      case ChatModelProvider.custom:
        return null;
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: CommonTitleMedium(text: title),
    );
  }

  Widget _buildInfoTile(BuildContext context, String label, String value) {
    return ListTile(
      dense: true,
      title: Text(label, style: Theme.of(context).textTheme.bodySmall),
      subtitle: Text(
        value,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _ApiKeySection extends StatefulWidget {
  final ApiKeyType apiKeyType;
  const _ApiKeySection({required this.apiKeyType});

  @override
  State<_ApiKeySection> createState() => _ApiKeySectionState();
}

class _ApiKeySectionState extends State<_ApiKeySection> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  List<String> _keys = [];
  int _activeIndex = 0;
  int? _editingIndex;
  bool _isLoading = false;

  bool get _isVertexAi => widget.apiKeyType == ApiKeyType.vertexAi;

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  @override
  void didUpdateWidget(covariant _ApiKeySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.apiKeyType != widget.apiKeyType) {
      _editingIndex = null;
      _apiKeyController.clear();
      _loadKeys();
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final type = widget.apiKeyType;
    final multiKeys = prefs.getString(type.multiStorageKey);
    final activeIdx = prefs.getInt(type.activeIndexKey) ?? 0;

    if (multiKeys != null) {
      final List<dynamic> decoded = jsonDecode(multiKeys);
      _keys = decoded.cast<String>();
    } else {
      _keys = [];
    }

    _activeIndex = _keys.isEmpty ? 0 : activeIdx.clamp(0, _keys.length - 1);
    _editingIndex = null;
    _apiKeyController.clear();

    if (mounted) setState(() {});
  }

  Future<void> _syncActiveKey() async {
    final prefs = await SharedPreferences.getInstance();
    final type = widget.apiKeyType;
    if (_keys.isNotEmpty) {
      final activeKey = _keys[_activeIndex];
      await prefs.setString(type.storageKey, activeKey);
      if (type == ApiKeyType.googleAiStudio) {
        await prefs.setString('api_key', activeKey);
      }
    } else {
      await prefs.remove(type.storageKey);
      if (type == ApiKeyType.googleAiStudio) {
        await prefs.remove('api_key');
      }
    }
  }

  Future<void> _saveKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final type = widget.apiKeyType;
    if (_keys.isEmpty) {
      await prefs.remove(type.multiStorageKey);
      await prefs.remove(type.activeIndexKey);
    } else {
      await prefs.setString(type.multiStorageKey, jsonEncode(_keys));
      await prefs.setInt(type.activeIndexKey, _activeIndex);
    }
    await _syncActiveKey();
  }

  Future<void> _saveOrUpdateKey() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final key = _apiKeyController.text.trim();

      const costFreeTypes = [ApiKeyType.openai, ApiKeyType.vertexAi];
      if (costFreeTypes.contains(widget.apiKeyType)) {
        final validationError = await AiService.validateApiKey(
          widget.apiKeyType.prefsKey,
          key,
        );
        if (validationError != null) {
          if (mounted) {
            await CommonDialog.showInfo(
              context: context,
              title: 'API 키 검증 실패',
              content: validationError,
            );
          }
          return;
        }
      }

      if (_editingIndex != null) {
        _keys[_editingIndex!] = key;
        if (_keys.length == 1) _activeIndex = 0;
      } else {
        _keys.add(key);
        if (_keys.length == 1) _activeIndex = 0;
      }

      await _saveKeys();
      _editingIndex = null;
      _apiKeyController.clear();

      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: '${widget.apiKeyType.displayName} API 키가 저장되었습니다',
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: AppLocalizations.of(context).tutorialApiKeySaveFailed(e.toString()),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteKey(int index) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await CommonDialog.showConfirmation(
      context: context,
      title: 'API key',
      content: l10n.chatModelApiKeyDeleteContent,
      confirmText: l10n.commonDelete,
      isDestructive: true,
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      _keys.removeAt(index);
      if (_keys.isEmpty) {
        _activeIndex = 0;
      } else if (_activeIndex >= _keys.length) {
        _activeIndex = _keys.length - 1;
      }

      if (_editingIndex == index) {
        _editingIndex = null;
        _apiKeyController.clear();
      } else if (_editingIndex != null && _editingIndex! > index) {
        _editingIndex = _editingIndex! - 1;
      }

      await _saveKeys();

      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: 'API key deleted',
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: 'API key delete failed: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _setActiveKey(int index) async {
    if (_keys.length <= 1) return;
    setState(() => _activeIndex = index);
    await _saveKeys();
    if (mounted) {
      CommonDialog.showSnackBar(
        context: context,
        message: 'API key ${index + 1} activated',
      );
    }
  }

  void _startEditing(int index) {
    setState(() {
      _editingIndex = index;
      _apiKeyController.text = _keys[index];
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingIndex = null;
      _apiKeyController.clear();
    });
  }

  Future<void> _pickVertexAiJsonFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.single.path == null) return;

    setState(() => _isLoading = true);
    try {
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();

      final validationError =
          await VertexAuthService.validateServiceAccountJson(jsonString);
      if (validationError != null) {
        if (mounted) {
          await CommonDialog.showInfo(
            context: context,
            title: AppLocalizations.of(context).chatModelVertexValidationFailed,
            content: validationError,
          );
        }
        return;
      }

      if (_editingIndex != null) {
        _keys[_editingIndex!] = jsonString;
        if (_keys.length == 1) _activeIndex = 0;
      } else {
        _keys.add(jsonString);
        if (_keys.length == 1) _activeIndex = 0;
      }

      await _saveKeys();
      _editingIndex = null;
      _apiKeyController.clear();

      if (mounted) {
        final email = VertexAuthService.extractClientEmail(jsonString) ?? '';
        CommonDialog.showSnackBar(
          context: context,
          message: '${AppLocalizations.of(context).tutorialVertexSaved} ($email)',
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: AppLocalizations.of(context).tutorialJsonReadFailed(e.toString()),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _vertexAiKeyLabel(String jsonString) {
    final projectId = VertexAuthService.extractProjectId(jsonString);
    final email = VertexAuthService.extractClientEmail(jsonString);
    if (projectId != null && email != null) {
      return '$projectId\n$email';
    }
    return '(Service account JSON)';
  }

  String _obscureKey(String key) {
    if (key.length <= 8) return '•' * key.length;
    return '${key.substring(0, 4)}${'•' * (key.length - 8)}${key.substring(key.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
              child: Row(
                children: [
                  const CommonTitleMedium(text: 'API key'),
                  const Spacer(),
                  if (_keys.isNotEmpty)
                    Text(
                      '${_keys.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                ],
              ),
            ),
            _buildKeyList(context),
            const SizedBox(height: 12),
            if (!_isVertexAi) ...[
              CommonCustomTextField(
                controller: _apiKeyController,
                label: _editingIndex != null
                    ? 'Key ${_editingIndex! + 1}'
                    : l10n.chatModelNewApiKey,
                hintText: l10n.tutorialApiKeyHint,
                maxLines: 1,
                obscureText: true,
                enableObscureToggle: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.tutorialApiKeyEmpty;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                if (_editingIndex != null) ...[
                  Expanded(
                    child: CommonButton.outlined(
                      onPressed: _cancelEditing,
                      icon: Icons.close,
                      label: l10n.commonCancel,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: CommonButton.filled(
                    onPressed: _isLoading
                        ? null
                        : (_isVertexAi ? _pickVertexAiJsonFile : _saveOrUpdateKey),
                    icon: _editingIndex != null
                        ? Icons.save
                        : (_isVertexAi ? Icons.upload_file : Icons.add),
                    label: _editingIndex != null
                        ? l10n.commonSave
                        : (_isVertexAi ? l10n.chatModelJsonAdd : l10n.chatModelKeyAdd),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyList(BuildContext context) {
    if (_keys.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          AppLocalizations.of(context).chatModelNoApiKey,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    return Column(
      children: List.generate(_keys.length, (index) {
        final isActive = index == _activeIndex;
        final isEditing = _editingIndex == index;

        return Card(
          color: isEditing
              ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
              : null,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _setActiveKey(index),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Radio<int>(
                    value: index,
                    groupValue: _activeIndex,
                    onChanged: _keys.length <= 1
                        ? null
                        : (value) {
                            if (value != null) _setActiveKey(value);
                          },
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Key ${index + 1}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: isActive
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        Text(
                          _isVertexAi
                              ? _vertexAiKeyLabel(_keys[index])
                              : _obscureKey(_keys[index]),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: _isVertexAi ? 2 : 1,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: () => _startEditing(index),
                    tooltip: AppLocalizations.of(context).commonEdit,
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () => _deleteKey(index),
                    tooltip: AppLocalizations.of(context).commonDelete,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
