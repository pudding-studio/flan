import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/character/character_book_folder.dart';
import '../models/chat/agent_entry.dart';
import '../models/chat/chat_model.dart';
import '../models/chat/chat_message.dart';
import '../models/chat/custom_model.dart';
import '../models/chat/custom_provider.dart';
import '../models/chat/unified_model.dart';
import '../models/prompt/auxiliary_prompt.dart';
import '../models/prompt/prompt_parameters.dart';
import '../providers/tokenizer_provider.dart';
import '../utils/token_counter.dart';
import 'ai_service.dart';
import 'auxiliary_prompt_service.dart';

class AgentSummaryService {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final AiService _aiService = AiService();

  static const String _logTag = 'AgentSummary';

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

  /// Copies CharacterBook entries flagged with `autoSummaryInsert == true`
  /// into the agent_entries table for [chatRoomId]. No-op if entries for the
  /// same (name, type) already exist — so calling this repeatedly is safe and
  /// idempotent.
  ///
  /// Category → AgentEntryType mapping follows the redesigned 설정집:
  ///  - character → character
  ///  - location  → location
  ///  - event     → event
  ///  - other     → item  (per spec: '기타 (요약의 물품이 이곳으로 통합)')
  ///
  /// Invoked on the first user message of a chat so the auto-summary pipeline
  /// already has the user-authored seed data to build on.
  Future<void> seedFromCharacterBooks({
    required int chatRoomId,
    required int characterId,
  }) async {
    try {
      final books = await _db.readCharacterBooks(characterId);
      // Disabled entries are switched off for the story, so they must not
      // reach the summary either; key-based ones stay, as they can still fire.
      final seedable = books
          .where((b) =>
              b.autoSummaryInsert &&
              b.enabled != CharacterBookActivationCondition.disabled)
          .toList();
      if (seedable.isEmpty) return;

      int created = 0;
      for (final book in seedable) {
        final type = _agentTypeForCategory(book.category);
        final existing = await _db.getAgentEntryByName(chatRoomId, book.name, type);
        if (existing != null) continue;

        final data = _seedDataForBook(book);
        final entry = AgentEntry(
          chatRoomId: chatRoomId,
          entryType: type,
          name: book.name,
          data: data,
          isActive: true,
        );
        await _db.createAgentEntry(entry);
        created++;
      }
      _log('Seeded $created agent_entries from character_books (chatRoom=$chatRoomId)');
    } catch (e) {
      _logError('seedFromCharacterBooks failed: $e');
    }
  }

  AgentEntryType _agentTypeForCategory(CharacterBookCategory category) {
    switch (category) {
      case CharacterBookCategory.character:
        return AgentEntryType.character;
      case CharacterBookCategory.location:
        return AgentEntryType.location;
      case CharacterBookCategory.event:
        return AgentEntryType.event;
      case CharacterBookCategory.other:
        return AgentEntryType.item;
    }
  }

  /// Maps CharacterBook structured fields onto the AgentEntry.data schema
  /// that [AgentEntry.toReadableText] already knows how to render. Fields that
  /// are empty on the source book are omitted so they don't appear as blank
  /// headers in the rendered prompt body.
  Map<String, dynamic> _seedDataForBook(CharacterBook book) {
    final data = <String, dynamic>{};
    void putIfNotEmpty(String key, String value) {
      if (value.trim().isNotEmpty) data[key] = value;
    }

    switch (book.category) {
      case CharacterBookCategory.character:
        putIfNotEmpty('appearance', book.appearance);
        putIfNotEmpty('personality', book.personality);
        putIfNotEmpty('past', book.past);
        putIfNotEmpty('abilities', book.abilities);
        putIfNotEmpty('dialogue_style', book.dialogueStyle);
        // Gender / age aren't first-class AgentEntry.character fields today,
        // but surface them via 'appearance' as a fallback if set — keeps the
        // info visible in the prompt without requiring a schema change.
        final age = book.age.trim();
        final gender = book.gender;
        if (gender != null || age.isNotEmpty) {
          final parts = <String>[];
          if (age.isNotEmpty) parts.add(age);
          if (gender != null) {
            parts.add(gender == CharacterBookGender.other
                ? (book.genderOther.isNotEmpty ? book.genderOther : gender.displayName)
                : gender.displayName);
          }
          final appearance = book.appearance.trim();
          final prefix = parts.join(', ');
          data['appearance'] =
              appearance.isEmpty ? prefix : '$prefix\n$appearance';
        }
      case CharacterBookCategory.location:
        putIfNotEmpty('features', book.setting);
      case CharacterBookCategory.event:
        putIfNotEmpty('datetime', book.eventDatetime);
        putIfNotEmpty('overview', book.eventContent);
        putIfNotEmpty('result', book.eventResult);
      case CharacterBookCategory.other:
        putIfNotEmpty('features', book.setting);
    }
    return data;
  }

