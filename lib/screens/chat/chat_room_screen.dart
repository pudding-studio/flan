import 'package:flutter/material.dart';
import '../../models/chat/chat_room.dart';
import '../../models/chat/chat_message.dart';
import '../../models/character/character.dart';
import '../../models/character/cover_image.dart';
import '../../models/character/persona.dart';
import '../../models/character/character_book_folder.dart';
import '../../models/prompt/chat_prompt.dart';
import '../../database/database_helper.dart';
import '../../utils/prompt_builder.dart';
import '../../utils/common_dialog.dart';
import '../../services/gemini_service.dart';

class ChatRoomScreen extends StatefulWidget {
  final int chatRoomId;

  const ChatRoomScreen({
    super.key,
    required this.chatRoomId,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final GeminiService _geminiService = GeminiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  ChatRoom? _chatRoom;
  Character? _character;
  List<ChatMessage> _messages = [];
  List<CoverImage> _coverImages = [];
  bool _isLoading = true;
  bool _isSending = false;
  int? _editingMessageId;
  final Map<int, TextEditingController> _editControllers = {};

  @override
  void initState() {
    super.initState();
    _loadChatData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    for (var controller in _editControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadChatData() async {
    setState(() => _isLoading = true);

    try {
      final chatRoom = await _db.readChatRoom(widget.chatRoomId);
      if (chatRoom == null) {
        throw Exception('채팅방을 찾을 수 없습니다');
      }

      final character = await _db.readCharacter(chatRoom.characterId);
      final messages = await _db.readChatMessagesByChatRoom(widget.chatRoomId);
      final coverImages = await _db.readCoverImages(chatRoom.characterId);

      setState(() {
        _chatRoom = chatRoom;
        _character = character;
        _messages = messages;
        _coverImages = coverImages;
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      debugPrint('Error loading chat data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<String> _generateSystemPrompt() async {
    if (_chatRoom == null || _character == null) {
      return '시스템 프롬프트를 생성할 수 없습니다.';
    }

    ChatPrompt? chatPrompt;
    if (_chatRoom!.selectedChatPromptId != null) {
      chatPrompt = await _db.readChatPrompt(_chatRoom!.selectedChatPromptId!);
    }

    Persona? persona;
    if (_chatRoom!.selectedPersonaId != null) {
      persona = await _db.readPersona(_chatRoom!.selectedPersonaId!);
    }

    final allCharacterBooks = await _db.readCharacterBooks(_character!.id!);
    final activeCharacterBooks = allCharacterBooks.where((characterBook) {
      return characterBook.enabled == CharacterBookActivationCondition.enabled;
    }).toList();

    return PromptBuilder.buildSystemPrompt(
      chatPrompt: chatPrompt,
      character: _character!,
      persona: persona,
      activeCharacterBooks: activeCharacterBooks,
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _chatRoom == null || _isSending) return;

    setState(() => _isSending = true);

    try {
      final userMessage = ChatMessage(
        chatRoomId: widget.chatRoomId,
        role: MessageRole.user,
        content: text,
      );

      await _db.createChatMessage(userMessage);
      _messageController.clear();

      final systemPrompt = await _generateSystemPrompt();

      ChatPrompt? chatPrompt;
      if (_chatRoom!.selectedChatPromptId != null) {
        chatPrompt = await _db.readChatPrompt(_chatRoom!.selectedChatPromptId!);
      }

      final aiResponse = await _geminiService.sendMessage(
        systemPrompt: systemPrompt,
        chatHistory: _messages,
        userMessage: text,
        promptParameters: chatPrompt?.parameters,
        chatRoomId: widget.chatRoomId,
        characterId: _character?.id,
      );

      final assistantMessage = ChatMessage(
        chatRoomId: widget.chatRoomId,
        role: MessageRole.assistant,
        content: aiResponse,
      );

      await _db.createChatMessage(assistantMessage);

      final updatedChatRoom = _chatRoom!.copyWith(
        updatedAt: DateTime.now(),
      );
      await _db.updateChatRoom(updatedChatRoom);

    } catch (e) {
      debugPrint('Error sending message: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('메시지 전송 중 오류가 발생했습니다: $e')),
      );
    } finally {
      await _loadChatData();
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _deleteMessage(int messageId) async {
    final confirmed = await CommonDialog.showDeleteConfirmation(
      context: context,
      itemName: '이 메시지',
    );

    if (!confirmed) return;

    try {
      await _db.deleteChatMessage(messageId);
      await _loadChatData();
      if (!mounted) return;
      CommonDialog.showSnackBar(
        context: context,
        message: '메시지가 삭제되었습니다',
      );
    } catch (e) {
      debugPrint('Error deleting message: $e');
      if (!mounted) return;
      CommonDialog.showSnackBar(
        context: context,
        message: '메시지 삭제 중 오류가 발생했습니다',
      );
    }
  }

  void _startEditMessage(ChatMessage message) {
    setState(() {
      _editingMessageId = message.id;
      _editControllers[message.id!] = TextEditingController(text: message.content);
    });
  }

  void _cancelEditMessage() {
    if (_editingMessageId != null) {
      _editControllers[_editingMessageId]?.dispose();
      _editControllers.remove(_editingMessageId);
      setState(() {
        _editingMessageId = null;
      });
    }
  }

  Future<void> _saveEditMessage(ChatMessage message) async {
    final controller = _editControllers[message.id];
    if (controller == null) return;

    final newContent = controller.text.trim();
    if (newContent.isEmpty || newContent == message.content) {
      _cancelEditMessage();
      return;
    }

    try {
      final updatedMessage = message.copyWith(
        content: newContent,
        editedAt: DateTime.now(),
      );

      await _db.updateChatMessage(updatedMessage);
      _cancelEditMessage();
      await _loadChatData();
      if (!mounted) return;
      CommonDialog.showSnackBar(
        context: context,
        message: '메시지가 수정되었습니다',
      );
    } catch (e) {
      debugPrint('Error editing message: $e');
      if (!mounted) return;
      CommonDialog.showSnackBar(
        context: context,
        message: '메시지 수정 중 오류가 발생했습니다',
      );
    }
  }

  Future<void> _regenerateMessage(int messageId) async {
    if (_isSending) return;

    setState(() => _isSending = true);

    try {
      final message = await _db.readChatMessage(messageId);
      if (message == null) return;

      final messageIndex = _messages.indexWhere((m) => m.id == messageId);
      if (messageIndex <= 0) return;

      final previousMessage = _messages[messageIndex - 1];
      if (previousMessage.role != MessageRole.user) return;

      final systemPrompt = await _generateSystemPrompt();
      final historyBeforeMessage = _messages.sublist(0, messageIndex - 1);

      ChatPrompt? chatPrompt;
      if (_chatRoom!.selectedChatPromptId != null) {
        chatPrompt = await _db.readChatPrompt(_chatRoom!.selectedChatPromptId!);
      }

      final aiResponse = await _geminiService.sendMessage(
        systemPrompt: systemPrompt,
        chatHistory: historyBeforeMessage,
        userMessage: previousMessage.content,
        promptParameters: chatPrompt?.parameters,
        chatRoomId: widget.chatRoomId,
        characterId: _character?.id,
      );

      final updatedMessage = message.copyWith(
        content: aiResponse,
        editedAt: DateTime.now(),
      );

      await _db.updateChatMessage(updatedMessage);
      await _loadChatData();
    } catch (e) {
      debugPrint('Error regenerating message: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('메시지 재생성 중 오류가 발생했습니다: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Widget _buildCharacterAvatar() {
    final selectedCover = _coverImages.isNotEmpty ? _coverImages.first : null;

    if (selectedCover == null || selectedCover.imageData == null) {
      return const CircleAvatar(
        radius: 16,
        backgroundColor: Color(0xFFE0E0E0),
        child: Icon(
          Icons.person_outline,
          size: 16,
          color: Color(0xFF757575),
        ),
      );
    }

    return CircleAvatar(
      radius: 16,
      backgroundImage: MemoryImage(selectedCover.imageData!),
    );
  }

  Widget _buildMessage(ChatMessage message, int index) {
    final isUser = message.role == MessageRole.user;
    final isEditing = _editingMessageId == message.id;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isEditing)
                TextField(
                  controller: _editControllers[message.id],
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  maxLines: null,
                  autofocus: true,
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                Text(
                  message.content,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Spacer(),
                  if (isEditing) ...[
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: _cancelEditMessage,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 0),
                    IconButton(
                      icon: const Icon(Icons.check, size: 18),
                      onPressed: () => _saveEditMessage(message),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ] else ...[
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () => _startEditMessage(message),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 0),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: () => _deleteMessage(message.id!),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    ),
                    if (!isUser) ...[
                      const SizedBox(width: 0),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 18),
                        onPressed: () => _regenerateMessage(message.id!),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ],
                ],
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_chatRoom == null || _character == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('채팅방을 불러올 수 없습니다'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            _buildCharacterAvatar(),
            const SizedBox(width: 12),
            Text(_character!.name),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: 케밥 메뉴 구현
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(_messages[index], index);
              },
            ),
          ),
          Container(
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
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        enabled: !_isSending,
                        decoration: InputDecoration(
                          hintText: _isSending ? '전송 중...' : '메시지를 입력하세요',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 5,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      onPressed: _isSending ? null : _sendMessage,
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
