// Outside agent summary mode, {{character_book}} carries the full details
// of character/location/event entries, even though their agent copies were
// seeded when the chat room was created.

import 'dart:convert';
import 'dart:io';

import 'package:flan/database/database_helper.dart';
import 'package:flan/models/character/character.dart';
import 'package:flan/models/character/character_book_folder.dart';
import 'package:flan/models/chat/auto_summary_settings.dart';
import 'package:flan/models/chat/chat_room.dart';
import 'package:flan/models/prompt/chat_prompt.dart';
import 'package:flan/models/prompt/prompt_item.dart';
import 'package:flan/services/agent_summary_service.dart';
import 'package:flan/services/chat_api_data_builder.dart';
import 'package:flan/providers/tokenizer_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  final db = DatabaseHelper.instance;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await databaseFactory.setDatabasesPath(
        Directory.systemTemp.createTempSync('flan_db_test').path);
  });

  tearDownAll(() async {
    await db.closeDatabase();
    await deleteDatabase(p.join(await getDatabasesPath(), 'flan.db'));
  });

  test('usesAgentMode needs auto summary switched on', () {
    expect(AutoSummarySettings(chatRoomId: 0).usesAgentMode, isTrue);
    expect(
        AutoSummarySettings(chatRoomId: 0, isEnabled: false).usesAgentMode,
        isFalse);
    expect(
        AutoSummarySettings(chatRoomId: 0, isAgentEnabled: false)
            .usesAgentMode,
        isFalse);
  });

  Future<String> systemPromptWith(AutoSummarySettings settings) async {
    final existing = await db.getAutoSummarySettings(0);
    if (existing == null) {
      await db.createAutoSummarySettings(settings);
    } else {
      await db.updateAutoSummarySettings(settings.copyWith(id: existing.id));
    }

    final characterId = await db.createCharacter(Character(name: 'c'));
    for (final (name, category, content) in [
      (
        'Alice',
        CharacterBookCategory.character,
        {'appearance': 'silver hair', 'personality': 'calm'}
      ),
      ('Harbor', CharacterBookCategory.location, {'setting': 'foggy docks'}),
      ('Festival', CharacterBookCategory.event, {'event_content': 'lanterns'}),
    ]) {
      await db.createCharacterBook(CharacterBook(
        characterId: characterId,
        name: name,
        order: 0,
        category: category,
        enabled: CharacterBookActivationCondition.enabled,
        content: jsonEncode(content),
      ));
    }

    final promptId = await db.createChatPrompt(ChatPrompt(name: 'p'));
    await db.createPromptItem(PromptItem(
      chatPromptId: promptId,
      role: PromptRole.system,
      content: '{{character_book}}',
    ));
    final room = ChatRoom(
      characterId: characterId,
      name: 'room',
      selectedChatPromptId: promptId,
    );
    final roomId = await db.createChatRoom(room);
    // Room creation always seeds the agent copies, whatever the mode.
    await AgentSummaryService()
        .seedFromCharacterBooks(chatRoomId: roomId, characterId: characterId);

    final data = await ChatApiDataBuilder().build(
      chatRoom: room.copyWith(id: roomId),
      character: (await db.readCharacter(characterId))!,
      chatRoomId: roomId,
      messages: const [],
      metadataMap: const {},
      userMessage: 'hello',
      outputLanguage: 'ko',
      tokenizer: TokenizerType.values.first,
      promptLoadFailedMessage: (id) => 'missing $id',
    );
    return data.systemPrompt;
  }

  for (final (label, settings) in [
    (
      'auto summary off',
      AutoSummarySettings(chatRoomId: 0, isEnabled: false)
    ),
    (
      'classic summary',
      AutoSummarySettings(chatRoomId: 0, isAgentEnabled: false)
    ),
  ]) {
    test('$label: lorebook section has every category with details',
        () async {
      final prompt = await systemPromptWith(settings);
      // The prompt is {{character_book}} alone, so every detail must come
      // from the lorebook section, not from an appended agent context.
      expect(prompt, isNot(contains('#### Characters')));
      for (final text in [
        '[Alice]\nAppearance: silver hair\nPersonality: calm',
        '[Harbor]\nFeatures: foggy docks',
        '[Festival]\nOverview: lanterns',
      ]) {
        expect(prompt, contains(text), reason: text);
      }
    });
  }
}
