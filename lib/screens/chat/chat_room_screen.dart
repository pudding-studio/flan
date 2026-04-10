import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
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
import '../../models/prompt/prompt_condition.dart';
import '../../models/prompt/prompt_condition_preset.dart';
import '../../models/prompt/prompt_condition_preset_value.dart';
import '../../models/prompt/prompt_regex_rule.dart';
import '../../utils/regex_processor.dart';
import '../../database/database_helper.dart';
import '../../providers/tokenizer_provider.dart';
import '../../utils/prompt_builder.dart';
import '../../utils/common_dialog.dart';
import '../../utils/token_counter.dart';
import '../../services/ai_service.dart';
import '../../services/agent_summary_service.dart';
import '../../services/auto_summary_service.dart';
import '../../models/chat/chat_message_metadata.dart';
import '../../models/chat/chat_summary.dart';
import '../../models/chat/chat_model.dart';
import '../../models/chat/unified_model.dart';
import '../../models/community/community_comment.dart';
import '../../models/news/news_article.dart';
import '../../utils/metadata_parser.dart';
import '../../widgets/common/common_character_card.dart';
import '../../widgets/common/common_appbar.dart';
import '../../widgets/common/common_settings.dart';
import '../../widgets/common/common_edit_text.dart';
import '../../providers/chat_model_provider.dart';
import '../../providers/localization_provider.dart';
import '../../providers/viewer_settings_provider.dart';
import 'widgets/chat_bottom_panel.dart';
import 'widgets/chat_room_drawer.dart';
import '../character/character_view_screen.dart';
import '../community/community_screen.dart';
import '../news/news_screen.dart';
import '../diary/diary_screen.dart';

