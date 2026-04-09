import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/chat/agent_entry.dart';
import '../models/chat/chat_model.dart';
import '../models/chat/chat_message.dart';
import '../models/chat/custom_model.dart';
import '../models/chat/custom_provider.dart';
import '../models/chat/unified_model.dart';
import '../models/prompt/prompt_parameters.dart';
import 'ai_service.dart';

class AgentSummaryService {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final AiService _aiService = AiService();

  static const String _logTag = 'AgentSummary';
  static const int _messageCount = 10;

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

  /// Main entry point: process agent summary for a chat room
  Future<void> processAgentSummary({required int chatRoomId}) async {
    _log('Starting agent summary for chatRoom=$chatRoomId');

    try {
      // Step 1: Build context
      final context = await _buildContext(chatRoomId);
      if (context.recentMessages.isEmpty) {
        _log('No recent messages, skipping');
        return;
      }

      // Step 2: Load settings and resolve model
      final settings = await _db.getAutoSummarySettings(0);
      if (settings == null) return;

      PromptParameters? promptParameters;
      if (settings.parameters != null && settings.parameters!.isNotEmpty) {
        promptParameters = PromptParameters.fromJson(jsonDecode(settings.parameters!));
      }

      final model = settings.useSubModel
          ? await _resolveSubModel()
          : await _resolveModel(settings.summaryModel);

      // Step 3: Extract structured data via AI
      final extracted = await _extractStructuredData(context, model, promptParameters, chatRoomId);
      if (extracted == null) {
        _logError('Failed to extract structured data');
        return;
      }

      // Step 4: Merge entries into database
      await _mergeEntries(chatRoomId, extracted);

      // Step 5: Update activation state
      await _updateActivation(chatRoomId);

      _logSuccess('Agent summary complete for chatRoom=$chatRoomId');
    } catch (e) {
      _logError('Agent summary failed: $e');
    }
  }

  /// Build context for AI extraction: recent messages + existing entries
  Future<_AgentContext> _buildContext(int chatRoomId) async {
    final allMessages = await _db.readChatMessagesByChatRoom(chatRoomId);
    final recentMessages = allMessages.length > _messageCount
        ? allMessages.sublist(allMessages.length - _messageCount)
        : allMessages;

    final existingEntries = await _db.getAgentEntries(chatRoomId);

    // Load character info for context
    final chatRoom = await _db.readChatRoom(chatRoomId);
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
      recentMessages: recentMessages,
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

  /// Load the extraction system prompt from assets
  Future<String> _loadExtractionPrompt() async {
    try {
      return await rootBundle.loadString(
        'assets/defaults/agent_summary_prompts/extraction_prompt.txt',
      );
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

  /// Build active entries text for prompt injection
  Future<String> buildActiveEntriesText(int chatRoomId) async {
    final allEntries = await _db.getAgentEntries(chatRoomId);
    if (allEntries.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('### 참고자료');

    for (final type in AgentEntryType.values) {
      final typeEntries = allEntries.where((e) => e.entryType == type).toList();
      if (typeEntries.isEmpty) continue;

      final activeEntries = typeEntries.where((e) => e.isActive).toList();

      buffer.writeln('\n#### ${type.displayName}');
      buffer.writeln('##### 목록');

      if (type == AgentEntryType.episode) {
        for (int i = 0; i < typeEntries.length; i++) {
          buffer.writeln('${i + 1}. ${typeEntries[i].name}');
        }
        if (activeEntries.isNotEmpty) {
          buffer.writeln('##### 내용');
          for (int i = 0; i < activeEntries.length; i++) {
            buffer.writeln('${i + 1}. ${activeEntries[i].toReadableText()}');
          }
        }
      } else {
        buffer.writeln(typeEntries.map((e) => e.name).join(', '));
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
