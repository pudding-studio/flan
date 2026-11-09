import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/character/persona.dart';
import '../models/character/start_scenario.dart';
import '../models/chat/auto_summary_settings.dart';
import '../models/chat/chat_model.dart';
import '../models/chat/chat_summary.dart';
import '../models/chat/chat_message.dart';
import '../models/chat/chat_message_metadata.dart';
import '../models/chat/summary_prompt_item.dart';
import '../models/chat/custom_model.dart';
import '../models/chat/custom_provider.dart';
import '../models/chat/unified_model.dart';
import '../models/prompt/prompt_parameters.dart';
import '../utils/character_book_lore.dart';
import '../utils/prompt_builder.dart';
import 'agent_summary_service.dart';
import 'ai_service.dart';

class AutoSummaryService {
  final DatabaseHelper _db;
  final AiService _aiService;

  AutoSummaryService({DatabaseHelper? db, AiService? aiService})
      : _db = db ?? DatabaseHelper.instance,
        _aiService = aiService ?? AiService();

  static const String _logTag = 'AutoSummary';

  void _log(String message) {
    developer.log(
      '\x1B[36m[$_logTag]\x1B[0m $message',
      name: _logTag,
    );
  }

  void _logError(String message) {
    developer.log(
      '\x1B[31m[$_logTag ERROR]\x1B[0m $message',
      name: _logTag,
      level: 1000,
    );
  }

  void _logSuccess(String message) {
    developer.log(
      '\x1B[32m[$_logTag]\x1B[0m $message',
      name: _logTag,
    );
  }

  /// Check if auto-summary should trigger (global settings, chatRoomId=0).
  /// Agent mode runs whenever a pin range is still uncovered, so a range
  /// missed earlier is caught up even without a new pin.
  Future<bool> shouldTriggerSummary({
    required int chatRoomId,
    required int currentTokenCount,
    required bool pinCreated,
  }) async {
    final settings = await _db.getAutoSummarySettings(0);
    if (settings == null || !settings.isEnabled) return false;

    if (settings.isAgentEnabled) {
      if (pinCreated) return true;
      final pins = await _db.getAgentSummaryPins(chatRoomId);
      final pending = pins.isNotEmpty && !pins.last.agentSummarized;
      if (pending) _log('Agent mode: uncovered pin range found');
      return pending;
    }

    // Every finished pin range is summarized right away; it only takes
    // effect once it leaves the token window (see getAppliedSummaries).
    final plan = await _planClassicSummaries(chatRoomId);
    final due = plan != null && plan.due.isNotEmpty;
    if (due) _log('Pin ranges to summarize: ${plan.due}');
    return due;
  }

  /// The pin ranges that still need a summary, in order. Null when there
  /// is nothing to plan from.
  Future<
      ({
        List<ChatMessage> allMessages,
        List<int> pinnedMessageIds,
        List<int> due,
      })?> _planClassicSummaries(int chatRoomId) async {
    final allMessages = await _db.readChatMessagesByChatRoom(chatRoomId);
    if (allMessages.isEmpty) return null;
    final pinnedMessageIds = await _getPinnedMessageIds(chatRoomId);
    if (pinnedMessageIds.isEmpty) return null;

    final summarizedEndIds = (await _db.getChatSummaries(chatRoomId))
        .map((s) => s.endPinMessageId)
        .toSet();
    // If the latest pin is already summarized, older unsummarized pins were
    // deleted by the user on purpose — leave them alone.
    final due = summarizedEndIds.contains(pinnedMessageIds.last)
        ? const <int>[]
        : [
            for (final id in pinnedMessageIds)
              if (!summarizedEndIds.contains(id)) id,
          ];
    return (
      allMessages: allMessages,
      pinnedMessageIds: pinnedMessageIds,
      due: due,
    );
  }

  /// The summaries that take effect in the prompt: those whose range has
  /// left the token window (counted back from the newest message). Newer
  /// ones exist already but wait, so the recent turns stay verbatim.
  Future<List<ChatSummary>> getAppliedSummaries(int chatRoomId) async {
    final summaries = await _db.getChatSummaries(chatRoomId);
    if (summaries.isEmpty) return summaries;
    final settings = await _db.getAutoSummarySettings(0);
    if (settings == null) return summaries;

    final allMessages = await _db.readChatMessagesByChatRoom(chatRoomId);
    final cutoffMessageId =
        _findCutoffMessageId(allMessages, settings.tokenThreshold);
    final cutoffIndex = cutoffMessageId == 0
        ? -1
        : allMessages.indexWhere((m) => m.id == cutoffMessageId);
    return [
      for (final summary in summaries)
        if (allMessages.indexWhere((m) => m.id == summary.endPinMessageId)
            case final endIndex when endIndex != -1 && endIndex <= cutoffIndex)
          summary,
    ];
  }