enum SendingPhase { none, preparing, waiting, summarizing }

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<ChatRoomDrawerState> _drawerKey = GlobalKey<ChatRoomDrawerState>();
  DrawerTab _drawerTab = DrawerTab.info;
  final DatabaseHelper _db = DatabaseHelper.instance;
  final AiService _aiService = AiService();
  final AutoSummaryService _autoSummaryService = AutoSummaryService();
  final TextEditingController _messageController = TextEditingController();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  ChatRoom? _chatRoom;
  Character? _character;
  StartScenario? _startScenario;
  List<ChatMessage> _messages = [];
  List<CoverImage> _coverImages = [];
  List<CoverImage> _additionalImages = [];
  Map<String, String> _imagePathMap = {}; // image name → file path
  bool _isLoading = true;
  SendingPhase _sendingPhase = SendingPhase.none;
  int _retryAttempt = 0;
  bool get _isSending => _sendingPhase != SendingPhase.none;
  int? _editingMessageId;
  final Map<int, TextEditingController> _editControllers = {};
  Map<int, ChatMessageMetadata> _metadataMap = {};
  int? _summaryThresholdIndex;
  Set<int> _summarizedMessageIds = {};
  bool _showMorePanel = false;
  bool _showScrollButtons = false;
  bool _hasNewMessage = false;
  List<ChatPrompt> _chatPrompts = [];
  List<Persona> _personas = [];
  List<PromptRegexRule> _regexRules = [];
  final FocusNode _messageFocusNode = FocusNode();

  // Search
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  // Each entry: (messageIndex, occurrenceIndex within that message)
  List<(int msgIdx, int occIdx)> _searchMatches = [];
  int _currentSearchIndex = -1;
  GlobalKey _searchHighlightKey = GlobalKey();
  bool _highlightKeyActive = false;

  @override
  void initState() {
    super.initState();
    _messageFocusNode.addListener(_onMessageFocusChanged);
    _itemPositionsListener.itemPositions.addListener(_onScrollChanged);
    _loadChatData();
  }

  void _onScrollChanged() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;
    final minIndex = positions.map((p) => p.index).reduce((a, b) => a < b ? a : b);
    final show = minIndex > 3;
    if (show != _showScrollButtons || (!show && _hasNewMessage)) {
      setState(() {
        _showScrollButtons = show;
        if (!show) _hasNewMessage = false;
      });
    }
  }

  void _onMessageFocusChanged() {
    if (_messageFocusNode.hasFocus && _showMorePanel) {
      setState(() => _showMorePanel = false);
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchMatches = [];
        _currentSearchIndex = -1;
      } else {
        _searchFocusNode.requestFocus();
      }
    });
  }

  static final _imageMarkdownPattern = RegExp(r'!\[[^\]]*\]\([^)]+\)');

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchMatches = [];
        _currentSearchIndex = -1;
      });
      return;
    }

    final lowerQuery = query.toLowerCase();
    final matches = <(int, int)>[];
    for (int i = 0; i < _messages.length; i++) {
      // Strip image markdown to match what MarkdownText actually renders as text
      var displayText = _buildDisplayContent(_messages[i].content);
      displayText = displayText.replaceAll(_imageMarkdownPattern, '');
      final lowerContent = displayText.toLowerCase();
      int start = 0;
      int occIdx = 0;
      while (true) {
        final pos = lowerContent.indexOf(lowerQuery, start);
        if (pos == -1) break;
        matches.add((i, occIdx));
        occIdx++;
        start = pos + lowerQuery.length;
      }
    }

    setState(() {
      _searchMatches = matches;
      _currentSearchIndex = matches.isNotEmpty ? 0 : -1;
    });

    if (matches.isNotEmpty) {
      _scrollToSearchResult(0);
    }
  }

  void _navigateSearch(int direction) {
    if (_searchMatches.isEmpty) return;
    setState(() {
      _currentSearchIndex =
          (_currentSearchIndex + direction) % _searchMatches.length;
      if (_currentSearchIndex < 0) {
        _currentSearchIndex = _searchMatches.length - 1;
      }
    });
    _scrollToSearchResult(_currentSearchIndex);
  }

  void _scrollToSearchResult(int searchIndex) {
    final (messageIndex, _) = _searchMatches[searchIndex];
    final listIndex = _messages.length - 1 - messageIndex;

    void doEnsureVisible() {
      setState(() {
        _searchHighlightKey = GlobalKey();
        _highlightKeyActive = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_searchHighlightKey.currentContext != null) {
          Scrollable.ensureVisible(
            _searchHighlightKey.currentContext!,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            alignment: 0.0,
          ).then((_) {
            if (mounted) setState(() => _highlightKeyActive = false);
          });
        } else {
          setState(() => _highlightKeyActive = false);
        }
      });
    }

    // Check if the item is already on screen
    final positions = _itemPositionsListener.itemPositions.value;
    final isOnScreen = positions.any((p) => p.index == listIndex);

    if (isOnScreen) {
      doEnsureVisible();
    } else {
      // Jump first, wait for settle, then assign key
      _itemScrollController.jumpTo(index: listIndex, alignment: 0.5);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        doEnsureVisible();
      });
    }
  }

  @override
  void dispose() {
    _messageFocusNode.removeListener(_onMessageFocusChanged);
    _messageFocusNode.dispose();
    _messageController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _itemPositionsListener.itemPositions.removeListener(_onScrollChanged);
    for (var controller in _editControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadChatData({bool showLoading = true}) async {
    if (showLoading && mounted) setState(() => _isLoading = true);

    try {
      final chatRoom = await _db.readChatRoom(widget.chatRoomId);
      if (chatRoom == null) {
        throw Exception('채팅방을 찾을 수 없습니다');
      }

      final character = await _db.readCharacter(chatRoom.characterId);
      final messages = await _db.readChatMessagesByChatRoom(widget.chatRoomId);
      final coverImages = await _db.readCoverImages(chatRoom.characterId);
      final additionalImages = await _db.readAdditionalImages(chatRoom.characterId);
      // Build name→path map for <img="name"> tag resolution
      final imagePathMap = <String, String>{};
      for (final img in [...coverImages, ...additionalImages]) {
        if (img.path != null && img.name.isNotEmpty) {
          imagePathMap[img.name] = img.path!;
        }
      }
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

      final regexRules = chatRoom.selectedChatPromptId != null
          ? await _db.readPromptRegexRules(chatRoom.selectedChatPromptId!)
          : <PromptRegexRule>[];

      // Load summarized message IDs and calculate threshold index
      final summarizedIds = await _autoSummaryService.getSummarizedMessageIds(widget.chatRoomId);
      int? summaryThresholdIndex;
      final summarySettings = await _db.getAutoSummarySettings(0);
      if (summarySettings != null && summarySettings.isEnabled && messages.isNotEmpty) {
        int cumulative = 0;
        for (int i = messages.length - 1; i >= 0; i--) {
          cumulative += messages[i].tokenCount;
          if (cumulative >= summarySettings.tokenThreshold) {
            summaryThresholdIndex = i;
            break;
          }
        }
      }

      if (!mounted) return;

      // Restore per-room model selection (only for custom preset)
      if (chatRoom.modelPreset == 'custom' && chatRoom.selectedModelId != null) {
        final modelProvider = context.read<ChatModelSettingsProvider>();
        final savedId = chatRoom.selectedModelId!;
        final available = modelProvider.availableModels;
        final match = available.where((m) => m.id == savedId);
        if (match.isNotEmpty && modelProvider.selectedModel.id != savedId) {
          await modelProvider.setModel(match.first);
        }
      }
      setState(() {
        _chatRoom = chatRoom;
        _character = character;
        _startScenario = startScenario;
        _messages = messages;
        _coverImages = coverImages;
        _additionalImages = additionalImages;
        _imagePathMap = imagePathMap;
        _metadataMap = metadataMap;
        _summaryThresholdIndex = summaryThresholdIndex;
        _summarizedMessageIds = summarizedIds;
        _chatPrompts = chatPrompts;
        _personas = personas;
        _regexRules = regexRules;
        _isLoading = false;
      });

    } catch (e) {
      debugPrint('Error loading chat data: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }


  Future<({String systemPrompt, List<Map<String, dynamic>> contents, PromptParameters? parameters, List<PromptRegexRule> regexRules})> _buildApiData({
    required String userMessage,
    List<int>? excludeMessageIds,
    int? beforeMessageIndex,
  }) async {
    if (_chatRoom == null || _character == null) {
      return (systemPrompt: '', contents: <Map<String, dynamic>>[], parameters: null, regexRules: <PromptRegexRule>[]);
    }

    // Capture AI response language before any async gaps
    final aiLanguageCode =
        context.read<LocalizationProvider>().effectiveAiLanguage;

    // Stage 1: Load prompt frame
    ChatPrompt? chatPrompt;
    if (_chatRoom!.selectedChatPromptId != null) {
      chatPrompt = await _db.readChatPrompt(_chatRoom!.selectedChatPromptId!);
    }

    // Load regex rules for this prompt
    final List<PromptRegexRule> regexRules = chatPrompt?.id != null
        ? await _db.readPromptRegexRules(chatPrompt!.id!)
        : [];

    // Stage 3 (pre): Apply inputModify to user message (API-only, DB message unchanged)
    final apiUserMessage = RegexProcessor.apply(userMessage, regexRules, RegexTarget.inputModify);

    Persona? persona;
    if (_chatRoom!.selectedPersonaId != null) {
      persona = await _db.readPersona(_chatRoom!.selectedPersonaId!);
    }

    StartScenario? startScenario;
    if (_chatRoom!.selectedStartScenarioId != null) {
      startScenario = await _db.readStartScenario(_chatRoom!.selectedStartScenarioId!);
    }

    // Stage 2.1: Filter character books (enabled only, ordered by insertionOrder in PromptBuilder)
    final allCharacterBooks = await _db.readCharacterBooks(_character!.id!);
    final activeCharacterBooks = allCharacterBooks
        .where((b) => b.enabled == CharacterBookActivationCondition.enabled)
        .toList();

    final summaries = await _db.getChatSummaries(widget.chatRoomId);

    final summaryMetadataMap = <int, ChatMessageMetadata>{};
    for (final summary in summaries) {
      final metadata = await _db.readChatMessageMetadataByMessage(summary.endPinMessageId);
      if (metadata != null) {
        summaryMetadataMap[summary.endPinMessageId] = metadata;
      }
    }

    // Load condition states from selected preset
    List<PromptCondition>? conditions;
    Map<int, String>? conditionStates;
    if (chatPrompt != null) {
      conditions = await _db.readPromptConditions(chatPrompt.id!);
      for (final condition in conditions) {
        final options = await _db.readPromptConditionOptions(condition.id!);
        condition.options.addAll(options);
      }

      final presets = await _db.readPromptConditionPresets(chatPrompt.id!);
      PromptConditionPreset? selectedPreset;
      final presetId = _chatRoom!.selectedConditionPresetId;
      if (presetId != null) {
        try {
          selectedPreset = presets.firstWhere((p) => p.id == presetId);
        } catch (_) {}
      }
      selectedPreset ??= presets.where((p) => p.isDefault).firstOrNull ?? presets.firstOrNull;

      if (selectedPreset != null) {
        final values = await _db.readPromptConditionPresetValues(selectedPreset.id!);
        conditionStates = {};
        for (final v in values) {
          if (v.conditionId != null) {
            if (v.value == PromptConditionPresetValue.customOptionKey) {
              conditionStates[v.conditionId!] = v.customValue ?? '';
            } else {
              conditionStates[v.conditionId!] = v.value;
            }
          }
        }
      }
    }

    final tokenizerProvider = context.read<TokenizerProvider>();
    final tokenizer = tokenizerProvider.selectedTokenizer;

    // Load agent context if agent mode is enabled
    String? agentContext;
    final summarySettings = await _db.getAutoSummarySettings(0);
    if (summarySettings != null && summarySettings.isAgentEnabled) {
      final agentService = AgentSummaryService();
      final maxInputTokens = chatPrompt?.parameters?.maxInputTokens;

      int? episodeBudget;
      if (maxInputTokens != null && maxInputTokens > 0) {
        // Probe: build agent context with no episode contents (just lists +
        // non-episode sections), then measure how many tokens are consumed by
        // the rest of the prompt frame to derive the remaining budget for
        // episode contents.
        final baselineAgentContext = await agentService.buildActiveEntriesText(
          widget.chatRoomId,
          episodeContentTokenBudget: 0,
          tokenizer: tokenizer,
        );

        final consumedByItem = chatPrompt?.items.any((item) =>
                item.content.contains('{{agent_context}}')) ??
            false;

        var baselineSystemPrompt = PromptBuilder.buildSystemPrompt(
          chatPrompt: chatPrompt,
          character: _character!,
          persona: persona,
          startScenario: startScenario,
          activeCharacterBooks: activeCharacterBooks,
          chatRoom: _chatRoom,
          summaries: summaries,
          summaryMetadataMap: summaryMetadataMap,
          conditions: conditions,
          conditionStates: conditionStates,
          agentContext: baselineAgentContext,
        );
        // Mirror the auto-append logic used after the real system prompt build.
        if (!consumedByItem && baselineAgentContext.isNotEmpty) {
          baselineSystemPrompt = baselineSystemPrompt.isEmpty
              ? baselineAgentContext
              : '$baselineSystemPrompt\n\n$baselineAgentContext';
        }

        int baseline = TokenCounter.estimateTokenCount(
          baselineSystemPrompt,
          tokenizer: tokenizer,
        );
        baseline += TokenCounter.estimateTokenCount(
          apiUserMessage,
          tokenizer: tokenizer,
        );
        if (chatPrompt != null) {
          final states = conditionStates ?? <int, String>{};
          for (final item in chatPrompt.items) {
            if (item.role == PromptRole.system ||
                item.role == PromptRole.chat) {
              continue;
            }
            if (!PromptBuilder.isItemActive(item, states)) continue;
            // Resolve {{agent_context}} so the baseline reflects the actual
            // user/assistant payload that will be sent.
            final resolved = item.content.replaceAll(
              '{{agent_context}}',
              baselineAgentContext,
            );
            baseline += TokenCounter.estimateTokenCount(
              resolved,
              tokenizer: tokenizer,
            );
          }
        }

        episodeBudget = maxInputTokens - baseline;
        if (episodeBudget < 0) episodeBudget = 0;
      }

      agentContext = await agentService.buildActiveEntriesText(
        widget.chatRoomId,
        episodeContentTokenBudget: episodeBudget,
        tokenizer: tokenizer,
      );
    }

    // Stage 1+2: Build frame and apply keyword substitution
    String rawSystemPrompt = PromptBuilder.buildSystemPrompt(
      chatPrompt: chatPrompt,
      character: _character!,
      persona: persona,
      startScenario: startScenario,
      activeCharacterBooks: activeCharacterBooks,
      chatRoom: _chatRoom,
      summaries: summaries,
      summaryMetadataMap: summaryMetadataMap,
      conditions: conditions,
      conditionStates: conditionStates,
      agentContext: agentContext,
    );

    // Auto-append agent context only when no prompt item consumes the
    // {{agent_context}} keyword. If any item (system/user/assistant) uses the
    // placeholder, it will be substituted in its own slot — appending here
    // would duplicate the text and place a copy at the very front of the
    // conversation.
    if (agentContext != null && agentContext.isNotEmpty) {
      final consumedByItem = chatPrompt?.items.any((item) =>
              item.content.contains('{{agent_context}}')) ??
          false;
      if (!consumedByItem) {
        rawSystemPrompt = rawSystemPrompt.isEmpty
            ? agentContext
            : '$rawSystemPrompt\n\n$agentContext';
      }
    }

    // Exclude old messages from chat history
    Set<int> contextExcludeIds;
    if (summarySettings != null && summarySettings.isAgentEnabled) {
      // Agent mode: keep messages from 2 summary periods ago onwards
      final period = _chatRoom!.autoPinByMessageCount ?? 10;
      contextExcludeIds = await _autoSummaryService.getAgentModeExcludeIds(
        chatRoomId: widget.chatRoomId,
        period: period,
      );
    } else {
      contextExcludeIds = await _autoSummaryService.getSummarizedMessageIds(widget.chatRoomId);
    }
    final allExcludeIds = {...contextExcludeIds, ...?excludeMessageIds};

    final chatHistoryMap = await _buildChatHistoryMap(
      chatPrompt: chatPrompt,
      excludeMessageIds: allExcludeIds.toList(),
      beforeMessageIndex: beforeMessageIndex,
    );

    final rawContents = PromptBuilder.buildContents(
      chatPrompt: chatPrompt,
      character: _character!,
      userMessage: apiUserMessage,
      chatHistoryMap: chatHistoryMap,
      systemPrompt: rawSystemPrompt,
      persona: persona,
      startScenario: startScenario,
      activeCharacterBooks: activeCharacterBooks,
      maxInputTokens: chatPrompt?.parameters?.maxInputTokens,
      tokenizer: tokenizer,
      metadataMap: _metadataMap,
      chatRoom: _chatRoom,
      summaries: summaries,
      summaryMetadataMap: summaryMetadataMap,
      conditions: conditions,
      conditionStates: conditionStates,
      agentContext: agentContext,
    );

    // Stage 3: Apply sendDataModify to the fully assembled prompt data
    var systemPrompt = RegexProcessor.apply(rawSystemPrompt, regexRules, RegexTarget.sendDataModify);
    final contents = RegexProcessor.applyToContents(rawContents, regexRules, RegexTarget.sendDataModify);

    // Append AI response language instruction (user-selected or app locale)
    final langInstruction = _languageInstructionFor(aiLanguageCode);
    if (langInstruction.isNotEmpty) {
      systemPrompt = systemPrompt.isEmpty
          ? langInstruction
          : '$systemPrompt\n\n$langInstruction';
    }

    return (systemPrompt: systemPrompt, contents: contents, parameters: chatPrompt?.parameters, regexRules: regexRules);
  }

  String _languageInstructionFor(String code) {
    switch (code) {
      case 'ko':
        return '[Language] Always respond in Korean (한국어).';
      case 'en':
        return '[Language] Always respond in English.';
      case 'ja':
        return '[Language] Always respond in Japanese (日本語).';
      default:
        return '';
    }
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

    setState(() => _sendingPhase = SendingPhase.preparing);

    try {
      // Fetch and prepend unused favorite community posts
      final favoritePosts = await _db.readUnusedFavoritePosts(widget.chatRoomId);
      String favoritePrefix = '';
      if (favoritePosts.isNotEmpty) {
        final parts = favoritePosts.map((p) {
          final buf = StringBuffer('[${p.author}] ${p.title}\n${p.content}');
          for (final c in p.comments) {
            buf.write('\n  ㄴ ${c.author}: ${c.content}');
          }
          return buf.toString();
        });
        favoritePrefix = '【SNS|${parts.join('\n\n')}】';
      }

      final tokenizerProvider = context.read<TokenizerProvider>();
      final tokenizer = tokenizerProvider.selectedTokenizer;
      String combinedUserMessage;
      int excludeId;

      if (_messages.isNotEmpty && _messages.last.role == MessageRole.user) {
        final lastUserMessage = _messages.last;
        final baseContent = text.isEmpty
            ? lastUserMessage.content
            : '${lastUserMessage.content}\n$text';
        combinedUserMessage = favoritePrefix.isNotEmpty
            ? '$favoritePrefix\n\n$baseContent'
            : baseContent;

        final tokenCount = TokenCounter.estimateTokenCount(combinedUserMessage, tokenizer: tokenizer);
        final updatedUserMessage = lastUserMessage.copyWith(
          content: combinedUserMessage,
          tokenCount: tokenCount,
          editedAt: DateTime.now(),
        );
        await _db.updateChatMessage(updatedUserMessage);
        excludeId = lastUserMessage.id!;
      } else {
        combinedUserMessage = favoritePrefix.isNotEmpty
            ? '$favoritePrefix\n\n$text'
            : text;
        final tokenCount = TokenCounter.estimateTokenCount(combinedUserMessage, tokenizer: tokenizer);
        final userMessage = ChatMessage(
          chatRoomId: widget.chatRoomId,
          role: MessageRole.user,
          content: combinedUserMessage,
          tokenCount: tokenCount,
        );
        excludeId = await _db.createChatMessage(userMessage);
      }

      // Mark favorite posts as used
      if (favoritePosts.isNotEmpty) {
        await _db.markFavoritePostsAsUsed(favoritePosts.map((p) => p.id!).toList());
      }

      _messageController.clear();

      final apiData = await _buildApiData(
        userMessage: combinedUserMessage,
        excludeMessageIds: [excludeId],
      );

      if (mounted) setState(() => _sendingPhase = SendingPhase.waiting);

      final modelProvider = context.read<ChatModelSettingsProvider>();
      await modelProvider.initialized;
      final model = _resolveModel();
      final maxRetries = model.retryCount;
      Object? lastError;

      for (int attempt = 0; attempt <= maxRetries; attempt++) {
        try {
          if (attempt > 0) {
            debugPrint('Retrying sendMessage (attempt ${attempt + 1}/${maxRetries + 1})');
            if (mounted) setState(() {
              _sendingPhase = SendingPhase.waiting;
              _retryAttempt = attempt;
            });
          }

          final aiResponse = await _aiService.sendMessage(
            systemPrompt: apiData.systemPrompt,
            contents: apiData.contents,
            model: model,
            promptParameters: apiData.parameters,
            chatRoomId: widget.chatRoomId,
            characterId: _character?.id,
          );

          // Stage 3: Apply outputModify to AI response
          final responseText = RegexProcessor.apply(aiResponse.text, apiData.regexRules, RegexTarget.outputModify);

          final assistantTokenCount = aiResponse.usageMetadata?.candidatesTokenCount ??
              TokenCounter.estimateTokenCount(responseText, tokenizer: tokenizer);
          final assistantMessage = ChatMessage(
            chatRoomId: widget.chatRoomId,
            role: MessageRole.assistant,
            content: responseText,
            tokenCount: assistantTokenCount,
            usageMetadata: aiResponse.usageMetadata,
            modelId: aiResponse.modelId,
          );

          final assistantMessageId = await _db.createChatMessage(assistantMessage);

          final pinCreated = await _saveMessageMetadata(assistantMessageId, responseText);

          // 채팅방 토큰 합산 업데이트
          await _db.updateChatRoomTotalTokenCount(widget.chatRoomId);

          final updatedChatRoom = _chatRoom!.copyWith(
            updatedAt: DateTime.now(),
          );
          await _db.updateChatRoom(updatedChatRoom);

          // 자동 요약 트리거 체크: 새 핀이 생성된 경우에만 실행
          if (pinCreated) {
            final latestChatRoom = await _db.readChatRoom(widget.chatRoomId);
            if (latestChatRoom != null) {
              final shouldTrigger = await _autoSummaryService.shouldTriggerSummary(
                chatRoomId: widget.chatRoomId,
                currentTokenCount: latestChatRoom.totalTokenCount,
              );

              if (shouldTrigger) {
                if (mounted) setState(() => _sendingPhase = SendingPhase.summarizing);
                await _autoSummaryService.generateAllPendingSummaries(chatRoomId: widget.chatRoomId);
              }
            }
          }

          // Future plan: agent summary 이후에 실행하여 우선순위를 보장
          final agentSettings = await _db.getAutoSummarySettings(0);
          if (agentSettings != null && agentSettings.isAgentEnabled) {
            final agentService = AgentSummaryService();
            await agentService.processFuturePlan(widget.chatRoomId, responseText);
          }

          lastError = null;
          break;
        } catch (e) {
          lastError = e;
          debugPrint('sendMessage attempt ${attempt + 1} failed: $e');
          if (attempt >= maxRetries) break;
        }
      }

      if (lastError != null) {
        throw lastError!;
      }

    } catch (e) {
      debugPrint('Error sending message: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('메시지 전송 중 오류가 발생했습니다: $e')),
      );
    } finally {
      await _finishSending();
    }
  }

  Future<void> _deleteMessage(int messageId) async {
    final confirmed = await CommonDialog.showDeleteConfirmation(
      context: context,
      itemName: '이 메시지',
    );

    if (!confirmed) return;

    try {
      await _db.deleteChatMessageMetadataByMessage(messageId);
      await _db.deleteChatMessage(messageId);
      // 채팅방 토큰 합산 업데이트
      await _db.updateChatRoomTotalTokenCount(widget.chatRoomId);
      await _loadChatData(showLoading: false);
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

  static final _imgTagPattern = RegExp(r'<img="([^"]+)">');

  String _buildDisplayContent(String content) {
    var text = MetadataParser.removeMetadataTags(content);
    text = RegexProcessor.apply(text, _regexRules, RegexTarget.displayModify);
    // <img="이름"> → 캐릭터 이미지가 있으면 로컬 이미지로 변환, 없으면 삭제
    text = text.replaceAllMapped(_imgTagPattern, (match) {
      if (_chatRoom?.showImages == false) return '';
      final name = match.group(1)!;
      final path = _imagePathMap[name];
      if (path != null) {
        return '![$name]($path)';
      }
      return '';
    });
    if (_chatRoom?.showImages == false) {
      text = text.replaceAll(_imageMarkdownPattern, '');
    }
    return text;
  }


  String _buildEditableContent(ChatMessage message) {
    return message.content;
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
      final cleanedContent = rawContent;

      if (message.role == MessageRole.assistant && message.id != null) {
        final parsed = MetadataParser.parse(rawContent);

        if (parsed.location != null || parsed.date != null || parsed.time != null) {
          final existingMetadata = _metadataMap[message.id!];
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
        }
        // Existing metadata is preserved when no tags are present in edited content
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
      await _loadChatData(showLoading: false);
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

  /// Returns true if a new pin was created for this message.
  Future<bool> _saveMessageMetadata(int messageId, String content) async {
    final previous = await _db.readLatestChatMessageMetadata(widget.chatRoomId);
    final metadata = MetadataParser.buildMetadata(
      chatMessageId: messageId,
      chatRoomId: widget.chatRoomId,
      content: content,
      previous: previous,
    );

    bool shouldPin = false;
    if (_chatRoom != null && _chatRoom!.autoPinByMessageCount != null && _chatRoom!.autoPinByMessageCount! > 0) {
      final count = await _db.countMetadataSinceLastPin(widget.chatRoomId);
      if (count >= _chatRoom!.autoPinByMessageCount!) {
        shouldPin = true;
      }
    }
    final finalMetadata = shouldPin ? metadata.copyWith(isPinned: true) : metadata;

    final metadataId = await _db.createChatMessageMetadata(finalMetadata);
    setState(() {
      _metadataMap[messageId] = finalMetadata.copyWith(id: metadataId);
    });
    return shouldPin;
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

  void _showMoreMenu() {
    if (_showMorePanel) {
      setState(() => _showMorePanel = false);
    } else {
      FocusScope.of(context).unfocus();
      setState(() => _showMorePanel = true);
    }
  }

  Widget _buildMorePanel() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 6, bottom: 12),
          child: GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 20,
            crossAxisSpacing: 8,
            childAspectRatio: 0.85,
            children: [
              _buildMenuAppIcon(
                context,
                icon: Icons.forum_outlined,
                label: 'SNS',
                onTap: () {
                  setState(() => _showMorePanel = false);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CommunityScreen(
                        characterId: _character!.id!,
                        chatRoomId: widget.chatRoomId,
                      ),
                    ),
                  );
                },
              ),
              _buildMenuAppIcon(
                context,
                icon: Icons.newspaper_outlined,
                label: 'News',
                onTap: () {
                  setState(() => _showMorePanel = false);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NewsScreen(
                        characterId: _character!.id!,
                        chatRoomId: widget.chatRoomId,
                      ),
                    ),
                  );
                },
              ),
              _buildMenuAppIcon(
                context,
                icon: Icons.auto_stories_outlined,
                label: 'Diary',
                onTap: () {
                  setState(() => _showMorePanel = false);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DiaryScreen(
                        characterId: _character!.id!,
                        chatRoomId: widget.chatRoomId,
                      ),
                    ),
                  );
                },
              ),
              _buildMenuAppIcon(
                context,
                icon: Icons.text_fields,
                label: '텍스트 설정',
                onTap: () {
                  setState(() => _showMorePanel = false);
                  _showViewerSettings();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuAppIcon(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              size: 21,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showViewerSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const ChatBottomPanel(),
    );
  }

  Future<void> _finishSending() async {
    final wasScrolledUp = _showScrollButtons;
    await _loadChatData(showLoading: false);
    if (mounted) {
      setState(() {
        _sendingPhase = SendingPhase.none;
        _retryAttempt = 0;
        if (wasScrolledUp) _hasNewMessage = true;
      });
    }
  }

  UnifiedModel _resolveModel() {
    final provider = context.read<ChatModelSettingsProvider>();
    switch (_chatRoom?.modelPreset) {
      case 'secondary':
        return provider.subModel;
      case 'custom':
        return provider.selectedModel;
      default: // 'primary'
        return provider.selectedModel;
    }
  }

  Future<void> _onModelPresetChanged(String preset) async {
    if (_chatRoom == null) return;
    final updated = _chatRoom!.copyWith(
      modelPreset: preset,
      updatedAt: DateTime.now(),
    );
    await _db.updateChatRoom(updated);
    setState(() => _chatRoom = updated);
  }

  Future<void> _onModelChanged(UnifiedModel model) async {
    final provider = context.read<ChatModelSettingsProvider>();
    await provider.setModel(model);

    if (_chatRoom != null) {
      final updated = _chatRoom!.copyWith(selectedModelId: model.id);
      await _db.updateChatRoom(updated);
      _chatRoom = updated;
    }
  }

  Future<void> _onPromptChanged(int? promptId) async {
    if (_chatRoom == null) return;
    final updated = _chatRoom!.copyWith(
      selectedChatPromptId: promptId,
      updatedAt: DateTime.now(),
    );
    await _db.updateChatRoom(updated);
    setState(() => _chatRoom = updated);
  }

  Future<void> _onPresetChanged(int? presetId) async {
    if (_chatRoom == null) return;
    final updated = _chatRoom!.copyWith(
      selectedConditionPresetId: presetId,
      updatedAt: DateTime.now(),
    );
    await _db.updateChatRoom(updated);
    setState(() => _chatRoom = updated);
  }

  Future<void> _onShowImagesChanged(bool value) async {
    if (_chatRoom == null) return;
    final updated = _chatRoom!.copyWith(
      showImages: value,
      updatedAt: DateTime.now(),
    );
    await _db.updateChatRoom(updated);
    setState(() => _chatRoom = updated);
  }

  Future<void> _onPersonaChanged(int? personaId) async {
    if (_chatRoom == null) return;
    final updated = _chatRoom!.copyWith(
      selectedPersonaId: personaId,
      updatedAt: DateTime.now(),
    );
    await _db.updateChatRoom(updated);
    final personas = await _db.readPersonas(_chatRoom!.characterId);
    setState(() {
      _chatRoom = updated;
      _personas = personas;
    });
  }

  Future<void> _onAutoPinMessageCountChanged(int? count) async {
    if (_chatRoom == null) return;
    final updated = _chatRoom!.copyWith(
      autoPinByMessageCount: count,
      updatedAt: DateTime.now(),
    );
    await _db.updateChatRoom(updated);
    setState(() => _chatRoom = updated);
  }

  Future<void> _resendLastUserMessage() async {
    if (_isSending || _messages.isEmpty) return;

    final lastMessage = _messages.last;
    if (lastMessage.role != MessageRole.user) return;

    setState(() => _sendingPhase = SendingPhase.preparing);

    try {
      final tokenizerProvider = context.read<TokenizerProvider>();
      final tokenizer = tokenizerProvider.selectedTokenizer;

      final apiData = await _buildApiData(
        userMessage: lastMessage.content,
        excludeMessageIds: [lastMessage.id!],
      );

      if (mounted) setState(() => _sendingPhase = SendingPhase.waiting);

      final model = _resolveModel();
      final maxRetries = model.retryCount;
      Object? lastError;

      for (int attempt = 0; attempt <= maxRetries; attempt++) {
        try {
          if (attempt > 0) {
            debugPrint('Retrying resendLastUserMessage (attempt ${attempt + 1}/${maxRetries + 1})');
            if (mounted) setState(() => _sendingPhase = SendingPhase.waiting);
          }

          final aiResponse2 = await _aiService.sendMessage(
            systemPrompt: apiData.systemPrompt,
            contents: apiData.contents,
            model: model,
            promptParameters: apiData.parameters,
            chatRoomId: widget.chatRoomId,
            characterId: _character?.id,
          );

          // Stage 3: Apply outputModify to AI response
          final responseText2 = RegexProcessor.apply(aiResponse2.text, apiData.regexRules, RegexTarget.outputModify);

          final tokenCount = aiResponse2.usageMetadata?.candidatesTokenCount ??
              TokenCounter.estimateTokenCount(responseText2, tokenizer: tokenizer);
          final assistantMessage = ChatMessage(
            chatRoomId: widget.chatRoomId,
            role: MessageRole.assistant,
            content: responseText2,
            tokenCount: tokenCount,
            usageMetadata: aiResponse2.usageMetadata,
            modelId: aiResponse2.modelId,
          );

          final assistantMessageId = await _db.createChatMessage(assistantMessage);

          await _saveMessageMetadata(assistantMessageId, responseText2);

          // 채팅방 토큰 합산 업데이트
          await _db.updateChatRoomTotalTokenCount(widget.chatRoomId);

          final updatedChatRoom = _chatRoom!.copyWith(
            updatedAt: DateTime.now(),
          );
          await _db.updateChatRoom(updatedChatRoom);

          // Future plan: AI 응답에서 [PLAN: ...] 파싱하여 활성화
          final agentSettings2 = await _db.getAutoSummarySettings(0);
          if (agentSettings2 != null && agentSettings2.isAgentEnabled) {
            final agentService = AgentSummaryService();
            await agentService.processFuturePlan(widget.chatRoomId, responseText2);
          }

          lastError = null;
          break;
        } catch (e) {
          lastError = e;
          debugPrint('resendLastUserMessage attempt ${attempt + 1} failed: $e');
          if (attempt >= maxRetries) break;
        }
      }

      if (lastError != null) {
        throw lastError!;
      }

    } catch (e) {
      debugPrint('Error resending message: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('메시지 재전송 중 오류가 발생했습니다: $e')),
      );
    } finally {
      await _finishSending();
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

      // 새 채팅방 생성 (기존 설정 전체 복사, id 제외)
      final branchName = await _generateBranchName();
      final newChatRoom = ChatRoom(
        characterId: _chatRoom!.characterId,
        name: branchName,
        selectedChatPromptId: _chatRoom!.selectedChatPromptId,
        selectedPersonaId: _chatRoom!.selectedPersonaId,
        selectedStartScenarioId: _chatRoom!.selectedStartScenarioId,
        selectedConditionPresetId: _chatRoom!.selectedConditionPresetId,
        memo: _chatRoom!.memo,
        summary: _chatRoom!.summary,
        autoPinByMessageCount: _chatRoom!.autoPinByMessageCount,
        selectedModelId: _chatRoom!.selectedModelId,
        modelPreset: _chatRoom!.modelPreset,
      );

      final newChatRoomId = await _db.createChatRoom(newChatRoom);

      // 분기점까지의 메시지 및 메타데이터 복사 (old ID -> new ID 매핑 생성)
      final messageIdMap = <int, int>{};
      for (int i = 0; i <= messageIndex; i++) {
        final msg = _messages[i];
        final newMessage = ChatMessage(
          chatRoomId: newChatRoomId,
          role: msg.role,
          content: msg.content,
          tokenCount: msg.tokenCount,
          createdAt: msg.createdAt,
          editedAt: msg.editedAt,
          usageMetadata: msg.usageMetadata,
          modelId: msg.modelId,
        );
        final newMessageId = await _db.createChatMessage(newMessage);

        if (msg.id != null) {
          messageIdMap[msg.id!] = newMessageId;

          // 메타데이터 복사 (날짜, 시간, 장소, 핀 상태)
          final metadata = _metadataMap[msg.id!];
          if (metadata != null) {
            final newMetadata = ChatMessageMetadata(
              chatMessageId: newMessageId,
              chatRoomId: newChatRoomId,
              location: metadata.location,
              date: metadata.date,
              time: metadata.time,
              isPinned: metadata.isPinned,
              createdAt: metadata.createdAt,
            );
            await _db.createChatMessageMetadata(newMetadata);
          }
        }
      }

      // 요약 복사 (메시지 ID 매핑 적용)
      final summaries = await _db.getChatSummaries(_chatRoom!.id!);
      for (final summary in summaries) {
        final newEndId = messageIdMap[summary.endPinMessageId];
        if (newEndId == null) continue;

        final newStartId = summary.startPinMessageId == 0
            ? 0
            : messageIdMap[summary.startPinMessageId];
        if (newStartId == null) continue;

        await _db.createChatSummary(ChatSummary(
          chatRoomId: newChatRoomId,
          startPinMessageId: newStartId,
          endPinMessageId: newEndId,
          summaryContent: summary.summaryContent,
          tokenCount: summary.tokenCount,
          createdAt: summary.createdAt,
          updatedAt: summary.updatedAt,
        ));
      }

      // 자동 요약 설정 복사
      final autoSummarySettings =
          await _db.getAutoSummarySettings(_chatRoom!.id!);
      if (autoSummarySettings != null) {
        await _db.createAutoSummarySettings(autoSummarySettings.copyWith(
          id: null,
          chatRoomId: newChatRoomId,
        ));
      }

      // 에이전트 엔트리 복사 (요약/등장인물/장소/물품/사건)
      final agentIdMap = <int, int>{};
      final agentEntries = await _db.getAgentEntries(_chatRoom!.id!);
      for (final entry in agentEntries) {
        final newId = await _db.createAgentEntry(entry.copyWith(
          id: null,
          chatRoomId: newChatRoomId,
        ));
        if (entry.id != null) {
          agentIdMap[entry.id!] = newId;
        }
      }

      // SNS(커뮤니티) 게시글 및 댓글 복사
      final communityPosts = await _db.readCommunityPosts(_chatRoom!.id!);
      for (final post in communityPosts) {
        final newPostId = await _db.createCommunityPost(post.copyWith(
          id: null,
          chatRoomId: newChatRoomId,
        ));
        for (final comment in post.comments) {
          await _db.createCommunityComment(CommunityComment(
            postId: newPostId,
            author: comment.author,
            time: comment.time,
            content: comment.content,
          ));
        }
      }

      // 다이어리 복사
      final diaryEntries = await _db.readDiaryEntries(_chatRoom!.id!);
      for (final diary in diaryEntries) {
        await _db.createDiaryEntry(diary.copyWith(
          id: null,
          chatRoomId: newChatRoomId,
        ));
      }

      // 뉴스 기사 복사 (에이전트 엔트리 ID 매핑 적용)
      final newsArticles = await _db.readNewsArticles(_chatRoom!.id!);
      for (final article in newsArticles) {
        final newAgentEntryId = article.agentEntryId != null
            ? agentIdMap[article.agentEntryId!]
            : null;
        await _db.createNewsArticle(NewsArticle(
          chatRoomId: newChatRoomId,
          topic: article.topic,
          tone: article.tone,
          author: article.author,
          title: article.title,
          time: article.time,
          content: article.content,
          createdAt: article.createdAt,
          agentEntryId: newAgentEntryId,
        ));
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

    setState(() => _sendingPhase = SendingPhase.preparing);

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

      if (mounted) setState(() => _sendingPhase = SendingPhase.waiting);

      final model = _resolveModel();
      final maxRetries = model.retryCount;
      Object? lastError;

      for (int attempt = 0; attempt <= maxRetries; attempt++) {
        try {
          if (attempt > 0) {
            debugPrint('Retrying regenerateMessage (attempt ${attempt + 1}/${maxRetries + 1})');
            if (mounted) setState(() {
              _sendingPhase = SendingPhase.waiting;
              _retryAttempt = attempt;
            });
          }

          final aiResponse3 = await _aiService.sendMessage(
            systemPrompt: apiData.systemPrompt,
            contents: apiData.contents,
            model: model,
            promptParameters: apiData.parameters,
            chatRoomId: widget.chatRoomId,
            characterId: _character?.id,
          );

          // Stage 3: Apply outputModify to AI response
          final responseText3 = RegexProcessor.apply(aiResponse3.text, apiData.regexRules, RegexTarget.outputModify);

          final tokenCount = aiResponse3.usageMetadata?.candidatesTokenCount ??
              TokenCounter.estimateTokenCount(responseText3, tokenizer: tokenizer);
          final updatedMessage = message.copyWith(
            content: responseText3,
            tokenCount: tokenCount,
            editedAt: DateTime.now(),
            usageMetadata: aiResponse3.usageMetadata,
            modelId: aiResponse3.modelId,
          );

          await _db.updateChatMessage(updatedMessage);

          await _db.deleteChatMessageMetadataByMessage(messageId);
          await _saveMessageMetadata(messageId, responseText3);

          // 채팅방 토큰 합산 업데이트
          await _db.updateChatRoomTotalTokenCount(widget.chatRoomId);

          lastError = null;
          break;
        } catch (e) {
          lastError = e;
          debugPrint('regenerateMessage attempt ${attempt + 1} failed: $e');
          if (attempt >= maxRetries) break;
        }
      }

      if (lastError != null) {
        throw lastError!;
      }

    } catch (e) {
      debugPrint('Error regenerating message: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('메시지 재생성 중 오류가 발생했습니다: $e')),
      );
    } finally {
      await _finishSending();
    }
  }

  Widget _buildCharacterAvatar() {
    final selectedCover = _coverImages.isNotEmpty ? _coverImages.first : null;

    const fallback = CircleAvatar(
      radius: 16,
      backgroundColor: Color(0xFFE0E0E0),
      child: Icon(
        Icons.person_outline,
        size: 16,
        color: Color(0xFF757575),
      ),
    );

    if (selectedCover == null) return fallback;

    return FutureBuilder<Uint8List?>(
      future: selectedCover.resolveImageData(),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) return fallback;
        return CircleAvatar(
          radius: 16,
          backgroundImage: MemoryImage(bytes),
        );
      },
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
    return CommonSettingsInfoCard(
      icon: Icons.warning_amber_rounded,
      iconColor: Theme.of(context).colorScheme.error,
      title: '주의',
      description: '모든 AI 응답은 자동 생성되며, 편향적이거나 부정확할 수 있습니다.',
    );
  }

  String _replaceStartTextKeywords(String text) {
    final selectedPersona = _personas
        .where((p) => p.id == _chatRoom?.selectedPersonaId)
        .firstOrNull;
    final keywords = {
      'char': _character?.name ?? '',
      'user': selectedPersona?.name ?? '',
    };
    var result = text;
    for (final entry in keywords.entries) {
      result = result.replaceAll('{{${entry.key}}}', entry.value);
    }
    return result;
  }

  Widget _buildStartSettingCard() {
    return CommonSettingsInfoCard(
      icon: Icons.settings_outlined,
      title: '시작 설정',
      description: _replaceStartTextKeywords(_startScenario!.startSetting!),
    );
  }

  Widget _buildStartMessageBubble() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        _replaceStartTextKeywords(_startScenario!.startMessage!),
        style: Theme.of(context).textTheme.bodyLarge,
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
              Flexible(
                child: Text(
                  locationMain,
                  style: metaStyle,
                  textAlign: TextAlign.end,
                ),
              ),
          ],
        ),
        if (locationSub != null)
          Align(
            alignment: Alignment.centerRight,
            child: Text(locationSub, style: metaStyle),
          ),
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

    final isSummaryThreshold = _summaryThresholdIndex != null && index == _summaryThresholdIndex;
    final isSummarized = message.id != null && _summarizedMessageIds.contains(message.id!);
    final isSearchMatch = _isSearching && _searchMatches.any((m) => m.$1 == index);
    final currentMatch = _currentSearchIndex >= 0 ? _searchMatches[_currentSearchIndex] : null;
    final isCurrentSearchMatch = isSearchMatch && currentMatch?.$1 == index;
    // Which occurrence within this message is the current one (-1 if none)
    final currentOccurrenceInMsg = isCurrentSearchMatch ? currentMatch!.$2 : -1;

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
              else ...[
                MarkdownText(
                  text: _buildDisplayContent(message.content),
                  baseStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: viewer.fontSize,
                    height: viewer.lineHeight,
                  ),
                  textAlign: viewer.textAlign,
                  paragraphSpacing: viewer.paragraphSpacing,
                  highlightQuery: isSearchMatch ? _searchController.text : null,
                  highlightColor: isSearchMatch
                      ? Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.35)
                      : null,
                  currentHighlightColor: isCurrentSearchMatch
                      ? Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.7)
                      : null,
                  currentOccurrence: currentOccurrenceInMsg,
                  highlightKey: (isCurrentSearchMatch && _highlightKeyActive) ? _searchHighlightKey : null,
                ),
                if (MetadataParser.parseCharacterTags(message.content).isNotEmpty)
                  const SizedBox(height: 4),
                ...MetadataParser.parseCharacterTags(message.content)
                    .map((tag) => CommonCharacterCard(tag: tag, fontSize: viewer.fontSize)),
              ],
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
                      icon: const Icon(Icons.copy_outlined, size: 18),
                      onPressed: () => Clipboard.setData(ClipboardData(text: message.content)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                    ),
                    const SizedBox(width: 0),
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
            thickness: isSummaryThreshold ? 1.5 : 1,
            color: isSummaryThreshold
                ? Theme.of(context).colorScheme.primary
                : isSummarized
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildScrollButton({required IconData icon, required VoidCallback onPressed}) {
    return SizedBox(
      width: 36,
      height: 36,
      child: FloatingActionButton.small(
        heroTag: null,
        onPressed: onPressed,
        elevation: 2,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        shape: const CircleBorder(),
        child: Icon(icon, size: 20),
      ),
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
      key: _scaffoldKey,
      endDrawerEnableOpenDragGesture: false,
      onEndDrawerChanged: (isOpen) {
        if (!isOpen) {
          _drawerKey.currentState?.saveCurrentTabData();
        }
      },
      endDrawer: ChatRoomDrawer(
        key: _drawerKey,
        chatRoom: _chatRoom!,
        character: _character!,
        selectedPersonaId: _chatRoom!.selectedPersonaId,
        initialTab: _drawerTab,
        onTabChanged: (tab) => _drawerTab = tab,
        onChatRoomUpdated: () => _loadChatData(showLoading: false),
        chatPrompts: _chatPrompts,
        personas: _personas,
        onModelChanged: _onModelChanged,
        onModelPresetChanged: _onModelPresetChanged,
        onPromptChanged: _onPromptChanged,
        onPersonaChanged: _onPersonaChanged,
        onAutoPinByMessageCountChanged: _onAutoPinMessageCountChanged,
        onPresetChanged: _onPresetChanged,
        onShowImagesChanged: _onShowImagesChanged,
      ),
      appBar: _isSearching
          ? AppBar(
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              title: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _toggleSearch,
                    padding: const EdgeInsets.only(left: 16),
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: const InputDecoration(
                        hintText: '메시지 검색...',
                        border: InputBorder.none,
                      ),
                      onChanged: _performSearch,
                      textInputAction: TextInputAction.search,
                    ),
                  ),
                  if (_searchMatches.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        '${_currentSearchIndex + 1}/${_searchMatches.length}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_up),
                    onPressed: () => _navigateSearch(-1),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down),
                    onPressed: () => _navigateSearch(1),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            )
          : CommonAppBar(
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
                    Flexible(
                      child: Text(
                        _character!.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                CommonAppBarIconButton(
                  icon: Icons.search,
                  onPressed: _toggleSearch,
                  tooltip: '검색',
                  offsetX: 20.0,
                ),
              ],
            ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    if (_showMorePanel) setState(() => _showMorePanel = false);
                  },
                  child: ScrollablePositionedList.builder(
                    itemScrollController: _itemScrollController,
                    itemPositionsListener: _itemPositionsListener,
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
                if (_hasNewMessage)
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            _itemScrollController.scrollTo(
                              index: 0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                            setState(() => _hasNewMessage = false);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '새로운 메시지',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else if (_showScrollButtons)
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildScrollButton(
                          icon: Icons.keyboard_arrow_up,
                          onPressed: () {
                            _itemScrollController.scrollTo(
                              index: _messages.length,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildScrollButton(
                          icon: Icons.keyboard_arrow_down,
                          onPressed: () {
                            _itemScrollController.scrollTo(
                              index: 0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
              ],
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
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: AnimatedRotation(
                        turns: _showMorePanel ? 0.125 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.add,
                          color: _showMorePanel
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                      onPressed: _showMoreMenu,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                    Expanded(
                      child: CommonEditText(
                        controller: _messageController,
                        focusNode: _messageFocusNode,
                        enabled: !_isSending,
                        hintText: _sendingPhase == SendingPhase.preparing
                            ? '메시지 생성 중...'
                            : _sendingPhase == SendingPhase.waiting
                                ? _retryAttempt > 0
                                    ? '재전송 중($_retryAttempt)...'
                                    : '응답 대기 중...'
                                : _sendingPhase == SendingPhase.summarizing
                                    ? '요약 중...'
                                    : '메시지를 입력하세요',
                        minLines: 1,
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                        suffixIcon: IconButton(
                          icon: _isSending
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _sendingPhase == SendingPhase.preparing
                                        ? Theme.of(context).colorScheme.primary
                                        : _sendingPhase == SendingPhase.summarizing
                                            ? Theme.of(context).colorScheme.secondary
                                            : null,
                                  ),
                                )
                              : const Icon(Icons.send),
                          onPressed: _isSending ? null : _sendMessage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_showMorePanel) _buildMorePanel(),
        ],
      ),
    );
  }
}
