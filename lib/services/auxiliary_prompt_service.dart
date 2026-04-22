import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import '../models/prompt/auxiliary_prompt.dart';

/// Source metadata that tells the service how to seed a given prompt key
/// from bundled defaults. Assets follow the `<base>_<lang>.<ext>` convention
/// (with `_en`, `_ko`, `_ja`, and a no-suffix fallback). When [assetBasePath]
/// is null, [fallbackNative] / [fallbackEnglish] are used verbatim.
class _AuxiliaryPromptDefaults {
  final String? assetBasePath;
  final String fallbackNative;
  final String fallbackEnglish;

  const _AuxiliaryPromptDefaults({
    this.assetBasePath,
    this.fallbackNative = '',
    this.fallbackEnglish = '',
  });
}

/// Default translation-system prompt used before a user overrides it. Kept
/// in-code because no asset file exists for this prompt yet; the translator
/// service historically inlined it.
const String _defaultTranslationSystemPrompt =
    'You are a professional translator. Translate the user message into natural, '
    'fluent English that preserves the original meaning, tone, and formatting. '
    'CRITICAL RULES:\n'
    '- Output ONLY the translated text. No preamble, no explanation, no quotes.\n'
    '- Preserve every placeholder like {{name}}, {{user}}, {{char}}, {{agent_context}} EXACTLY as-is.\n'
    '- Preserve all markdown, XML-like tags, line breaks, and whitespace structure.\n'
    '- If the input is already in English, return it unchanged.';

/// Persists and restores auxiliary (non-chat) system prompts. Each prompt key
/// corresponds to a single DB row; callers use [getEffectiveContent] to pull
/// the ready-to-send prompt text (respecting the per-prompt English toggle)
/// and [upsert] / [resetToDefaults] from the settings UI. Seeding from bundled
/// assets happens lazily on first access.
class AuxiliaryPromptService {
  static final AuxiliaryPromptService instance = AuxiliaryPromptService._();
  AuxiliaryPromptService._();

  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Cache of loaded prompts — invalidated after upsert/reset.
  final Map<AuxiliaryPromptKey, AuxiliaryPrompt> _cache = {};

  static const Map<AuxiliaryPromptKey, _AuxiliaryPromptDefaults> _defaults = {
    AuxiliaryPromptKey.flanAgentSystem: _AuxiliaryPromptDefaults(
      assetBasePath: 'assets/defaults/agent_prompts/system_prompt',
    ),
    AuxiliaryPromptKey.chatTranslation: _AuxiliaryPromptDefaults(
      fallbackNative: _defaultTranslationSystemPrompt,
      fallbackEnglish: _defaultTranslationSystemPrompt,
    ),
    AuxiliaryPromptKey.agentSummary: _AuxiliaryPromptDefaults(
      assetBasePath:
          'assets/defaults/agent_summary_prompts/extraction_prompt',
    ),
    AuxiliaryPromptKey.snsGenerate: _AuxiliaryPromptDefaults(
      assetBasePath: 'assets/defaults/community_prompts/community_generate',
    ),
    AuxiliaryPromptKey.snsPostReplies: _AuxiliaryPromptDefaults(
      assetBasePath: 'assets/defaults/community_prompts/post_replies',
    ),
    AuxiliaryPromptKey.snsCommentReplies: _AuxiliaryPromptDefaults(
      assetBasePath: 'assets/defaults/community_prompts/comment_replies',
    ),
    AuxiliaryPromptKey.diaryGenerate: _AuxiliaryPromptDefaults(
      assetBasePath: 'assets/defaults/diary_prompts/diary_generate',
    ),
    AuxiliaryPromptKey.newsGenerate: _AuxiliaryPromptDefaults(
      assetBasePath: 'assets/defaults/news_prompts/news_generate',
    ),
    AuxiliaryPromptKey.newsEventGenerate: _AuxiliaryPromptDefaults(
      assetBasePath: 'assets/defaults/news_prompts/news_event_generate',
    ),
  };

  /// Load the prompt for [key], seeding from defaults on first access.
  Future<AuxiliaryPrompt> get(AuxiliaryPromptKey key) async {
    final cached = _cache[key];
    if (cached != null) return cached;

    final existing = await _db.readAuxiliaryPromptByKey(key.storageKey);
    if (existing != null) {
      _cache[key] = existing;
      return existing;
    }

    final seeded = await _seed(key);
    _cache[key] = seeded;
    return seeded;
  }

