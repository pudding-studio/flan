import '../models/prompt/prompt_item.dart';

/// Converts RisuAI botPreset JSON to the native ChatPrompt import format.
///
/// Two Risu layouts are supported:
/// - Legacy: `formatingOrder[]` chooses which sections appear where. Section
///   text comes from top-level `mainPrompt` / `jailbreak` / `globalNote`; the
///   character/persona/lorebook slots become `{{character}}` / `{{persona}}` /
///   `{{character_book}}` placeholder items.
/// - Modern: `promptTemplate[]` carries explicit per-item entries
///   (plain / chat / typed / authornote / chatML). Cache markers are dropped.
class RisuPresetConverter {
  /// Detect if a JSON map is a Risu botPreset. Risu presets always carry
  /// `mainPrompt` + `globalNote` plus either the legacy `formatingOrder` or
  /// the modern `promptTemplate` array — a combination that neither Flan's
  /// native prompts nor SillyTavern presets use.
  static bool isRisuPreset(Map<String, dynamic> json) {
    if (json.containsKey('supportedModel')) return false;
    if (!json.containsKey('mainPrompt')) return false;
    if (!json.containsKey('globalNote')) return false;
    return json.containsKey('formatingOrder') ||
        json.containsKey('promptTemplate');
  }

  static Map<String, dynamic> convertToNativeFormat(
    Map<String, dynamic> risuJson, {
    required String fileName,
  }) {
    final parameters = _extractParameters(risuJson);
    final items = _convertPrompts(risuJson);

    final apiType = risuJson['apiType'] as String?;
    final description = apiType != null && apiType.isNotEmpty
        ? 'Imported from RisuAI ($apiType)'
        : 'Imported from RisuAI';

    final name = (risuJson['name'] as String?)?.trim();
    return {
      'name': (name != null && name.isNotEmpty) ? name : fileName,
      'description': description,
      'supportedModel': 'ALL',
      'parameters': parameters,
      'standaloneItems': items,
    };
  }

  static Map<String, dynamic> _extractParameters(Map<String, dynamic> j) {
    final params = <String, dynamic>{};

    final temperature = j['temperature'];
    if (temperature is num) params['temperature'] = temperature.toDouble();

    final topP = j['top_p'];
    if (topP is num) params['topP'] = topP.toDouble();

    final topK = j['top_k'];
    if (topK is num && topK.toInt() > 0) params['topK'] = topK.toInt();

    // Risu keeps a typo in the field name: `PresensePenalty`.
    final presPenalty = j['PresensePenalty'] ?? j['presencePenalty'];
    if (presPenalty is num) {
      params['presencePenalty'] = presPenalty.toDouble();
    }

    final freqPenalty = j['frequencyPenalty'];
    if (freqPenalty is num) {
      params['frequencyPenalty'] = freqPenalty.toDouble();
    }

    final maxResponse = j['maxResponse'];
    if (maxResponse is num) params['maxOutputTokens'] = maxResponse.toInt();

    final maxContext = j['maxContext'];
    if (maxContext is num) params['maxInputTokens'] = maxContext.toInt();

    return params;
  }

  static List<Map<String, dynamic>> _convertPrompts(Map<String, dynamic> j) {
    final template = j['promptTemplate'];
    if (template is List && template.isNotEmpty) {
      return _convertPromptTemplate(template, j);
    }

    final formatingOrder = j['formatingOrder'];
    if (formatingOrder is List && formatingOrder.isNotEmpty) {
      return _convertFormatingOrder(formatingOrder.cast<dynamic>(), j);
    }

    // Fall back: emit main + jailbreak + chat when neither array exists.
    return _convertFormatingOrder(
      const ['main', 'chats', 'jailbreak'],
      j,
    );
  }