  /// Generate summaries for every finished pin range not summarized yet.
  /// They take effect later, once their range leaves the token window.
  Future<void> generateAllPendingSummaries({
    required int chatRoomId,
  }) async {
    final settings = await _db.getAutoSummarySettings(0);
    if (settings == null || !settings.isEnabled) return;

    if (settings.isAgentEnabled) {
      _log('Agent mode enabled, delegating to AgentSummaryService');
      final agentService = AgentSummaryService();
      await agentService.processAgentSummary(chatRoomId: chatRoomId);
      return;
    }

    _log('Starting summary generation for chatRoom=$chatRoomId');

    final plan = await _planClassicSummaries(chatRoomId);
    if (plan == null || plan.due.isEmpty) {
      _log('No pin ranges left to summarize');
      return;
    }
    final allMessages = plan.allMessages;
    final pinnedMessageIds = plan.pinnedMessageIds;

    // Build ranges: [beginning→pin1], [pin1→pin2], ...
    // Process sequentially so earlier summaries feed into {{chat_historys}} for later ones
    int generatedCount = 0;
    for (final endPinId in plan.due) {
      final pinIndex = pinnedMessageIds.indexOf(endPinId);
      final startPinId = pinIndex == 0 ? 0 : pinnedMessageIds[pinIndex - 1];

      final messagesToSummarize = _getMessagesInRange(
        allMessages: allMessages,
        startPinMessageId: startPinId,
        endPinMessageId: endPinId,
      );
      if (messagesToSummarize.isEmpty) continue;

      _log('Generating summary for range [$startPinId → $endPinId] (${messagesToSummarize.length} messages)');

      try {
        // Requested one range at a time so {{chat_historys}} includes the
        // summaries generated just before.
        final result =
            await _requestSummary(chatRoomId, settings, messagesToSummarize);
        final summary = ChatSummary(
          chatRoomId: chatRoomId,
          startPinMessageId: startPinId,
          endPinMessageId: endPinId,
          summaryContent: result.text,
          tokenCount: result.tokenCount,
        );
        await _db.createChatSummary(summary);
        generatedCount++;
        _logSuccess('Summary generated for range [$startPinId → $endPinId], tokens: ${result.tokenCount}');
      } catch (e) {
        _logError('Failed to generate summary for pin $endPinId: $e');
        // Stop here: a later summary would make this gap look user-deleted.
        break;
      }
    }

    _logSuccess('Summary generation complete: $generatedCount new summaries created');
  }

  /// Count tokens from the most recent message backwards and return the
  /// message ID where cumulative tokens first reach or exceed the threshold.
  /// Returns 0 if all messages fit within the threshold (nothing to summarize).
  int _findCutoffMessageId(List<ChatMessage> allMessages, int tokenThreshold) {
    int cumulative = 0;
    for (int i = allMessages.length - 1; i >= 0; i--) {
      cumulative += allMessages[i].tokenCount;
      if (cumulative >= tokenThreshold) {
        return allMessages[i].id ?? 0;
      }
    }
    return 0;
  }

