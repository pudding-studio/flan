import '../models/community/community_post.dart';
import '../models/community/community_comment.dart';

class CommunityParser {
  /// Parses AI-generated text into posts with attached comments.
  ///
  /// Expected format (one entry per line):
  ///   [Post]Auther:'...'|Title:'...'|Time:'YYYYMMDD'|Content:'...'
  ///   [Comment]Auther:'...'|Time:'YYYYMMDD'|Content:'...'
  ///
  /// Comments belong to the post immediately above them.
  /// If a time value cannot be parsed, it is set to latestTime + 1 minute.
  static List<CommunityPost> parse(String raw, {required int chatRoomId}) {
    final lines = raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty);

    final posts = <CommunityPost>[];
    DateTime latestTime = DateTime.now();

    for (final line in lines) {
      if (line.startsWith('[Post]')) {
        final fields = _extractFields(line.substring('[Post]'.length));
        final time = _parseTime(fields['Time']) ?? latestTime.add(const Duration(minutes: 1));
        latestTime = time;
        posts.add(CommunityPost(
          chatRoomId: chatRoomId,
          author: fields['Auther'] ?? '익명',
          title: fields['Title'] ?? '(제목 없음)',
          time: time,
          content: fields['Content'] ?? '',
        ));
      } else if (line.startsWith('[Comment]') && posts.isNotEmpty) {
        final fields = _extractFields(line.substring('[Comment]'.length));
        final time = _parseTime(fields['Time']) ?? latestTime.add(const Duration(minutes: 1));
        latestTime = time;
        posts.last.comments.add(CommunityComment(
          postId: 0, // filled after DB insert
          author: fields['Auther'] ?? '익명',
          time: time,
          content: fields['Content'] ?? '',
        ));
      }
    }

    return posts;
  }

  /// Parses AI-generated text that contains only [Comment] lines.
  static List<CommunityComment> parseComments(String raw, {required int postId}) {
    final lines = raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty);
    final comments = <CommunityComment>[];
    DateTime latestTime = DateTime.now();

    for (final line in lines) {
      if (!line.startsWith('[Comment]')) continue;
      final fields = _extractFields(line.substring('[Comment]'.length));
      final time = _parseTime(fields['Time']) ?? latestTime.add(const Duration(minutes: 1));
      latestTime = time;
      comments.add(CommunityComment(
        postId: postId,
        author: fields['Auther'] ?? '익명',
        time: time,
        content: fields['Content'] ?? '',
      ));
    }

    return comments;
  }

  static Map<String, String> _extractFields(String segment) {
    final result = <String, String>{};

    // Find all field start positions: Key:'
    final keyPattern = RegExp(r"(\w+):'");
    final keyMatches = keyPattern.allMatches(segment).toList();

    for (int i = 0; i < keyMatches.length; i++) {
      final key = keyMatches[i].group(1)!;
      final valueStart = keyMatches[i].end; // right after Key:'

      // Value ends at the next field boundary (|Key:') or end of segment
      String value;
      if (i + 1 < keyMatches.length) {
        final nextFieldStart = keyMatches[i + 1].start;
        final endPos = nextFieldStart > 0 && segment[nextFieldStart - 1] == '|'
            ? nextFieldStart - 1
            : nextFieldStart;
        value = segment.substring(valueStart, endPos);
      } else {
        value = segment.substring(valueStart);
      }

      // Strip trailing quote
      if (value.endsWith("'")) {
        value = value.substring(0, value.length - 1);
      }

      result[key] = value;
    }

    return result;
  }

  static DateTime? _parseTime(String? value) {
    if (value == null || (value.length != 8 && value.length != 12)) return null;
    final year = int.tryParse(value.substring(0, 4));
    final month = int.tryParse(value.substring(4, 6));
    final day = int.tryParse(value.substring(6, 8));
    if (year == null || month == null || day == null) return null;

    int hour = 0;
    int minute = 0;
    if (value.length == 12) {
      hour = int.tryParse(value.substring(8, 10)) ?? 0;
      minute = int.tryParse(value.substring(10, 12)) ?? 0;
    }

    try {
      return DateTime(year, month, day, hour, minute);
    } catch (_) {
      return null;
    }
  }
}
