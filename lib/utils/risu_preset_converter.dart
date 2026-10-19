import 'dart:convert';

import '../models/prompt/prompt_item.dart';
import 'cbs/cbs_context.dart';

/// Converts RisuAI botPreset JSON to the native ChatPrompt import format,
/// reproducing what RisuAI sends for the preset.
///
/// - Preset toggles (`customPromptTemplateToggle`) become prompt conditions
///   that CBS reads as `toggle_<key>` globals, plus one default condition
///   preset. Jailbreak and chain-of-thought prompts hang off two extra
///   toggles standing in for RisuAI's global switches.
/// - Prompt items keep their per-item options: role, `innerFormat` around
///   `{{slot}}` (sent only when the slot has content), author note default
///   text, chat ranges and ChatML blocks.
/// - Preset prompt settings map to the template behavior parameters
///   (`sendChatAsSystem`, `sendName`, `templateDefaultVariables`), to the
///   `[Start a new chat]` marker and to the post-everything text.
/// - Both the modern `promptTemplate[]` and the legacy `formatingOrder[]`
///   layouts are supported.
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
    final conditions = _RisuConditions.fromToggleSyntax(
      risuJson['customPromptTemplateToggle'] as String?,
    );
    final items = _RisuItemConverter(risuJson, conditions).convert();

    final apiType = risuJson['apiType'] as String?;
    final description = apiType != null && apiType.isNotEmpty
        ? 'Imported from RisuAI ($apiType)'
        : 'Imported from RisuAI';

    final name = (risuJson['name'] as String?)?.trim();
    return {
      'name': (name != null && name.isNotEmpty) ? name : fileName,
      'description': description,
      'supportedModel': 'ALL',
      'parameters': _extractParameters(risuJson),
      'standaloneItems': items,
      if (conditions.isNotEmpty) ...{
        'conditions': conditions.toJson(),
        'conditionPresets': [conditions.defaultPresetJson()],
      },
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

    // RisuAI sends the new message as part of the chat history.
    params['userMessageInChatHistory'] = true;

    // RisuAI reads these settings only when the preset uses a template.
    final template = j['promptTemplate'];
    final settings = j['promptSettings'];
    if (template is List && template.isNotEmpty && settings is Map) {
      final chatItems = template
          .whereType<Map>()
          .where((item) => item['type'] == 'chat')
          .toList();
      final allChatsKeepRole = chatItems.isNotEmpty &&
          chatItems.every((item) => item['chatAsOriginalOnSystem'] == true);
      if (settings['sendChatAsSystem'] == true && !allChatsKeepRole) {
        params['sendChatAsSystem'] = true;
      }
      if (settings['sendName'] == true) params['sendName'] = true;
    }

    final defaults = (j['templateDefaultVariables'] as String?)?.trim();
    if (defaults != null && defaults.isNotEmpty) {
      params['defaultVariables'] = defaults;
    }

    return params;
  }
}

/// One RisuAI preset toggle as a native prompt condition.
class _RisuCondition {
  final int id;
  final String key;
  final String name;
  final String type;
  final List<String> options;
  final String? defaultValue;

  const _RisuCondition({
    required this.id,
    required this.key,
    required this.name,
    required this.type,
    this.options = const [],
    this.defaultValue,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'variableName': key,
        'order': id - 1,
        'options': [
          for (var i = 0; i < options.length; i++)
            {'name': options[i], 'order': i},
        ],
      };
}

class _RisuConditions {
  final List<_RisuCondition> _items = [];

  bool get isNotEmpty => _items.isNotEmpty;

