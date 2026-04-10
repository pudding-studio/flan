import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/common_dialog.dart';
import '../../widgets/common/common_button.dart';
import '../../widgets/common/common_custom_text_field.dart';
import '../../widgets/common/common_appbar.dart';
import '../../widgets/common/common_filter_chip.dart';
import '../../widgets/common/common_settings.dart';
import '../../services/ai_service.dart';
import '../../services/vertex_auth_service.dart';

enum ApiKeyType {
  googleAiStudio('Google AI Studio', 'google'),
  vertexAi('Vertex AI', 'vertex_ai'),
  openai('OpenAI', 'openai'),
  anthropic('Anthropic', 'anthropic');
  // openRouter('OpenRouter', 'openrouter');

  final String displayName;
  final String prefsKey;
  const ApiKeyType(this.displayName, this.prefsKey);

  String get storageKey => 'api_key_$prefsKey';
  String get multiStorageKey => 'api_keys_$prefsKey';
  String get activeIndexKey => 'api_key_active_$prefsKey';
}

class ApiKeyScreen extends StatefulWidget {
  const ApiKeyScreen({super.key});

  @override
  State<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends State<ApiKeyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  bool _isLoading = false;
  ApiKeyType _selectedApiKeyType = ApiKeyType.googleAiStudio;
  List<String> _keys = [];
  int _activeIndex = 0;
  int? _editingIndex;
  bool get _isVertexAi => _selectedApiKeyType == ApiKeyType.vertexAi;

  @override
  void initState() {
    super.initState();
    _migrateAndLoadApiKeys();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _migrateAndLoadApiKeys() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();

      // Migrate legacy single 'api_key' to 'api_key_google'
      final legacyKey = prefs.getString('api_key');
      if (legacyKey != null && legacyKey.isNotEmpty) {
        final googleKey = prefs.getString('api_key_google');
        if (googleKey == null || googleKey.isEmpty) {
          await prefs.setString('api_key_google', legacyKey);
        }
      }

      // Migrate single key to multi-key format for all types
      for (final type in ApiKeyType.values) {
        final multiKeys = prefs.getString(type.multiStorageKey);
        if (multiKeys == null) {
          final singleKey = prefs.getString(type.storageKey);
          if (singleKey != null && singleKey.isNotEmpty) {
            await prefs.setString(
                type.multiStorageKey, jsonEncode([singleKey]));
            await prefs.setInt(type.activeIndexKey, 0);
          }
        }
      }

      _loadKeysForType(_selectedApiKeyType);
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: 'API 키 불러오기 실패: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadKeysForType(ApiKeyType type) async {
    final prefs = await SharedPreferences.getInstance();
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
    if (_keys.isNotEmpty) {
      final activeKey = _keys[_activeIndex];
      await prefs.setString(_selectedApiKeyType.storageKey, activeKey);

      if (_selectedApiKeyType == ApiKeyType.googleAiStudio) {
        await prefs.setString('api_key', activeKey);
      }
    } else {
      await prefs.remove(_selectedApiKeyType.storageKey);
      if (_selectedApiKeyType == ApiKeyType.googleAiStudio) {
        await prefs.remove('api_key');
      }
    }
  }

  Future<void> _saveKeys() async {
    final prefs = await SharedPreferences.getInstance();
    if (_keys.isEmpty) {
      await prefs.remove(_selectedApiKeyType.multiStorageKey);
      await prefs.remove(_selectedApiKeyType.activeIndexKey);
    } else {
      await prefs.setString(
          _selectedApiKeyType.multiStorageKey, jsonEncode(_keys));
      await prefs.setInt(_selectedApiKeyType.activeIndexKey, _activeIndex);
    }
    await _syncActiveKey();
  }

  Future<void> _saveOrUpdateKey() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final key = _apiKeyController.text.trim();

      // Validate API key before saving (skip for types that incur API costs)
      const costFreeTypes = [ApiKeyType.openai, ApiKeyType.vertexAi];
      if (costFreeTypes.contains(_selectedApiKeyType)) {
        final validationError = await AiService.validateApiKey(
          _selectedApiKeyType.prefsKey,
          key,
        );
        if (validationError != null) {
          if (mounted) {
            await CommonDialog.showInfo(
              context: context,
              title: 'API key validation failed',
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
          message: AppLocalizations.of(context).tutorialApiKeySaved(_selectedApiKeyType.displayName),
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
      } else {
        if (_activeIndex >= _keys.length) {
          _activeIndex = _keys.length - 1;
        }
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _setActiveKey(int index) async {
    if (_keys.length <= 1) return;

    setState(() {
      _activeIndex = index;
    });

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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );
    if (result == null || result.files.single.path == null) return;

    setState(() => _isLoading = true);
    try {
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();

      // Validate JSON structure
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
    return '(서비스 계정 JSON)';
  }

  String _obscureKey(String key) {
    if (key.length <= 8) return '•' * key.length;
    return '${key.substring(0, 4)}${'•' * (key.length - 8)}${key.substring(key.length - 4)}';
  }

  Widget _buildApiKeyTypeSelector(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ApiKeyType.values.map((type) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CommonFilterChip(
              label: type.displayName,
              selected: _selectedApiKeyType == type,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedApiKeyType = type;
                    _editingIndex = null;
                    _apiKeyController.clear();
                  });
                  _loadKeysForType(type);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKeyList() {
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
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: isActive
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                  ),
                        ),
                        Text(
                          _isVertexAi
                              ? _vertexAiKeyLabel(_keys[index])
                              : _obscureKey(_keys[index]),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontFamily: 'monospace',
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: CommonAppBar(
        title: l10n.settingsApiKey,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CommonSettingsInfoCard(
                      title: l10n.settingsApiKey,
                      description: l10n.apiKeyMultiInfo,
                    ),
                    const SizedBox(height: 24),
                    _buildApiKeyTypeSelector(context),
                    const SizedBox(height: 16),
                    _buildKeyList(),
                    const SizedBox(height: 16),
                    if (_isVertexAi) ...[
                                      CommonButton.filled(
                        onPressed:
                            _isLoading ? null : _pickVertexAiJsonFile,
                        icon: _editingIndex != null
                            ? Icons.refresh
                            : Icons.upload_file,
                        label: _editingIndex != null
                            ? l10n.tutorialReRegister
                            : l10n.tutorialVertexImport,
                      ),
                      if (_editingIndex != null) ...[
                        const SizedBox(height: 8),
                        CommonButton.outlined(
                          onPressed: _cancelEditing,
                          icon: Icons.close,
                          label: l10n.commonCancel,
                        ),
                      ],
                    ] else ...[
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
                      const SizedBox(height: 16),
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
                              onPressed:
                                  _isLoading ? null : _saveOrUpdateKey,
                              icon: _editingIndex != null
                                  ? Icons.save
                                  : Icons.add,
                              label:
                                  _editingIndex != null ? l10n.commonSave : l10n.chatModelKeyAdd,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