  /// Load keyword map for keyword substitution in summary prompts
  Future<Map<String, String>> _loadKeywordMap(int chatRoomId) async {
    final chatRoom = await _db.readChatRoom(chatRoomId);
    if (chatRoom == null) return {};

    final character = await _db.readCharacter(chatRoom.characterId);
    if (character == null) return {};

    Persona? persona;
    if (chatRoom.selectedPersonaId != null) {
      persona = await _db.readPersona(chatRoom.selectedPersonaId!);
    }

    StartScenario? startScenario;
    if (chatRoom.selectedStartScenarioId != null) {
      startScenario = await _db.readStartScenario(chatRoom.selectedStartScenarioId!);
    }

    // Same lorebook selection as a chat turn: enabled entries plus key-based
    // ones mentioned in the latest messages, with their details.
    final allCharacterBooks = await _db.readCharacterBooks(character.id!);
    final messages = await _db.readChatMessagesByChatRoom(chatRoomId);
    final scanned = messages.length > characterBookScanDepth
        ? messages.sublist(messages.length - characterBookScanDepth)
        : messages;
    final activeCharacterBooks = selectActiveCharacterBooks(
      allCharacterBooks,
      [for (final m in scanned) m.content],
    );

    final summaries = await _db.getChatSummaries(chatRoomId);
    final summaryMetadataMap = <int, ChatMessageMetadata>{};
    for (final summary in summaries) {
      final metadata = await _db.readChatMessageMetadataByMessage(summary.endPinMessageId);
      if (metadata != null) {
        summaryMetadataMap[summary.endPinMessageId] = metadata;
      }
    }

    final latestMetadata =
        await _db.readLatestChatMessageMetadata(chatRoomId);

    return {
      ...PromptBuilder.buildKeywordMap(
        character: character,
        persona: persona,
        startScenario: startScenario,
        activeCharacterBooks: activeCharacterBooks,
        chatRoom: chatRoom,
        summaries: summaries,
        summaryMetadataMap: summaryMetadataMap,
        latestMetadata: latestMetadata,
      ),
      'character_book': PromptBuilder.buildCharacterBookText(
        activeCharacterBooks,
        withDetails: (_) => true,
      ),
    };
  }

  /// Build prompt from SummaryPromptItem list
  _PromptBuildResult _buildPromptFromItems(
    List<SummaryPromptItem> items,
    String conversationText,
    Map<String, String> keywords,
  ) {
    final systemParts = <String>[];
    final contents = <Map<String, dynamic>>[];

    for (final item in items) {
      final replaced = PromptBuilder.replaceKeywords(item.content, keywords);
      switch (item.role) {
        case SummaryPromptRole.system:
          if (replaced.isNotEmpty) {
            systemParts.add(replaced);
          }
        case SummaryPromptRole.user:
          contents.add({
            'role': 'user',
            'parts': [{'text': replaced}]
          });
        case SummaryPromptRole.assistant:
          contents.add({
            'role': 'model',
            'parts': [{'text': replaced}]
          });
        case SummaryPromptRole.summary:
          contents.add({
            'role': 'user',
            'parts': [{'text': conversationText}]
          });
      }
    }

    return _PromptBuildResult(
      systemPrompt: systemParts.join('\n\n'),
      contents: contents,
    );
  }

  /// Asks the summary model for a summary of [messages] with the user's
  /// summary prompt, model and parameters.
  Future<({String text, int tokenCount})> _requestSummary(
    int chatRoomId,
    AutoSummarySettings settings,
    List<ChatMessage> messages,
  ) async {
    PromptParameters? promptParameters;
    if (settings.parameters != null && settings.parameters!.isNotEmpty) {
      promptParameters = PromptParameters.fromJson(jsonDecode(settings.parameters!));
    }

    final promptItems = settings.summaryPromptItems != null &&
            settings.summaryPromptItems!.isNotEmpty
        ? SummaryPromptItem.listFromJson(settings.summaryPromptItems)
        : <SummaryPromptItem>[];

    final keywords = await _loadKeywordMap(chatRoomId);
    final conversationText = _buildConversationText(messages);

    String systemPrompt = '';
    List<Map<String, dynamic>> contents = [];

    if (promptItems.isNotEmpty) {
      final result = _buildPromptFromItems(promptItems, conversationText, keywords);
      systemPrompt = result.systemPrompt;
      contents = result.contents;
    } else {
      // Fallback: legacy single prompt
      final replacedPrompt = PromptBuilder.replaceKeywords(settings.summaryPrompt, keywords);
      final summaryPrompt = '$replacedPrompt\n\n$conversationText';
      contents = [
        {
          'role': 'user',
          'parts': [{'text': summaryPrompt}]
        }
      ];
    }

    final summaryModel = settings.useSubModel
        ? await _resolveSubModel()
        : await _resolveModel(settings.summaryModel);
    final response = await _aiService.sendMessage(
      systemPrompt: systemPrompt,
      contents: contents,
      model: summaryModel,
      promptParameters: promptParameters,
      chatRoomId: chatRoomId,
      logType: 'auto_summary',
    );
    return (
      text: response.text,
      tokenCount: response.usageMetadata?.totalTokenCount ?? 0,
    );
  }