  /// Port of RisuAI `parseToggleSyntax`: one `key=label[=type[=options]]`
  /// per line. Checkboxes store "1"/"0", selects the option index and text
  /// toggles the text, all under `toggle_<key>` — exactly what
  /// `cbsToggleVars` produces from these conditions. Groups have no native
  /// equivalent, so their label prefixes the toggles inside them; captions
  /// and dividers are layout only and are dropped.
  factory _RisuConditions.fromToggleSyntax(String? syntax) {
    final result = _RisuConditions._();
    if (syntax == null || syntax.isEmpty) return result;

    String? group;
    for (final line in syntax.split('\n')) {
      final parts = line.split('=');
      final key = parts[0];
      final label = parts.length > 1 ? parts[1] : '';
      final type = parts.length > 2 ? parts[2] : '';
      final options = parts.length > 3 ? parts[3].split(',') : <String>[];

      switch (type) {
        case 'group':
          group = label.isEmpty ? null : label;
          continue;
        case 'groupEnd':
          group = null;
          continue;
        case 'divider':
        case 'caption':
          continue;
      }
      if (key.isEmpty || label.isEmpty) continue;

      final name = group == null ? label : '$group / $label';
      switch (type) {
        case 'select':
          result._add(key, name, 'singleSelect', options: options);
        case 'text':
        case 'textarea':
          result._add(key, name, 'variable');
        default:
          result._add(key, name, 'toggle', defaultValue: 'false');
      }
    }
    return result;
  }

  _RisuConditions._();

  /// Adds (once) the toggle that stands in for one of RisuAI's global
  /// switches and returns its id. Both switches are off by default, as in
  /// a fresh RisuAI install.
  int switchFor(String key, String name) =>
      _add(key, name, 'toggle', defaultValue: 'false');

  int _add(
    String key,
    String name,
    String type, {
    List<String> options = const [],
    String? defaultValue,
  }) {
    for (final existing in _items) {
      if (existing.key == key) return existing.id;
    }
    final condition = _RisuCondition(
      id: _items.length + 1,
      key: key,
      name: name,
      type: type,
      options: options,
      defaultValue: defaultValue,
    );
    _items.add(condition);
    return condition.id;
  }

  List<Map<String, dynamic>> toJson() =>
      [for (final condition in _items) condition.toJson()];

  /// Selects and text toggles start unset, so they read "null" like a
  /// toggle RisuAI has never stored.
  Map<String, dynamic> defaultPresetJson() => {
        'name': 'Default',
        'isDefault': true,
        'order': 0,
        'values': [
          for (final condition in _items)
            if (condition.defaultValue != null)
              {'conditionId': condition.id, 'value': condition.defaultValue},
        ],
      };
}

/// A native item before its final role is known: RisuAI sends a system
/// message that follows the start of the conversation as a user message
/// prefixed with `system: `, so the role depends on what came before.
class _Draft {
  final String role;
  final String name;

  /// Builds the content from the text that prefixes the item's own text.
  final String Function(String prefix)? content;
  final Map<String, dynamic> extra;

  const _Draft(this.role, this.name, this.content, [this.extra = const {}]);

  const _Draft.chat(this.name, this.extra)
      : role = 'chat',
        content = null;
}

class _RisuItemConverter {
  static const _startNewChat = '[Start a new chat]';
  static final _jbToggled = RegExp(r'\{\{\s*jbtoggled\s*\}\}', caseSensitive: false);
  static final _positionToken =
      RegExp(r'\{\{\s*position\s*::[^}]*\}\}', caseSensitive: false);

  final Map<String, dynamic> preset;
  final _RisuConditions conditions;

  _RisuItemConverter(this.preset, this.conditions);

  List<Map<String, dynamic>> convert() {
    final template = preset['promptTemplate'];
    final drafts = template is List && template.isNotEmpty
        ? _fromTemplate(template)
        : _fromFormatingOrder(preset['formatingOrder']);
    // `{{jbtoggled}}` reads the jailbreak switch even without jailbreak items.
    if (_jbToggled.hasMatch(jsonEncode(template ?? preset['mainPrompt']))) {
      conditions.switchFor(cbsJailbreakToggleKey, 'Jailbreak');
    }
    return _finalize(drafts);
  }

  List<_Draft> _fromTemplate(List<dynamic> template) {
    final drafts = <_Draft>[];
    var hasPostEverything = false;
    for (final raw in template) {
      if (raw is! Map) continue;
      final entry = raw.cast<String, dynamic>();
      final type = entry['type'] as String?;
      if (type == 'postEverything') hasPostEverything = true;
      drafts.addAll(_templateItem(entry, type));
    }
    // RisuAI appends a post-everything slot when the template has none.
    if (!hasPostEverything) drafts.addAll(_postEverything(null));
    return drafts;
  }

