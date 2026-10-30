// Agent summaries cover every pin range once, catching up missed ones.

import 'dart:io';

import 'package:flan/database/database_helper.dart';
import 'package:flan/models/character/character.dart';
import 'package:flan/models/chat/chat_message.dart';
import 'package:flan/models/chat/chat_message_metadata.dart';
import 'package:flan/models/chat/chat_room.dart';
import 'package:flan/services/agent_summary_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

({int metadataId, int messageId, bool agentSummarized}) _pin(
  int messageId, {
  bool done = false,
}) =>
    (metadataId: messageId * 10, messageId: messageId, agentSummarized: done);

void main() {
  final messages = [for (var i = 1; i <= 12; i++) i];

  group('planning', () {
    test('every uncovered range from the start, oldest first', () {
      final plan = planAgentSummaryRanges(
        messageIds: messages,
        pins: [_pin(4), _pin(8), _pin(12)],
        maxRanges: 5,
      );
      expect([for (final r in plan.ranges) r.messageIds], [
        [1, 2, 3, 4],
        [5, 6, 7, 8],
        [9, 10, 11, 12],
      ]);
      expect(plan.covered, isEmpty);
    });

    test('a missed range after the last covered pin is caught up', () {
      final plan = planAgentSummaryRanges(
        messageIds: messages,
        pins: [_pin(4, done: true), _pin(8), _pin(12)],
        maxRanges: 5,
      );
      expect([for (final r in plan.ranges) r.pinMessageId], [8, 12]);
      expect(plan.ranges.first.messageIds, [5, 6, 7, 8]);
    });

    test('a pin added inside covered history is only marked covered', () {
      final plan = planAgentSummaryRanges(
        messageIds: messages,
        pins: [_pin(4, done: true), _pin(6), _pin(8, done: true), _pin(12)],
        maxRanges: 5,
      );
      expect(plan.covered, [60]);
      expect([for (final r in plan.ranges) r.messageIds], [
        [9, 10, 11, 12],
      ]);
    });

    test('a long backlog is spread over runs', () {
      final plan = planAgentSummaryRanges(
        messageIds: messages,
        pins: [_pin(2), _pin(4), _pin(6), _pin(8)],
        maxRanges: 2,
      );
      expect([for (final r in plan.ranges) r.pinMessageId], [2, 4]);
    });

    test('pins of deleted messages are ignored', () {
      final plan = planAgentSummaryRanges(
        messageIds: messages,
        pins: [_pin(99), _pin(5)],
        maxRanges: 5,
      );
      expect([for (final r in plan.ranges) r.messageIds], [
        [1, 2, 3, 4, 5],
      ]);
    });
  });

  group('manual range', () {
    test('runs from the previous pin to the tapped pin', () {
      final range = agentSummaryRangeUpTo(
        messageIds: messages,
        pins: [_pin(4, done: true), _pin(8), _pin(12)],
        pinMessageId: 8,
      );
      expect(range?.messageIds, [5, 6, 7, 8]);
      expect(range?.pinMetadataId, 80);
    });

    test('runs from the start when there is no earlier pin', () {
      final range = agentSummaryRangeUpTo(
        messageIds: messages,
        pins: [_pin(6), _pin(12)],
        pinMessageId: 6,
      );
      expect(range?.messageIds, [1, 2, 3, 4, 5, 6]);
    });

    test('ignores later pins and needs the tapped message to be a pin', () {
      expect(
        agentSummaryRangeUpTo(
          messageIds: messages,
          pins: [_pin(10)],
          pinMessageId: 10,
        )?.messageIds.first,
        1,
      );
      expect(
        agentSummaryRangeUpTo(messageIds: messages, pins: [_pin(10)], pinMessageId: 5),
        isNull,
      );
    });
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

    Future<({int roomId, List<int> metadataIds})> roomWithPins() async {
      final characterId = await db.createCharacter(Character(name: 'c'));
      final roomId = await db.createChatRoom(
          ChatRoom(characterId: characterId, name: 'room'));
      final metadataIds = <int>[];
      for (var i = 0; i < 3; i++) {
        final messageId = await db.createChatMessage(ChatMessage(
          chatRoomId: roomId,
          role: MessageRole.assistant,
          content: 'm$i',
          createdAt: DateTime(2026, 1, 1, 0, i),
        ));
        metadataIds.add(await db.createChatMessageMetadata(ChatMessageMetadata(
          chatMessageId: messageId,
          chatRoomId: roomId,
          isPinned: i != 1,
        )));
      }
      return (roomId: roomId, metadataIds: metadataIds);
    }

    test('pins are tracked and marked in message order', () async {
      final room = await roomWithPins();
      var pins = await db.getAgentSummaryPins(room.roomId);
      expect(pins.map((p) => p.agentSummarized), [false, false]);

      await db.markPinsAgentSummarized([pins.first.metadataId]);
      pins = await db.getAgentSummaryPins(room.roomId);
      expect(pins.map((p) => p.agentSummarized), [true, false]);
    });

    test('upgrading from v60 counts existing pins as covered', () async {
      final room = await roomWithPins();
      final raw = await db.database;
      await raw.execute(
          'ALTER TABLE chat_message_metadata DROP COLUMN agent_summarized');
      await raw.setVersion(60);
      await db.closeDatabase();

      final pins = await db.getAgentSummaryPins(room.roomId);
      expect(pins.map((p) => p.agentSummarized), [true, true]);
    });
  });
}