  /// Modern format: iterate `promptTemplate` entries and map each to a
  /// native item, preserving order.
  static List<Map<String, dynamic>> _convertPromptTemplate(
    List<dynamic> template,
    Map<String, dynamic> preset,
  ) {
    final result = <Map<String, dynamic>>[];
    int order = 0;

    for (final raw in template) {
      if (raw is! Map) continue;
      final entry = raw.cast<String, dynamic>();
      final type = entry['type'] as String?;
      if (type == null) continue;

      final item = _templateItemToNative(entry, type, order, preset);
      if (item != null) {
        result.add(item);
        order++;
      }
    }

    return result;
  }

  static Map<String, dynamic>? _templateItemToNative(
    Map<String, dynamic> entry,
    String type,
    int order,
    Map<String, dynamic> preset,
  ) {
    switch (type) {
      case 'plain':
      case 'jailbreak':
      case 'cot':
      case 'chatML':
        final text = (entry['text'] as String?) ?? '';
        if (text.trim().isEmpty) return null;
        return {
          'role': _mapRole(entry['role'] as String?),
          'content': text,
          'name': entry['name'] as String? ?? _defaultNameFor(type),
          'order': order,
          'enabled': true,
          'chatSettingMode': 'basic',
          'chatRangeType': 'recent',
        };

      case 'persona':
        return _keywordItem(
          '{{persona}}',
          entry['name'] as String? ?? 'Persona',
          entry['role2'] as String?,
          order,
        );
      case 'description':
        return _keywordItem(
          '{{character}}',
          entry['name'] as String? ?? 'Character',
          entry['role2'] as String?,
          order,
        );
      case 'lorebook':
        return _keywordItem(
          '{{character_book}}',
          entry['name'] as String? ?? 'Lorebook',
          entry['role2'] as String?,
          order,
        );
      case 'memory':
        return _keywordItem(
          '{{chat_historys}}',
          entry['name'] as String? ?? 'Memory',
          entry['role2'] as String?,
          order,
        );
      case 'postEverything':
        final inner = (entry['innerFormat'] as String?)?.trim() ?? '';
        if (inner.isEmpty) return null;
        return {
          'role': _mapRole(entry['role2'] as String?),
          'content': inner,
          'name': entry['name'] as String? ?? 'Post-Everything',
          'order': order,
          'enabled': true,
          'chatSettingMode': 'basic',
          'chatRangeType': 'recent',
        };

      case 'authornote':
        final defaultText = (entry['defaultText'] as String?)?.trim() ?? '';
        final inner = (entry['innerFormat'] as String?)?.trim() ?? '';
        final content = defaultText.isNotEmpty ? defaultText : inner;
        if (content.isEmpty) return null;
        return {
          'role': _mapRole(entry['role2'] as String?),
          'content': content,
          'name': entry['name'] as String? ?? 'Author Note',
          'order': order,
          'enabled': true,
          'chatSettingMode': 'basic',
          'chatRangeType': 'recent',
        };

      case 'chat':
        return _chatItemFromTemplate(entry, order);

      case 'cache':
        // Anthropic prompt-cache marker; no Flan equivalent.
        return null;

      default:
        return null;
    }
  }

  static Map<String, dynamic> _chatItemFromTemplate(
    Map<String, dynamic> entry,
    int order,
  ) {
    final rangeStart = (entry['rangeStart'] as num?)?.toInt() ?? 0;
    final rangeEndRaw = entry['rangeEnd'];
    final isFullRange = rangeStart == 0 &&
        (rangeEndRaw == 'end' ||
            rangeEndRaw == null ||
            (rangeEndRaw is num && rangeEndRaw.toInt() <= 0));

    if (isFullRange) {
      return {
        'role': 'chat',
        'content': '',
        'name': entry['name'] as String? ?? 'Chat History',
        'order': order,
        'enabled': true,
        'chatSettingMode': 'basic',
        'chatRangeType': 'recent',
      };
    }

    // Approximate Risu's numeric window with Flan's advanced-recent mode.
    // Risu counts messages from the most-recent end; Flan's `recentChatCount`
    // captures the tail size, which matches for the common `0..N` case.
    final int? recentCount = (rangeEndRaw is num)
        ? rangeEndRaw.toInt()
        : null;
    return {
      'role': 'chat',
      'content': '',
      'name': entry['name'] as String? ?? 'Chat History',
      'order': order,
      'enabled': true,
      'chatSettingMode': 'advanced',
      'chatRangeType': 'recent',
      if (recentCount != null && recentCount > 0)
        'recentChatCount': recentCount,
    };
  }

