import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatPromptScreen extends StatefulWidget {
  const ChatPromptScreen({super.key});

  @override
  State<ChatPromptScreen> createState() => _ChatPromptScreenState();
}

class _ChatPromptScreenState extends State<ChatPromptScreen> {
  final _formKey = GlobalKey<FormState>();
  final _promptController = TextEditingController();
  bool _isLoading = false;

  static const String _defaultPrompt =
      'You are a helpful AI assistant. '
      'Respond in a friendly and informative manner.';

  @override
  void initState() {
    super.initState();
    _loadPrompt();
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _loadPrompt() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final prompt = prefs.getString('chat_prompt') ?? _defaultPrompt;
      _promptController.text = prompt;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('프롬프트 불러오기 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _savePrompt() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('chat_prompt', _promptController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프롬프트가 저장되었습니다')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('프롬프트 저장 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetToDefault() {
    setState(() {
      _promptController.text = _defaultPrompt;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('채팅 프롬프트'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _resetToDefault,
            tooltip: '기본값으로 초기화',
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
                                  '프롬프트 정보',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '시스템 프롬프트는 AI의 응답 스타일과 행동을 정의합니다.\n'
                              '캐릭터와의 대화에 전역적으로 적용됩니다.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _promptController,
                      decoration: const InputDecoration(
                        labelText: '시스템 프롬프트',
                        hintText: 'AI의 역할과 응답 방식을 정의하세요',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 10,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '프롬프트를 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _savePrompt,
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
