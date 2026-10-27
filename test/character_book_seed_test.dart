// New chat rooms seed the summary from the character's lorebook entries,
// skipping the ones switched off.

import 'dart:io';

import 'package:flan/database/database_helper.dart';
import 'package:flan/models/character/character.dart';
import 'package:flan/models/character/character_book_folder.dart';
import 'package:flan/models/chat/chat_room.dart';
import 'package:flan/services/agent_summary_service.dart';
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

  test('disabled lorebook entries are not added to the summary', () async {
    final characterId = await db.createCharacter(Character(name: 'c'));
    Future<void> book(
      String name,
      CharacterBookActivationCondition enabled, {
      bool autoSummaryInsert = true,
    }) =>
        db.createCharacterBook(CharacterBook(
          characterId: characterId,
          name: name,
          order: 0,
          enabled: enabled,
          content: '$name content',
          autoSummaryInsert: autoSummaryInsert,
        ));
    await book('always', CharacterBookActivationCondition.enabled);
    await book('by key', CharacterBookActivationCondition.keyBased);
    await book('off', CharacterBookActivationCondition.disabled);
    await book('opted out', CharacterBookActivationCondition.enabled,
        autoSummaryInsert: false);

    final roomId = await db.createChatRoom(
        ChatRoom(characterId: characterId, name: 'room'));
    await AgentSummaryService()
        .seedFromCharacterBooks(chatRoomId: roomId, characterId: characterId);

    final entries = await db.getAgentEntries(roomId);
    expect(entries.map((e) => e.name).toSet(), {'always', 'by key'});
  });
}