  Iterable<_Draft> _templateItem(Map<String, dynamic> entry, String? type) {
    final name = entry['name'] as String?;
    switch (type) {
      case 'plain':
      case 'jailbreak':
      case 'cot':
        final text = _inlinePresetTexts((entry['text'] as String?) ?? '');
        if (text.trim().isEmpty) return const [];
        return [
          _Draft(
            _role(entry['role'] as String?),
            name ?? _defaultNameFor(type!),
            (prefix) => '$prefix$text',
            _switchCondition(type!),
          ),
        ];
      case 'chatML':
        return _chatML((entry['text'] as String?) ?? '', name ?? 'ChatML');
      case 'persona':
        return [_slotItem(entry, 'user_description', name ?? 'Persona')];
      case 'description':
        return [_slotItem(entry, 'char_description', name ?? 'Description')];
      case 'memory':
        return [_slotItem(entry, 'chat_historys', name ?? 'Memory')];
      case 'lorebook':
        // RisuAI ignores innerFormat for the lorebook slot.
        return [
          _Draft(
            _role(entry['role2'] as String?),
            name ?? 'Lorebook',
            (prefix) => _whenNotEmpty('character_book', '$prefix{{character_book}}'),
          ),
        ];
      case 'authornote':
        return [_authorNote(entry, name)];
      case 'postEverything':
        return _postEverything(name);
      case 'chat':
        return [_Draft.chat(name ?? 'Chat History', _chatRange(entry))];
      default:
        // `cache` marks Anthropic prompt-cache points; nothing to send.
        return const [];
    }
  }

  /// RisuAI fills the first `{{slot}}` of `innerFormat` with the block's
  /// content and sends nothing when that content is empty.
  _Draft _slotItem(Map<String, dynamic> entry, String keyword, String name) {
    final format = _innerFormat(entry);
    return _Draft(
      _role(entry['role2'] as String?),
      name,
      (prefix) => _whenNotEmpty(
        keyword,
        '$prefix${format.replaceFirst('{{slot}}', '{{$keyword}}')}',
      ),
    );
  }

  /// The author note slot holds the chat memo, falling back to the item's
  /// default text.
  _Draft _authorNote(Map<String, dynamic> entry, String? name) {
    final format = _innerFormat(entry);
    final defaultText = (entry['defaultText'] as String?) ?? '';
    return _Draft(
      _role(entry['role2'] as String?),
      name ?? 'Author Note',
      (prefix) {
        final withMemo =
            '$prefix${format.replaceFirst('{{slot}}', '{{chat_memo}}')}';
        if (defaultText.isEmpty) return _whenNotEmpty('chat_memo', withMemo);
        final withDefault =
            '$prefix${format.replaceFirst('{{slot}}', defaultText)}';
        return '${_whenNotEmpty('chat_memo', withMemo)}'
            '${_whenEmpty('chat_memo', withDefault)}';
      },
    );
  }

  /// Post-everything carries RisuAI's `postEndInnerFormat`. The lorebook
  /// entries RisuAI also places here have no native equivalent.
  Iterable<_Draft> _postEverything(String? name) {
    final settings = preset['promptSettings'];
    final text = settings is Map ? settings['postEndInnerFormat'] : null;
    if (text is! String || text.trim().isEmpty) return const [];
    return [
      _Draft('system', name ?? 'Post Everything', (prefix) => '$prefix$text'),
    ];
  }

