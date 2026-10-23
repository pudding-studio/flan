// The SNS feed lists posts by when they were posted, while each post keeps
// the story time it was written at.

import 'dart:io';

import 'package:flan/database/database_helper.dart';
import 'package:flan/models/community/community_post.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  final db = DatabaseHelper.instance;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // Test files run in parallel; each needs its own flan.db.
    await databaseFactory.setDatabasesPath(
        Directory.systemTemp.createTempSync('flan_db_test').path);
  });

  tearDownAll(() async {
    await db.closeDatabase();
    await deleteDatabase(p.join(await getDatabasesPath(), 'flan.db'));
  });

  test('a new post at an earlier story time still comes first', () async {
    CommunityPost post(String title, DateTime storyTime, DateTime postedAt) =>
        CommunityPost(
          chatRoomId: 1,
          author: 'a',
          title: title,
          time: storyTime,
          content: '',
          createdAt: postedAt,
        );

    // An old post saved with the real clock, far after the story's time.
    await db.createCommunityPost(
        post('old', DateTime(2026, 10, 23), DateTime(2026, 10, 23, 9)));
    await db.createCommunityPost(
        post('new', DateTime(2024, 3, 1, 14), DateTime(2026, 10, 23, 10)));

    final posts = await db.readCommunityPosts(1);
    expect(posts.map((p) => p.title), ['new', 'old']);
    expect(posts.first.time, DateTime(2024, 3, 1, 14));
  });
}
