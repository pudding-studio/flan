// Classic (non-agent) automatic summary, run the way the chat screen runs
// it after each reply.

import 'dart:io';

import 'package:flan/database/database_helper.dart';
import 'package:flan/models/character/character.dart';
import 'package:flan/models/chat/auto_summary_settings.dart';
import 'package:flan/models/chat/chat_message.dart';
import 'package:flan/models/chat/chat_message_metadata.dart';
import 'package:flan/models/chat/chat_room.dart';
import 'package:flan/models/chat/unified_model.dart';
import 'package:flan/models/prompt/prompt_parameters.dart';
import 'package:flan/services/ai_service.dart';
import 'package:flan/services/auto_summary_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeAi extends AiService {
  int calls = 0;

  @override
  Future<AiResponse> sendMessage({
    required String systemPrompt,
    required List<Map<String, dynamic>> contents,
    required UnifiedModel model,
    PromptParameters? promptParameters,
    int? chatRoomId,
    int? characterId,
    String logType = 'ai',
  }) async {
    calls++;
    return AiResponse(text: 'summary $calls');
  }
}

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

  test('each pin range is summarized at once and applied once it leaves '
      'the token window', () async {
    await db.createAutoSummarySettings(AutoSummarySettings(
      chatRoomId: 0,
      isAgentEnabled: false,
      tokenThreshold: 5000,
    ));
    final characterId = await db.createCharacter(Character(name: 'c'));
    final roomId = await db.createChatRoom(ChatRoom(
        characterId: characterId, name: 'room', autoPinByMessageCount: 10));
    final ai = _FakeAi();
    final service = AutoSummaryService(aiService: ai);

    final pins = <int>[];
    // Applied summaries (by end pin) right after each pin was created.
    final appliedAtPin = <int, List<int>>{};
    var time = DateTime(2026, 1, 1);
    for (var i = 1; i <= 60; i++) {
      time = time.add(const Duration(minutes: 1));
      final user = i.isOdd;
      final id = await db.createChatMessage(ChatMessage(
        chatRoomId: roomId,
        role: user ? MessageRole.user : MessageRole.assistant,
        content: 'm$i',
        tokenCount: user ? 100 : 900,
        createdAt: time,
      ));
      if (user) continue;
      // Like _saveMessageMetadata: a pin every 10 AI replies' metadata.
      final count = await db.countMetadataSinceLastPin(roomId);
      final pinCreated = count >= 10;
      await db.createChatMessageMetadata(ChatMessageMetadata(
        chatMessageId: id,
        chatRoomId: roomId,
        isPinned: pinCreated,
        createdAt: time,
      ));
      if (pinCreated) pins.add(id);
      await db.updateChatRoomTotalTokenCount(roomId);
      final room = (await db.readChatRoom(roomId))!;
      if (await service.shouldTriggerSummary(
        chatRoomId: roomId,
        currentTokenCount: room.totalTokenCount,
        pinCreated: pinCreated,
      )) {
        await service.generateAllPendingSummaries(chatRoomId: roomId);
      }
      if (pinCreated) {
        appliedAtPin[id] = [
          for (final s in await service.getAppliedSummaries(roomId))
            s.endPinMessageId,
        ];
      }
    }

    final summaries = await db.getChatSummaries(roomId);
    expect(pins, hasLength(2));
    // Summarized as soon as each pin closed its range.
    expect(summaries.map((s) => s.endPinMessageId), pins);
    expect(summaries.first.startPinMessageId, 0);
    expect(summaries.last.startPinMessageId, pins.first);
    expect(ai.calls, 2);
    // A fresh range is still inside the 5000-token window: not applied yet.
    expect(appliedAtPin[pins.first], isEmpty);
    expect(appliedAtPin[pins.last], [pins.first]);
    // By the end both ranges have left the window.
    expect(
      [for (final s in await service.getAppliedSummaries(roomId)) s.endPinMessageId],
      pins,
    );
    final excluded = await service.getSummarizedMessageIds(roomId);
    final messages = await db.readChatMessagesByChatRoom(roomId);
    expect(excluded, contains(messages.first.id));
    expect(excluded, isNot(contains(messages.last.id)));
  });
}
