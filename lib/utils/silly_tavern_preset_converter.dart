import '../models/prompt/prompt_item.dart';

/// Converts SillyTavern Chat Completion preset JSON to native app format.
class SillyTavernPresetConverter {
  /// Detect if a JSON map is a SillyTavern preset format.
  static bool isSillyTavernPreset(Map<String, dynamic> json) {
    return json.containsKey('prompts') &&
        !json.containsKey('supportedModel') &&
        (json.containsKey('chat_completion_source') ||
            json.containsKey('openai_max_context') ||
            json.containsKey('openai_max_tokens'));
  }

  /// Convert ST preset JSON to native import format compatible with
  /// ChatPrompt.fromJson().
  static Map<String, dynamic> convertToNativeFormat(
    Map<String, dynamic> stJson, {
    required String fileName,
  }) {
    final parameters = _extractParameters(stJson);
    final items = _convertPrompts(stJson);

    final source = stJson['chat_completion_source'] as String?;
    final description =
        source != null ? 'Imported from SillyTavern ($source)' : 'Imported from SillyTavern';

    return {
      'name': fileName,
      'description': description,
      'supportedModel': 'ALL',
      'parameters': parameters,
      'standaloneItems': items,
    };
  }

  static Map<String, dynamic> _extractParameters(Map<String, dynamic> stJson) {
    final params = <String, dynamic>{};

    final temperature = stJson['temperature'];
    if (temperature != null) {
      params['temperature'] = (temperature as num).toDouble();
    }

    final topP = stJson['top_p'];
    if (topP != null) {
      params['topP'] = (topP as num).toDouble();
    }

    final topK = stJson['top_k'];
    if (topK != null && (topK as num).toInt() > 0) {
      params['topK'] = topK.toInt();
    }

    final freqPenalty = stJson['frequency_penalty'];
    if (freqPenalty != null) {
      params['frequencyPenalty'] = (freqPenalty as num).toDouble();
    }

    final presPenalty = stJson['presence_penalty'];
    if (presPenalty != null) {
      params['presencePenalty'] = (presPenalty as num).toDouble();
    }

    final maxTokens = stJson['openai_max_tokens'];
    if (maxTokens != null) {
      params['maxOutputTokens'] = (maxTokens as num).toInt();
    }

    final maxContext = stJson['openai_max_context'];
    if (maxContext != null) {
      params['maxInputTokens'] = (maxContext as num).toInt();
    }

    return params;
  }

  static List<Map<String, dynamic>> _convertPrompts(
    Map<String, dynamic> stJson,
  ) {
    final prompts = stJson['prompts'] as List<dynamic>? ?? [];
    final promptOrder = _buildPromptOrder(stJson);
    final promptEnabled = _buildPromptEnabled(stJson);

    // Separate relative and in-chat prompts
    final relativeItems = <_StPrompt>[];
    final inChatItems = <_StPrompt>[];

    for (final p in prompts) {
      final prompt = p as Map<String, dynamic>;
      if (prompt['marker'] == true) continue;

      final rawContent = prompt['content'] as String? ?? '';
      final content = _stripMacros(rawContent);
      if (content.trim().isEmpty) continue;

      final identifier = prompt['identifier'] as String? ?? '';
      final stPrompt = _StPrompt(
        identifier: identifier,
        name: prompt['name'] as String?,
        role: prompt['role'] as String? ?? 'system',
        content: content,
        enabled: promptEnabled[identifier] ?? prompt['enabled'] as bool? ?? true,
        injectionPosition: prompt['injection_position'] as int? ?? 0,
        injectionDepth: prompt['injection_depth'] as int? ?? 0,
        injectionOrder: prompt['injection_order'] as int? ?? 100,
      );

      if (stPrompt.injectionPosition == 1) {
        inChatItems.add(stPrompt);
      } else {
        relativeItems.add(stPrompt);
      }
    }

    // Sort relative items by prompt_order if available
    if (promptOrder.isNotEmpty) {
      relativeItems.sort((a, b) {
        final aOrder = promptOrder[a.identifier] ?? 999;
        final bOrder = promptOrder[b.identifier] ?? 999;
        return aOrder.compareTo(bOrder);
      });
    }

    final result = <Map<String, dynamic>>[];
    int order = 0;
    bool chatInserted = false;

    // Find where the chat history marker would be in prompt_order
    final chatOrderIndex = promptOrder['chatHistory'] ?? -1;

    for (final item in relativeItems) {
      final itemOrderIndex = promptOrder[item.identifier] ?? -1;

      // Insert chat items before items that come after chat in order
      if (!chatInserted && chatOrderIndex >= 0 && itemOrderIndex > chatOrderIndex) {
        order = _insertChatAndInChatItems(result, inChatItems, order);
        chatInserted = true;
      }

      result.add(_toNativeItem(item, order++));
    }

    // If chat wasn't inserted yet, add it at the end
    if (!chatInserted) {
      order = _insertChatAndInChatItems(result, inChatItems, order);
    }

    return result;
  }

