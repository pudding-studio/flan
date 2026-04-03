import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../database/database_helper.dart';
import '../../models/chat/chat_message.dart';
import '../../models/chat/unified_model.dart';
import '../ai_service.dart';
import 'agent_executor.dart';
import 'agent_tool.dart';

class AgentMessage {
  final String text;
  final List<AgentToolResult> toolResults;
  final UsageMetadata? usageMetadata;

  const AgentMessage({
    required this.text,
    this.toolResults = const [],
    this.usageMetadata,
  });
}

class AgentService {
  static const int maxToolIterations = 5;
  static const String _promptAssetPath =
      'assets/defaults/agent_prompts/system_prompt.txt';

  final AiService _aiService = AiService();
  final AgentExecutor _executor;
  String? _cachedPromptTemplate;

  AgentService(DatabaseHelper db) : _executor = AgentExecutor(db);

  Future<String> buildSystemPrompt() async {
    _cachedPromptTemplate ??= await rootBundle.loadString(_promptAssetPath);

    final toolDescriptions = _executor.toolSchemas.map((schema) {
      final params = (schema['parameters'] as List)
          .map((p) {
            final req = p['required'] == true ? ' (required)' : ' (optional)';
            return '    - ${p['name']} (${p['type']}): ${p['description']}$req';
          })
          .join('\n');
      final paramSection = params.isNotEmpty ? '\n  Parameters:\n$params' : '';
      return '- ${schema['name']}: ${schema['description']}$paramSection';
    }).join('\n\n');

    return _cachedPromptTemplate!.replaceAll('{{tools}}', toolDescriptions);
  }

  Future<AgentMessage> sendMessage({
    required String userText,
    required List<ChatMessage> chatHistory,
    required UnifiedModel model,
  }) async {
    final contents = _buildContents(chatHistory, userText);
    return _executeLoop(contents, model);
  }

  List<Map<String, dynamic>> _buildContents(
    List<ChatMessage> history,
    String userText,
  ) {
    final contents = <Map<String, dynamic>>[];

    for (final msg in history) {
      final role = msg.role == MessageRole.user ? 'user' : 'model';
      contents.add({
        'role': role,
        'parts': [{'text': msg.content}],
      });
    }

    contents.add({
      'role': 'user',
      'parts': [{'text': userText}],
    });

    return contents;
  }

  Future<AgentMessage> _executeLoop(
    List<Map<String, dynamic>> contents,
    UnifiedModel model,
  ) async {
    final allToolResults = <AgentToolResult>[];
    UsageMetadata? lastUsage;
    final systemPrompt = await buildSystemPrompt();

    for (int i = 0; i < maxToolIterations; i++) {
      final response = await _aiService.sendMessage(
        systemPrompt: systemPrompt,
        contents: contents,
        model: model,
        logType: 'agent',
      );

      lastUsage = response.usageMetadata;
      final parsed = _executor.parseResponse(response.text);

      if (!parsed.hasToolCalls) {
        return AgentMessage(
          text: parsed.conversationText.isNotEmpty
              ? parsed.conversationText
              : response.text,
          toolResults: allToolResults,
          usageMetadata: lastUsage,
        );
      }

      // Execute tool calls and build results
      final resultTexts = <String>[];
      for (final call in parsed.toolCalls) {
        final result = await _executor.executeToolCall(call);
        allToolResults.add(result);
        resultTexts.add(
          '[Tool: ${call.toolName}] ${result.toJsonString()}',
        );
      }

      // Append AI response (with tool calls) as model turn
      contents.add({
        'role': 'model',
        'parts': [{'text': response.text}],
      });

      // Append tool results as user turn
      contents.add({
        'role': 'user',
        'parts': [{'text': 'Tool execution results:\n${resultTexts.join('\n')}'}],
      });
    }

    // Max iterations reached
    debugPrint('Agent reached max tool iterations ($maxToolIterations)');
    return AgentMessage(
      text: '도구 실행 횟수가 최대치에 도달했습니다. 요청을 다시 시도해 주세요.',
      toolResults: allToolResults,
      usageMetadata: lastUsage,
    );
  }
}
