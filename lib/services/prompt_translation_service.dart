import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat/chat_model.dart';
import '../models/chat/custom_model.dart';
import '../models/chat/custom_provider.dart';
import '../models/chat/unified_model.dart';
import '../models/prompt/auxiliary_prompt.dart';
import 'ai_service.dart';
import 'auxiliary_prompt_service.dart';

/// Translates prompt-item bodies into English using the user's auxiliary
/// (sub) chat model. Callers supply Korean/Japanese/other-language strings
/// keyed by item id; the service returns English replacements keyed the same
/// way so the UI can update controllers in place.
///
/// The service deliberately makes one API call per item (instead of batching
/// everything into a single request) so that a long failing translation on
/// one item doesn't invalidate the others.
class PromptTranslationService {
  final AiService _aiService = AiService();

  Future<UnifiedModel> _resolveSubModel() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('sub_model');
    if (stored != null) {
      if (stored.startsWith('custom:')) {
        final customId = stored.replaceFirst('custom:', '');
        final customModels = await CustomModelRepository.loadAll();
        final custom = customModels.where((m) => m.id == customId).firstOrNull;
        if (custom != null) {
          final providers = await CustomProviderRepository.loadAll();
          final cp = custom.providerId != null
              ? providers.where((p) => p.id == custom.providerId).firstOrNull
              : null;
          return UnifiedModel.fromCustomModel(custom, provider: cp);
        }
      }
      final resolved = ChatModel.resolveFromStoredValue(stored);
      return UnifiedModel.fromChatModel(resolved);
    }
    return UnifiedModel.fromChatModel(ChatModel.geminiFlash25);
  }

  /// Translate [nativeContent] to English. Preserves placeholder tokens of
  /// the form `{{name}}` verbatim so prompt keyword substitution keeps
  /// working after translation.
  Future<String> translateToEnglish(String nativeContent) async {
    if (nativeContent.trim().isEmpty) return '';

    final model = await _resolveSubModel();

    final systemPrompt = await AuxiliaryPromptService.instance
        .getEffectiveContent(AuxiliaryPromptKey.chatTranslation);

    final contents = [
      {
        'role': 'user',
        'parts': [
          {'text': nativeContent},
        ],
      },
    ];

    final response = await _aiService.sendMessage(
      systemPrompt: systemPrompt,
      contents: contents,
      model: model,
      logType: 'prompt_translation',
    );

    return response.text.trim();
  }

  /// Translates only items whose native content has changed since the last
  /// translation (i.e. `previousNative[id] != currentNative[id]`) or whose
  /// English counterpart is still empty. Returns a map of item id → new
  /// English text; unchanged items are omitted from the returned map so the
  /// caller can leave their existing English content alone.
  Future<Map<int, String>> translateChanged({
    required Map<int, String> currentNative,
    required Map<int, String> previousNative,
    required Map<int, String> currentEnglish,
  }) async {
    final result = <int, String>{};
    for (final entry in currentNative.entries) {
      final id = entry.key;
      final native = entry.value;
      if (native.trim().isEmpty) continue;

      final prev = previousNative[id];
      final english = currentEnglish[id] ?? '';
      final changed = prev != native;
      final missingEnglish = english.trim().isEmpty;
      if (!changed && !missingEnglish) continue;

      final translated = await translateToEnglish(native);
      result[id] = translated;
    }
    return result;
  }
}
