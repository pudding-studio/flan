import '../models/character/character.dart';
import '../models/character/persona.dart';
import '../models/character/character_book_folder.dart';
import '../models/character/start_scenario.dart';
import '../models/chat/chat_message.dart';
import '../models/chat/chat_message_metadata.dart';
import '../models/chat/chat_room.dart';
import '../models/chat/chat_summary.dart';
import '../models/prompt/chat_prompt.dart';
import '../models/prompt/prompt_condition.dart';
import '../models/prompt/prompt_item.dart';
import '../providers/tokenizer_provider.dart';
import 'date_formatter.dart';
import 'metadata_parser.dart';
import 'token_counter.dart';

class PromptBuilder {
  static String buildSystemPrompt({
    required ChatPrompt? chatPrompt,
    required Character character,
    Persona? persona,
    StartScenario? startScenario,
    List<CharacterBook>? activeCharacterBooks,
    ChatRoom? chatRoom,
    List<ChatSummary>? summaries,
    Map<int, ChatMessageMetadata>? summaryMetadataMap,
    ChatMessageMetadata? latestMetadata,
    List<PromptCondition>? conditions,
    Map<int, String>? conditionStates,
    String? agentContext,
    Map<String, String>? extraKeywords,
  }) {
    final keywords = buildKeywordMap(
      character: character,
      persona: persona,
      startScenario: startScenario,
      activeCharacterBooks: activeCharacterBooks,
      chatRoom: chatRoom,
      summaries: summaries,
      summaryMetadataMap: summaryMetadataMap,
      latestMetadata: latestMetadata,
      agentContext: agentContext,
    );

    // Add condition variable keywords
    if (conditions != null && conditionStates != null) {
      keywords.addAll(buildConditionKeywords(conditions, conditionStates, existingKeywords: keywords));
    }

    // Extra keywords (e.g. output_language resolved from app settings)
    if (extraKeywords != null) keywords.addAll(extraKeywords);

    final states = conditionStates ?? {};
    final buffer = StringBuffer();

    if (chatPrompt != null && chatPrompt.items.isNotEmpty) {
      for (final item in chatPrompt.items) {
        if (item.role != PromptRole.system || !isItemActive(item, states)) continue;

        final replaced = replaceKeywords(item.content, keywords);
        buffer.writeln(replaced);
        buffer.writeln();
      }
    }

    return buffer.toString().trim();
  }