  /// Summarizes, on request, the messages from the start or the previous
  /// pin up to the pinned message [pinMessageId] — in agent mode as agent
  /// entries, otherwise as that range's summary (replacing an existing one).
  /// Throws when the range cannot be summarized.
  Future<void> summarizeUpTo({
    required int chatRoomId,
    required int pinMessageId,
  }) async {
    final settings = await _db.getAutoSummarySettings(0);
    if (settings == null) {
      throw Exception('Auto summary settings not found');
    }
    if (settings.isAgentEnabled) {
      await AgentSummaryService()
          .summarizeUpTo(chatRoomId: chatRoomId, pinMessageId: pinMessageId);
      return;
    }

    final allMessages = await _db.readChatMessagesByChatRoom(chatRoomId);
    final position = {
      for (var i = 0; i < allMessages.length; i++) allMessages[i].id: i,
    };
    final pinIndex = position[pinMessageId];
    if (pinIndex == null) throw Exception('Message not found');
    final earlierPins = (await _getPinnedMessageIds(chatRoomId))
        .where((id) => (position[id] ?? pinIndex) < pinIndex)
        .toList()
      ..sort((a, b) => position[a]!.compareTo(position[b]!));
    final startPinId = earlierPins.isEmpty ? 0 : earlierPins.last;

    final messages = _getMessagesInRange(
      allMessages: allMessages,
      startPinMessageId: startPinId,
      endPinMessageId: pinMessageId,
    );
    if (messages.isEmpty) throw Exception('No messages found in summary range');

    final result = await _requestSummary(chatRoomId, settings, messages);
    final existing = (await _db.getChatSummaries(chatRoomId))
        .where((s) => s.endPinMessageId == pinMessageId)
        .firstOrNull;
    if (existing != null) {
      await _db.updateChatSummary(existing.copyWith(
        startPinMessageId: startPinId,
        summaryContent: result.text,
        tokenCount: result.tokenCount,
        updatedAt: DateTime.now(),
      ));
    } else {
      await _db.createChatSummary(ChatSummary(
        chatRoomId: chatRoomId,
        startPinMessageId: startPinId,
        endPinMessageId: pinMessageId,
        summaryContent: result.text,
        tokenCount: result.tokenCount,
      ));
    }
    _logSuccess('Manual summary for range [$startPinId → $pinMessageId]');
  }

  /// Regenerate a single existing summary by re-fetching messages in its range
  Future<ChatSummary> regenerateSummary({
    required ChatSummary summary,
  }) async {
    final settings = await _db.getAutoSummarySettings(0);
    if (settings == null) {
      throw Exception('Auto summary settings not found');
    }

    final chatRoomId = summary.chatRoomId;
    final allMessages = await _db.readChatMessagesByChatRoom(chatRoomId);

    final messagesToSummarize = _getMessagesInRange(
      allMessages: allMessages,
      startPinMessageId: summary.startPinMessageId,
      endPinMessageId: summary.endPinMessageId,
    );

    if (messagesToSummarize.isEmpty) {
      throw Exception('No messages found in summary range');
    }

    _log('Regenerating summary #${summary.id} for range [${summary.startPinMessageId} → ${summary.endPinMessageId}]');

    final result =
        await _requestSummary(chatRoomId, settings, messagesToSummarize);
    final updated = summary.copyWith(
      summaryContent: result.text,
      tokenCount: result.tokenCount,
      updatedAt: DateTime.now(),
    );
    await _db.updateChatSummary(updated);

    _logSuccess('Summary #${summary.id} regenerated, tokens: ${result.tokenCount}');
    return updated;
  }

  /// Get message IDs to exclude in agent mode.
  /// Keeps messages from max(0, lastPinIndex - 2*period) onwards.
  Future<Set<int>> getAgentModeExcludeIds({
    required int chatRoomId,
    required int period,
  }) async {
    final allMessages = await _db.readChatMessagesByChatRoom(chatRoomId);
    if (allMessages.isEmpty) return {};

    final pinnedMessageIds = await _getPinnedMessageIds(chatRoomId);
    if (pinnedMessageIds.isEmpty) return {};

    final lastPinId = pinnedMessageIds.last;
    final lastPinIdx = allMessages.indexWhere((m) => m.id == lastPinId);
    if (lastPinIdx == -1) return {};

    final startIdx = (lastPinIdx - 2 * period).clamp(0, allMessages.length);
    if (startIdx == 0) return {};

    final excludeIds = <int>{};
    for (int i = 0; i < startIdx; i++) {
      if (allMessages[i].id != null) excludeIds.add(allMessages[i].id!);
    }
    _log('Agent mode: excluding ${excludeIds.length} messages before index $startIdx (lastPin=$lastPinIdx, period=$period)');
    return excludeIds;
  }

