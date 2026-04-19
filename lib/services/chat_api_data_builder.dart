import '../database/database_helper.dart';
import '../models/character/character.dart';
import '../models/character/character_book_folder.dart';
import '../models/character/persona.dart';
import '../models/character/start_scenario.dart';
import '../models/chat/chat_message.dart';
import '../models/chat/chat_message_metadata.dart';
import '../models/chat/chat_room.dart';
import '../models/prompt/chat_prompt.dart';
import '../models/prompt/prompt_condition.dart';
import '../models/prompt/prompt_condition_preset.dart';
import '../models/prompt/prompt_condition_preset_value.dart';
import '../models/prompt/prompt_item.dart';
import '../models/prompt/prompt_parameters.dart';
import '../models/prompt/prompt_regex_rule.dart';
import '../providers/tokenizer_provider.dart';
import '../screens/chat/chat_send_errors.dart';
import '../utils/prompt_builder.dart';
import '../utils/regex_processor.dart';
import '../utils/token_counter.dart';
import 'agent_summary_service.dart';
import 'auto_summary_service.dart';

/// Result tuple returned by [ChatApiDataBuilder.build] — everything the
/// AI service call needs, plus the regex rules so the caller can apply
/// `outputModify` to the response without re-loading them.
class ChatApiData {
  final String systemPrompt;
  final List<Map<String, dynamic>> contents;
  final PromptParameters? parameters;
  final List<PromptRegexRule> regexRules;

  const ChatApiData({
    required this.systemPrompt,
    required this.contents,
    required this.parameters,
    required this.regexRules,
  });

  static const ChatApiData empty = ChatApiData(
    systemPrompt: '',
    contents: <Map<String, dynamic>>[],
    parameters: null,
    regexRules: <PromptRegexRule>[],
  );
}

/// Assembles the system prompt + content list passed to the AI service
/// for a single chat room send.
///
/// Pure async — no `BuildContext` and no widget state. Callers must
/// capture the localization output language and the active tokenizer
/// before invoking [build] (those values can otherwise change during
/// awaits).
///
/// Throws [ChatPromptLoadException] when [ChatRoom.selectedChatPromptId]
/// points to a row that no longer exists; the caller is expected to
/// surface the localized message verbatim.
class ChatApiDataBuilder {
  final DatabaseHelper db;
  final AutoSummaryService autoSummaryService;
  final AgentSummaryService agentSummaryService;

  ChatApiDataBuilder({
    DatabaseHelper? db,
    AutoSummaryService? autoSummaryService,
    AgentSummaryService? agentSummaryService,
  })  : db = db ?? DatabaseHelper.instance,
        autoSummaryService = autoSummaryService ?? AutoSummaryService(),
        agentSummaryService = agentSummaryService ?? AgentSummaryService();

  static final ChatApiDataBuilder instance = ChatApiDataBuilder();

