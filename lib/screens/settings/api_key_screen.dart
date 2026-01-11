import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/custom_text_field.dart';

enum ApiKeyType {
  googleAiStudio('Google AI Studio');

  final String displayName;
  const ApiKeyType(this.displayName);
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
    _loadApiKey();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final apiKey = prefs.getString('api_key') ?? '';
      _apiKeyController.text = apiKey;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('API 키 불러오기 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveApiKey() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('api_key', _apiKeyController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API 키가 저장되었습니다')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('API 키 저장 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteApiKey() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API 키 삭제'),
        content: const Text('저장된 API 키를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('api_key');
      _apiKeyController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API 키가 삭제되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('API 키 삭제 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildApiKeyTypeSelector(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ApiKeyType.values.map((type) {
        final isSelected = _selectedApiKeyType == type;
        return FilterChip(
          selected: isSelected,
          label: Text(type.displayName),
          labelStyle: textTheme.bodyMedium?.copyWith(
            color: isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurface,
          ),
          backgroundColor: colorScheme.surface,
          selectedColor: colorScheme.secondaryContainer,
          checkmarkColor: colorScheme.onSecondaryContainer,
          side: BorderSide(
            color: isSelected ? colorScheme.secondary : colorScheme.outline.withValues(alpha: 0.3),
          ),
          onSelected: (selected) {
            if (selected) {
              setState(() => _selectedApiKeyType = type);
            }
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API 키 등록'),
        actions: [
          if (_apiKeyController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
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
                                Text(
                                  'API 키 정보',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'AI 모델을 사용하기 위해 API 키가 필요합니다.\n'
                              'API 키는 안전하게 암호화되어 기기에 저장됩니다.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildApiKeyTypeSelector(context),
                    const SizedBox(height: 24),
                    CustomTextField(
                      controller: _apiKeyController,
                      label: 'API 키',
                      helpText: '${_selectedApiKeyType.displayName}에서 발급받은 API 키를 입력해주세요.',
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
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _saveApiKey,
                      icon: const Icon(Icons.save),
                      label: const Text('저장'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