  /// Get all message IDs covered by existing summaries
  /// Messages replaced in the prompt by an applied summary.
  Future<Set<int>> getSummarizedMessageIds(int chatRoomId) async {
    final summaries = await getAppliedSummaries(chatRoomId);
    if (summaries.isEmpty) return {};

    final allMessages = await _db.readChatMessagesByChatRoom(chatRoomId);
    if (allMessages.isEmpty) return {};

    final summarizedIds = <int>{};
    for (final summary in summaries) {
      final startIdx = summary.startPinMessageId == 0
          ? 0
          : allMessages.indexWhere((m) => m.id == summary.startPinMessageId);
      final endIdx = allMessages.indexWhere((m) => m.id == summary.endPinMessageId);

      if (startIdx == -1 || endIdx == -1) continue;

      // Include all messages from start up to and including end pin
      for (int i = startIdx; i <= endIdx; i++) {
        if (allMessages[i].id != null) {
          summarizedIds.add(allMessages[i].id!);
        }
      }
    }
    return summarizedIds;
  }

  Future<List<int>> _getPinnedMessageIds(int chatRoomId) async {
    final allMetadata = await _db.getChatMessageMetadataList(chatRoomId);
    final pinnedMetadata = allMetadata.where((m) => m.isPinned).toList();
    pinnedMetadata.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return pinnedMetadata.map((m) => m.chatMessageId).toList();
  }

  List<ChatMessage> _getMessagesInRange({
    required List<ChatMessage> allMessages,
    required int startPinMessageId,
    required int endPinMessageId,
  }) {
    final startIdx = startPinMessageId == 0
        ? 0
        : allMessages.indexWhere((m) => m.id == startPinMessageId);
    final endIdx = allMessages.indexWhere((m) => m.id == endPinMessageId);

    if (startIdx == -1 || endIdx == -1 || startIdx > endIdx) return [];

    // startPinMessageId=0 → include from index 0
    // otherwise → start after the previous pin
    final from = startPinMessageId == 0 ? 0 : startIdx + 1;
    return allMessages.sublist(from, endIdx + 1);
  }

  static const _englishDays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  String _buildConversationText(List<ChatMessage> messages) {
    final buffer = StringBuffer();
    for (final message in messages) {
      final msgId = message.id ?? 0;
      final dt = message.createdAt;
      final day = _englishDays[dt.weekday - 1];
      final period = dt.hour < 12 ? 'Day' : 'Night';
      final dateStr = '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} ($day), ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}($period)';
      final cleanContent = _stripMetadataTags(message.content);
      buffer.writeln('<msg$msgId Datetime=$dateStr>');
      buffer.writeln(cleanContent);
      buffer.writeln('</msg$msgId>');
    }
    return buffer.toString().trim();
  }

  String _stripMetadataTags(String text) {
    return text.replaceAll(RegExp(r'【[^】]*】'), '').trim();
  }

  Future<UnifiedModel> _resolveModel(String storedValue) async {
    if (storedValue.startsWith('custom:')) {
      final customId = storedValue.replaceFirst('custom:', '');
      final customModels = await CustomModelRepository.loadAll();
      final custom = customModels.where((m) => m.id == customId).firstOrNull;
      if (custom != null) {
        final providers = await CustomProviderRepository.loadAll();
        final cp = custom.providerId != null
            ? providers.where((p) => p.id == custom.providerId).firstOrNull
            : null;
        return UnifiedModel.fromCustomModel(custom, provider: cp);
      }
    }
    final resolved = ChatModel.resolveFromStoredValue(storedValue);
    return UnifiedModel.fromChatModel(resolved);
  }

  Future<UnifiedModel> _resolveSubModel() async {
    final prefs = await SharedPreferences.getInstance();
    final subModelString = prefs.getString('sub_model');
    if (subModelString != null) {
      return _resolveModel(subModelString);
    }
    return UnifiedModel.fromChatModel(ChatModel.geminiFlash25);
  }

  Future<List<ChatMessageMetadata>> getChatMessageMetadataList(
      int chatRoomId) async {
    return await _db.getChatMessageMetadataList(chatRoomId);
  }
}

class _PromptBuildResult {
  final String systemPrompt;
  final List<Map<String, dynamic>> contents;

  _PromptBuildResult({
    required this.systemPrompt,
    required this.contents,
  });
}