  /// Port of RisuAI `parseChatML`: text not starting with `<|im_start|>`
  /// sends nothing.
  Iterable<_Draft> _chatML(String text, String name) {
    const starter = '<|im_start|>';
    const separator = '<|im_sep|>';
    const ender = '<|im_end|>';
    final trimmed = text.trim();
    if (!trimmed.startsWith(starter)) return const [];

    final drafts = <_Draft>[];
    for (var block in trimmed.split(starter).where((b) => b.isNotEmpty)) {
      var role = 'user';
      for (final candidate in const ['user', 'system', 'assistant']) {
        if (block.startsWith('$candidate$separator')) {
          role = candidate;
          block = block.substring(candidate.length + separator.length);
          break;
        }
        if (block.startsWith('$candidate ') || block.startsWith('$candidate\n')) {
          role = candidate;
          block = block.substring(candidate.length + 1);
          break;
        }
      }
      block = block.trim();
      if (block.endsWith(ender)) {
        block = block.substring(0, block.length - ender.length);
      }
      final content = _inlinePresetTexts(block);
      drafts.add(_Draft(
        role == 'assistant' ? PromptRole.assistant.name : role,
        name,
        (prefix) => '$prefix$content',
      ));
    }
    return drafts;
  }

  /// Legacy layout: `formatingOrder` names the sections; prompt text comes
  /// from `mainPrompt` / `jailbreak` / `globalNote`, which may switch roles
  /// with `@@user` / `@@assistant` / `@@system` lines.
  List<_Draft> _fromFormatingOrder(Object? order) {
    final sections = order is List && order.isNotEmpty
        ? order.whereType<String>()
        : const ['main', 'chats', 'jailbreak'];
    final drafts = <_Draft>[];
    for (final section in sections) {
      switch (section) {
        case 'main':
          drafts.addAll(_rolePrompt(preset['mainPrompt'], 'Main Prompt'));
        case 'jailbreak':
          final id = conditions.switchFor(cbsJailbreakToggleKey, 'Jailbreak');
          drafts.addAll(_rolePrompt(
            preset['jailbreak'],
            'Jailbreak',
            _conditional(id),
          ));
        case 'globalNote':
          drafts.addAll(_rolePrompt(preset['globalNote'], 'Global Note'));
        case 'description':
          drafts.add(_slotItem(const {}, 'char_description', 'Description'));
        case 'personaPrompt':
          drafts.add(_slotItem(const {}, 'user_description', 'Persona'));
        case 'lorebook':
          drafts.add(_slotItem(const {}, 'character_book', 'Lorebook'));
        case 'authorNote':
          drafts.add(_authorNote(const {}, null));
        case 'chats':
          drafts.add(_Draft.chat('Chat History', _chatRange(const {})));
        // `lastChat` is the new message, which follows the chat history.
      }
    }
    return drafts;
  }

  /// RisuAI's legacy `formatPrompt`.
  Iterable<_Draft> _rolePrompt(
    Object? raw,
    String name, [
    Map<String, dynamic> extra = const {},
  ]) {
    if (raw is! String || raw.trim().isEmpty) return const [];
    final data = raw.startsWith('@@') ? raw : '@@system\n$raw';
    final parts = data.split(RegExp(r'@@@?(user|assistant|system)\n'));
    final roles = RegExp(r'@@@?(user|assistant|system)\n')
        .allMatches(data)
        .map((m) => m.group(1)!)
        .toList();
    final drafts = <_Draft>[];
    for (var i = 0; i < roles.length; i++) {
      final text = _inlinePresetTexts(parts[i + 1].trim());
      drafts.add(_Draft(
        roles[i] == 'assistant' ? PromptRole.assistant.name : roles[i],
        name,
        (prefix) => '$prefix$text',
        extra,
      ));
    }
    return drafts;
  }

  /// Applies RisuAI's system-message placement and the `[Start a new chat]`
  /// marker, then emits native item JSON.
  List<Map<String, dynamic>> _finalize(List<_Draft> drafts) {
    final settings = preset['promptSettings'];
    final markNewChat = !(settings is Map && settings['trimStartNewChat'] == true);

    final result = <Map<String, dynamic>>[];
    var conversationStarted = false;
    var markerAdded = false;

    void emit(_Draft draft) {
      final isSystem = draft.role == 'system';
      final asUserTurn = isSystem && conversationStarted;
      result.add({
        'role': asUserTurn ? PromptRole.user.name : draft.role,
        'content': draft.content?.call(asUserTurn ? 'system: ' : '') ?? '',
        'name': draft.name,
        'order': result.length,
        'enabled': true,
        'chatSettingMode': 'basic',
        'chatRangeType': 'recent',
        ...draft.extra,
      });
      if (!isSystem) conversationStarted = true;
    }

    for (final draft in drafts) {
      if (draft.role == 'chat' && markNewChat && !markerAdded) {
        emit(_Draft('system', 'Start a new chat', (p) => '$p$_startNewChat'));
        markerAdded = true;
      }
      emit(draft);
    }
    return result;
  }

