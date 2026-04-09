import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/character/character_book_folder.dart';
import '../models/character/persona.dart';
import '../models/character/start_scenario.dart';
import '../models/chat/chat_model.dart';
import '../models/chat/chat_summary.dart';
import '../models/chat/chat_message.dart';
import '../models/chat/chat_message_metadata.dart';
import '../models/chat/summary_prompt_item.dart';
import '../models/chat/custom_model.dart';
import '../models/chat/custom_provider.dart';
import '../models/chat/unified_model.dart';
import '../models/prompt/prompt_parameters.dart';
import '../utils/prompt_builder.dart';
import 'agent_summary_service.dart';
import 'ai_service.dart';

class AutoSummaryService {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final AiService _aiService = AiService();

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

  /// Check if auto-summary should trigger (global settings, chatRoomId=0)
  Future<bool> shouldTriggerSummary({
    required int chatRoomId,
    required int currentTokenCount,
  }) async {
    final settings = await _db.getAutoSummarySettings(0);
    if (settings == null || !settings.isEnabled) return false;

    if (settings.isAgentEnabled) {
      _log('Agent mode: triggering on pin creation');
      return true;
    }

    final shouldTrigger = currentTokenCount >= settings.tokenThreshold;
    if (shouldTrigger) {
      _log('Trigger condition met: $currentTokenCount >= ${settings.tokenThreshold} tokens');
    }
    return shouldTrigger;
  }

  /// Generate pending summaries only for pin ranges outside the token window.
  /// Counts tokens from the most recent message backwards; only pin ranges
  /// whose endPinId falls before the threshold cutoff are summarized.
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

    final allMessages = await _db.readChatMessagesByChatRoom(chatRoomId);
    if (allMessages.isEmpty) {
      _log('No messages found, skipping');
      return;
    }

    final pinnedMessageIds = await _getPinnedMessageIds(chatRoomId);
    if (pinnedMessageIds.isEmpty) {
      _log('No pinned messages found, skipping');
      return;
    }

    // Find the token-window cutoff
    final cutoffMessageId = _findCutoffMessageId(allMessages, settings.tokenThreshold);
    _log('Token cutoff messageId=$cutoffMessageId (threshold=${settings.tokenThreshold})');

    // Only pins outside the token window (at or before the cutoff)
    final eligiblePinIds = _filterPinsBeforeCutoff(
      allMessages: allMessages,
      pinnedMessageIds: pinnedMessageIds,
      cutoffMessageId: cutoffMessageId,
    );

    if (eligiblePinIds.isEmpty) {
      _log('No pin ranges outside token window, skipping');
      return;
    }

    final existingSummaries = await _db.getChatSummaries(chatRoomId);
    final summarizedEndIds = existingSummaries.map((s) => s.endPinMessageId).toSet();

    // Detect user-deleted summaries: if the latest eligible pin is already
    // summarized, any older unsummarized pin was intentionally deleted by the
    // user — skip them all.
    final latestEligiblePin = eligiblePinIds.last;
    final hasLatestSummary = summarizedEndIds.contains(latestEligiblePin);
    if (hasLatestSummary) {
      _log('Latest eligible pin already summarized, skipping older gaps (user-deleted)');
    }

    // Parse parameters
    PromptParameters? promptParameters;
    if (settings.parameters != null && settings.parameters!.isNotEmpty) {
      promptParameters = PromptParameters.fromJson(jsonDecode(settings.parameters!));
    }

    // Parse prompt items
    final promptItems = settings.summaryPromptItems != null &&
            settings.summaryPromptItems!.isNotEmpty
        ? SummaryPromptItem.listFromJson(settings.summaryPromptItems)
        : <SummaryPromptItem>[];

    _log('Found ${eligiblePinIds.length} eligible pins (out of ${pinnedMessageIds.length}), '
        '${existingSummaries.length} existing summaries');

