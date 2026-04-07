import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../database/database_helper.dart';
import '../../models/chat/chat_message.dart';
import '../../models/chat/chat_model.dart';
import '../../models/chat/unified_model.dart';
import '../../providers/chat_model_provider.dart';
import '../../services/agent/agent_service.dart';
import '../../services/agent/agent_tool.dart';
import '../../widgets/agent/tool_result_card.dart';
import '../../widgets/common/common_appbar.dart';
import '../../widgets/common/common_dropdown_button.dart';
import '../../widgets/common/common_edit_text.dart';
import '../../widgets/common/markdown_text.dart';

class AgentChatScreen extends StatefulWidget {
  const AgentChatScreen({super.key});

  @override
  State<AgentChatScreen> createState() => _AgentChatScreenState();
}

class _AgentChatScreenState extends State<AgentChatScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  late AgentService _agentService;
  int? _chatRoomId;
  List<ChatMessage> _messages = [];
  bool _isSending = false;

  // Store tool results per assistant message ID
  final Map<int, List<_ToolResultEntry>> _toolResultsMap = {};

  @override
  void initState() {
    super.initState();
    _agentService = AgentService(_db);
    _loadData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final roomId = await _db.getOrCreateAgentChatRoom();
    final messages = await _db.readChatMessagesByChatRoom(roomId);

    if (mounted) {
      setState(() {
        _chatRoomId = roomId;
        _messages = messages;
      });
      _scrollToBottom(force: true);
    }
  }

  bool get _isNearBottom {
    if (!_scrollController.hasClients) return true;
    final pos = _scrollController.position;
    return pos.maxScrollExtent - pos.pixels < 150;
  }

  void _scrollToBottom({bool force = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && (force || _isNearBottom)) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (_chatRoomId == null || _isSending) return;

    // Retry: if last message is user (failed previous attempt), resend with empty input
    final isRetry = _messages.isNotEmpty &&
        _messages.last.role == MessageRole.user;

    if (text.isEmpty && !isRetry) return;

    final modelProvider = context.read<ChatModelSettingsProvider>();
    final model = modelProvider.selectedModel;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      String userText;

      if (isRetry) {
        // Reuse existing last user message, append new text if any
        final lastUserMessage = _messages.last;
        userText = text.isEmpty
            ? lastUserMessage.content
            : '${lastUserMessage.content}\n$text';

        if (text.isNotEmpty) {
          final updated = lastUserMessage.copyWith(
            content: userText,
            editedAt: DateTime.now(),
          );
          await _db.updateChatMessage(updated);
          await _reloadMessages();
        }
      } else {
        userText = text;
        final userMessage = ChatMessage(
          chatRoomId: _chatRoomId!,
          role: MessageRole.user,
          content: text,
        );
        await _db.createChatMessage(userMessage);
        await _reloadMessages();
      }

      final agentMessage = await _agentService.sendMessage(
        userText: userText,
        chatHistory: _messages.take(_messages.length - 1).toList(),
        model: model,
      );

      // Save assistant response (strip tool_call blocks for display)
      final displayText = _stripToolCallBlocks(agentMessage.text);
      final assistantMessage = ChatMessage(
        chatRoomId: _chatRoomId!,
        role: MessageRole.assistant,
        content: displayText,
        usageMetadata: agentMessage.usageMetadata,
      );
      final assistantId = await _db.createChatMessage(assistantMessage);

      // Store tool results for this message
      if (agentMessage.toolResults.isNotEmpty) {
        _toolResultsMap[assistantId] = agentMessage.toolResults
            .asMap()
            .entries
            .map((e) => _ToolResultEntry(
                  toolName: _inferToolName(e.value),
                  result: e.value,
                ))
            .toList();
      }

      await _reloadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _reloadMessages() async {
    if (_chatRoomId == null) return;
    final messages = await _db.readChatMessagesByChatRoom(_chatRoomId!);
    if (mounted) {
      setState(() => _messages = messages);
      _scrollToBottom();
    }
  }

  String _stripToolCallBlocks(String text) {
    return text.replaceAll(
      RegExp(r'```tool_call\s*\n[\s\S]*?```'),
      '',
    ).trim();
  }

  String _inferToolName(AgentToolResult result) {
    final msg = result.message;
    if (msg.contains('목록') || msg.contains('찾았습니다')) return 'list_characters';
    if (msg.contains('정보를 가져')) return 'get_character';
    // Order matters: check specific types before generic
    if (msg.contains('시작 시나리오')) {
      if (msg.contains('추가')) return 'create_start_scenario';
      if (msg.contains('수정')) return 'update_start_scenario';
      if (msg.contains('삭제')) return 'delete_start_scenario';
    }
    if (msg.contains('캐릭터북')) {
      if (msg.contains('추가')) return 'create_character_book';
      if (msg.contains('수정')) return 'update_character_book';
      if (msg.contains('삭제')) return 'delete_character_book';
    }
    if (msg.contains('페르소나')) {
      if (msg.contains('추가')) return 'create_persona';
      if (msg.contains('수정')) return 'update_persona';
      if (msg.contains('삭제')) return 'delete_persona';
    }
    if (msg.contains('캐릭터')) {
      if (msg.contains('생성')) return 'create_character';
      if (msg.contains('수정')) return 'update_character';
    }
    return 'unknown';
  }

  Future<void> _clearChat() async {
    if (_chatRoomId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('대화 초기화'),
        content: const Text('모든 대화 내용이 삭제됩니다. 계속하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = await _db.database;
      await db.delete(
        'chat_messages',
        where: 'chat_room_id = ?',
        whereArgs: [_chatRoomId],
      );
      _toolResultsMap.clear();
      await _reloadMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Flan Agent',
        actions: [
          CommonAppBarIconButton(
            icon: Icons.delete_outline,
            onPressed: _messages.isEmpty ? null : _clearChat,
            tooltip: '대화 초기화',
            offsetX: 26,
          ),
        ],
      ),
      endDrawer: _buildModelDrawer(),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) =>
                        _buildMessage(_messages[index]),
                  ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 48,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Flan Agent',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '캐릭터 생성, 수정, 편집을 도와드립니다',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final isUser = message.role == MessageRole.user;
    final toolResults = message.id != null ? _toolResultsMap[message.id!] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Role label
          Text(
            isUser ? '나' : 'Agent',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isUser
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          // Message content
          MarkdownText(
            text: message.content,
            baseStyle: Theme.of(context).textTheme.bodyMedium,
          ),
          // Tool result cards
          if (toolResults != null && toolResults.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                children: toolResults
                    .map((entry) => ToolResultCard(
                          toolName: entry.toolName,
                          result: entry.result,
                        ))
                    .toList(),
              ),
            ),
          const Divider(height: 16),
        ],
      ),
    );
  }

  Widget _buildModelDrawer() {
    final selectableProviders = ChatModelProvider.values.toList();

    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Consumer<ChatModelSettingsProvider>(
            builder: (context, provider, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '사용 모델',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 16),
                _buildSettingRow(
                  label: '제조사',
                  child: CommonDropdownButton<ChatModelProvider>(
                    value: provider.selectedProvider,
                    items: selectableProviders,
                    onChanged: (p) { if (p != null) provider.setProvider(p); },
                    labelBuilder: (p) => p.displayName,
                    size: CommonDropdownButtonSize.xsmall,
                  ),
                ),
                const SizedBox(height: 8),
                _buildSettingRow(
                  label: '모델',
                  child: CommonDropdownButton<UnifiedModel>(
                    value: provider.selectedModel,
                    items: provider.availableModels,
                    onChanged: (m) { if (m != null) provider.setModel(m); },
                    labelBuilder: (m) => m.displayName,
                    size: CommonDropdownButtonSize.xsmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingRow({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  Widget _buildInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CommonEditText(
            controller: _messageController,
            focusNode: _messageFocusNode,
            enabled: !_isSending,
            hintText: _isSending ? '응답 대기 중...' : '메시지를 입력하세요',
            minLines: 1,
            maxLines: 5,
            textInputAction: TextInputAction.newline,
            suffixIcon: IconButton(
              icon: _isSending
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              onPressed: _isSending ? null : _sendMessage,
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolResultEntry {
  final String toolName;
  final AgentToolResult result;

  const _ToolResultEntry({
    required this.toolName,
    required this.result,
  });
}