  /// Main entry point: process agent summary for a chat room
  /// At most this many pin ranges are caught up per run, so a long backlog
  /// spreads over several replies instead of one long wait.
  static const int maxPinRangesPerRun = 5;

  /// Summarizes every pin range not covered yet, oldest first: the messages
  /// after the previous pin up to and including the pin. Each range is
  /// marked done only after its extraction is merged, so a failed range is
  /// retried on the next run instead of being skipped for good.
  Future<void> processAgentSummary({required int chatRoomId}) async {
    _log('Starting agent summary for chatRoom=$chatRoomId');

    try {
      final allMessages = await _db.readChatMessagesByChatRoom(chatRoomId);
      final pins = await _db.getAgentSummaryPins(chatRoomId);
      final plan = planAgentSummaryRanges(
        messageIds: [for (final m in allMessages) if (m.id != null) m.id!],
        pins: pins,
        maxRanges: maxPinRangesPerRun,
      );
      await _db.markPinsAgentSummarized(plan.covered);
      if (plan.ranges.isEmpty) {
        _log('No pin ranges left to summarize');
        return;
      }

      final setup = await _loadExtractionSetup();
      if (setup == null) return;

      final byId = {for (final m in allMessages) if (m.id != null) m.id!: m};
      var summarized = 0;
      for (final range in plan.ranges) {
        final messages = [for (final id in range.messageIds) byId[id]!];
        if (!await _summarizeRange(chatRoomId, messages, setup)) {
          // Keep the order: later ranges wait until this one succeeds.
          _logError('Extraction failed for pin ${range.pinMessageId}; will retry');
          break;
        }
        await _db.markPinsAgentSummarized([range.pinMetadataId]);
        summarized++;
      }

      if (summarized > 0) await _updateActivation(chatRoomId);
      _logSuccess('Agent summary complete for chatRoom=$chatRoomId '
          '($summarized of ${plan.ranges.length} pin ranges)');
    } catch (e) {
      _logError('Agent summary failed: $e');
    }
  }

  /// Summarizes, on request, the messages from the start or the previous
  /// pin up to the pin [pinMessageId], and marks that pin covered. Throws
  /// when the range cannot be summarized.
  Future<void> summarizeUpTo({
    required int chatRoomId,
    required int pinMessageId,
  }) async {
    final allMessages = await _db.readChatMessagesByChatRoom(chatRoomId);
    final messageIds = [for (final m in allMessages) if (m.id != null) m.id!];
    final pins = await _db.getAgentSummaryPins(chatRoomId);
    final range = agentSummaryRangeUpTo(
      messageIds: messageIds,
      pins: pins,
      pinMessageId: pinMessageId,
    );
    if (range == null) throw Exception('No messages found in summary range');

    final setup = await _loadExtractionSetup();
    if (setup == null) throw Exception('Auto summary settings not found');
    final byId = {for (final m in allMessages) if (m.id != null) m.id!: m};
    final messages = [for (final id in range.messageIds) byId[id]!];
    if (!await _summarizeRange(chatRoomId, messages, setup)) {
      throw Exception('Failed to extract structured data');
    }
    await _db.markPinsAgentSummarized([range.pinMetadataId]);
    await _updateActivation(chatRoomId);
    _logSuccess('Manual agent summary up to pin $pinMessageId');
  }

  Future<({UnifiedModel model, PromptParameters? parameters})?>
      _loadExtractionSetup() async {
    final settings = await _db.getAutoSummarySettings(0);
    if (settings == null) return null;
    PromptParameters? parameters;
    if (settings.parameters != null && settings.parameters!.isNotEmpty) {
      parameters = PromptParameters.fromJson(jsonDecode(settings.parameters!));
    }
    final model = settings.useSubModel
        ? await _resolveSubModel()
        : await _resolveModel(settings.summaryModel);
    return (model: model, parameters: parameters);
  }

