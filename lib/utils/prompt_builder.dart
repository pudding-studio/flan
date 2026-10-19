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
import 'cbs/cbs_context.dart';
import 'cbs/cbs_parser.dart';
import 'context_pdf.dart';
import 'date_formatter.dart';
import 'metadata_parser.dart';
import 'token_counter.dart';

class PromptBuilder {
  static String buildSystemPrompt({
    CbsContext? cbsContext,
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

        final replaced = replaceKeywords(item.content, keywords,
            context: cbsContext, role: 'system');
        // Like RisuAI, a block that renders to nothing is not sent.
        if (replaced.trim().isEmpty) continue;
        buffer.writeln(replaced);
        buffer.writeln();
      }
    }

    return buffer.toString().trim();
  }

  static List<Map<String, dynamic>> buildContents({
    CbsContext? cbsContext,
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
    // When given, chat history is collected here instead of being emitted as
    // turns, and a single PDF placeholder takes the first history slot. All
    // chat items share that slot, so items placed between two chat items end
    // up after the whole history.
    List<ContextPdfEntry>? pdfHistorySink,
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
      cbsContext: cbsContext,
      chatPrompt: chatPrompt,
      chatHistoryMap: chatHistoryMap,
      systemPrompt: systemPrompt,
      userMessage: userMessage,
      keywords: keywords,
      maxInputTokens: maxInputTokens,
      tokenizer: tokenizer,
      conditionStates: states,
    );

    // Attach `Start Date + start message` in front of the user's first message
    // on the very first send (no prior chat history after exclusions) so the
    // whole bundle — Start Date / start message / user input — arrives as a
    // single user turn.
    final hasChatHistory =
        adjustedChatHistoryMap.values.any((list) => list.isNotEmpty);
    var resolvedUserMessage = replaceKeywords(userMessage, keywords,
        context: cbsContext, role: 'user');
    if (!hasChatHistory &&
        startScenario?.startMessage != null &&
        startScenario!.startMessage!.isNotEmpty) {
      final resolvedStartMessage =
          replaceKeywords(startScenario.startMessage!, keywords,
              context: cbsContext, role: 'char');
      final bundle =
          _prefixStartDate(resolvedStartMessage, character.worldStartDate);
      resolvedUserMessage = '$bundle\n$resolvedUserMessage';
    }

    final settings = chatPrompt?.parameters;
    final historyFormat = _HistoryFormat(
      sendName: settings?.sendName == true,
      sendChatAsSystem: settings?.sendChatAsSystem == true,
    );
    // RisuAI keeps the new message inside the chat history, so prompt items
    // placed after the history follow it.
    PromptItem? userMessageAnchor;
    if (settings?.userMessageInChatHistory == true && chatPrompt != null) {
      for (final item in chatPrompt.items) {
        if (item.role == PromptRole.chat && isItemActive(item, states)) {
          userMessageAnchor = item;
        }
      }
    }
    final contents = <Map<String, dynamic>>[];
    var userMessageAdded = false;
    void addUserMessage() {
      final turn = historyFormat.apply(
        role: 'user',
        speaker: _userName(persona),
        text: resolvedUserMessage,
      );
      _addContent(contents, turn.role, turn.text);
      userMessageAdded = true;
    }

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
            if (pdfHistorySink != null) {
              if (pdfHistorySink.isEmpty) {
                _addPart(contents, 'user', ContextPdf.placeholderPart());
              }
              pdfHistorySink.add(ContextPdfEntry(
                _speakerName(msg, character, persona),
                content,
              ));
              continue;
            }
            final turn = historyFormat.apply(
              role: _chatMessageRole(msg),
              speaker: _speakerName(msg, character, persona),
              text: content,
            );
            _addContent(contents, turn.role, turn.text);
          }
          if (identical(item, userMessageAnchor)) addUserMessage();
        } else {
          final role = item.role == PromptRole.user ? 'user' : 'model';
          final replaced = replaceKeywords(item.content, keywords,
              context: cbsContext, role: role == 'user' ? 'user' : 'char');
          if (replaced.trim().isEmpty) continue;
          _addContent(contents, role, replaced);
        }
      }
    }

    if (!userMessageAdded) addUserMessage();

    return contents;
  }

  /// 토큰 제한에 맞춰 채팅 히스토리 조정 (오래된 메시지부터 생략)
  static Map<PromptItem, List<ChatMessage>> _adjustChatHistoryForTokenLimit({
    CbsContext? cbsContext,
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
        final replaced =
            replaceKeywords(item.content, keywords, context: cbsContext);
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
      final lastText = parts.last['text'];
      if (lastText is String) {
        parts.last = {'text': '$lastText\n$text'};
      } else {
        // The previous part is not text (the context PDF placeholder).
        parts.add({'text': text});
      }
    } else {
      contents.add({
        'role': role,
        'parts': <Map<String, dynamic>>[
          {'text': text}
        ]
      });
    }
  }

  static void _addPart(
    List<Map<String, dynamic>> contents,
    String role,
    Map<String, dynamic> part,
  ) {
    if (contents.isNotEmpty && contents.last['role'] == role) {
      (contents.last['parts'] as List).add(part);
    } else {
      contents.add({
        'role': role,
        'parts': <Map<String, dynamic>>[part],
      });
    }
  }

  static String _chatMessageRole(ChatMessage msg) {
    return msg.role == MessageRole.user ? 'user' : 'model';
  }

  static String _speakerName(
    ChatMessage msg,
    Character character,
    Persona? persona,
  ) {
    if (msg.role != MessageRole.user) return character.name;
    return _userName(persona);
  }

  static String _userName(Persona? persona) {
    final name = persona?.name ?? '';
    return name.isEmpty ? 'User' : name;
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

  /// Produces the `{{character_book}}` template body. Active entries are grouped
  /// by [CharacterBookCategory] and rendered as `이름|한줄설명` lines, with
  /// `### <category>` headers. Entries whose one-line description is empty are
  /// emitted as `이름` (no pipe). Within each category entries are ordered by
  /// `insertionOrder` so higher-priority lines surface first.
  ///
  /// Categories are emitted in a fixed order: 등장인물 → 지역/장소 → 역사/사건 → 기타,
  /// matching the redesigned 설정집 UI.
  static String _buildCharacterBookText(List<CharacterBook>? books) {
    if (books == null || books.isEmpty) return '';

    final grouped = <CharacterBookCategory, List<CharacterBook>>{
      for (final c in CharacterBookCategory.values) c: <CharacterBook>[],
    };
    for (final book in books) {
      grouped[book.category]!.add(book);
    }

    final buffer = StringBuffer();
    for (final category in CharacterBookCategory.values) {
      final entries = grouped[category]!;
      if (entries.isEmpty) continue;

      entries.sort((a, b) => a.insertionOrder.compareTo(b.insertionOrder));

      buffer.writeln('### ${category.promptHeader}');
      for (final book in entries) {
        final desc = book.oneLineDescription.trim();
        if (desc.isEmpty) {
          buffer.writeln(book.name);
        } else {
          buffer.writeln('${book.name}|$desc');
        }
      }
      buffer.writeln();
    }
    return buffer.toString().trim();
  }

  // Legacy flat replacement, superseded by the RisuAI-compatible CBS engine
  // below. Kept for reference while the engine settles in.
  //
  // static String replaceKeywords(String text, Map<String, String> keywords) {
  //   var result = text;
  //   for (final entry in keywords.entries) {
  //     result = result.replaceAll('{{${entry.key}}}', entry.value);
  //   }
  //   return stripComments(result);
  // }

  /// Renders [text] with the RisuAI-compatible CBS engine.
  ///
  /// [keywords] keep the meaning they had under the old flat replacement: an
  /// exact `{{name}}` match wins over any CBS function. Variable writes
  /// (`setvar`, `addvar`, ...) are stripped without running, because
  /// assembling a prompt must not change chat state; regenerating would
  /// apply them twice. Without a [context], chat-level CBS functions see an
  /// empty chat.
  static String replaceKeywords(
    String text,
    Map<String, String> keywords, {
    CbsContext? context,
    String? role,
  }) {
    final base = context ??
        CbsContext(
          charName: keywords['char'] ?? '',
          userName: keywords['user'] ?? '',
        );
    final rendered = CbsParser.render(
      text,
      CbsRun(base.withKeywords(keywords), rmVar: true, role: role),
    );
    return stripComments(cbsUnescape(rendered));
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

/// How chat history turns are sent, following RisuAI's preset settings.
class _HistoryFormat {
  final bool sendName;
  final bool sendChatAsSystem;

  const _HistoryFormat({required this.sendName, required this.sendChatAsSystem});

  /// [role] is 'user' or 'model'. RisuAI's `sendName` wraps each turn in
  /// its default group template and sends it as a user turn;
  /// `sendChatAsSystem` turns it into a system message labelled with its
  /// role, which RisuAI sends mid-conversation as a `system: ` user turn.
  ({String role, String text}) apply({
    required String role,
    required String speaker,
    required String text,
  }) {
    var turnRole = role;
    var turnText = text;
    if (sendName) {
      turnText = "<$speaker's Message>\n$turnText\n</$speaker's Message>";
      turnRole = 'user';
    }
    if (sendChatAsSystem) {
      turnText =
          'system: ${turnRole == 'user' ? 'user' : 'assistant'}: $turnText';
      turnRole = 'user';
    }
    return (role: turnRole, text: turnText);
  }
}
