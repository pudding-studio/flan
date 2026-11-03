// Users can fix typos in SNS posts/comments, diary entries and articles.

import 'dart:io';

import 'package:flan/database/database_helper.dart';
import 'package:flan/l10n/app_localizations.dart';
import 'package:flan/models/character/character.dart';
import 'package:flan/models/chat/chat_room.dart';
import 'package:flan/models/community/community_comment.dart';
import 'package:flan/models/community/community_post.dart';
import 'package:flan/models/diary/diary_entry.dart';
import 'package:flan/widgets/common/edit_text_entry_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group('edit sheet', () {
    Future<EditedTextEntry?> editWith(
      WidgetTester tester, {
      String? author,
      String? title,
      required String content,
      required Map<int, String> typed,
    }) async {
      EditedTextEntry? result;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await EditTextEntrySheet.show(
                context,
                heading: 'edit',
                author: author,
                title: title,
                content: content,
              );
            },
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      for (final entry in typed.entries) {
        await tester.enterText(find.byType(TextField).at(entry.key), entry.value);
      }
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('returns the fixed text; a cleared nickname or title stays',
        (tester) async {
      final result = await editWith(
        tester,
        author: 'Bo',
        title: 'Helo',
        content: 'teh text',
        typed: {0: '', 1: 'Hello', 2: 'the text'},
      );
      expect(result, (author: 'Bo', title: 'Hello', content: 'the text'));
    });

    testWidgets('shows only the given fields and needs content',
        (tester) async {
      final result =
          await editWith(tester, content: 'x', typed: {0: '   '});
      expect(find.byType(TextField), findsOneWidget);
      expect(result, isNull);
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

    test('updates only the text of posts, comments and diary entries',
        () async {
      final characterId = await db.createCharacter(Character(name: 'c'));
      final roomId = await db.createChatRoom(
          ChatRoom(characterId: characterId, name: 'room'));
      final time = DateTime(2030, 1, 1, 9);

      final postId = await db.createCommunityPost(CommunityPost(
          chatRoomId: roomId, author: 'a', title: 't', time: time, content: 'c'));
      final commentId = await db.createCommunityComment(CommunityComment(
          postId: postId, author: 'b', time: time, content: 'cc'));
      await db.updateCommunityPostText(postId,
          author: 'A', title: 'T', content: 'C');
      await db.updateCommunityCommentText(commentId, author: 'B', content: 'CC');

      final post = (await db.readCommunityPosts(roomId)).single;
      expect([post.author, post.title, post.content, post.time],
          ['A', 'T', 'C', time]);
      expect([post.comments.single.author, post.comments.single.content],
          ['B', 'CC']);

      final diaryId = await db.createDiaryEntry(DiaryEntry(
          chatRoomId: roomId,
          author: 'c',
          title: 'dt',
          content: 'dc',
          date: '2030.01.01'));
      await db.updateDiaryEntryText(diaryId, title: 'DT', content: 'DC');
      final diary =
          (await db.readDiaryEntriesByDate(roomId, '2030.01.01')).single;
      expect([diary.author, diary.title, diary.content], ['c', 'DT', 'DC']);
    });
  });
}