  /// Legacy format: `formatingOrder` names the sections; content comes from
  /// top-level `mainPrompt` / `jailbreak` / `globalNote` for those slots and
  /// from keyword placeholders for the character/persona/lorebook slots.
  static List<Map<String, dynamic>> _convertFormatingOrder(
    List<dynamic> order,
    Map<String, dynamic> preset,
  ) {
    final result = <Map<String, dynamic>>[];
    int idx = 0;

    for (final section in order) {
      final item = _formatingSectionToItem(section as String, idx, preset);
      if (item != null) {
        result.add(item);
        idx++;
      }
    }

    return result;
  }

  static Map<String, dynamic>? _formatingSectionToItem(
    String section,
    int order,
    Map<String, dynamic> preset,
  ) {
    switch (section) {
      case 'main':
        final text = (preset['mainPrompt'] as String?) ?? '';
        if (text.trim().isEmpty) return null;
        return _systemItem(text, 'Main Prompt', order);
      case 'jailbreak':
        final text = (preset['jailbreak'] as String?) ?? '';
        if (text.trim().isEmpty) return null;
        return _systemItem(text, 'Jailbreak', order);
      case 'globalNote':
        final text = (preset['globalNote'] as String?) ?? '';
        if (text.trim().isEmpty) return null;
        return _systemItem(text, 'Global Note', order);
      case 'description':
        return _keywordItem('{{character}}', 'Character', null, order);
      case 'personaPrompt':
        return _keywordItem('{{persona}}', 'Persona', null, order);
      case 'lorebook':
        return _keywordItem('{{character_book}}', 'Lorebook', null, order);
      case 'chats':
      case 'lastChat':
        return {
          'role': 'chat',
          'content': '',
          'name': section == 'lastChat' ? 'Last Chat' : 'Chat History',
          'order': order,
          'enabled': true,
          'chatSettingMode': 'basic',
          'chatRangeType': 'recent',
        };
      case 'authorNote':
      case 'postEverything':
        // Legacy format has no source text for these slots; skip silently.
        return null;
      default:
        return null;
    }
  }

  static Map<String, dynamic> _systemItem(String text, String name, int order) {
    return {
      'role': PromptRole.system.name,
      'content': text,
      'name': name,
      'order': order,
      'enabled': true,
      'chatSettingMode': 'basic',
      'chatRangeType': 'recent',
    };
  }

  static Map<String, dynamic> _keywordItem(
    String keyword,
    String name,
    String? roleHint,
    int order,
  ) {
    return {
      'role': _mapRole(roleHint),
      'content': keyword,
      'name': name,
      'order': order,
      'enabled': true,
      'chatSettingMode': 'basic',
      'chatRangeType': 'recent',
    };
  }

  static String _mapRole(String? risuRole) {
    switch (risuRole?.toLowerCase()) {
      case 'user':
        return PromptRole.user.name;
      case 'bot':
      case 'assistant':
        return PromptRole.assistant.name;
      case 'system':
      case null:
      default:
        return PromptRole.system.name;
    }
  }

  static String _defaultNameFor(String type) {
    switch (type) {
      case 'jailbreak':
        return 'Jailbreak';
      case 'cot':
        return 'Chain of Thought';
      case 'chatML':
        return 'ChatML';
      case 'plain':
      default:
        return 'Prompt';
    }
  }
}