  static List<Map<String, dynamic>> buildContents({
    required ChatPrompt? chatPrompt,
    required Character character,
    required String userMessage,
    required Map<PromptItem, List<ChatMessage>> chatHistoryMap,
    required String systemPrompt,
    Persona? persona,
    StartScenario? startScenario,
    List<CharacterBook>? activeCharacterBooks,
    int? maxInputTokens,
    TokenizerType? tokenizer,
    Map<int, ChatMessageMetadata>? metadataMap,
    ChatRoom? chatRoom,
    List<ChatSummary>? summaries,
    Map<int, ChatMessageMetadata>? summaryMetadataMap,
    ChatMessageMetadata? latestMetadata,
    List<PromptCondition>? conditions,
    Map<int, String>? conditionStates,
    String? agentContext,
    Map<String, String>? extraKeywords,
  }) {
    final keywords = buildKeywordMap(
      character: character,
      persona: persona,
      startScenario: startScenario,
      activeCharacterBooks: activeCharacterBooks,
      chatRoom: chatRoom,
      summaries: summaries,
      summaryMetadataMap: summaryMetadataMap,
      latestMetadata: latestMetadata,
      agentContext: agentContext,
    );

    // Add condition variable keywords
    if (conditions != null && conditionStates != null) {
      keywords.addAll(buildConditionKeywords(conditions, conditionStates, existingKeywords: keywords));
    }

    // Extra keywords (e.g. output_language resolved from app settings)
    if (extraKeywords != null) keywords.addAll(extraKeywords);

    final states = conditionStates ?? {};

    // 토큰 제한이 있으면 채팅 히스토리 조정
    final adjustedChatHistoryMap = _adjustChatHistoryForTokenLimit(
      chatPrompt: chatPrompt,
      chatHistoryMap: chatHistoryMap,
      systemPrompt: systemPrompt,
      userMessage: userMessage,
      keywords: keywords,
      maxInputTokens: maxInputTokens,
      tokenizer: tokenizer,
      conditionStates: states,
    );

    final contents = <Map<String, dynamic>>[];

    if (chatPrompt != null && chatPrompt.items.isNotEmpty) {
      for (final item in chatPrompt.items) {
        if (item.role == PromptRole.system || !isItemActive(item, states)) continue;

        if (item.role == PromptRole.chat) {
          final messages = adjustedChatHistoryMap[item] ?? [];
          for (final msg in messages) {
            var content = msg.content;
            if (metadataMap != null &&
                msg.role == MessageRole.assistant &&
                msg.id != null) {
              final metadata = metadataMap[msg.id!];
              if (metadata != null) {
                final tagString =
                    metadata.toTagString(worldStartDate: character.worldStartDate);
                if (tagString.isNotEmpty) {
                  content = '$content\n$tagString';
                }
              }
            }
            _addContent(contents, _chatMessageRole(msg), content);
          }
        } else {
          final role = item.role == PromptRole.user ? 'user' : 'model';
          final replaced = replaceKeywords(item.content, keywords);
          _addContent(contents, role, replaced);
        }
      }
    }

    // Attach `Start Date + start message` in front of the user's first message
    // on the very first send (no prior chat history after exclusions) so the
    // whole bundle — Start Date / start message / user input — arrives as a
    // single user turn.
    final hasChatHistory =
        adjustedChatHistoryMap.values.any((list) => list.isNotEmpty);
    var resolvedUserMessage = replaceKeywords(userMessage, keywords);
    if (!hasChatHistory &&
        startScenario?.startMessage != null &&
        startScenario!.startMessage!.isNotEmpty) {
      final resolvedStartMessage =
          replaceKeywords(startScenario.startMessage!, keywords);
      final bundle =
          _prefixStartDate(resolvedStartMessage, character.worldStartDate);
      resolvedUserMessage = '$bundle\n$resolvedUserMessage';
    }
    _addContent(contents, 'user', resolvedUserMessage);

    return contents;
  }

  /// 토큰 제한에 맞춰 채팅 히스토리 조정 (오래된 메시지부터 생략)
  static Map<PromptItem, List<ChatMessage>> _adjustChatHistoryForTokenLimit({
    required ChatPrompt? chatPrompt,
    required Map<PromptItem, List<ChatMessage>> chatHistoryMap,
    required String systemPrompt,
    required String userMessage,
    required Map<String, String> keywords,
    int? maxInputTokens,
    TokenizerType? tokenizer,
    Map<int, String> conditionStates = const {},
  }) {
    if (maxInputTokens == null || maxInputTokens <= 0) {
      return chatHistoryMap;
    }

    // 기본 토큰 계산 (시스템 프롬프트 + 사용자 메시지 + 프롬프트 항목들)
    int baseTokens = TokenCounter.estimateTokenCount(systemPrompt, tokenizer: tokenizer);
    baseTokens += TokenCounter.estimateTokenCount(userMessage, tokenizer: tokenizer);

    // 프롬프트 항목 중 chat이 아닌 것들의 토큰 계산
    if (chatPrompt != null) {
      for (final item in chatPrompt.items) {
        if (item.role == PromptRole.system || item.role == PromptRole.chat || !isItemActive(item, conditionStates)) continue;
        final replaced = replaceKeywords(item.content, keywords);
        baseTokens += TokenCounter.estimateTokenCount(replaced, tokenizer: tokenizer);
      }
    }

    // 채팅에 사용 가능한 토큰 수
    final availableTokens = maxInputTokens - baseTokens;
    if (availableTokens <= 0) {
      // 기본 프롬프트만으로도 토큰 초과 - 빈 채팅 히스토리 반환
      return chatHistoryMap.map((key, value) => MapEntry(key, <ChatMessage>[]));
    }

    // 모든 채팅 메시지를 시간순으로 정렬 (오래된 것 먼저)
    final allMessages = <ChatMessage>[];
    final messageToItem = <int, PromptItem>{};

    for (final entry in chatHistoryMap.entries) {
      for (final msg in entry.value) {
        if (msg.id != null && !allMessages.any((m) => m.id == msg.id)) {
          allMessages.add(msg);
          messageToItem[msg.id!] = entry.key;
        }
      }
    }

    allMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // 최신 메시지부터 포함하면서 토큰 계산
    final includedMessageIds = <int>{};
    int currentTokens = 0;

    for (int i = allMessages.length - 1; i >= 0; i--) {
      final msg = allMessages[i];
      final msgTokens = msg.tokenCount > 0
          ? msg.tokenCount
          : TokenCounter.estimateTokenCount(msg.content, tokenizer: tokenizer);

      if (currentTokens + msgTokens <= availableTokens) {
        currentTokens += msgTokens;
        if (msg.id != null) {
          includedMessageIds.add(msg.id!);
        }
      } else {
        // 토큰 초과 - 이 메시지와 더 오래된 메시지는 제외
        break;
      }
    }

    // 조정된 채팅 히스토리 맵 생성
    final adjustedMap = <PromptItem, List<ChatMessage>>{};
    for (final entry in chatHistoryMap.entries) {
      final filteredMessages = entry.value
          .where((msg) => msg.id != null && includedMessageIds.contains(msg.id))
          .toList();
      adjustedMap[entry.key] = filteredMessages;
    }

    return adjustedMap;
  }

