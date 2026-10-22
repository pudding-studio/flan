// Database v59: emotion settings per character, emotion per message.

import 'package:flan/database/database_helper.dart';
import 'package:flan/models/character/character.dart';
import 'package:flan/models/character/cover_image.dart';
import 'package:flan/models/character/emotion_mode.dart';
import 'package:flan/models/chat/chat_message.dart';
import 'package:flan/models/chat/chat_room.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  final db = DatabaseHelper.instance;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await deleteDatabase(p.join(await getDatabasesPath(), 'flan.db'));
  });

  tearDownAll(() async {
    await db.closeDatabase();
    await deleteDatabase(p.join(await getDatabasesPath(), 'flan.db'));
  });

  Future<void> checkRoundTrip() async {
    final characterId = await db.createCharacter(Character(
      name: 'Risu',
      emotionMode: EmotionMode.inline,
      emotionInstructions: 'Pick one: {{slot}}',
    ));
    final character = await db.readCharacter(characterId);
    expect(character?.emotionMode, EmotionMode.inline);
    expect(character?.emotionInstructions, 'Pick one: {{slot}}');

    await db.createCoverImage(CoverImage(
      characterId: characterId,
      name: 'happy',
      order: 0,
      path: '/tmp/happy.png',
      imageType: 'emotion',
    ));
    expect((await db.readEmotionImages(characterId)).map((i) => i.name),
        ['happy']);
    expect(await db.readAdditionalImages(characterId), isEmpty);

    final roomId = await db.createChatRoom(
        ChatRoom(characterId: characterId, name: 'room'));
    final messageId = await db.createChatMessage(ChatMessage(
      chatRoomId: roomId,
      role: MessageRole.assistant,
      content: 'Hello',
    ));
    await db.updateChatMessageEmotion(messageId, 'happy');
    final messages = await db.readChatMessagesByChatRoom(roomId);
    expect(messages.single.emotion, 'happy');
  }

  test('fresh install stores emotion settings and picks', checkRoundTrip);

  test('upgrading from v58 adds the emotion columns', () async {
    final raw = await db.database;
    await raw.execute('ALTER TABLE characters DROP COLUMN emotion_mode');
    await raw.execute('ALTER TABLE characters DROP COLUMN emotion_instructions');
    await raw.execute('ALTER TABLE chat_messages DROP COLUMN emotion');
    await raw.setVersion(58);
    await db.closeDatabase();

    await checkRoundTrip();
  });
}
