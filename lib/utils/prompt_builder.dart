import '../models/character/character.dart';
import '../models/character/persona.dart';
import '../models/character/character_book_folder.dart';
import '../models/prompt/chat_prompt.dart';

class PromptBuilder {
  static String buildSystemPrompt({
    required ChatPrompt? chatPrompt,
    required Character character,
    Persona? persona,
    List<CharacterBook>? activeCharacterBooks,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('# 시스템 프롬프트');
    if (chatPrompt != null && chatPrompt.items.isNotEmpty) {
      for (final item in chatPrompt.items) {
        buffer.writeln('## ${item.role.displayName}');
        buffer.writeln(item.content);
        buffer.writeln();
      }
    } else {
      buffer.writeln('(채팅 프롬프트가 선택되지 않았습니다)');
    }
    buffer.writeln();

    if (persona != null && persona.content != null && persona.content!.isNotEmpty) {
      buffer.writeln('# ${persona.name}');
      buffer.writeln('## 내용:');
      buffer.writeln(persona.content);
      buffer.writeln();
    }

    buffer.writeln('# ${character.name}');

    if (character.description != null && character.description!.isNotEmpty) {
      buffer.writeln('## 세계관 설정:');
      buffer.writeln(character.description);
      buffer.writeln();
    }

    if (activeCharacterBooks != null && activeCharacterBooks.isNotEmpty) {
      buffer.writeln('## 로어북:');
      for (final characterBook in activeCharacterBooks) {
        if (characterBook.content != null && characterBook.content!.isNotEmpty) {
          buffer.writeln('### ${characterBook.name}');
          buffer.writeln(characterBook.content);
          buffer.writeln();
        }
      }
    }

    return buffer.toString().trim();
  }
}
