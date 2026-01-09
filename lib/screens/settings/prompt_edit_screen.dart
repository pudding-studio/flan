import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/prompt/chat_prompt.dart';

class PromptEditScreen extends StatefulWidget {
  final ChatPrompt? prompt;

  const PromptEditScreen({super.key, this.prompt});

  @override
  State<PromptEditScreen> createState() => _PromptEditScreenState();
}

class _PromptEditScreenState extends State<PromptEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contentController = TextEditingController();
  final DatabaseHelper _db = DatabaseHelper.instance;
  bool _isLoading = false;

  bool get _isEditing => widget.prompt != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.prompt!.name;
      _contentController.text = widget.prompt!.content;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _savePrompt() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      if (_isEditing) {
        final updated = widget.prompt!.copyWith(
          name: _nameController.text.trim(),
          content: _contentController.text.trim(),
          updatedAt: DateTime.now(),
        );
        await _db.updateChatPrompt(updated);
      } else {
        final prompt = ChatPrompt(
          name: _nameController.text.trim(),
          content: _contentController.text.trim(),
        );
        await _db.createChatPrompt(prompt);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('프롬프트가 ${_isEditing ? "수정" : "생성"}되었습니다')),
        );
        Navigator.pop(context, true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '프롬프트 수정' : '새 프롬프트'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _savePrompt,
            ),
        ],
      ),
      body: SingleChildScrollView(
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
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '시스템 프롬프트는 AI의 응답 스타일과 행동을 정의합니다.\n'
                        '캐릭터와의 대화에 적용할 프롬프트를 선택할 수 있습니다.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '프롬프트 이름',
                  hintText: '예: 친근한 도우미, 전문가 모드',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '프롬프트 이름을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: '프롬프트 내용',
                  hintText: 'AI의 역할과 응답 방식을 정의하세요',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 12,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '프롬프트 내용을 입력해주세요';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