  /// Extracts entries from one range and merges them; false when the AI
  /// answer could not be used.
  Future<bool> _summarizeRange(
    int chatRoomId,
    List<ChatMessage> messages,
    ({UnifiedModel model, PromptParameters? parameters}) setup,
  ) async {
    final context = await _buildContext(chatRoomId, messages);
    final extracted = await _extractStructuredData(
        context, setup.model, setup.parameters, chatRoomId);
    if (extracted == null) return false;
    await _mergeEntries(chatRoomId, extracted);
    return true;
  }

  /// Context for AI extraction: one pin range + existing entries.
  Future<_AgentContext> _buildContext(
    int chatRoomId,
    List<ChatMessage> messages,
  ) async {
    final chatRoom = await _db.readChatRoom(chatRoomId);
    final existingEntries = await _db.getAgentEntries(chatRoomId);

    // Load character info for context
    String characterName = '';
    String userName = '';
    if (chatRoom != null) {
      final character = await _db.readCharacter(chatRoom.characterId);
      characterName = character?.name ?? '';
      if (chatRoom.selectedPersonaId != null) {
        final persona = await _db.readPersona(chatRoom.selectedPersonaId!);
        userName = persona?.name ?? '';
      }
    }

    return _AgentContext(
      recentMessages: messages,
      existingEntries: existingEntries,
      characterName: characterName,
      userName: userName,
    );
  }

  /// Send messages + existing entries to AI for structured extraction
  Future<Map<String, dynamic>?> _extractStructuredData(
    _AgentContext context,
    UnifiedModel model,
    PromptParameters? promptParameters,
    int chatRoomId,
  ) async {
    final systemPrompt = await _loadExtractionPrompt();
    final userContent = _buildExtractionUserContent(context);

    final contents = [
      {
        'role': 'user',
        'parts': [{'text': userContent}]
      }
    ];

    _log('Sending extraction request (${context.recentMessages.length} messages, ${context.existingEntries.length} existing entries)');

    final response = await _aiService.sendMessage(
      systemPrompt: systemPrompt,
      contents: contents,
      model: model,
      promptParameters: promptParameters,
      chatRoomId: chatRoomId,
      logType: 'agent_summary',
    );

    _log('Extraction response received, tokens: ${response.usageMetadata?.totalTokenCount ?? 0}');

    // Parse JSON from response
    try {
      final jsonStr = _extractJsonFromResponse(response.text);
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      _logError('Failed to parse extraction response as JSON: $e');
      _logError('Response text: ${response.text.substring(0, response.text.length.clamp(0, 500))}');
      return null;
    }
  }

  /// Extract JSON block from AI response (handles markdown code blocks)
  String _extractJsonFromResponse(String text) {
    // Try to find JSON in code block
    final codeBlockRegex = RegExp(r'```(?:json)?\s*\n?([\s\S]*?)\n?```');
    final match = codeBlockRegex.firstMatch(text);
    if (match != null) {
      return match.group(1)!.trim();
    }

    // Try to find raw JSON object
    final jsonStart = text.indexOf('{');
    final jsonEnd = text.lastIndexOf('}');
    if (jsonStart != -1 && jsonEnd > jsonStart) {
      return text.substring(jsonStart, jsonEnd + 1);
    }

    return text;
  }

  /// Load the extraction system prompt (user-editable via Auxiliary Prompts)
  Future<String> _loadExtractionPrompt() async {
    try {
      final content = await AuxiliaryPromptService.instance
          .getEffectiveContent(AuxiliaryPromptKey.agentSummary);
      if (content.trim().isEmpty) return _fallbackExtractionPrompt;
      return content;
    } catch (e) {
      _logError('Failed to load extraction prompt: $e');
      return _fallbackExtractionPrompt;
    }
  }