  static void _addContent(
    List<Map<String, dynamic>> contents,
    String role,
    String text,
  ) {
    if (contents.isNotEmpty && contents.last['role'] == role) {
      final parts = contents.last['parts'] as List;
      final lastText = parts.last['text'] as String;
      parts.last = {'text': '$lastText\n$text'};
    } else {
      contents.add({
        'role': role,
        'parts': [
          {'text': text}
        ]
      });
    }
  }

  static String _chatMessageRole(ChatMessage msg) {
    return msg.role == MessageRole.user ? 'user' : 'model';
  }

  static Map<String, String> buildKeywordMap({
    required Character character,
    Persona? persona,
    StartScenario? startScenario,
    List<CharacterBook>? activeCharacterBooks,
    ChatRoom? chatRoom,
    List<ChatSummary>? summaries,
    Map<int, ChatMessageMetadata>? summaryMetadataMap,
    ChatMessageMetadata? latestMetadata,
    String? agentContext,
  }) {
    // Phase 1: identity keywords that other values may reference
    final baseKeywords = {
      'char': character.name,
      'user': persona?.name ?? '',
    };

    // Phase 2: build derived values, pre-applying base keywords
    String resolve(String text) {
      var result = text;
      for (final entry in baseKeywords.entries) {
        result = result.replaceAll('{{${entry.key}}}', entry.value);
      }
      return result;
    }

    return {
      ...baseKeywords,
      'char_description': resolve(character.description ?? ''),
      'user_description': resolve(persona?.content ?? ''),
      'character_book': resolve(_buildCharacterBookText(activeCharacterBooks)),
      'start_setting': _prefixStartDate(
        resolve(startScenario?.startSetting ?? ''),
        character.worldStartDate,
      ),
      'chat_memo': resolve(chatRoom?.memo ?? ''),
      'chat_historys': resolve(_buildChatHistorysText(
        summaries,
        summaryMetadataMap,
        character.worldStartDate,
      )),
      'agent_context': resolve(agentContext ?? ''),
      'world_date': _formatWorldDate(character, latestMetadata),
    };
  }