    // Build ranges: [beginning→pin1], [pin1→pin2], ...
    // Process sequentially so earlier summaries feed into {{chat_historys}} for later ones
    int generatedCount = 0;
    for (final endPinId in eligiblePinIds) {
      if (summarizedEndIds.contains(endPinId)) continue;
      // If the latest eligible pin is summarized, older gaps are user-deleted
      if (hasLatestSummary) continue;

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
        // Reload keywords each iteration so {{chat_historys}} includes previously generated summaries
        final keywords = await _loadKeywordMap(chatRoomId);
        final conversationText = _buildConversationText(messagesToSummarize);

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

        final summary = ChatSummary(
          chatRoomId: chatRoomId,
          startPinMessageId: startPinId,
          endPinMessageId: endPinId,
          summaryContent: response.text,
          tokenCount: response.usageMetadata?.totalTokenCount ?? 0,
        );
        await _db.createChatSummary(summary);
        generatedCount++;
        _logSuccess('Summary generated for range [$startPinId → $endPinId], tokens: ${response.usageMetadata?.totalTokenCount ?? 0}');
      } catch (e) {
        _logError('Failed to generate summary for pin $endPinId: $e');
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

  /// Return only pinned message IDs whose position is at or before the cutoff.
  List<int> _filterPinsBeforeCutoff({
    required List<ChatMessage> allMessages,
    required List<int> pinnedMessageIds,
    required int cutoffMessageId,
  }) {
    if (cutoffMessageId == 0) return [];

    final cutoffIdx = allMessages.indexWhere((m) => m.id == cutoffMessageId);
    if (cutoffIdx == -1) return [];

    final result = <int>[];
    for (final pinId in pinnedMessageIds) {
      final pinIdx = allMessages.indexWhere((m) => m.id == pinId);
      if (pinIdx != -1 && pinIdx <= cutoffIdx) {
        result.add(pinId);
      }
    }
    return result;
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

    final allCharacterBooks = await _db.readCharacterBooks(character.id!);
    final activeCharacterBooks = allCharacterBooks
        .where((b) => b.enabled == CharacterBookActivationCondition.enabled)
        .toList();

    final summaries = await _db.getChatSummaries(chatRoomId);
    final summaryMetadataMap = <int, ChatMessageMetadata>{};
    for (final summary in summaries) {
      final metadata = await _db.readChatMessageMetadataByMessage(summary.endPinMessageId);
      if (metadata != null) {
        summaryMetadataMap[summary.endPinMessageId] = metadata;
      }
    }

    return PromptBuilder.buildKeywordMap(
      character: character,
      persona: persona,
      startScenario: startScenario,
      activeCharacterBooks: activeCharacterBooks,
      chatRoom: chatRoom,
      summaries: summaries,
      summaryMetadataMap: summaryMetadataMap,
    );
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

    PromptParameters? promptParameters;
    if (settings.parameters != null && settings.parameters!.isNotEmpty) {
      promptParameters = PromptParameters.fromJson(jsonDecode(settings.parameters!));
    }

    final promptItems = settings.summaryPromptItems != null &&
            settings.summaryPromptItems!.isNotEmpty
        ? SummaryPromptItem.listFromJson(settings.summaryPromptItems)
        : <SummaryPromptItem>[];

    final keywords = await _loadKeywordMap(chatRoomId);
    final conversationText = _buildConversationText(messagesToSummarize);

    String systemPrompt = '';
    List<Map<String, dynamic>> contents = [];

    if (promptItems.isNotEmpty) {
      final result = _buildPromptFromItems(promptItems, conversationText, keywords);
      systemPrompt = result.systemPrompt;
      contents = result.contents;
    } else {
      final replacedPrompt = PromptBuilder.replaceKeywords(settings.summaryPrompt, keywords);
      final summaryPrompt = '$replacedPrompt\n\n$conversationText';
      contents = [
        {
          'role': 'user',
          'parts': [{'text': summaryPrompt}]
        }
      ];
    }

    _log('Regenerating summary #${summary.id} for range [${summary.startPinMessageId} → ${summary.endPinMessageId}]');

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

    final updated = summary.copyWith(
      summaryContent: response.text,
      tokenCount: response.usageMetadata?.totalTokenCount ?? 0,
      updatedAt: DateTime.now(),
    );
    await _db.updateChatSummary(updated);

    _logSuccess('Summary #${summary.id} regenerated, tokens: ${response.usageMetadata?.totalTokenCount ?? 0}');
    return updated;
  }

  /// Get all message IDs covered by existing summaries
  Future<Set<int>> getSummarizedMessageIds(int chatRoomId) async {
    final summaries = await _db.getChatSummaries(chatRoomId);
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
