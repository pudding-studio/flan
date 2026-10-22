import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/character/character.dart';
import '../models/character/emotion_mode.dart';
import '../models/chat/chat_message.dart';
import '../models/chat/unified_model.dart';
import '../utils/emotion_picker.dart';
import '../utils/metadata_parser.dart';
import 'ai_service.dart';

/// Picks the emotion image for an AI reply in [EmotionMode.classifier]
/// mode, the way RisuAI does after each reply.
class EmotionService {
  /// RisuAI remembers this many recent emotions per character.
  static const int recentLimit = 5;

  final DatabaseHelper db;
  final AiService aiService;

  EmotionService({DatabaseHelper? db, AiService? aiService})
      : db = db ?? DatabaseHelper.instance,
        aiService = aiService ?? AiService();

  /// Classifies [reply], stores the result on message [messageId] and
  /// returns it. Returns null without a request when the character does not
  /// use the classifier or has no emotion images; failures are logged and
  /// also return null, since the emotion must never block the reply.
  Future<String?> pickForReply({
    required Character character,
    required int messageId,
    required String reply,
    required List<ChatMessage> history,
    required UnifiedModel model,
  }) async {
    if (character.emotionMode != EmotionMode.classifier) return null;
    try {
      final emotions = (await db.readEmotionImages(character.id!))
          .map((image) => image.name)
          .where((name) => name.isNotEmpty)
          .toList();
      if (emotions.isEmpty) return null;

      final request = EmotionPicker.classifierRequest(
        instructions: character.emotionInstructions ??
            EmotionMode.classifier.defaultInstructions,
        emotions: emotions,
        reply: MetadataParser.removeMetadataTags(reply),
        recent: _recentEmotions(history),
      );
      final response = await aiService.sendMessage(
        systemPrompt: request.systemPrompt,
        contents: request.contents,
        model: model,
        characterId: character.id,
        logType: 'emotion',
      );
      final emotion =
          EmotionPicker.matchClassifierOutput(response.text, emotions);
      await db.updateChatMessageEmotion(messageId, emotion);
      return emotion;
    } catch (e, stack) {
      debugPrint('Emotion pick failed: $e\n$stack');
      return null;
    }
  }

  static List<String> _recentEmotions(List<ChatMessage> history) {
    final recent = <String>[];
    for (final message in history.reversed) {
      final emotion = message.emotion;
      if (emotion == null) continue;
      recent.add(emotion);
      if (recent.length == recentLimit) break;
    }
    return recent;
  }
}