  /// Build the API payload for a send.
  ///
  /// [outputLanguage] / [tokenizer] are captured by the caller before
  /// any awaits. [promptLoadFailedMessage] is a closure that produces
  /// the localized "prompt missing" error string from a prompt id —
  /// this lets the host inject `AppLocalizations` without coupling
  /// this service to the widget layer.
  ///
  /// [excludeMessageIds] removes messages from the chat-history portion
  /// of the prompt (used to keep the just-saved user message out of
  /// history). [beforeMessageIndex] limits history to messages strictly
  /// before that index in the host's `messages` list — used by the
  /// regenerate path so the regenerated turn doesn't see itself.
  Future<ChatApiData> build({
    required ChatRoom chatRoom,
    required Character character,
    required int chatRoomId,
    required List<ChatMessage> messages,
    required Map<int, ChatMessageMetadata> metadataMap,
    required String userMessage,
    required String outputLanguage,
    required TokenizerType tokenizer,
    required String Function(String promptId) promptLoadFailedMessage,
    List<int>? excludeMessageIds,
    int? beforeMessageIndex,
  }) async {
    // Stage 1: Load prompt frame.
    // selectedChatPromptId == null means the user explicitly chose "없음".
    // Anything else is a saved prompt id that MUST resolve — if the row
    // is missing we retry once and then throw, instead of silently
    // sending with an empty system prompt as if "없음" had been chosen.
    ChatPrompt? chatPrompt;
    if (chatRoom.selectedChatPromptId != null) {
      final selectedId = chatRoom.selectedChatPromptId!;
      chatPrompt = await db.readChatPrompt(selectedId);
      // Retry once — the row may have been re-created in another
      // screen between the chat room loading and this send.
      chatPrompt ??= await db.readChatPrompt(selectedId);
      if (chatPrompt == null) {
        throw ChatPromptLoadException(
          promptLoadFailedMessage(selectedId.toString()),
        );
      }
    }

    // Load regex rules for this prompt
    final List<PromptRegexRule> regexRules = chatPrompt?.id != null
        ? await db.readPromptRegexRules(chatPrompt!.id!)
        : [];

    // Stage 3 (pre): Apply inputModify to user message (API-only, DB message unchanged)
    final apiUserMessage =
        RegexProcessor.apply(userMessage, regexRules, RegexTarget.inputModify);

    Persona? persona;
    if (chatRoom.selectedPersonaId != null) {
      persona = await db.readPersona(chatRoom.selectedPersonaId!);
    }

    StartScenario? startScenario;
    if (chatRoom.selectedStartScenarioId != null) {
      startScenario = await db.readStartScenario(chatRoom.selectedStartScenarioId!);
    }

    // Stage 2.1: Filter character books (enabled only, ordered by insertionOrder in PromptBuilder)
    final allCharacterBooks = await db.readCharacterBooks(character.id!);
    final activeCharacterBooks = allCharacterBooks
        .where((b) => b.enabled == CharacterBookActivationCondition.enabled)
        .toList();

    final summaries = await db.getChatSummaries(chatRoomId);

    final summaryMetadataMap = <int, ChatMessageMetadata>{};
    for (final summary in summaries) {
      final metadata =
          await db.readChatMessageMetadataByMessage(summary.endPinMessageId);
      if (metadata != null) {
        summaryMetadataMap[summary.endPinMessageId] = metadata;
      }
    }

    // Load condition states from selected preset
    List<PromptCondition>? conditions;
    Map<int, String>? conditionStates;
    if (chatPrompt != null) {
      conditions = await db.readPromptConditions(chatPrompt.id!);
      for (final condition in conditions) {
        final options = await db.readPromptConditionOptions(condition.id!);
        condition.options.addAll(options);
      }

      final presets = await db.readPromptConditionPresets(chatPrompt.id!);
      PromptConditionPreset? selectedPreset;
      final presetId = chatRoom.selectedConditionPresetId;
      if (presetId != null) {
        try {
          selectedPreset = presets.firstWhere((p) => p.id == presetId);
        } catch (_) {}
      }
      selectedPreset ??=
          presets.where((p) => p.isDefault).firstOrNull ?? presets.firstOrNull;

      if (selectedPreset != null) {
        final values = await db.readPromptConditionPresetValues(selectedPreset.id!);
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

    // Load agent context if agent mode is enabled
    String? agentContext;
    final summarySettings = await db.getAutoSummarySettings(0);
    if (summarySettings != null && summarySettings.isAgentEnabled) {
      final maxInputTokens = chatPrompt?.parameters?.maxInputTokens;

      int? episodeBudget;
      if (maxInputTokens != null && maxInputTokens > 0) {
        // Probe: build agent context with no episode contents (just lists +
        // non-episode sections), then measure how many tokens are consumed by
        // the rest of the prompt frame to derive the remaining budget for
        // episode contents.
        final baselineAgentContext =
            await agentSummaryService.buildActiveEntriesText(
          chatRoomId,
          episodeContentTokenBudget: 0,
          tokenizer: tokenizer,
        );

        final consumedByItem = chatPrompt?.items
                .any((item) => item.content.contains('{{agent_context}}')) ??
            false;

        var baselineSystemPrompt = PromptBuilder.buildSystemPrompt(
          chatPrompt: chatPrompt,
          character: character,
          persona: persona,
          startScenario: startScenario,
          activeCharacterBooks: activeCharacterBooks,
          chatRoom: chatRoom,
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

      agentContext = await agentSummaryService.buildActiveEntriesText(
        chatRoomId,
        episodeContentTokenBudget: episodeBudget,
        tokenizer: tokenizer,
      );
    }

    // Stage 1+2: Build frame and apply keyword substitution
    final outputLanguageKeywords = {'output_language': outputLanguage};

    // Derive the progressive world time from the most recent message that
    // has a resolved date tag, falling back to earlier messages so the
    // `{{world_date}}` keyword reflects chat progression even when the last
    // message hasn't re-emitted a date tag.
    ChatMessageMetadata? latestMetadata;
    for (var i = messages.length - 1; i >= 0; i--) {
      final id = messages[i].id;
      if (id == null) continue;
      final md = metadataMap[id];
      if (md != null && md.date != null && md.date!.isNotEmpty) {
        latestMetadata = md;
        break;
      }
    }

    String rawSystemPrompt = PromptBuilder.buildSystemPrompt(
      chatPrompt: chatPrompt,
      character: character,
      persona: persona,
      startScenario: startScenario,
      activeCharacterBooks: activeCharacterBooks,
      chatRoom: chatRoom,
      summaries: summaries,
      summaryMetadataMap: summaryMetadataMap,
      latestMetadata: latestMetadata,
      conditions: conditions,
      conditionStates: conditionStates,
      agentContext: agentContext,
      extraKeywords: outputLanguageKeywords,
    );

    // Auto-append agent context only when no prompt item consumes the
    // {{agent_context}} keyword. If any item (system/user/assistant) uses the
    // placeholder, it will be substituted in its own slot — appending here
    // would duplicate the text and place a copy at the very front of the
    // conversation.
    if (agentContext != null && agentContext.isNotEmpty) {
      final consumedByItem = chatPrompt?.items
              .any((item) => item.content.contains('{{agent_context}}')) ??
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
      final period = chatRoom.autoPinByMessageCount ?? 10;
      contextExcludeIds = await autoSummaryService.getAgentModeExcludeIds(
        chatRoomId: chatRoomId,
        period: period,
      );
    } else {
      contextExcludeIds =
          await autoSummaryService.getSummarizedMessageIds(chatRoomId);
    }
    final allExcludeIds = {...contextExcludeIds, ...?excludeMessageIds};

    final chatHistoryMap = await _buildChatHistoryMap(
      chatPrompt: chatPrompt,
      chatRoomId: chatRoomId,
      messages: messages,
      excludeMessageIds: allExcludeIds.toList(),
      beforeMessageIndex: beforeMessageIndex,
    );

    final rawContents = PromptBuilder.buildContents(
      chatPrompt: chatPrompt,
      character: character,
      userMessage: apiUserMessage,
      chatHistoryMap: chatHistoryMap,
      systemPrompt: rawSystemPrompt,
      persona: persona,
      startScenario: startScenario,
      activeCharacterBooks: activeCharacterBooks,
      maxInputTokens: chatPrompt?.parameters?.maxInputTokens,
      tokenizer: tokenizer,
      metadataMap: metadataMap,
      chatRoom: chatRoom,
      summaries: summaries,
      summaryMetadataMap: summaryMetadataMap,
      latestMetadata: latestMetadata,
      conditions: conditions,
      conditionStates: conditionStates,
      agentContext: agentContext,
      extraKeywords: outputLanguageKeywords,
    );

    // Stage 3: Apply sendDataModify to the fully assembled prompt data
    final systemPrompt =
        RegexProcessor.apply(rawSystemPrompt, regexRules, RegexTarget.sendDataModify);
    final contents = RegexProcessor.applyToContents(
        rawContents, regexRules, RegexTarget.sendDataModify);

    return ChatApiData(
      systemPrompt: systemPrompt,
      contents: contents,
      parameters: chatPrompt?.parameters,
      regexRules: regexRules,
    );
  }

  Future<Map<PromptItem, List<ChatMessage>>> _buildChatHistoryMap({
    required ChatPrompt? chatPrompt,
    required int chatRoomId,
    required List<ChatMessage> messages,
    List<int>? excludeMessageIds,
    int? beforeMessageIndex,
  }) async {
    final map = <PromptItem, List<ChatMessage>>{};
    if (chatPrompt == null) return map;

    final chatItems =
        chatPrompt.items.where((item) => item.role == PromptRole.chat).toList();
    if (chatItems.isEmpty) return map;

    for (final chatItem in chatItems) {
      var itemMessages = await _loadChatItemMessages(chatItem, chatRoomId);

      if (excludeMessageIds != null && excludeMessageIds.isNotEmpty) {
        itemMessages =
            itemMessages.where((m) => !excludeMessageIds.contains(m.id)).toList();
      }

      if (beforeMessageIndex != null) {
        itemMessages = itemMessages.where((m) {
          final idx = messages.indexWhere((msg) => msg.id == m.id);
          return idx >= 0 && idx < beforeMessageIndex;
        }).toList();
      }

      map[chatItem] = itemMessages;
    }

    return map;
  }

  Future<List<ChatMessage>> _loadChatItemMessages(
      PromptItem chatItem, int chatRoomId) async {
    if (chatItem.chatSettingMode == ChatSettingMode.basic) {
      return await db.readChatMessagesByChatRoom(chatRoomId);
    }

    switch (chatItem.chatRangeType) {
      case ChatRangeType.recent:
        final count = chatItem.recentChatCount ?? 0;
        if (count <= 0) {
          return await db.readChatMessagesByChatRoom(chatRoomId);
        }
        return await db.readChatMessagesRecent(chatRoomId, count);
      case ChatRangeType.middle:
        final start = chatItem.chatStartPosition ?? 1;
        final end = chatItem.chatEndPosition ?? start;
        return await db.readChatMessagesMiddle(chatRoomId, start, end);
      case ChatRangeType.old:
        final recentExclude = chatItem.chatStartPosition ?? 0;
        if (recentExclude <= 0) {
          return await db.readChatMessagesByChatRoom(chatRoomId);
        }
        return await db.readChatMessagesOld(chatRoomId, recentExclude);
    }
  }
}
