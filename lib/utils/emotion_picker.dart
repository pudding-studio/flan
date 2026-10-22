import 'dart:math';

/// RisuAI's emotion image selection, without any I/O.
class EmotionPicker {
  /// `<Emotion="name">`, the tag RisuAI's inline mode asks the reply for.
  static final RegExp inlineTag =
      RegExp(r'<Emotion="(.+?)">', caseSensitive: false);

  /// `{{emotion::name}}`, RisuAI's display form of an emotion image.
  static final RegExp cbsTag = RegExp(r'\{\{emotion::(.+?)\}\}');

  /// RisuAI's few-shot pair for the classifier.
  static const String exampleReply =
      '"Good morning, Master! Is there anything I can do for you today?"';
  static const String exampleEmotion = 'happy';

  /// The classifier request RisuAI sends: the instruction with the shuffled
  /// emotion list, one example, then the reply to classify. RisuAI also
  /// lowers the odds of the last five emotions with a logit bias, which
  /// Gemini does not support, so they are named in the instruction instead.
  static ({String systemPrompt, List<Map<String, dynamic>> contents})
      classifierRequest({
    required String instructions,
    required List<String> emotions,
    required String reply,
    List<String> recent = const [],
    Random? random,
  }) {
    final shuffled = [...emotions]..shuffle(random);
    final avoid = recent.toSet().where(emotions.contains).toList();
    final systemPrompt = StringBuffer(instructions)
      ..write('\n\n list: ${shuffled.join(', ')} \noutput only one word.');
    if (avoid.isNotEmpty) {
      systemPrompt.write(
          '\nRecently used: ${avoid.join(', ')}. Prefer another word when one fits as well.');
    }
    Map<String, dynamic> turn(String role, String text) => {
          'role': role,
          'parts': [
            {'text': text},
          ],
        };
    return (
      systemPrompt: systemPrompt.toString(),
      contents: [
        turn('user', exampleReply),
        turn('model', exampleEmotion),
        turn('user', reply),
      ],
    );
  }

  /// RisuAI's matching of the classifier output: an exact name, else the
  /// first name the output contains, else `neutral` when the character has
  /// it. Unlike RisuAI, names compare without regard to case, since RisuAI
  /// lowercases the output but not the names.
  static String? matchClassifierOutput(String output, List<String> emotions) {
    final word = output.replaceAll(RegExp(r'[ \n]'), '').trim().toLowerCase();
    if (word.isEmpty) return _neutral(emotions);
    for (final emotion in emotions) {
      if (emotion.toLowerCase() == word) return emotion;
    }
    for (final emotion in emotions) {
      if (emotion.isNotEmpty && word.contains(emotion.toLowerCase())) {
        return emotion;
      }
    }
    return _neutral(emotions);
  }

  static String? _neutral(List<String> emotions) {
    for (final emotion in emotions) {
      if (emotion.toLowerCase() == 'neutral') return emotion;
    }
    return null;
  }

  /// The inline-mode instruction with the emotion list in `{{slot}}`.
  static String inlineInstruction(String template, List<String> emotions) =>
      template.replaceAll('{{slot}}', emotions.join(', '));
}
