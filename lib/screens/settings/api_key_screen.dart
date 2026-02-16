import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/common_dialog.dart';
import '../../widgets/common/common_button.dart';
import '../../widgets/common/common_custom_text_field.dart';
import '../../widgets/common/common_appbar.dart';
import '../../widgets/common/common_filter_chip.dart';
import '../../widgets/common/common_title_medium.dart';

enum ApiKeyType {
  googleAiStudio('Google AI Studio', 'google'),
  openai('OpenAI', 'openai'),
  anthropic('Anthropic', 'anthropic');
  // openRouter('OpenRouter', 'openrouter');

  final String displayName;
  final String prefsKey;
  const ApiKeyType(this.displayName, this.prefsKey);

  String get storageKey => 'api_key_$prefsKey';
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

  @override
  void initState() {
    super.initState();
    _migrateAndLoadApiKey();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _migrateAndLoadApiKey() async {
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

      _loadKeyForType(_selectedApiKeyType);
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

  Future<void> _loadKeyForType(ApiKeyType type) async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(type.storageKey) ?? '';
    _apiKeyController.text = key;
  }

  Future<void> _saveApiKey() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _apiKeyController.text.trim();
      await prefs.setString(_selectedApiKeyType.storageKey, key);

      // Also write legacy key for backward compatibility
      if (_selectedApiKeyType == ApiKeyType.googleAiStudio) {
        await prefs.setString('api_key', key);
      }

      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: '${_selectedApiKeyType.displayName} API 키가 저장되었습니다',
        );
      }
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: 'API 키 저장 실패: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteApiKey() async {
    final confirmed = await CommonDialog.showConfirmation(
      context: context,
      title: 'API 키 삭제',
      content: '${_selectedApiKeyType.displayName}의 API 키를 삭제하시겠습니까?',
      confirmText: '삭제',
      isDestructive: true,
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_selectedApiKeyType.storageKey);

      if (_selectedApiKeyType == ApiKeyType.googleAiStudio) {
        await prefs.remove('api_key');
      }

      _apiKeyController.clear();

      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: 'API 키가 삭제되었습니다',
        );
      }
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: 'API 키 삭제 실패: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
                  setState(() => _selectedApiKeyType = type);
                  _loadKeyForType(type);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'API 키 등록',
        actions: [
          if (_apiKeyController.text.isNotEmpty)
            CommonAppBarIconButton(
              icon: Icons.delete_outline,
              onPressed: _isLoading ? null : _deleteApiKey,
            ),
        ],
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
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                const CommonTitleMedium(text: 'API 키 정보'),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'AI 모델을 사용하기 위해 API 키가 필요합니다.\n'
                              '각 제공사별로 API 키를 등록해주세요.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildApiKeyTypeSelector(context),
                    const SizedBox(height: 24),
                    CommonCustomTextField(
                      controller: _apiKeyController,
                      label: '${_selectedApiKeyType.displayName} API 키',
                      helpText:
                          '${_selectedApiKeyType.displayName}에서 발급받은 API 키를 입력해주세요.',
                      hintText: 'API 키를 입력해주세요',
                      maxLines: 1,
                      obscureText: true,
                      enableObscureToggle: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'API 키를 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    CommonButton.filled(
                      onPressed: _isLoading ? null : _saveApiKey,
                      icon: Icons.save,
                      label: '저장',
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
