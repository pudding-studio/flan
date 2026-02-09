import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/markdown_text.dart';
import '../../models/chat/chat_room.dart';
import '../../models/chat/chat_message.dart';
import '../../models/character/character.dart';
import '../../models/character/cover_image.dart';
import '../../models/character/persona.dart';
import '../../models/character/character_book_folder.dart';
import '../../models/character/start_scenario.dart';
import '../../models/prompt/chat_prompt.dart';
import '../../models/prompt/prompt_item.dart';
import '../../models/prompt/prompt_parameters.dart';
import '../../database/database_helper.dart';
import '../../providers/tokenizer_provider.dart';
import '../../utils/prompt_builder.dart';
import '../../utils/common_dialog.dart';
import '../../utils/token_counter.dart';
import '../../services/gemini_service.dart';
import '../../models/chat/chat_message_metadata.dart';
import '../../models/chat/chat_model.dart';
import '../../utils/metadata_parser.dart';
import '../../widgets/common/common_appbar.dart';
import '../../widgets/common/common_edit_text.dart';
import '../../providers/chat_model_provider.dart';
import '../../providers/viewer_settings_provider.dart';
import 'widgets/chat_bottom_panel.dart';
import '../character/character_view_screen.dart';

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
  StartScenario? _startScenario;
  List<ChatMessage> _messages = [];
  List<CoverImage> _coverImages = [];
  bool _isLoading = true;
  bool _isSending = false;
  int? _editingMessageId;
  final Map<int, TextEditingController> _editControllers = {};
  Map<int, ChatMessageMetadata> _metadataMap = {};
  bool _showBottomPanel = false;
  List<ChatPrompt> _chatPrompts = [];
  List<Persona> _personas = [];
  final FocusNode _messageFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _messageFocusNode.addListener(_onMessageFocusChanged);
    _loadChatData();
  }

  void _onMessageFocusChanged() {
    if (_messageFocusNode.hasFocus && _showBottomPanel) {
      setState(() => _showBottomPanel = false);
    }
  }

  @override
  void dispose() {
    _messageFocusNode.removeListener(_onMessageFocusChanged);
    _messageFocusNode.dispose();
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
      final metadataList = await _db.readChatMessageMetadataByChatRoom(widget.chatRoomId);
      final metadataMap = <int, ChatMessageMetadata>{};
      for (final m in metadataList) {
        metadataMap[m.chatMessageId] = m;
      }

      StartScenario? startScenario;
      if (chatRoom.selectedStartScenarioId != null) {
        startScenario = await _db.readStartScenario(chatRoom.selectedStartScenarioId!);
      }

      final chatPrompts = await _db.readAllChatPrompts();
      final personas = character != null
          ? await _db.readPersonas(character.id!)
          : <Persona>[];

      setState(() {
        _chatRoom = chatRoom;
        _character = character;
        _startScenario = startScenario;
        _messages = messages;
        _coverImages = coverImages;
        _metadataMap = metadataMap;
        _chatPrompts = chatPrompts;
        _personas = personas;
        _isLoading = false;
      });

    } catch (e) {
      debugPrint('Error loading chat data: $e');
      setState(() => _isLoading = false);
    }
  }


  Future<({String systemPrompt, List<Map<String, dynamic>> contents, PromptParameters? parameters})> _buildApiData({
    required String userMessage,
    List<int>? excludeMessageIds,
    int? beforeMessageIndex,
  }) async {
    if (_chatRoom == null || _character == null) {
      return (systemPrompt: '', contents: <Map<String, dynamic>>[], parameters: null);
    }

    ChatPrompt? chatPrompt;
    if (_chatRoom!.selectedChatPromptId != null) {
      chatPrompt = await _db.readChatPrompt(_chatRoom!.selectedChatPromptId!);
    }

    Persona? persona;
    if (_chatRoom!.selectedPersonaId != null) {
      persona = await _db.readPersona(_chatRoom!.selectedPersonaId!);
    }

    StartScenario? startScenario;
    if (_chatRoom!.selectedStartScenarioId != null) {
      startScenario = await _db.readStartScenario(_chatRoom!.selectedStartScenarioId!);
    }

    final allCharacterBooks = await _db.readCharacterBooks(_character!.id!);
    final activeCharacterBooks = allCharacterBooks.where((characterBook) {
      return characterBook.enabled == CharacterBookActivationCondition.enabled;
    }).toList();

    final systemPrompt = PromptBuilder.buildSystemPrompt(
      chatPrompt: chatPrompt,
      character: _character!,
      persona: persona,
      startScenario: startScenario,
      activeCharacterBooks: activeCharacterBooks,
    );

    final chatHistoryMap = await _buildChatHistoryMap(
      chatPrompt: chatPrompt,
      excludeMessageIds: excludeMessageIds,
      beforeMessageIndex: beforeMessageIndex,
    );

    final tokenizerProvider = context.read<TokenizerProvider>();
    final tokenizer = tokenizerProvider.selectedTokenizer;

    final lastMetadata = await _db.readLatestChatMessageMetadata(widget.chatRoomId);

    final contents = PromptBuilder.buildContents(
      chatPrompt: chatPrompt,
      character: _character!,
      userMessage: userMessage,
      chatHistoryMap: chatHistoryMap,
      systemPrompt: systemPrompt,
      persona: persona,
      startScenario: startScenario,
      activeCharacterBooks: activeCharacterBooks,
      maxInputTokens: chatPrompt?.parameters?.maxInputTokens,
      tokenizer: tokenizer,
      lastMetadata: lastMetadata,
    );

    return (systemPrompt: systemPrompt, contents: contents, parameters: chatPrompt?.parameters);
  }

  Future<Map<PromptItem, List<ChatMessage>>> _buildChatHistoryMap({
    required ChatPrompt? chatPrompt,
    List<int>? excludeMessageIds,
    int? beforeMessageIndex,
  }) async {
    final map = <PromptItem, List<ChatMessage>>{};
    if (chatPrompt == null) return map;

    final chatItems = chatPrompt.items.where((item) => item.role == PromptRole.chat).toList();
    if (chatItems.isEmpty) return map;

    for (final chatItem in chatItems) {
      var messages = await _loadChatItemMessages(chatItem);

      if (excludeMessageIds != null && excludeMessageIds.isNotEmpty) {
        messages = messages.where((m) => !excludeMessageIds.contains(m.id)).toList();
      }

      if (beforeMessageIndex != null) {
        messages = messages.where((m) {
          final idx = _messages.indexWhere((msg) => msg.id == m.id);
          return idx >= 0 && idx < beforeMessageIndex;
        }).toList();
      }

      map[chatItem] = messages;
    }

    return map;
  }

  Future<List<ChatMessage>> _loadChatItemMessages(PromptItem chatItem) async {
    if (chatItem.chatSettingMode == ChatSettingMode.basic) {
      return await _db.readChatMessagesByChatRoom(widget.chatRoomId);
    }

    switch (chatItem.chatRangeType) {
      case ChatRangeType.recent:
        final count = chatItem.recentChatCount ?? 0;
        if (count <= 0) return await _db.readChatMessagesByChatRoom(widget.chatRoomId);
        return await _db.readChatMessagesRecent(widget.chatRoomId, count);
      case ChatRangeType.middle:
        final start = chatItem.chatStartPosition ?? 1;
        final end = chatItem.chatEndPosition ?? start;
        return await _db.readChatMessagesMiddle(widget.chatRoomId, start, end);
      case ChatRangeType.old:
        final recentExclude = chatItem.chatStartPosition ?? 0;
        if (recentExclude <= 0) return await _db.readChatMessagesByChatRoom(widget.chatRoomId);
        return await _db.readChatMessagesOld(widget.chatRoomId, recentExclude);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (_chatRoom == null || _isSending) return;

    setState(() => _isSending = true);

    try {
      final tokenizerProvider = context.read<TokenizerProvider>();
      final tokenizer = tokenizerProvider.selectedTokenizer;
      String combinedUserMessage;
      int excludeId;

      if (_messages.isNotEmpty && _messages.last.role == MessageRole.user) {
        final lastUserMessage = _messages.last;
        combinedUserMessage = text.isEmpty
            ? lastUserMessage.content
            : '${lastUserMessage.content}\n$text';

        final tokenCount = TokenCounter.estimateTokenCount(combinedUserMessage, tokenizer: tokenizer);
        final updatedUserMessage = lastUserMessage.copyWith(
          content: combinedUserMessage,
          tokenCount: tokenCount,
          editedAt: DateTime.now(),
        );
        await _db.updateChatMessage(updatedUserMessage);
        excludeId = lastUserMessage.id!;
      } else {
        combinedUserMessage = text;
        final tokenCount = TokenCounter.estimateTokenCount(text, tokenizer: tokenizer);
        final userMessage = ChatMessage(
          chatRoomId: widget.chatRoomId,
          role: MessageRole.user,
          content: text,
          tokenCount: tokenCount,
        );
        excludeId = await _db.createChatMessage(userMessage);
      }

      _messageController.clear();

      final apiData = await _buildApiData(
        userMessage: combinedUserMessage,
        excludeMessageIds: [excludeId],
      );

      final geminiResponse = await _geminiService.sendMessage(
        systemPrompt: apiData.systemPrompt,
        contents: apiData.contents,
        promptParameters: apiData.parameters,
        chatRoomId: widget.chatRoomId,
        characterId: _character?.id,
      );

      final assistantTokenCount = geminiResponse.usageMetadata?.candidatesTokenCount ??
          TokenCounter.estimateTokenCount(geminiResponse.text, tokenizer: tokenizer);
      final assistantMessage = ChatMessage(
        chatRoomId: widget.chatRoomId,
        role: MessageRole.assistant,
        content: geminiResponse.text,
        tokenCount: assistantTokenCount,
        usageMetadata: geminiResponse.usageMetadata,
        modelId: geminiResponse.modelId,
      );

      final assistantMessageId = await _db.createChatMessage(assistantMessage);

      await _saveMessageMetadata(assistantMessageId, geminiResponse.text);

      // 채팅방 토큰 합산 업데이트
      await _db.updateChatRoomTotalTokenCount(widget.chatRoomId);

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
      // 채팅방 토큰 합산 업데이트
      await _db.updateChatRoomTotalTokenCount(widget.chatRoomId);
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

  String _buildEditableContent(ChatMessage message) {
    final metadata = message.id != null ? _metadataMap[message.id!] : null;
    if (metadata == null) return message.content;

    final tagString = metadata.toTagString();
    if (tagString.isEmpty) return message.content;
    return '$tagString\n${message.content}';
  }

  void _startEditMessage(ChatMessage message) {
    setState(() {
      _editingMessageId = message.id;
      _editControllers[message.id!] = TextEditingController(
        text: _buildEditableContent(message),
      );
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

    final rawContent = controller.text.trim();
    if (rawContent.isEmpty) {
      _cancelEditMessage();
      return;
    }

    try {
      final cleanedContent = MetadataParser.removeMetadataTags(rawContent);

      if (message.role == MessageRole.assistant && message.id != null) {
        final parsed = MetadataParser.parse(rawContent);
        final existingMetadata = _metadataMap[message.id!];

        if (parsed.location != null || parsed.date != null || parsed.time != null) {
          final newMetadata = ChatMessageMetadata(
            chatMessageId: message.id!,
            chatRoomId: widget.chatRoomId,
            location: parsed.location,
            date: parsed.date,
            time: parsed.time,
          );
          if (existingMetadata != null) {
            await _db.updateChatMessageMetadata(
              newMetadata.copyWith(id: existingMetadata.id),
            );
          } else {
            await _db.createChatMessageMetadata(newMetadata);
          }
        } else if (existingMetadata != null) {
          await _db.deleteChatMessageMetadata(existingMetadata.id!);
        }
      }

      final tokenizerProvider = context.read<TokenizerProvider>();
      final tokenizer = tokenizerProvider.selectedTokenizer;
      final tokenCount = TokenCounter.estimateTokenCount(cleanedContent, tokenizer: tokenizer);

      final updatedMessage = message.copyWith(
        content: cleanedContent,
        tokenCount: tokenCount,
        editedAt: DateTime.now(),
      );

      await _db.updateChatMessage(updatedMessage);
      await _db.updateChatRoomTotalTokenCount(widget.chatRoomId);
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

  Future<void> _saveMessageMetadata(int messageId, String content) async {
    final previous = await _db.readLatestChatMessageMetadata(widget.chatRoomId);
    final metadata = MetadataParser.buildMetadata(
      chatMessageId: messageId,
      chatRoomId: widget.chatRoomId,
      content: content,
      previous: previous,
    );

    final shouldPin = MetadataParser.shouldAutoPin(metadata, previous);
    final finalMetadata = shouldPin ? metadata.copyWith(isPinned: true) : metadata;

    final metadataId = await _db.createChatMessageMetadata(finalMetadata);
    setState(() {
      _metadataMap[messageId] = finalMetadata.copyWith(id: metadataId);
    });

    if (MetadataParser.hasMetadataPattern(content)) {
      final cleaned = MetadataParser.removeMetadataTags(content);
      final message = await _db.readChatMessage(messageId);
      if (message != null) {
        await _db.updateChatMessage(message.copyWith(content: cleaned));
      }
    }
  }

  Future<void> _togglePin(int messageId) async {
    final metadata = _metadataMap[messageId];
    if (metadata == null || metadata.id == null) return;

    final updated = metadata.copyWith(isPinned: !metadata.isPinned);
    await _db.updateChatMessageMetadata(updated);
    setState(() {
      _metadataMap[messageId] = updated;
    });
  }

  void _toggleBottomPanel() {
    if (_showBottomPanel) {
      setState(() => _showBottomPanel = false);
    } else {
      FocusScope.of(context).unfocus();
      setState(() => _showBottomPanel = true);
    }
  }

  Future<void> _onModelChanged(ChatModel model) async {
    final provider = context.read<ChatModelSettingsProvider>();
    await provider.setModel(model);
  }

  Future<void> _onPromptChanged(int? promptId) async {
    if (_chatRoom == null) return;
    final updated = ChatRoom(
      id: _chatRoom!.id,
      characterId: _chatRoom!.characterId,
      name: _chatRoom!.name,
      selectedChatPromptId: promptId,
      selectedPersonaId: _chatRoom!.selectedPersonaId,
      selectedStartScenarioId: _chatRoom!.selectedStartScenarioId,
      totalTokenCount: _chatRoom!.totalTokenCount,
      createdAt: _chatRoom!.createdAt,
      updatedAt: DateTime.now(),
    );
    await _db.updateChatRoom(updated);
    setState(() => _chatRoom = updated);
  }

  Future<void> _onPersonaChanged(int? personaId) async {
    if (_chatRoom == null) return;
    final updated = ChatRoom(
      id: _chatRoom!.id,
      characterId: _chatRoom!.characterId,
      name: _chatRoom!.name,
      selectedChatPromptId: _chatRoom!.selectedChatPromptId,
      selectedPersonaId: personaId,
      selectedStartScenarioId: _chatRoom!.selectedStartScenarioId,
      totalTokenCount: _chatRoom!.totalTokenCount,
      createdAt: _chatRoom!.createdAt,
      updatedAt: DateTime.now(),
    );
    await _db.updateChatRoom(updated);
    setState(() => _chatRoom = updated);
  }

  Future<void> _resendLastUserMessage() async {
    if (_isSending || _messages.isEmpty) return;

    final lastMessage = _messages.last;
    if (lastMessage.role != MessageRole.user) return;

    setState(() => _isSending = true);

    try {
      final tokenizerProvider = context.read<TokenizerProvider>();
      final tokenizer = tokenizerProvider.selectedTokenizer;

      final apiData = await _buildApiData(
        userMessage: lastMessage.content,
        excludeMessageIds: [lastMessage.id!],
      );

      final geminiResponse = await _geminiService.sendMessage(
        systemPrompt: apiData.systemPrompt,
        contents: apiData.contents,
        promptParameters: apiData.parameters,
        chatRoomId: widget.chatRoomId,
        characterId: _character?.id,
      );

      final tokenCount = geminiResponse.usageMetadata?.candidatesTokenCount ??
          TokenCounter.estimateTokenCount(geminiResponse.text, tokenizer: tokenizer);
      final assistantMessage = ChatMessage(
        chatRoomId: widget.chatRoomId,
        role: MessageRole.assistant,
        content: geminiResponse.text,
        tokenCount: tokenCount,
        usageMetadata: geminiResponse.usageMetadata,
        modelId: geminiResponse.modelId,
      );

      final assistantMessageId = await _db.createChatMessage(assistantMessage);

      await _saveMessageMetadata(assistantMessageId, geminiResponse.text);

      // 채팅방 토큰 합산 업데이트
      await _db.updateChatRoomTotalTokenCount(widget.chatRoomId);

      final updatedChatRoom = _chatRoom!.copyWith(
        updatedAt: DateTime.now(),
      );
      await _db.updateChatRoom(updatedChatRoom);

    } catch (e) {
      debugPrint('Error resending message: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('메시지 재전송 중 오류가 발생했습니다: $e')),
      );
    } finally {
      await _loadChatData();
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<String> _generateBranchName() async {
    final currentName = _chatRoom!.name;

    // 기존 이름에서 베이스 이름 추출 (예: "채팅방(2)" -> "채팅방")
    final branchPattern = RegExp(r'^(.+)\((\d+)\)$');
    final match = branchPattern.firstMatch(currentName);
    final baseName = match != null ? match.group(1)! : currentName;

    // 같은 캐릭터의 모든 채팅방 조회
    final allChatRooms = await _db.readChatRoomsByCharacter(_chatRoom!.characterId);

    // 같은 베이스 이름을 가진 채팅방들의 숫자 추출
    int maxNumber = 0;
    final namePattern = RegExp('^${RegExp.escape(baseName)}\\((\\d+)\\)\$');

    for (final room in allChatRooms) {
      final roomMatch = namePattern.firstMatch(room.name);
      if (roomMatch != null) {
        final number = int.parse(roomMatch.group(1)!);
        if (number > maxNumber) {
          maxNumber = number;
        }
      }
    }

    return '$baseName(${maxNumber + 1})';
  }

  Future<void> _createBranch(int messageIndex) async {
    final confirmed = await CommonDialog.showConfirmation(
      context: context,
      title: '분기 생성',
      content: '이 메시지까지의 내용으로 새 분기점을 생성하시겠습니까?',
      confirmText: '생성',
    );

    if (confirmed != true) return;

    try {
      if (_chatRoom == null || _character == null) return;

      // 새 채팅방 생성
      final branchName = await _generateBranchName();
      final newChatRoom = ChatRoom(
        characterId: _chatRoom!.characterId,
        name: branchName,
        selectedChatPromptId: _chatRoom!.selectedChatPromptId,
        selectedPersonaId: _chatRoom!.selectedPersonaId,
        selectedStartScenarioId: _chatRoom!.selectedStartScenarioId,
      );

      final newChatRoomId = await _db.createChatRoom(newChatRoom);

      // 분기점까지의 메시지 복사
      for (int i = 0; i <= messageIndex; i++) {
        final msg = _messages[i];
        final newMessage = ChatMessage(
          chatRoomId: newChatRoomId,
          role: msg.role,
          content: msg.content,
          tokenCount: msg.tokenCount,
          createdAt: msg.createdAt,
          usageMetadata: msg.usageMetadata,
          modelId: msg.modelId,
        );
        await _db.createChatMessage(newMessage);
      }

      // 새 채팅방 토큰 합산 업데이트
      await _db.updateChatRoomTotalTokenCount(newChatRoomId);

      if (!mounted) return;

      CommonDialog.showSnackBar(
        context: context,
        message: '분기가 생성되었습니다',
      );

      // 새 채팅방으로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatRoomScreen(chatRoomId: newChatRoomId),
        ),
      );
    } catch (e) {
      debugPrint('Error creating branch: $e');
      if (!mounted) return;
      CommonDialog.showSnackBar(
        context: context,
        message: '분기 생성 중 오류가 발생했습니다',
      );
    }
  }

  Future<void> _regenerateMessage(int messageId) async {
    if (_isSending) return;

    setState(() => _isSending = true);

    try {
      final tokenizerProvider = context.read<TokenizerProvider>();
      final tokenizer = tokenizerProvider.selectedTokenizer;
      final message = await _db.readChatMessage(messageId);
      if (message == null) return;

      final messageIndex = _messages.indexWhere((m) => m.id == messageId);
      if (messageIndex <= 0) return;

      final previousMessage = _messages[messageIndex - 1];
      if (previousMessage.role != MessageRole.user) return;

      final apiData = await _buildApiData(
        userMessage: previousMessage.content,
        beforeMessageIndex: messageIndex - 1,
      );

      final geminiResponse = await _geminiService.sendMessage(
        systemPrompt: apiData.systemPrompt,
        contents: apiData.contents,
        promptParameters: apiData.parameters,
        chatRoomId: widget.chatRoomId,
        characterId: _character?.id,
      );

      final tokenCount = geminiResponse.usageMetadata?.candidatesTokenCount ??
          TokenCounter.estimateTokenCount(geminiResponse.text, tokenizer: tokenizer);
      final updatedMessage = message.copyWith(
        content: geminiResponse.text,
        tokenCount: tokenCount,
        editedAt: DateTime.now(),
        usageMetadata: geminiResponse.usageMetadata,
        modelId: geminiResponse.modelId,
      );

      await _db.updateChatMessage(updatedMessage);

      await _db.deleteChatMessageMetadataByMessage(messageId);
      await _saveMessageMetadata(messageId, geminiResponse.text);

      // 채팅방 토큰 합산 업데이트
      await _db.updateChatRoomTotalTokenCount(widget.chatRoomId);
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

  Widget _buildChatHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildWarningCard(),
          if (_startScenario?.startSetting != null &&
              _startScenario!.startSetting!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildStartSettingCard(),
          ],
          if (_startScenario?.startMessage != null &&
              _startScenario!.startMessage!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildStartMessageBubble(),
          ],
        ],
      ),
    );
  }

  Widget _buildWarningCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  '주의',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '모든 AI 응답은 자동 생성되며, 편향적이거나 부정확할 수 있습니다.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartSettingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '시작 설정',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _startScenario!.startSetting!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartMessageBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          _startScenario!.startMessage!,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }

  void _showUsageMetadataDialog(ChatMessage message) {
    final metadata = message.usageMetadata;
    if (metadata == null) {
      CommonDialog.showSnackBar(
        context: context,
        message: '통계 정보가 없습니다',
      );
      return;
    }

    final model = message.modelId != null ? ChatModel.fromModelId(message.modelId!) : null;

    double? cost;
    if (model != null) {
      cost = model.pricing.calculateCost(
        promptTokens: metadata.promptTokenCount,
        cachedTokens: metadata.cachedContentTokenCount ?? 0,
        outputTokens: metadata.candidatesTokenCount,
        thinkingTokens: metadata.thoughtsTokenCount ?? 0,
      );
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('응답 통계'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (model != null)
              _buildStatRow('모델', model.displayName),
            if (model != null) const Divider(),
            _buildStatRow('입력 토큰', '${metadata.promptTokenCount}'),
            if (metadata.cachedContentTokenCount != null) ...[
              _buildStatRow('캐시 토큰', '${metadata.cachedContentTokenCount}'),
              _buildStatRow('캐시 비율', '${(metadata.cacheRatio * 100).toStringAsFixed(1)}%'),
            ],
            const Divider(),
            _buildStatRow('출력 토큰', '${metadata.candidatesTokenCount}'),
            if (metadata.thoughtsTokenCount != null) ...[
              _buildStatRow('생각 토큰', '${metadata.thoughtsTokenCount}'),
              _buildStatRow('생각 비율', '${(metadata.thoughtsRatio * 100).toStringAsFixed(1)}%'),
            ],
            const Divider(),
            _buildStatRow('총 토큰', '${metadata.totalTokenCount}'),
            if (cost != null) ...[
              const Divider(),
              _buildStatRow('예상 비용', '\$${cost.toStringAsFixed(6)}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          )),
        ],
      ),
    );
  }

  static const _dayNames = ['월', '화', '수', '목', '금', '토', '일'];

  String _formatMetadataDateTime(String? date, String? time) {
    final parts = <String>[];
    if (date != null) {
      final segments = date.split('.');
      if (segments.length == 3) {
        final year = int.tryParse(segments[0]);
        final month = int.tryParse(segments[1]);
        final day = int.tryParse(segments[2]);
        if (year != null && month != null && day != null) {
          final dt = DateTime(year, month, day);
          final dayName = _dayNames[dt.weekday - 1];
          parts.add('$date($dayName)');
        } else {
          parts.add(date);
        }
      } else {
        parts.add(date);
      }
    }
    if (time != null) {
      final timeParts = time.split(':');
      if (timeParts.length == 2) {
        final hour = int.tryParse(timeParts[0]);
        if (hour != null) {
          final period = (hour >= 6 && hour < 18) ? '낮' : '밤';
          parts.add('$time($period)');
        } else {
          parts.add(time);
        }
      } else {
        parts.add(time);
      }
    }
    return parts.join(' ');
  }

  Widget _buildMetadataHeader(ChatMessageMetadata metadata) {
    final metaStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    final hasDateTime = metadata.date != null || metadata.time != null;
    final location = metadata.location;

    // 장소를 쉼표 기준으로 분리
    String? locationMain;
    String? locationSub;
    if (location != null) {
      final commaIndex = location.indexOf(',');
      if (commaIndex != -1) {
        locationMain = location.substring(0, commaIndex).trim();
        locationSub = location.substring(commaIndex + 1).trim();
      } else {
        locationMain = location;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (hasDateTime)
              Text(
                _formatMetadataDateTime(metadata.date, metadata.time),
                style: metaStyle,
              )
            else
              const SizedBox.shrink(),
            if (locationMain != null)
              Text(locationMain, style: metaStyle),
          ],
        ),
        if (locationSub != null)
          Text(locationSub, style: metaStyle),
      ],
    );
  }

  Widget _buildMessage(ChatMessage message, int index) {
    final isUser = message.role == MessageRole.user;
    final isEditing = _editingMessageId == message.id;
    final isLastMessage = index == _messages.length - 1;
    final hasUsageMetadata = !isUser && message.usageMetadata != null;
    final metadata = message.id != null ? _metadataMap[message.id!] : null;
    final hasMetadata = !isUser && metadata != null &&
        (metadata.date != null || metadata.time != null || metadata.location != null);
    final viewer = context.watch<ViewerSettingsProvider>();

    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16 + viewer.paragraphWidth,
            vertical: 0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasMetadata)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _buildMetadataHeader(metadata),
                ),
              if (isEditing)
                CommonEditText(
                  controller: _editControllers[message.id],
                  size: CommonEditTextSize.small,
                  maxLines: null,
                )
              else
                MarkdownText(
                  text: message.content,
                  baseStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: viewer.fontSize,
                    height: viewer.lineHeight,
                  ),
                  textAlign: viewer.textAlign,
                  paragraphSpacing: viewer.paragraphSpacing,
                ),
              const SizedBox(height: 0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (hasUsageMetadata) ...[
                    IconButton(
                      icon: const Icon(Icons.bar_chart, size: 18),
                      onPressed: () => _showUsageMetadataDialog(message),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                    ),
                  ],
                  if (hasMetadata) ...[
                    IconButton(
                      icon: Icon(
                        metadata.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                        size: 18,
                        color: metadata.isPinned
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                      onPressed: () => _togglePin(message.id!),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                    ),
                  ],
                  const Spacer(),
                  if (isEditing) ...[
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: _cancelEditMessage,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                    ),
                    const SizedBox(width: 0),
                    IconButton(
                      icon: const Icon(Icons.check, size: 18),
                      onPressed: () => _saveEditMessage(message),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                    ),
                  ] else ...[
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () => _startEditMessage(message),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                    ),
                    const SizedBox(width: 0),
                    IconButton(
                      icon: const Icon(Icons.call_split, size: 18),
                      onPressed: () => _createBranch(index),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                    ),
                    const SizedBox(width: 0),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: () => _deleteMessage(message.id!),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                    ),
                    if (isLastMessage) ...[
                      const SizedBox(width: 0),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 18),
                        onPressed: isUser
                          ? _resendLastUserMessage
                          : () => _regenerateMessage(message.id!),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                      ),
                    ],
                  ],
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 8),
          child: Divider(
            height: 1,
            thickness: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
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
      appBar: CommonAppBar(
        title: _character!.name,
        titleWidget: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CharacterViewScreen(characterId: _character!.id!),
              ),
            );
          },
          child: Row(
            children: [
              _buildCharacterAvatar(),
              const SizedBox(width: 12),
              Text(_character!.name),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_showBottomPanel) {
                  setState(() => _showBottomPanel = false);
                }
              },
              child: ListView.builder(
                controller: _scrollController,
                reverse: true,
                itemCount: _messages.length + 1,
                itemBuilder: (context, index) {
                  if (index == _messages.length) {
                    return _buildChatHeader();
                  }
                  final messageIndex = _messages.length - 1 - index;
                  return _buildMessage(_messages[messageIndex], messageIndex);
                },
              ),
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
                child: CommonEditText(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  enabled: !_isSending,
                  hintText: _isSending ? '전송 중...' : '메시지를 입력하세요',
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Transform.translate(
                        offset: const Offset(8, 0),
                        child: IconButton(
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
                      IconButton(
                        icon: Icon(
                          Icons.more_vert,
                          color: _showBottomPanel
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        onPressed: _toggleBottomPanel,
                        padding: const EdgeInsets.only(left: 0, top: 8, right: 8, bottom: 8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_showBottomPanel)
            ChatBottomPanel(
              chatRoom: _chatRoom!,
              chatPrompts: _chatPrompts,
              personas: _personas,
              onModelChanged: _onModelChanged,
              onPromptChanged: _onPromptChanged,
              onPersonaChanged: _onPersonaChanged,
            ),
        ],
      ),
    );
  }
}
