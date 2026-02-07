import '../models/character/character.dart';
import '../models/character/persona.dart';
import '../models/character/character_book_folder.dart';
import '../models/character/start_scenario.dart';
import '../models/chat/chat_message.dart';
import '../models/chat/chat_message_metadata.dart';
import '../models/prompt/chat_prompt.dart';
import '../models/prompt/prompt_item.dart';
import '../providers/tokenizer_provider.dart';
import 'token_counter.dart';

class PromptBuilder {
  static String buildSystemPrompt({
    required ChatPrompt? chatPrompt,
    required Character character,
    Persona? persona,
    StartScenario? startScenario,
    List<CharacterBook>? activeCharacterBooks,
  }) {
    final keywords = _buildKeywordMap(
      character: character,
      persona: persona,
      startScenario: startScenario,
      activeCharacterBooks: activeCharacterBooks,
    );

    final buffer = StringBuffer();

    if (chatPrompt != null && chatPrompt.items.isNotEmpty) {
      for (final item in chatPrompt.items) {
        if (item.role != PromptRole.system) continue;

        final replaced = replaceKeywords(item.content, keywords);
        buffer.writeln('## ${item.name ?? item.role.displayName}');
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
    ChatMessageMetadata? lastMetadata,
  }) {
    final keywords = _buildKeywordMap(
      character: character,
      persona: persona,
      startScenario: startScenario,
      activeCharacterBooks: activeCharacterBooks,
    );

    // 토큰 제한이 있으면 채팅 히스토리 조정
    final adjustedChatHistoryMap = _adjustChatHistoryForTokenLimit(
      chatPrompt: chatPrompt,
      chatHistoryMap: chatHistoryMap,
      systemPrompt: systemPrompt,
      userMessage: userMessage,
      keywords: keywords,
      maxInputTokens: maxInputTokens,
      tokenizer: tokenizer,
    );

    // 마지막 assistant 메시지 ID를 찾기 위해 전체 chat 메시지를 수집
    ChatMessage? lastAssistantMessage;
    if (lastMetadata != null) {
      for (final messages in adjustedChatHistoryMap.values) {
        for (final msg in messages) {
          if (msg.role == MessageRole.assistant) {
            lastAssistantMessage = msg;
          }
        }
      }
    }

    final contents = <Map<String, dynamic>>[];

    if (chatPrompt != null && chatPrompt.items.isNotEmpty) {
      for (final item in chatPrompt.items) {
        if (item.role == PromptRole.system) continue;

        if (item.role == PromptRole.chat) {
          final messages = adjustedChatHistoryMap[item] ?? [];
          for (final msg in messages) {
            var content = msg.content;
            if (lastAssistantMessage != null && msg.id == lastAssistantMessage.id) {
              content = '$content\n${lastMetadata!.toTagString()}';
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

    _addContent(contents, 'user', userMessage);

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
        if (item.role == PromptRole.system || item.role == PromptRole.chat) continue;
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

  static Map<String, String> _buildKeywordMap({
    required Character character,
    Persona? persona,
    StartScenario? startScenario,
    List<CharacterBook>? activeCharacterBooks,
  }) {
    return {
      'char': character.name,
      'char_description': character.description ?? '',
      'user': persona?.name ?? '',
      'user_description': persona?.content ?? '',
      'character_book': _buildCharacterBookText(activeCharacterBooks),
      'start_setting': startScenario?.startSetting ?? '',
      'start_message': startScenario?.startMessage ?? '',
    };
  }

  static String _buildCharacterBookText(List<CharacterBook>? books) {
    if (books == null || books.isEmpty) return '';

    final buffer = StringBuffer();
    for (final book in books) {
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
    return result;
  }
}
