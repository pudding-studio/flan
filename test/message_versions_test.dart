// Regenerating an AI reply keeps the earlier ones selectable.

import 'dart:io';

import 'package:flan/database/database_helper.dart';
import 'package:flan/models/character/character.dart';
import 'package:flan/models/chat/chat_message.dart';
import 'package:flan/models/chat/chat_room.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

ChatMessageVersion _reply(String text) => ChatMessageVersion(
      content: text,
      tokenCount: text.length,
      createdAt: DateTime(2026, 1, 1),
      modelId: 'model-$text',
    );

void main() {
  final original = ChatMessage(
    id: 1,
    chatRoomId: 1,
    role: MessageRole.assistant,
    content: 'first',
    tokenCount: 5,
    emotion: 'happy',
  );

  test('a new reply keeps the earlier one and is selected', () {
    final second = original.withNewVersion(_reply('second'));
    expect(second.content, 'second');
    expect(second.emotion, isNull);
    expect(second.versionCount, 2);
    expect(second.versionIndex, 1);
    expect(second.versions.map((v) => v.content), ['first', 'second']);
    expect(second.versions.first.emotion, 'happy');
  });

  test('switching back restores the earlier reply with its details', () {
    final back = original
        .withNewVersion(_reply('second'))
        .withNewVersion(_reply('third'))
        .withVersionSelected(0);
    expect(back.content, 'first');
    expect(back.tokenCount, 5);
    expect(back.emotion, 'happy');
    expect(back.versionIndex, 0);
    expect(back.versionCount, 3);
  });

  test('edits and emotions of the shown reply survive a switch', () {
    final edited = original
        .withNewVersion(_reply('second'))
        .copyWith(content: 'second (edited)', emotion: 'sad')
        .withVersionSelected(0)
        .withVersionSelected(1);
    expect(edited.content, 'second (edited)');
    expect(edited.emotion, 'sad');
  });

  test('messages never regenerated have one version', () {
    expect(original.versionCount, 1);
    expect(original.withVersionSelected(3).content, 'first');
  });

  group('database', () {
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

    Future<void> checkRoundTrip() async {
      final characterId = await db.createCharacter(Character(name: 'c'));
      final roomId = await db.createChatRoom(
          ChatRoom(characterId: characterId, name: 'room'));
      final id = await db.createChatMessage(original.copyWith(chatRoomId: roomId));
      final stored = (await db.readChatMessage(id))!;
      await db.updateChatMessage(stored.withNewVersion(_reply('second')));

      final reread = (await db.readChatMessage(id))!;
      expect(reread.content, 'second');
      expect(reread.versionIndex, 1);
      expect(reread.versions.map((v) => v.content), ['first', 'second']);
      expect(reread.withVersionSelected(0).content, 'first');
    }

    test('fresh install stores reply versions', checkRoundTrip);

    test('upgrading from v59 adds the version columns', () async {
      final raw = await db.database;
      await raw.execute('ALTER TABLE chat_messages DROP COLUMN versions');
      await raw.execute('ALTER TABLE chat_messages DROP COLUMN version_index');
      await raw.setVersion(59);
      await db.closeDatabase();

      await checkRoundTrip();
    });
  });
}
