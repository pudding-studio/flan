import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../l10n/app_localizations.dart';
import '../../models/chat/chat_room.dart';
import '../../models/chat/chat_message.dart';
import '../../models/character/character.dart';
import '../../models/character/cover_image.dart';
import '../../models/character/persona.dart';
import '../../models/character/start_scenario.dart';
import '../../models/prompt/chat_prompt.dart';
import '../../models/prompt/prompt_regex_rule.dart';
import '../../utils/chat_content_formatter.dart';
import '../../utils/regex_processor.dart';
import '../../utils/retry_runner.dart';
import '../../database/database_helper.dart';
import '../../providers/tokenizer_provider.dart';
import '../../utils/common_dialog.dart';
import '../../utils/token_counter.dart';
import '../../services/ai_service.dart';
import '../../services/agent_summary_service.dart';
import '../../services/auto_summary_service.dart';
import '../../services/chat_api_data_builder.dart';
import '../../services/chat_branch_service.dart';
import '../../services/chat_model_resolver.dart';
import '../../models/chat/chat_message_metadata.dart';
import '../../models/chat/unified_model.dart';
import '../../utils/metadata_parser.dart';
import '../../widgets/common/common_appbar.dart';
import '../../providers/chat_background_provider.dart';
import '../../providers/chat_model_provider.dart';
import '../../providers/localization_provider.dart';
import 'chat_send_errors.dart';
import 'controllers/chat_message_edit_controller.dart';
import 'controllers/chat_search_controller.dart';
import 'widgets/chat_message_bubble.dart';
import 'widgets/chat_room_character_avatar.dart';
import 'widgets/chat_room_drawer.dart';
import 'widgets/chat_room_header.dart';
import 'widgets/chat_room_input_bar.dart';
import 'widgets/chat_room_more_menu.dart';
import 'widgets/chat_room_scroll_buttons.dart';
import 'widgets/chat_room_search_app_bar.dart';
import 'widgets/chat_usage_metadata_dialog.dart';
import '../character/character_view_screen.dart';
import 'chat_sending_phase.dart';

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
  List<CoverImage> _backgroundImages = [];
  Map<String, String> _imagePathMap = {}; // image name → file path
  // Subset of _imagePathMap restricted to additional images. Used by the
  // conversation-view renderer to look up per-speaker avatars of the form
  // `${speakerName}_default` without falling back to cover images when no
  // such additional image exists.
  Map<String, String> _additionalImagePathMap = {};
  bool _isLoading = true;
  SendingPhase _sendingPhase = SendingPhase.none;
  int _retryAttempt = 0;
  bool get _isSending => _sendingPhase != SendingPhase.none;
  late final ChatMessageEditController _editController =
      ChatMessageEditController(onChanged: () => setState(() {}));
  Map<int, ChatMessageMetadata> _metadataMap = {};
  int? _summaryThresholdIndex;
  Set<int> _summarizedMessageIds = {};
  bool _showMorePanel = false;
  bool _showScrollButtons = false;
  bool _hasNewMessage = false;
  // Number of latest messages hidden from the rendered list while the user is
  // scrolled up. Keeps the visible itemCount stable so the viewport doesn't
  // jump when new assistant messages arrive. Revealed when the user reaches
  // the bottom or taps the "new messages" / scroll-to-bottom button.
  int _hiddenNewMessageCount = 0;
  List<ChatPrompt> _chatPrompts = [];
  List<Persona> _personas = [];
  List<PromptRegexRule> _regexRules = [];
  // Set when chatRoom.modelPreset == 'custom' and the saved selectedModelId
  // is not present in the provider's available models. Send-time code
  // re-checks this and aborts with a clear error rather than silently
  // sending with whatever model the provider currently exposes.
  String? _customModelLoadFailedId;
  final FocusNode _messageFocusNode = FocusNode();

  late final ChatSearchController _searchController = ChatSearchController(
    messagesProvider: () => _messages,
    displayContentBuilder: _buildDisplayContent,
    itemScrollController: _itemScrollController,
    itemPositionsListener: _itemPositionsListener,
  );

  @override
  void initState() {
    super.initState();
    _messageFocusNode.addListener(_onMessageFocusChanged);
    _itemPositionsListener.itemPositions.addListener(_onScrollChanged);
    _searchController.addListener(_onSearchChanged);
    _loadChatData();
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  void _onScrollChanged() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;
    final minIndex = positions.map((p) => p.index).reduce((a, b) => a < b ? a : b);
    final show = minIndex > 3;
    final shouldReveal =
        !show && (_hasNewMessage || _hiddenNewMessageCount > 0);
    if (show != _showScrollButtons || shouldReveal) {
      setState(() {
        _showScrollButtons = show;
        if (!show) {
          _hasNewMessage = false;
          _hiddenNewMessageCount = 0;
        }
      });
    }
  }

  void _onMessageFocusChanged() {
    if (_messageFocusNode.hasFocus && _showMorePanel) {
      setState(() => _showMorePanel = false);
    }
  }

  @override
  void dispose() {
    _messageFocusNode.removeListener(_onMessageFocusChanged);
    _messageFocusNode.dispose();
    _messageController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _itemPositionsListener.itemPositions.removeListener(_onScrollChanged);
    _editController.dispose();
    super.dispose();
  }

  Future<void> _loadChatData({bool showLoading = true}) async {
    if (showLoading && mounted) setState(() => _isLoading = true);

    try {
      final chatRoom = await _db.readChatRoom(widget.chatRoomId);
      if (chatRoom == null) {
        throw Exception('Chat room not found');
      }

      final character = await _db.readCharacter(chatRoom.characterId);
      final messages = await _db.readChatMessagesByChatRoom(widget.chatRoomId);
      final coverImages = await _db.readCoverImages(chatRoom.characterId);
      final additionalImages = await _db.readAdditionalImages(chatRoom.characterId);
      final backgroundImages = await _db.readBackgroundImages(chatRoom.characterId);
      // Build name→path map for <img="name"> tag resolution.
      // Register both the original name and the extension-stripped name so
      // the tag matches regardless of whether either side carries ".png" etc.
      final imagePathMap = <String, String>{};
      final additionalImagePathMap = <String, String>{};
      final imageExtPattern = RegExp(
        r'\.(png|jpe?g|gif|webp|bmp|heic|avif)$',
        caseSensitive: false,
      );
      for (final img in [...coverImages, ...additionalImages]) {
        if (img.path == null || img.name.isEmpty) continue;
        imagePathMap.putIfAbsent(img.name, () => img.path!);
        final stripped = img.name.replaceFirst(imageExtPattern, '');
        if (stripped != img.name) {
          imagePathMap.putIfAbsent(stripped, () => img.path!);
        }
      }
      for (final img in additionalImages) {
        if (img.path == null || img.name.isEmpty) continue;
        additionalImagePathMap.putIfAbsent(img.name, () => img.path!);
        final stripped = img.name.replaceFirst(imageExtPattern, '');
        if (stripped != img.name) {
          additionalImagePathMap.putIfAbsent(stripped, () => img.path!);
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

      // Restore per-room model selection (only for custom preset).
      // If the saved model is missing we record the failure instead of
      // silently leaving the provider on its current default — send-time
      // code will retry the lookup and surface a clear error if it
      // still cannot be resolved.
      String? customModelLoadFailedId;
      if (chatRoom.modelPreset == 'custom' && chatRoom.selectedModelId != null) {
        final modelProvider = context.read<ChatModelSettingsProvider>();
        final savedId = chatRoom.selectedModelId!;
        final available = modelProvider.availableModels;
        final match = available.where((m) => m.id == savedId);
        if (match.isNotEmpty) {
          if (modelProvider.selectedModel.id != savedId) {
            await modelProvider.setModel(match.first);
          }
        } else {
          customModelLoadFailedId = savedId;
        }
      }
      setState(() {
        _chatRoom = chatRoom;
        _character = character;
        _startScenario = startScenario;
        _messages = messages;
        _coverImages = coverImages;
        _additionalImages = additionalImages;
        _backgroundImages = backgroundImages;
        _imagePathMap = imagePathMap;
        _additionalImagePathMap = additionalImagePathMap;
        _metadataMap = metadataMap;
        _summaryThresholdIndex = summaryThresholdIndex;
        _summarizedMessageIds = summarizedIds;
        _chatPrompts = chatPrompts;
        _personas = personas;
        _regexRules = regexRules;
        _customModelLoadFailedId = customModelLoadFailedId;
        _isLoading = false;
      });

    } catch (e) {
      debugPrint('Error loading chat data: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }


  Future<ChatApiData> _buildApiData({
    required String userMessage,
    List<int>? excludeMessageIds,
    int? beforeMessageIndex,
  }) async {
    if (_chatRoom == null || _character == null) return ChatApiData.empty;

    // Capture context-derived values before any async gaps.
    final l10n = AppLocalizations.of(context);
    final outputLanguage =
        context.read<LocalizationProvider>().effectiveAiLanguageName;
    final tokenizer = context.read<TokenizerProvider>().selectedTokenizer;

    return ChatApiDataBuilder.instance.build(
      chatRoom: _chatRoom!,
      character: _character!,
      chatRoomId: widget.chatRoomId,
      messages: _messages,
      metadataMap: _metadataMap,
      userMessage: userMessage,
      outputLanguage: outputLanguage,
      tokenizer: tokenizer,
      promptLoadFailedMessage: l10n.chatRoomPromptLoadFailed,
      excludeMessageIds: excludeMessageIds,
      beforeMessageIndex: beforeMessageIndex,
    );
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
      final model = await _resolveModel();

      await RetryRunner.run<void>(
        maxRetries: model.retryCount,
        tag: 'sendMessage',
        onRetry: (attempt) {
          if (mounted) {
            setState(() {
              _sendingPhase = SendingPhase.waiting;
              _retryAttempt = attempt;
            });
          }
        },
        attempt: (_) async {
          final aiResponse = await _aiService.sendMessage(
            systemPrompt: apiData.systemPrompt,
            contents: apiData.contents,
            model: model,
            promptParameters: apiData.parameters,
            chatRoomId: widget.chatRoomId,
            characterId: _character?.id,
          );

          // Stage 3: Apply outputModify to AI response
          final responseText = RegexProcessor.apply(
              aiResponse.text, apiData.regexRules, RegexTarget.outputModify);

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
          await _db.updateChatRoom(_chatRoom!.copyWith(updatedAt: DateTime.now()));

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
                await _autoSummaryService.generateAllPendingSummaries(
                    chatRoomId: widget.chatRoomId);
              }
            }
          }

          // Future plan: agent summary 이후에 실행하여 우선순위를 보장
          final agentSettings = await _db.getAutoSummarySettings(0);
          if (agentSettings != null && agentSettings.isAgentEnabled) {
            await AgentSummaryService()
                .processFuturePlan(widget.chatRoomId, responseText);
          }
        },
      );
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final message = (e is ChatModelLoadException || e is ChatPromptLoadException)
          ? e.toString()
          : l10n.chatRoomMessageSendFailed(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      await _finishSending();
    }
  }

  Future<void> _deleteMessage(int messageId) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await CommonDialog.showDeleteConfirmation(
      context: context,
      itemName: l10n.chatRoomMessageItemName,
    );

    if (!confirmed) return;

    try {
      await _db.deleteChatMessageMetadataByMessage(messageId);
      await _db.deleteChatMessage(messageId);
      // Update chat room total token count
      await _db.updateChatRoomTotalTokenCount(widget.chatRoomId);
      await _loadChatData(showLoading: false);
      if (!mounted) return;
      CommonDialog.showSnackBar(
        context: context,
        message: l10n.chatRoomMessageDeleted,
      );
    } catch (e) {
      debugPrint('Error deleting message: $e');
      if (!mounted) return;
      CommonDialog.showSnackBar(
        context: context,
        message: l10n.chatRoomMessageDeleteFailed,
      );
    }
  }

  String _buildDisplayContent(String content) {
    return ChatContentFormatter.buildDisplayContent(
      content: content,
      chatRoom: _chatRoom,
      regexRules: _regexRules,
      imagePathMap: _imagePathMap,
    );
  }

  Future<void> _saveEditMessage(ChatMessage message) async {
    final rawContent = _editController.trimmedTextFor(message);
    if (rawContent == null) return;
    if (rawContent.isEmpty) {
      _editController.cancel();
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
      _editController.cancel();
      await _loadChatData(showLoading: false);
      if (!mounted) return;
      CommonDialog.showSnackBar(
        context: context,
        message: AppLocalizations.of(context).chatRoomMessageEdited,
      );
    } catch (e) {
      debugPrint('Error editing message: $e');
      if (!mounted) return;
      CommonDialog.showSnackBar(
        context: context,
        message: AppLocalizations.of(context).chatRoomMessageEditFailed,
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

  Future<void> _finishSending() async {
    final wasScrolledUp = _showScrollButtons;
    final prevMessageCount = _messages.length;

    await _loadChatData(showLoading: false);
    if (!mounted) return;

    final delta = _messages.length - prevMessageCount;
    setState(() {
      _sendingPhase = SendingPhase.none;
      _retryAttempt = 0;
      // When the user is scrolled up, keep the viewport stable by hiding the
      // freshly-arrived messages. The visible item count doesn't change, so
      // ScrollablePositionedList keeps the same indices pinned to the same
      // messages. The messages get revealed when the user scrolls back to
      // the bottom or taps the "new messages" chip.
      if (wasScrolledUp && delta > 0) {
        _hiddenNewMessageCount += delta;
        _hasNewMessage = true;
      }
    });

    // When the user was at the bottom and new messages arrived, anchor the
    // viewport to the end of the second-to-last message instead of letting
    // the reverse list auto-pin to the very bottom of the new last message.
    if (!wasScrolledUp && delta > 0 && _messages.length >= 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_itemScrollController.isAttached) return;
        _itemScrollController.scrollTo(
          index: 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  /// Resolves the model to use for the next API call. Unlike a simple
  /// getter, this verifies that the saved choice (primary, sub, or this
  /// chat room's per-room custom model) actually resolves to an available
  /// model. If the saved choice is missing it retries once after
  /// refreshing the catalog from disk, and only throws if the model is
  /// still unavailable. Throwing is intentional: it prevents send paths
  /// from silently substituting a default (e.g. Google AIS Gemini Pro)
  /// when the user's chosen model can't be found.
  Future<UnifiedModel> _resolveModel() async {
    final provider = context.read<ChatModelSettingsProvider>();
    final l10n = AppLocalizations.of(context);
    final resolution = await ChatModelResolver.resolve(
      provider: provider,
      chatRoom: _chatRoom,
      customModelLoadFailedId: _customModelLoadFailedId,
      subModelLoadFailedMessage: l10n.chatRoomSubModelLoadFailed,
      primaryModelLoadFailedMessage: l10n.chatRoomMainModelLoadFailed,
      customModelLoadFailedMessage: l10n.chatRoomCustomModelLoadFailed,
    );
    if (resolution.clearCustomLoadFailedFlag && mounted) {
      setState(() => _customModelLoadFailedId = null);
    }
    return resolution.model;
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

      final model = await _resolveModel();

      await RetryRunner.run<void>(
        maxRetries: model.retryCount,
        tag: 'resendLastUserMessage',
        onRetry: (_) {
          if (mounted) setState(() => _sendingPhase = SendingPhase.waiting);
        },
        attempt: (_) async {
          final aiResponse2 = await _aiService.sendMessage(
            systemPrompt: apiData.systemPrompt,
            contents: apiData.contents,
            model: model,
            promptParameters: apiData.parameters,
            chatRoomId: widget.chatRoomId,
            characterId: _character?.id,
          );

          // Stage 3: Apply outputModify to AI response
          final responseText2 = RegexProcessor.apply(
              aiResponse2.text, apiData.regexRules, RegexTarget.outputModify);

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
          await _db.updateChatRoom(_chatRoom!.copyWith(updatedAt: DateTime.now()));

          // Future plan: AI 응답에서 [PLAN: ...] 파싱하여 활성화
          final agentSettings2 = await _db.getAutoSummarySettings(0);
          if (agentSettings2 != null && agentSettings2.isAgentEnabled) {
            await AgentSummaryService()
                .processFuturePlan(widget.chatRoomId, responseText2);
          }
        },
      );
    } catch (e) {
      debugPrint('Error resending message: $e');
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final message = (e is ChatModelLoadException || e is ChatPromptLoadException)
          ? e.toString()
          : l10n.chatRoomMessageRetryFailed(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      await _finishSending();
    }
  }

  Future<void> _createBranch(int messageIndex) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await CommonDialog.showConfirmation(
      context: context,
      title: l10n.chatRoomBranchTitle,
      content: l10n.chatRoomBranchContent,
      confirmText: l10n.chatRoomBranchConfirm,
    );

    if (confirmed != true) return;
    if (_chatRoom == null || _character == null) return;

    try {
      final newChatRoomId = await ChatBranchService.instance.createBranch(
        source: _chatRoom!,
        messages: _messages,
        metadataMap: _metadataMap,
        branchAtIndex: messageIndex,
      );

      if (!mounted) return;
      CommonDialog.showSnackBar(
        context: context,
        message: l10n.chatRoomBranchCreated,
      );
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
        message: l10n.chatRoomBranchFailed,
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

      final model = await _resolveModel();

      await RetryRunner.run<void>(
        maxRetries: model.retryCount,
        tag: 'regenerateMessage',
        onRetry: (attempt) {
          if (mounted) {
            setState(() {
              _sendingPhase = SendingPhase.waiting;
              _retryAttempt = attempt;
            });
          }
        },
        attempt: (_) async {
          final aiResponse3 = await _aiService.sendMessage(
            systemPrompt: apiData.systemPrompt,
            contents: apiData.contents,
            model: model,
            promptParameters: apiData.parameters,
            chatRoomId: widget.chatRoomId,
            characterId: _character?.id,
          );

          // Stage 3: Apply outputModify to AI response
          final responseText3 = RegexProcessor.apply(
              aiResponse3.text, apiData.regexRules, RegexTarget.outputModify);

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
        },
      );
    } catch (e) {
      debugPrint('Error regenerating message: $e');
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final message = (e is ChatModelLoadException || e is ChatPromptLoadException)
          ? e.toString()
          : l10n.chatRoomMessageRegenerateFailed(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      await _finishSending();
    }
  }

  Widget _buildMessage(ChatMessage message, int index) {
    final isUser = message.role == MessageRole.user;
    final visibleCount = _messages.length - _hiddenNewMessageCount;
    final isLastMessage = index == visibleCount - 1;
    final metadata = message.id != null ? _metadataMap[message.id!] : null;
    final isSummaryThreshold =
        _summaryThresholdIndex != null && index == _summaryThresholdIndex;
    final isSummarized =
        message.id != null && _summarizedMessageIds.contains(message.id!);
    final isSearchMatch =
        _searchController.isSearching && _searchController.isMatchedMessage(index);
    final isCurrentSearchMatch =
        isSearchMatch && _searchController.isCurrentMessage(index);
    final currentOccurrenceInMsg =
        isCurrentSearchMatch ? _searchController.currentOccurrenceIn(index) : -1;

    return ChatMessageBubble(
      message: message,
      index: index,
      isLastMessage: isLastMessage,
      displayContent: _buildDisplayContent(message.content),
      metadata: metadata,
      character: _character,
      coverImages: _coverImages,
      additionalImagePathMap: _additionalImagePathMap,
      isEditing: _editController.isEditing(message),
      editController: _editController.controllerFor(message),
      isSummaryThreshold: isSummaryThreshold,
      isSummarized: isSummarized,
      isSearchMatch: isSearchMatch,
      isCurrentSearchMatch: isCurrentSearchMatch,
      currentOccurrenceInMsg: currentOccurrenceInMsg,
      searchQuery: _searchController.inputController.text,
      searchHighlightKey: _searchController.highlightKey,
      onTogglePin: () => _togglePin(message.id!),
      onShowUsage: () => ChatUsageMetadataDialog.show(context, message),
      onCancelEdit: _editController.cancel,
      onSaveEdit: () => _saveEditMessage(message),
      onStartEdit: () => _editController.start(message),
      onCreateBranch: () => _createBranch(index),
      onDelete: () => _deleteMessage(message.id!),
      onResendOrRegenerate:
          isUser ? _resendLastUserMessage : () => _regenerateMessage(message.id!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
        body: Center(
          child: Text(l10n.chatRoomCannotLoad),
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
      appBar: _searchController.isSearching
          ? ChatRoomSearchAppBar(
              controller: _searchController.inputController,
              focusNode: _searchController.focusNode,
              currentIndex: _searchController.currentIndex,
              totalMatches: _searchController.matches.length,
              onClose: _searchController.toggle,
              onChanged: _searchController.search,
              onPrev: () => _searchController.navigate(-1),
              onNext: () => _searchController.navigate(1),
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
                    ChatRoomCharacterAvatar(coverImages: _coverImages),
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
                  onPressed: _searchController.toggle,
                  tooltip: l10n.chatRoomSearchTooltip,
                  offsetX: 20.0,
                ),
              ],
            ),
      body: Stack(
        children: [
          _buildBackgroundWatermark(),
          Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    if (_showMorePanel) setState(() => _showMorePanel = false);
                  },
                  child: Builder(
                    builder: (context) {
                      final visibleCount =
                          (_messages.length - _hiddenNewMessageCount)
                              .clamp(0, _messages.length);
                      return ScrollablePositionedList.builder(
                        itemScrollController: _itemScrollController,
                        itemPositionsListener: _itemPositionsListener,
                        reverse: true,
                        itemCount: visibleCount + 1,
                        itemBuilder: (context, index) {
                          if (index == visibleCount) {
                            return ChatRoomHeader(
                              character: _character!,
                              selectedPersona: _personas
                                  .where((p) =>
                                      p.id == _chatRoom?.selectedPersonaId)
                                  .firstOrNull,
                              startScenario: _startScenario,
                              displayContentBuilder: _buildDisplayContent,
                            );
                          }
                          final messageIndex = visibleCount - 1 - index;
                          return _buildMessage(
                              _messages[messageIndex], messageIndex);
                        },
                      );
                    },
                  ),
                ),
                ChatRoomScrollButtons(
                  hasNewMessage: _hasNewMessage,
                  showScrollButtons: _showScrollButtons,
                  onJumpToLatest: () {
                    setState(() {
                      _hiddenNewMessageCount = 0;
                      _hasNewMessage = false;
                    });
                    _itemScrollController.scrollTo(
                      index: 0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                  onScrollToTop: () {
                    final visibleCount =
                        (_messages.length - _hiddenNewMessageCount)
                            .clamp(0, _messages.length);
                    _itemScrollController.scrollTo(
                      index: visibleCount,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                  onScrollToBottom: () {
                    setState(() {
                      _hiddenNewMessageCount = 0;
                      _hasNewMessage = false;
                    });
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
          ChatRoomInputBar(
            controller: _messageController,
            focusNode: _messageFocusNode,
            sendingPhase: _sendingPhase,
            retryAttempt: _retryAttempt,
            isMorePanelOpen: _showMorePanel,
            onSend: _sendMessage,
            onMoreToggle: _showMoreMenu,
          ),
          if (_showMorePanel)
            ChatRoomMoreMenu(
              characterId: _character!.id!,
              chatRoomId: widget.chatRoomId,
              onClose: () => setState(() => _showMorePanel = false),
            ),
        ],
      ),
        ],
      ),
    );
  }

  Widget _buildBackgroundWatermark() {
    final enabled = context.watch<ChatBackgroundProvider>().enabled;
    if (!enabled || _backgroundImages.isEmpty) {
      return const SizedBox.shrink();
    }
    final image = _backgroundImages.first;
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.05,
          child: FutureBuilder<Uint8List?>(
            future: image.resolveImageData(),
            builder: (context, snapshot) {
              final bytes = snapshot.data;
              if (bytes == null) return const SizedBox.shrink();
              return Image.memory(
                bytes,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              );
            },
          ),
        ),
      ),
    );
  }
}
