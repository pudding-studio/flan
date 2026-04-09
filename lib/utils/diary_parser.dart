import '../models/diary/diary_entry.dart';

class DiaryParser {
  /// Parses AI-generated text into diary entries.
  ///
  /// Expected format (one entry per line):
  ///   [Diary]Author:'...'|Title:'...'|Content:'...'
  static List<DiaryEntry> parse(String raw, {required int chatRoomId, required String date}) {
    final lines = raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty);
    final entries = <DiaryEntry>[];

    for (final line in lines) {
      if (!line.startsWith('[Diary]')) continue;
      final fields = _extractFields(line.substring('[Diary]'.length));
      entries.add(DiaryEntry(
        chatRoomId: chatRoomId,
        author: fields['Author'] ?? '익명',
        title: fields['Title'] ?? '(제목 없음)',
        content: fields['Content'] ?? '',
        date: date,
      ));
    }

    return entries;
  }

  static Map<String, String> _extractFields(String segment) {
    final result = <String, String>{};

    // Content is always last — extract it first to avoid splitting its value
    final contentKey = "|Content:'";
    final contentStart = segment.indexOf(contentKey);
    String remaining = segment;

    if (contentStart >= 0) {
      final raw = segment.substring(contentStart + contentKey.length);
      result['Content'] = raw.endsWith("'") ? raw.substring(0, raw.length - 1) : raw;
      remaining = segment.substring(0, contentStart);
    }

    // Parse remaining key:'value' pairs
    final pattern = RegExp(r"(\w+):'(.*?)'");
    for (final match in pattern.allMatches(remaining)) {
      result[match.group(1)!] = match.group(2)!;
    }

    return result;
  }
}
