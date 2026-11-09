import '../models/character/character_book_folder.dart';
import '../models/chat/agent_entry.dart';

/// How many of the latest chat messages (plus the new one) are scanned for
/// the keywords of key-based lorebook entries.
const int characterBookScanDepth = 4;

/// The lorebook entries that apply to this turn: every enabled entry, plus
/// key-based entries whose keyword appears in [recentTexts] (case
/// insensitive). With secondary keys switched on, a key-based entry also
/// needs one of its secondary keys to appear.
List<CharacterBook> selectActiveCharacterBooks(
  List<CharacterBook> books,
  Iterable<String> recentTexts,
) {
  final haystack = recentTexts.join('\n').toLowerCase();
  bool mentions(List<String> keys) => keys.any((key) {
        final k = key.trim().toLowerCase();
        return k.isNotEmpty && haystack.contains(k);
      });
  return [
    for (final book in books)
      if (book.enabled == CharacterBookActivationCondition.enabled ||
          (book.enabled == CharacterBookActivationCondition.keyBased &&
              mentions(book.keys) &&
              (book.secondaryKeyUsage != CharacterBookSecondaryKeyUsage.enabled ||
                  book.secondaryKeys.isEmpty ||
                  mentions(book.secondaryKeys))))
        book,
  ];
}

/// The entry's details in the same form the agent summary shows them, or an
/// empty string when it has none beyond its name.
String characterBookDetails(CharacterBook book) {
  final data = characterBookAgentData(book);
  if (data.isEmpty) return '';
  return AgentEntry(
    chatRoomId: 0,
    entryType: characterBookAgentType(book.category),
    name: book.name,
    data: data,
  ).toReadableText().trim();
}

/// The agent entry type for a lorebook category (other → item).
AgentEntryType characterBookAgentType(CharacterBookCategory category) {
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
Map<String, dynamic> characterBookAgentData(CharacterBook book) {
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