  /// Insert a chat item and any in-chat injection items around it.
  /// Returns the next available order value.
  static int _insertChatAndInChatItems(
    List<Map<String, dynamic>> result,
    List<_StPrompt> inChatItems,
    int startOrder,
  ) {
    int order = startOrder;

    // Group in-chat items by depth
    final byDepth = <int, List<_StPrompt>>{};
    for (final item in inChatItems) {
      byDepth.putIfAbsent(item.injectionDepth, () => []).add(item);
    }
    // Sort within each depth group by injection_order
    for (final group in byDepth.values) {
      group.sort((a, b) => a.injectionOrder.compareTo(b.injectionOrder));
    }

    final depths = byDepth.keys.toList()..sort((a, b) => b.compareTo(a));
    final hasNonZeroDepth = depths.any((d) => d > 0);

    if (hasNonZeroDepth) {
      // Find the maximum depth to split chat
      final maxDepth = depths.where((d) => d > 0).reduce((a, b) => a > b ? a : b);

      // Chat item 1: older messages (basic mode)
      result.add({
        'role': 'chat',
        'content': '',
        'name': '채팅 이력 (이전)',
        'order': order++,
        'enabled': true,
        'chatSettingMode': 'basic',
        'chatRangeType': 'recent',
      });

      // Insert depth>0 items between chat splits (deepest first = oldest position)
      for (final depth in depths) {
        if (depth == 0) continue;
        for (final item in byDepth[depth]!) {
          result.add(_toNativeItem(item, order++));
        }
      }

      // Chat item 2: recent N messages
      result.add({
        'role': 'chat',
        'content': '',
        'name': '채팅 이력 (최근)',
        'order': order++,
        'enabled': true,
        'chatSettingMode': 'advanced',
        'chatRangeType': 'recent',
        'recentChatCount': maxDepth,
      });
    } else {
      // No depth splitting needed, just a simple chat item
      result.add({
        'role': 'chat',
        'content': '',
        'name': '채팅 이력',
        'order': order++,
        'enabled': true,
        'chatSettingMode': 'basic',
        'chatRangeType': 'recent',
      });
    }

    // Insert depth=0 items after chat
    if (byDepth.containsKey(0)) {
      for (final item in byDepth[0]!) {
        result.add(_toNativeItem(item, order++));
      }
    }

    return order;
  }

  static Map<String, dynamic> _toNativeItem(_StPrompt stPrompt, int order) {
    return {
      'role': _mapRole(stPrompt.role),
      'content': stPrompt.content,
      'name': stPrompt.name,
      'order': order,
      'enabled': stPrompt.enabled,
      'chatSettingMode': 'basic',
      'chatRangeType': 'recent',
    };
  }