  Map<String, dynamic> _switchCondition(String type) {
    return switch (type) {
      'jailbreak' => _conditional(
          conditions.switchFor(cbsJailbreakToggleKey, 'Jailbreak')),
      'cot' => _conditional(
          conditions.switchFor(cbsChainOfThoughtToggleKey, 'Chain of Thought')),
      _ => const {},
    };
  }

  static Map<String, dynamic> _conditional(int conditionId) => {
        'enableMode': EnableMode.conditional.name,
        'conditionId': conditionId,
        'conditionValue': 'true',
      };

  /// RisuAI chat ranges slice the message list (negative = from the end,
  /// `-1000` = everything). Native ranges count turns of two messages from
  /// the newest end, so ranges counted from the oldest message keep the
  /// whole history.
  static Map<String, dynamic> _chatRange(Map<String, dynamic> entry) {
    final start = (entry['rangeStart'] as num?)?.toInt() ?? 0;
    final rawEnd = entry['rangeEnd'];
    final end = rawEnd is num ? rawEnd.toInt() : null;
    int turns(int messages) => (messages + 1) ~/ 2;

    if (start == -1000 || (start == 0 && end == null)) return const {};
    if (start < 0 && end == null) {
      return {
        'chatSettingMode': 'advanced',
        'chatRangeType': ChatRangeType.recent.name,
        'recentChatCount': turns(-start),
      };
    }
    if (start == 0 && end != null && end < 0) {
      return {
        'chatSettingMode': 'advanced',
        'chatRangeType': ChatRangeType.old.name,
        'chatStartPosition': turns(-end),
      };
    }
    if (start < 0 && end != null && start < end && end < 0) {
      return {
        'chatSettingMode': 'advanced',
        'chatRangeType': ChatRangeType.middle.name,
        'chatStartPosition': turns(-end) + 1,
        'chatEndPosition': turns(-start),
      };
    }
    return const {};
  }

  String _innerFormat(Map<String, dynamic> entry) {
    final format = entry['innerFormat'];
    if (format is! String || format.isEmpty) return '{{slot}}';
    return _inlinePresetTexts(format);
  }

  /// RisuAI's `{{mainprompt}}` / `{{jb}}` / `{{globalnote}}` read the
  /// preset's own texts, which only exist at import time; lorebook
  /// `{{position::…}}` anchors have no native equivalent.
  String _inlinePresetTexts(String text) {
    String read(String field) => (preset[field] as String?) ?? '';
    return text.replaceAll(_positionToken, '').replaceAllMapped(
      RegExp(
        r'\{\{\s*(main_?prompt|system_?prompt|jb|jailbreak|global_?note|system_?note|ujb)\s*\}\}',
        caseSensitive: false,
      ),
      (match) => switch (match.group(1)!.toLowerCase().replaceAll('_', '')) {
        'mainprompt' || 'systemprompt' => read('mainPrompt'),
        'jb' || 'jailbreak' => read('jailbreak'),
        _ => read('globalNote'),
      },
    );
  }

  static String _whenNotEmpty(String keyword, String body) =>
      '{{#if {{? {{length::{{$keyword}}}} > 0}}}}$body{{/if}}';

  static String _whenEmpty(String keyword, String body) =>
      '{{#if {{? {{length::{{$keyword}}}} == 0}}}}$body{{/if}}';

  static String _role(String? risuRole) {
    switch (risuRole?.toLowerCase()) {
      case 'user':
        return PromptRole.user.name;
      case 'bot':
      case 'char':
      case 'assistant':
        return PromptRole.assistant.name;
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
      default:
        return 'Prompt';
    }
  }
}
