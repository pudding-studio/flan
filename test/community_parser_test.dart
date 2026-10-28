// SNS entry times are the AI's call; the app only fills in missing ones.

import 'package:flan/utils/community_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final storyNow = DateTime(2030, 5, 1, 12, 0);

  test('nextTime keeps the story time unless it is not newer', () {
    expect(CommunityParser.nextTime(DateTime(2030, 5, 2), storyNow),
        DateTime(2030, 5, 2));
    expect(CommunityParser.nextTime(DateTime(2030, 4, 1), storyNow),
        DateTime(2030, 5, 1, 12, 1));
    expect(CommunityParser.nextTime(DateTime(2030, 4, 1), null),
        DateTime(2030, 4, 1));
  });

  test('generated posts and comments keep the times the AI chose', () {
    final posts = CommunityParser.parse(
      "[Post]Auther:'a'|Title:'earlier'|Time:'203004011000'|Content:'x'\n"
      "[Comment]Auther:'b'|Time:'203003011000'|Content:'y'\n"
      "[Post]Auther:'c'|Title:'later'|Time:'203005021000'|Content:'z'",
      chatRoomId: 1,
      fallbackStart: storyNow,
    );
    expect(posts.map((p) => p.time),
        [DateTime(2030, 4, 1, 10), DateTime(2030, 5, 2, 10)]);
    expect(posts.first.comments.single.time, DateTime(2030, 3, 1, 10));
  });

  test('missing times continue from the story time, not the real clock', () {
    final posts = CommunityParser.parse(
      "[Post]Auther:'a'|Title:'t'|Content:'x'\n"
      "[Comment]Auther:'b'|Content:'y'",
      chatRoomId: 1,
      fallbackStart: storyNow,
    );
    expect(posts.single.time, DateTime(2030, 5, 1, 12, 1));
    expect(posts.single.comments.single.time, DateTime(2030, 5, 1, 12, 2));
  });

  test('replies keep their times; missing ones follow the fallback', () {
    final comments = CommunityParser.parseComments(
      "[Comment]Auther:'a'|Time:'203001011000'|Content:'x'\n"
      "[Comment]Auther:'b'|Content:'y'",
      postId: 1,
      fallbackStart: storyNow,
    );
    expect(comments.map((c) => c.time),
        [DateTime(2030, 1, 1, 10), DateTime(2030, 1, 1, 10, 1)]);
  });

  test('reads the nickname the AI chose for a blank author', () {
    const raw = "[Author]Name:'night owl'\n"
        "[Comment]Auther:'a'|Time:'203001011000'|Content:'hi'";
    expect(CommunityParser.parseChosenAuthor(raw), 'night owl');
    expect(
      CommunityParser.parseComments(raw, postId: 1).map((c) => c.content),
      ['hi'],
    );
    expect(CommunityParser.parseChosenAuthor("[Author]Name:''"), isNull);
    expect(CommunityParser.parseChosenAuthor("[Comment]Auther:'a'"), isNull);
  });
}