  /// Strip SillyTavern macros: {{// comments }}, {{trim}}, and other
  /// non-functional macros that should not appear in imported content.
  static String _stripMacros(String content) {
    return content
        .replaceAll(RegExp(r'\{\{//.*?\}\}'), '')
        .replaceAll(RegExp(r'\{\{trim\}\}'), '')
        .trim();
  }

  static String _mapRole(String stRole) {
    switch (stRole.toLowerCase()) {
      case 'user':
        return PromptRole.user.name;
      case 'assistant':
        return PromptRole.assistant.name;
      case 'system':
      default:
        return PromptRole.system.name;
    }
  }

  /// Build a map of identifier -> enabled from prompt_order.
  /// prompt_order's enabled value overrides the prompt's own enabled value.
  static Map<String, bool> _buildPromptEnabled(Map<String, dynamic> stJson) {
    final promptOrder = stJson['prompt_order'] as List<dynamic>?;
    if (promptOrder == null || promptOrder.isEmpty) return {};

    final enabledMap = <String, bool>{};
    List<dynamic>? bestOrderList;

    for (final entry in promptOrder) {
      final map = entry as Map<String, dynamic>;
      if (map.containsKey('order')) {
        final orderList = map['order'] as List<dynamic>? ?? [];
        if (bestOrderList == null || orderList.length > bestOrderList.length) {
          bestOrderList = orderList;
        }
      } else if (map.containsKey('identifier')) {
        for (final item in promptOrder) {
          final m = item as Map<String, dynamic>;
          final id = m['identifier'] as String?;
          if (id != null) {
            enabledMap[id] = m['enabled'] as bool? ?? true;
          }
        }
        return enabledMap;
      }
    }

    if (bestOrderList == null) return {};

    for (final item in bestOrderList) {
      final m = item as Map<String, dynamic>;
      final id = m['identifier'] as String?;
      if (id != null) {
        enabledMap[id] = m['enabled'] as bool? ?? true;
      }
    }
    return enabledMap;
  }

  /// Build a map of identifier -> order index from prompt_order.
  static Map<String, int> _buildPromptOrder(Map<String, dynamic> stJson) {
    final promptOrder = stJson['prompt_order'] as List<dynamic>?;
    if (promptOrder == null || promptOrder.isEmpty) return {};

    // prompt_order can be either:
    // 1. List of {identifier, enabled} objects
    // 2. List of {character_id, order: [{identifier, enabled}]} objects
    // Find the entry with the most items (most comprehensive ordering)
    List<dynamic>? bestOrderList;

    for (final entry in promptOrder) {
      final map = entry as Map<String, dynamic>;
      if (map.containsKey('order')) {
        // Format 2: {character_id, order: [...]}
        final orderList = map['order'] as List<dynamic>? ?? [];
        if (bestOrderList == null || orderList.length > bestOrderList.length) {
          bestOrderList = orderList;
        }
      } else if (map.containsKey('identifier')) {
        // Format 1: direct list — use the entire promptOrder as-is
        final orderMap = <String, int>{};
        for (final item in promptOrder) {
          final id = (item as Map<String, dynamic>)['identifier'] as String?;
          if (id != null) {
            orderMap[id] = orderMap.length;
          }
        }
        return orderMap;
      }
    }

    if (bestOrderList == null) return {};

    final orderMap = <String, int>{};
    for (int i = 0; i < bestOrderList.length; i++) {
      final item = bestOrderList[i] as Map<String, dynamic>;
      final id = item['identifier'] as String?;
      if (id != null) {
        orderMap[id] = i;
      }
    }
    return orderMap;
  }
}

class _StPrompt {
  final String identifier;
  final String? name;
  final String role;
  final String content;
  final bool enabled;
  final int injectionPosition;
  final int injectionDepth;
  final int injectionOrder;

  _StPrompt({
    required this.identifier,
    required this.name,
    required this.role,
    required this.content,
    required this.enabled,
    required this.injectionPosition,
    required this.injectionDepth,
    required this.injectionOrder,
  });
}
