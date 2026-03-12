import '../models/prompt/prompt_regex_rule.dart';

class RegexProcessor {
  /// Applies regex rules with the given [target] to [text] in order.
  /// Invalid patterns are skipped silently.
  /// Capture groups are referenced as $1, $2, ... in [replacement].
  static String apply(
    String text,
    List<PromptRegexRule> rules,
    RegexTarget target,
  ) {
    if (rules.isEmpty || text.isEmpty) return text;

    final applicable = rules
        .where((r) => r.target == target && r.pattern.isNotEmpty)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    if (applicable.isEmpty) return text;

    var result = text;
    for (final rule in applicable) {
      try {
        final regex = RegExp(rule.pattern, multiLine: true, dotAll: false);
        result = result.replaceAllMapped(regex, (match) {
          var replacement = rule.replacement;
          for (int i = 1; i <= match.groupCount; i++) {
            replacement = replacement.replaceAll('\$$i', match.group(i) ?? '');
          }
          return replacement;
        });
      } catch (_) {
        // Skip rules with invalid regex patterns
      }
    }
    return result;
  }

  /// Applies regex rules to every `text` field in the Gemini-format [contents] list.
  static List<Map<String, dynamic>> applyToContents(
    List<Map<String, dynamic>> contents,
    List<PromptRegexRule> rules,
    RegexTarget target,
  ) {
    if (rules.isEmpty) return contents;

    return contents.map((message) {
      final parts = message['parts'] as List<dynamic>?;
      if (parts == null) return message;

      final newParts = parts.map((part) {
        if (part is Map<String, dynamic>) {
          final text = part['text'];
          if (text is String) {
            return {'text': apply(text, rules, target)};
          }
        }
        return part;
      }).toList();

      return {...message, 'parts': newParts};
    }).toList();
  }
}
