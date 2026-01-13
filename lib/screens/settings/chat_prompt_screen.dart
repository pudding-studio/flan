import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/prompt/chat_prompt.dart';
import 'widgets/prompt_list_item.dart';
import 'prompt_edit_screen.dart';

class ChatPromptScreen extends StatefulWidget {
  const ChatPromptScreen({super.key});

  @override
  State<ChatPromptScreen> createState() => _ChatPromptScreenState();
}

class _ChatPromptScreenState extends State<ChatPromptScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<ChatPrompt> _prompts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrompts();
  }

  Future<void> _loadPrompts() async {
    setState(() => _isLoading = true);
    try {
      final prompts = await _db.readAllChatPrompts();
      setState(() => _prompts = prompts);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('프롬프트 목록을 불러오는데 실패했습니다: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectPrompt(int id) async {
    try {
      await _db.setSelectedChatPrompt(id);
      await _loadPrompts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('프롬프트 선택에 실패했습니다: $e')),
        );
      }
    }
  }

  Future<void> _deletePrompt(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('프롬프트 삭제'),
        content: Text('\'$name\'을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _db.deleteChatPrompt(id);
        await _loadPrompts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('프롬프트가 삭제되었습니다')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('프롬프트 삭제에 실패했습니다: $e')),
          );
        }
      }
    }
  }

  Future<void> _navigateToEdit(ChatPrompt? prompt) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PromptEditScreen(prompt: prompt),
      ),
    );
    if (result == true) {
      _loadPrompts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.05;

    return Scaffold(
      appBar: AppBar(
        title: const Text('채팅 프롬프트'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _prompts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 80,
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '프롬프트가 없습니다',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color
                              ?.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '+ 버튼을 눌러 새 프롬프트를 추가해보세요',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color
                              ?.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 16.0,
                  ),
                  itemCount: _prompts.length,
                  itemBuilder: (context, index) {
                    final prompt = _prompts[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: PromptListItem(
                        title: prompt.name,
                        description: prompt.description ?? '${prompt.items.length}개 항목',
                        isSelected: prompt.isSelected,
                        onRadioTap: () => _selectPrompt(prompt.id!),
                        onTap: () => _navigateToEdit(prompt),
                        onDelete: () => _deletePrompt(
                          prompt.id!,
                          prompt.name,
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEdit(null),
        elevation: 0,
        child: const Icon(Icons.add),
      ),
    );
  }
}