  /// Convenience accessor for callers that only care about the active text
  /// (native vs. english, based on the per-prompt toggle).
  Future<String> getEffectiveContent(AuxiliaryPromptKey key) async {
    final prompt = await get(key);
    return prompt.effectiveContent;
  }

  /// Persist edits from the settings UI.
  Future<AuxiliaryPrompt> upsert({
    required AuxiliaryPromptKey key,
    required String contentNative,
    required String contentEnglish,
    required bool useEnglish,
  }) async {
    final now = DateTime.now();
    final prompt = AuxiliaryPrompt(
      key: key,
      contentNative: contentNative,
      contentEnglish: contentEnglish,
      useEnglish: useEnglish,
      updatedAt: now,
    );
    await _db.upsertAuxiliaryPrompt(prompt);
    final stored = await _db.readAuxiliaryPromptByKey(key.storageKey);
    final result = stored ?? prompt;
    _cache[key] = result;
    return result;
  }

  /// Wipe the stored row and re-seed from bundled defaults.
  Future<AuxiliaryPrompt> resetToDefaults(AuxiliaryPromptKey key) async {
    await _db.deleteAuxiliaryPromptByKey(key.storageKey);
    _cache.remove(key);
    final seeded = await _seed(key);
    _cache[key] = seeded;
    return seeded;
  }

  /// Wipe every stored auxiliary prompt and re-seed all of them from bundled
  /// defaults. Used by the "reset all" action in the Auxiliary Prompts hub.
  Future<void> resetAllToDefaults() async {
    for (final key in AuxiliaryPromptKey.values) {
      await _db.deleteAuxiliaryPromptByKey(key.storageKey);
    }
    _cache.clear();
    for (final key in AuxiliaryPromptKey.values) {
      final seeded = await _seed(key);
      _cache[key] = seeded;
    }
  }

  /// Load the default native/english bodies for [key] without touching the
  /// database. Used by the edit UI to show the built-in reference text.
  Future<({String native, String english})> loadDefaults(
    AuxiliaryPromptKey key,
  ) async {
    final defaults = _defaults[key]!;
    final native = await _loadNativeDefault(defaults);
    final english = await _loadEnglishDefault(defaults);
    return (native: native, english: english);
  }

  Future<AuxiliaryPrompt> _seed(AuxiliaryPromptKey key) async {
    final defaults = _defaults[key]!;
    final native = await _loadNativeDefault(defaults);
    final english = await _loadEnglishDefault(defaults);

    final prompt = AuxiliaryPrompt(
      key: key,
      contentNative: native,
      contentEnglish: english,
      useEnglish: false,
      updatedAt: DateTime.now(),
    );
    await _db.upsertAuxiliaryPrompt(prompt);
    final stored = await _db.readAuxiliaryPromptByKey(key.storageKey);
    return stored ?? prompt;
  }

  Future<String> _loadNativeDefault(_AuxiliaryPromptDefaults defaults) async {
    final base = defaults.assetBasePath;
    if (base == null) return defaults.fallbackNative;

    final locale = ui.PlatformDispatcher.instance.locale.languageCode;
    final suffixes = <String>[];
    if (locale == 'ko') {
      suffixes.addAll(['_ko', '', '_en']);
    } else if (locale == 'ja') {
      suffixes.addAll(['_ja', '', '_en']);
    } else {
      suffixes.addAll(['_en', '']);
    }
    return _loadFirstAvailable(
      base,
      suffixes,
      defaults.fallbackNative,
    );
  }

  Future<String> _loadEnglishDefault(_AuxiliaryPromptDefaults defaults) async {
    final base = defaults.assetBasePath;
    if (base == null) return defaults.fallbackEnglish;
    return _loadFirstAvailable(
      base,
      ['_en', ''],
      defaults.fallbackEnglish,
    );
  }

  Future<String> _loadFirstAvailable(
    String basePath,
    List<String> suffixes,
    String fallback,
  ) async {
    for (final suffix in suffixes) {
      try {
        return await rootBundle.loadString('$basePath$suffix.txt');
      } catch (_) {
        continue;
      }
    }
    return fallback;
  }
}