  /// Build user content with recent messages and existing entries
  String _buildExtractionUserContent(_AgentContext context) {
    final buffer = StringBuffer();

    // Existing entries context
    if (context.existingEntries.isNotEmpty) {
      buffer.writeln('=== 기존 데이터 ===');
      for (final type in AgentEntryType.values) {
        final entries = context.existingEntries
            .where((e) => e.entryType == type)
            .toList();
        if (entries.isEmpty) continue;
        buffer.writeln('\n[${type.displayName}]');
        for (final entry in entries) {
          buffer.writeln(entry.toReadableText());
        }
      }
      buffer.writeln();
    }

    // Recent messages
    buffer.writeln('=== 최근 메시지 ===');
    if (context.userName.isNotEmpty) {
      buffer.writeln('{{user}} = ${context.userName}');
    }
    if (context.characterName.isNotEmpty) {
      buffer.writeln('{{char}} = ${context.characterName}');
    }
    buffer.writeln();

    for (final message in context.recentMessages) {
      final dt = message.createdAt;
      final dateStr = '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      final role = message.role == MessageRole.user ? (context.userName.isNotEmpty ? context.userName : 'User') : (context.characterName.isNotEmpty ? context.characterName : 'Assistant');
      final cleanContent = message.content.replaceAll(RegExp(r'【[^】]*】'), '').trim();
      buffer.writeln('[$dateStr] $role:');
      buffer.writeln(cleanContent);
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Merge extracted data into database (upsert by name + type)
  Future<void> _mergeEntries(int chatRoomId, Map<String, dynamic> extracted) async {
    final typeMap = {
      'episodes': AgentEntryType.episode,
      'characters': AgentEntryType.character,
      'locations': AgentEntryType.location,
      'items': AgentEntryType.item,
      'events': AgentEntryType.event,
    };

    int created = 0;
    int updated = 0;

    for (final entry in typeMap.entries) {
      final key = entry.key;
      final type = entry.value;
      final items = extracted[key];
      if (items == null || items is! List) continue;

      for (final item in items) {
        if (item is! Map<String, dynamic>) continue;
        final name = item['name'] as String?;
        if (name == null || name.isEmpty) continue;

        final action = item['_action'] as String? ?? 'create';
        if (action == 'unchanged') continue;

        // Build data map (exclude meta fields)
        final data = Map<String, dynamic>.from(item)
          ..remove('name')
          ..remove('_action');

        // Build related names from cross-references in data
        final relatedNames = _extractRelatedNames(data, type);

        final existing = await _db.getAgentEntryByName(chatRoomId, name, type);

        if (existing != null) {
          // Merge: update existing data with new data
          final mergedData = Map<String, dynamic>.from(existing.data)..addAll(data);
          final mergedRelated = {...existing.relatedNames, ...relatedNames}.toList();
          await _db.updateAgentEntry(existing.copyWith(
            data: mergedData,
            relatedNames: mergedRelated,
            updatedAt: DateTime.now(),
          ));
          updated++;
        } else {
          await _db.createAgentEntry(AgentEntry(
            chatRoomId: chatRoomId,
            entryType: type,
            name: name,
            data: data,
            relatedNames: relatedNames.toList(),
          ));
          created++;
        }
      }
    }

    _logSuccess('Merge complete: $created created, $updated updated');
  }

  /// Extract related names from cross-reference fields in data
  Set<String> _extractRelatedNames(Map<String, dynamic> data, AgentEntryType type) {
    final names = <String>{};

    switch (type) {
      case AgentEntryType.episode:
        _addListItems(names, data['characters']);
        _addListItems(names, data['locations']);
      case AgentEntryType.character:
        _addListItems(names, data['possessions']);
      case AgentEntryType.location:
        if (data['parent_location'] is String && (data['parent_location'] as String).isNotEmpty) {
          names.add(data['parent_location'] as String);
        }
        _addListItems(names, data['related_episodes']);
      case AgentEntryType.item:
        _addListItems(names, data['related_episodes']);
      case AgentEntryType.event:
        _addListItems(names, data['related_episodes']);
    }

    return names;
  }

  void _addListItems(Set<String> names, dynamic value) {
    if (value is List) {
      for (final item in value) {
        if (item is String && item.isNotEmpty) {
          names.add(item);
        }
      }
    }
  }

  /// Update activation state based on current context
  Future<void> _updateActivation(int chatRoomId) async {
    // Deactivate all first
    await _db.deactivateAllAgentEntries(chatRoomId);

    final allEntries = await _db.getAgentEntries(chatRoomId);
    if (allEntries.isEmpty) return;

    // Get last few messages to determine current context
    final allMessages = await _db.readChatMessagesByChatRoom(chatRoomId);
    if (allMessages.isEmpty) return;

    final recentMessages = allMessages.length > 3
        ? allMessages.sublist(allMessages.length - 3)
        : allMessages;
    final recentText = recentMessages.map((m) => m.content).join('\n');

    // Build name-indexed maps
    final entryByTypeAndName = <String, AgentEntry>{};
    for (final e in allEntries) {
      entryByTypeAndName['${e.entryType.name}:${e.name}'] = e;
    }

    final activatedIds = <int>{};

    // Activate characters mentioned in recent messages
    final characters = allEntries.where((e) => e.entryType == AgentEntryType.character);
    for (final char in characters) {
      if (recentText.contains(char.name)) {
        _activateEntry(char, activatedIds);
      }
    }

    // Activate locations mentioned in recent messages
    final locations = allEntries.where((e) => e.entryType == AgentEntryType.location);
    for (final loc in locations) {
      if (recentText.contains(loc.name)) {
        _activateEntry(loc, activatedIds);
        // Activate parent locations recursively
        _activateParentLocations(loc, allEntries, activatedIds);
      }
    }

    // Activate items mentioned in recent messages
    final items = allEntries.where((e) => e.entryType == AgentEntryType.item);
    for (final item in items) {
      if (recentText.contains(item.name)) {
        _activateEntry(item, activatedIds);
      }
    }

    // Activate episodes related to any activated entry
    final episodes = allEntries.where((e) => e.entryType == AgentEntryType.episode);
    for (final episode in episodes) {
      final episodeCharacters = episode.data['characters'] as List? ?? [];
      final episodeLocations = episode.data['locations'] as List? ?? [];

      final isRelated = activatedIds.any((id) {
        final entry = allEntries.firstWhere((e) => e.id == id, orElse: () => episode);
        if (entry.entryType == AgentEntryType.character) {
          return episodeCharacters.contains(entry.name);
        }
        if (entry.entryType == AgentEntryType.location) {
          return episodeLocations.contains(entry.name);
        }
        return false;
      });

      if (isRelated) {
        _activateEntry(episode, activatedIds);
      }
    }

    // Activate events related to activated episodes
    final events = allEntries.where((e) => e.entryType == AgentEntryType.event);
    for (final event in events) {
      final relatedEpisodes = event.data['related_episodes'] as List? ?? [];
      final isRelated = activatedIds.any((id) {
        final entry = allEntries.firstWhere((e) => e.id == id, orElse: () => event);
        return entry.entryType == AgentEntryType.episode &&
            relatedEpisodes.contains(entry.name);
      });

      if (isRelated) {
        _activateEntry(event, activatedIds);
      }
    }

    // Apply activation to database
    for (final id in activatedIds) {
      await _db.setAgentEntryActive(id, true);
    }

    _logSuccess('Activation updated: ${activatedIds.length}/${allEntries.length} entries active');
  }

  void _activateEntry(AgentEntry entry, Set<int> activatedIds) {
    if (entry.id != null) {
      activatedIds.add(entry.id!);
    }
  }

  /// Recursively activate parent locations
  void _activateParentLocations(
    AgentEntry location,
    List<AgentEntry> allEntries,
    Set<int> activatedIds,
  ) {
    final parentName = location.data['parent_location'] as String?;
    if (parentName == null || parentName.isEmpty) return;

    final parent = allEntries.firstWhere(
      (e) => e.entryType == AgentEntryType.location && e.name == parentName,
      orElse: () => location,
    );

    if (parent != location && parent.id != null && !activatedIds.contains(parent.id)) {
      activatedIds.add(parent.id!);
      _activateParentLocations(parent, allEntries, activatedIds);
    }
  }

  static final _futurePlanPattern = RegExp(r'【PLAN\|([^】]+)】');

  /// Parse 【PLAN|...】 tag from AI response and activate matching entries
  Future<void> processFuturePlan(int chatRoomId, String responseText) async {
    final match = _futurePlanPattern.firstMatch(responseText);
    if (match == null) return;

    final keywords = match.group(1)!
        .split(',')
        .map((k) => k.trim())
        .where((k) => k.isNotEmpty)
        .toList();
    if (keywords.isEmpty) return;

    _log('Future plan found: $keywords');

    await _db.deactivateAllAgentEntries(chatRoomId);

    final allEntries = await _db.getAgentEntries(chatRoomId);
    for (final entry in allEntries) {
      if (keywords.any((k) => entry.name == k || entry.name.contains(k) || k.contains(entry.name))) {
        if (entry.id != null) {
          await _db.setAgentEntryActive(entry.id!, true);
        }
      }
    }

    _logSuccess('Future plan applied: ${keywords.length} keywords matched');
  }

  /// Build active entries text for prompt injection.
  ///
  /// [episodeContentTokenBudget] limits how many tokens episode contents may
  /// occupy. When null, all episodes are included. When non-null, episodes are
  /// selected by priority (location-related → character-related → others) so
  /// that the total fits within the budget. Selected episodes are always
  /// emitted in chronological order (oldest first).
  Future<String> buildActiveEntriesText(
    int chatRoomId, {
    int? episodeContentTokenBudget,
    TokenizerType? tokenizer,
  }) async {
    final allEntries = await _db.getAgentEntries(chatRoomId);
    if (allEntries.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('### 참고자료');

    for (final type in AgentEntryType.values) {
      final typeEntries = allEntries.where((e) => e.entryType == type).toList();
      if (typeEntries.isEmpty) continue;

      buffer.writeln('\n#### ${type.displayName}');
      buffer.writeln('##### 목록');

      if (type == AgentEntryType.episode) {
        // Episodes: chronological order (oldest first) for both list and content
        typeEntries.sort((a, b) => a.createdAt.compareTo(b.createdAt));

        for (int i = 0; i < typeEntries.length; i++) {
          buffer.writeln('${i + 1}. ${typeEntries[i].name}');
        }

        final selected = _selectEpisodesForContent(
          typeEntries,
          episodeContentTokenBudget,
          tokenizer,
        );
        if (selected.isNotEmpty) {
          buffer.writeln('##### 내용');
          for (int i = 0; i < selected.length; i++) {
            buffer.writeln('${i + 1}. ${selected[i].toReadableText()}');
          }
        }
      } else {
        buffer.writeln(typeEntries.map((e) => e.name).join(', '));
        final activeEntries = typeEntries.where((e) => e.isActive).toList();
        if (activeEntries.isNotEmpty) {
          buffer.writeln('##### 내용');
          for (int i = 0; i < activeEntries.length; i++) {
            buffer.writeln('${i + 1}. ${activeEntries[i].toReadableText()}');
          }
        }
      }
    }

    return buffer.toString();
  }

  /// Select episodes for the content section, fitting within [tokenBudget].
  ///
  /// - When [tokenBudget] is null, all episodes are returned.
  /// - When [tokenBudget] is 0 or negative, no episodes are returned.
  /// - When the full set fits, all are returned.
  /// - Otherwise, episodes are prioritized:
  ///     1. episodes referencing locations
  ///     2. episodes referencing characters (and not already in 1)
  ///     3. remaining episodes
  ///   Within each priority bucket, chronological order is preserved.
  ///   The returned list is always sorted chronologically (oldest first).
  List<AgentEntry> _selectEpisodesForContent(
    List<AgentEntry> chronologicalEpisodes,
    int? tokenBudget,
    TokenizerType? tokenizer,
  ) {
    if (tokenBudget == null) return chronologicalEpisodes;
    if (tokenBudget <= 0) return const [];

    final tokenCache = <AgentEntry, int>{};
    int totalTokens = 0;
    for (final ep in chronologicalEpisodes) {
      final t = TokenCounter.estimateTokenCount(
        ep.toReadableText(),
        tokenizer: tokenizer,
      );
      tokenCache[ep] = t;
      totalTokens += t;
    }

    if (totalTokens <= tokenBudget) return chronologicalEpisodes;

    final priority1 = <AgentEntry>[];
    final priority2 = <AgentEntry>[];
    final priority3 = <AgentEntry>[];
    for (final ep in chronologicalEpisodes) {
      final hasLocations = ep.data['locations'] is List &&
          (ep.data['locations'] as List).isNotEmpty;
      final hasCharacters = ep.data['characters'] is List &&
          (ep.data['characters'] as List).isNotEmpty;
      if (hasLocations) {
        priority1.add(ep);
      } else if (hasCharacters) {
        priority2.add(ep);
      } else {
        priority3.add(ep);
      }
    }

    final selected = <AgentEntry>{};
    int used = 0;
    for (final group in [priority1, priority2, priority3]) {
      for (final ep in group) {
        final t = tokenCache[ep] ?? 0;
        if (used + t <= tokenBudget) {
          selected.add(ep);
          used += t;
        }
      }
    }

    return chronologicalEpisodes.where(selected.contains).toList();
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

  static const _fallbackExtractionPrompt = '''
You are a world-building data extraction agent for a roleplay chat application.
Analyze the provided messages and existing world data, then output a JSON object with the following structure:

{
  "episodes": [...],
  "characters": [...],
  "locations": [...],
  "items": [...],
  "events": [...]
}

Each entry must include a "name" field and an "_action" field ("create", "update", or "unchanged").
Only include entries that are new or have changed. Use "unchanged" to skip entries that don't need updates.

Respond ONLY with the JSON object, no other text.
''';
}

class _AgentContext {
  final List<ChatMessage> recentMessages;
  final List<AgentEntry> existingEntries;
  final String characterName;
  final String userName;

  _AgentContext({
    required this.recentMessages,
    required this.existingEntries,
    required this.characterName,
    required this.userName,
  });
}

/// One pin range the agent summary still has to cover.
class AgentSummaryRange {
  final int pinMetadataId;
  final int pinMessageId;

  /// Messages after the previous pin, up to and including this pin.
  final List<int> messageIds;

  const AgentSummaryRange({
    required this.pinMetadataId,
    required this.pinMessageId,
    required this.messageIds,
  });
}

/// The range ending at the pin [pinMessageId]: from the start or the
/// previous pin. Null when that message is not a pin.
AgentSummaryRange? agentSummaryRangeUpTo({
  required List<int> messageIds,
  required List<({int metadataId, int messageId, bool agentSummarized})> pins,
  required int pinMessageId,
}) {
  final position = {for (var i = 0; i < messageIds.length; i++) messageIds[i]: i};
  final end = position[pinMessageId];
  final pin = pins.where((p) => p.messageId == pinMessageId).firstOrNull;
  if (end == null || pin == null) return null;
  var start = 0;
  for (final other in pins) {
    final at = position[other.messageId];
    if (at != null && at < end && at + 1 > start) start = at + 1;
  }
  return AgentSummaryRange(
    pinMetadataId: pin.metadataId,
    pinMessageId: pinMessageId,
    messageIds: messageIds.sublist(start, end + 1),
  );
}

/// Decides which pin ranges to summarize. Pins before the newest covered
/// pin are already inside a covered range (a pin added later in the
/// middle), so they are only marked [covered]. The rest become [ranges],
/// oldest first, at most [maxRanges].
({List<AgentSummaryRange> ranges, List<int> covered}) planAgentSummaryRanges({
  required List<int> messageIds,
  required List<({int metadataId, int messageId, bool agentSummarized})> pins,
  required int maxRanges,
}) {
  final position = {for (var i = 0; i < messageIds.length; i++) messageIds[i]: i};
  final ordered = pins.where((p) => position.containsKey(p.messageId)).toList()
    ..sort((a, b) => position[a.messageId]!.compareTo(position[b.messageId]!));

  final lastDone = ordered.lastIndexWhere((p) => p.agentSummarized);
  final covered = [
    for (var i = 0; i < lastDone; i++)
      if (!ordered[i].agentSummarized) ordered[i].metadataId,
  ];

  final ranges = <AgentSummaryRange>[];
  for (var i = lastDone + 1; i < ordered.length && ranges.length < maxRanges; i++) {
    final start = i == 0 ? 0 : position[ordered[i - 1].messageId]! + 1;
    final end = position[ordered[i].messageId]!;
    final ids = messageIds.sublist(start, end + 1);
    if (ids.isEmpty) continue;
    ranges.add(AgentSummaryRange(
      pinMetadataId: ordered[i].metadataId,
      pinMessageId: ordered[i].messageId,
      messageIds: ids,
    ));
  }
  return (ranges: ranges, covered: covered);
}

