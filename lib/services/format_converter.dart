/// Converts the internal Gemini content format to OpenAI/Claude message formats.
///
/// Internal format (Gemini):
///   [{"role": "user"|"model", "parts": [{"text": "..."}]}]
///
/// OpenAI format:
///   [{"role": "user"|"assistant"|"system", "content": "..."}]
///
/// Claude format:
///   [{"role": "user"|"assistant", "content": "..."}]
class FormatConverter {
  static List<Map<String, dynamic>> toOpenAIMessages(
    String systemPrompt,
    List<Map<String, dynamic>> geminiContents,
  ) {
    final messages = <Map<String, dynamic>>[];

    if (systemPrompt.isNotEmpty) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }

    for (final content in geminiContents) {
      final role = _geminiRoleToOpenAI(content['role'] as String? ?? 'user');
      final text = _extractText(content);
      messages.add({'role': role, 'content': text});
    }

    return messages;
  }

  static ({String systemPrompt, List<Map<String, dynamic>> messages})
      toClaudeMessages(
    String systemPrompt,
    List<Map<String, dynamic>> geminiContents,
  ) {
    final messages = <Map<String, dynamic>>[];

    for (final content in geminiContents) {
      final role = _geminiRoleToOpenAI(content['role'] as String? ?? 'user');
      final text = _extractText(content);
      messages.add({'role': role, 'content': text});
    }

    return (systemPrompt: systemPrompt, messages: messages);
  }

  static String _geminiRoleToOpenAI(String geminiRole) {
    switch (geminiRole) {
      case 'model':
        return 'assistant';
      case 'user':
        return 'user';
      default:
        return geminiRole;
    }
  }

  static String _extractText(Map<String, dynamic> content) {
    final parts = content['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) return '';

    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is Map<String, dynamic> && part.containsKey('text')) {
        if (buffer.isNotEmpty) buffer.write('\n');
        buffer.write(part['text'] as String? ?? '');
      }
    }
    return buffer.toString();
  }
}
