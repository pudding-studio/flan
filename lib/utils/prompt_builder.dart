import '../models/character/character.dart';
import '../models/character/persona.dart';
import '../models/character/character_book_folder.dart';
import '../models/character/start_scenario.dart';
import '../models/chat/chat_message.dart';
import '../models/prompt/chat_prompt.dart';
import '../models/prompt/prompt_item.dart';

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

    final contents = <Map<String, dynamic>>[];

    if (chatPrompt != null && chatPrompt.items.isNotEmpty) {
      for (final item in chatPrompt.items) {
        if (item.role == PromptRole.system) continue;

        if (item.role == PromptRole.chat) {
          final messages = chatHistoryMap[item] ?? [];
          for (final msg in messages) {
            _addContent(contents, _chatMessageRole(msg), msg.content);
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
