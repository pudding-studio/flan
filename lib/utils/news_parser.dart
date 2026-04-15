import '../models/news/news_article.dart';

class NewsParser {
  /// Parses AI-generated text into news articles.
  ///
  /// Expected format (one entry per line):
  ///   [Article]Topic:'...'|Tone:'...'|Author:'...'|Title:'...'|Time:'YYYYMMDDHHmm'|Content:'...'
  ///
  /// If a time value cannot be parsed, it is set to latestTime + 1 minute.
  static List<NewsArticle> parse(
    String raw, {
    required int chatRoomId,
    int? agentEntryId,
  }) {
    final lines = raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty);

    final articles = <NewsArticle>[];
    DateTime latestTime = DateTime.now();

    for (final line in lines) {
      if (!line.startsWith('[Article]')) continue;
      final fields = _extractFields(line.substring('[Article]'.length));
      final time = _parseTime(fields['Time']) ?? latestTime.add(const Duration(minutes: 1));
      latestTime = time;
      articles.add(NewsArticle(
        chatRoomId: chatRoomId,
        topic: fields['Topic'] ?? 'society',
        tone: fields['Tone'] ?? 'neutral',
        author: fields['Author'] ?? fields['Auther'] ?? 'reporter',
        title: fields['Title'] ?? '(No title)',
        time: time,
        content: fields['Content'] ?? '',
        agentEntryId: agentEntryId,
      ));
    }

    return articles;
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
        // End before the | that precedes the next key
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