  static String _buildChatHistorysText(
    List<ChatSummary>? summaries,
    Map<int, ChatMessageMetadata>? summaryMetadataMap,
    DateTime? worldStartDate,
  ) {
    if (summaries == null || summaries.isEmpty) return '';

    final buffer = StringBuffer();
    for (int i = 0; i < summaries.length; i++) {
      final summary = summaries[i];
      final sceneNumber = i + 1;
      final metadata = summaryMetadataMap?[summary.endPinMessageId];

      if (metadata != null) {
        buffer.writeln(MetadataParser.buildSceneOpenTag(
          sceneNumber: sceneNumber,
          metadata: metadata,
          worldStartDate: worldStartDate,
        ));
      } else {
        buffer.writeln('<$sceneNumber>');
      }

      buffer.writeln(summary.summaryContent);
      buffer.writeln(MetadataParser.buildSceneCloseTag(sceneNumber));

      if (i < summaries.length - 1) {
        buffer.writeln();
      }
    }
    return buffer.toString().trim();
  }

  /// Prepends `Start Date : YYYY.MM.DD\n` to [body], using the character's
  /// configured world start date (or today when unset) so the AI always sees
  /// a concrete anchor date before the start setting / start message.
  static String _prefixStartDate(String body, DateTime? worldStartDate) {
    final dateStr = DateFormatter.canonicalMetadataDate(null, worldStartDate);
    final header = 'Start Date : $dateStr';
    return body.isEmpty ? header : '$header\n$body';
  }

  static String _formatWorldDate(
    Character character,
    ChatMessageMetadata? latestMetadata,
  ) {
    // Progressive world time from the latest chat metadata takes precedence
    // over the character's configured start date.
    final progressiveDate = DateFormatter.parseMetadataDateTime(
      latestMetadata?.date,
      latestMetadata?.time,
    );
    final date = progressiveDate ?? character.worldStartDate;
    if (date == null) return '';
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  static String _buildCharacterBookText(List<CharacterBook>? books) {
    if (books == null || books.isEmpty) return '';

    // Sort by insertionOrder so higher-priority entries appear first
    final sorted = [...books]
      ..sort((a, b) => a.insertionOrder.compareTo(b.insertionOrder));

    final buffer = StringBuffer();
    for (final book in sorted) {
      if (book.content != null && book.content!.isNotEmpty) {
        buffer.writeln('### ${book.name}');
        buffer.writeln(book.content);
      }
    }
    return buffer.toString().trim();
  }

  static String replaceKeywords(String text, Map<String, String> keywords) {
    var result = text;
    for (final entry in keywords.entries) {
      result = result.replaceAll('{{${entry.key}}}', entry.value);
    }
    return stripComments(result);
  }

  /// Strips /* ... */ block comments from text before sending to AI.
  static String stripComments(String text) {
    return text.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
  }

  /// Check if a prompt item is active based on its enableMode and condition states.
  /// [conditionStates] maps conditionId -> current value
  ///   - toggle: "true" or "false"
  ///   - singleSelect: selected option name
  static bool isItemActive(
    PromptItem item,
    Map<int, String> conditionStates,
  ) {
    switch (item.enableMode) {
      case EnableMode.enabled:
        return true;
      case EnableMode.disabled:
        return false;
      case EnableMode.conditional:
        if (item.conditionId == null || item.conditionValue == null) {
          return false;
        }
        final currentValue = conditionStates[item.conditionId!];
        if (currentValue == null) return false;
        return currentValue == item.conditionValue;
    }
  }

  /// Build variable substitution keywords from condition states.
  /// For conditions of type "variable", replaces {{variableName}} with
  /// the currently selected option value.
  /// [existingKeywords] is used to pre-resolve nested references
  /// (e.g. option value "{{user}}" is resolved to the actual user name).
  static Map<String, String> buildConditionKeywords(
    List<PromptCondition> conditions,
    Map<int, String> conditionStates, {
    Map<String, String> existingKeywords = const {},
  }) {
    final keywords = <String, String>{};
    for (final condition in conditions) {
      if (condition.type == ConditionType.variable &&
          condition.variableName != null &&
          condition.variableName!.isNotEmpty) {
        var value = conditionStates[condition.id!] ?? '';
        // Pre-resolve nested variable references (e.g. {{user}}, {{char}})
        for (final entry in existingKeywords.entries) {
          value = value.replaceAll('{{${entry.key}}}', entry.value);
        }
        keywords[condition.variableName!] = value;
      }
    }
    return keywords;
  }
}
