// New community posts and comments must sort as the latest.

import 'package:flan/utils/community_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final latest = DateTime(2030, 5, 1, 12, 0);

  test('nextTime keeps the story time unless it is not newer', () {
    expect(CommunityParser.nextTime(DateTime(2030, 5, 2), latest),
        DateTime(2030, 5, 2));
    expect(CommunityParser.nextTime(DateTime(2030, 4, 1), latest),
        DateTime(2030, 5, 1, 12, 1));
    expect(CommunityParser.nextTime(latest, latest), DateTime(2030, 5, 1, 12, 1));
    expect(CommunityParser.nextTime(DateTime(2030, 4, 1), null),
        DateTime(2030, 4, 1));
  });

  test('generated posts older than the newest post move after it', () {
    final posts = CommunityParser.parse(
      "[Post]Auther:'a'|Title:'old'|Time:'203004011000'|Content:'x'\n"
      "[Comment]Auther:'b'|Time:'203003011000'|Content:'y'\n"
      "[Post]Auther:'c'|Title:'new'|Time:'203005021000'|Content:'z'",
      chatRoomId: 1,
      notBefore: latest,
    );
    expect(posts.map((p) => p.time),
        [DateTime(2030, 5, 1, 12, 1), DateTime(2030, 5, 2, 10, 0)]);
    expect(posts.first.comments.single.time, DateTime(2030, 5, 1, 12, 2));
  });

  test('missing times start from the newest post, not the real clock', () {
    final posts = CommunityParser.parse(
      "[Post]Auther:'a'|Title:'t'|Content:'x'",
      chatRoomId: 1,
      notBefore: latest,
    );
    expect(posts.single.time, DateTime(2030, 5, 1, 12, 1));
  });

  test('replies come after what they answer', () {
    final comments = CommunityParser.parseComments(
      "[Comment]Auther:'a'|Time:'203001011000'|Content:'x'\n"
      "[Comment]Auther:'b'|Content:'y'",
      postId: 1,
      notBefore: latest,
    );
    expect(comments.map((c) => c.time),
        [DateTime(2030, 5, 1, 12, 1), DateTime(2030, 5, 1, 12, 2)]);
  });
}
