import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../database/database_helper.dart';
import 'agent_tool.dart';
import 'agent_tools.dart';

class ToolCall {
  final String toolName;
  final Map<String, dynamic> args;

  const ToolCall({required this.toolName, required this.args});
}

class ParsedResponse {
  final String conversationText;
  final List<ToolCall> toolCalls;

  const ParsedResponse({
    required this.conversationText,
    required this.toolCalls,
  });

  bool get hasToolCalls => toolCalls.isNotEmpty;
}

class AgentExecutor {
  final Map<String, AgentTool> _tools = {};

  AgentExecutor(DatabaseHelper db) {
    _registerTools(db);
  }

  void _registerTools(DatabaseHelper db) {
    final tools = <AgentTool>[
      ListCharactersTool(db),
      GetCharacterTool(db),
      CreateCharacterTool(db),
      UpdateCharacterTool(db),
      CreatePersonaTool(db),
      UpdatePersonaTool(db),
      DeletePersonaTool(db),
      CreateStartScenarioTool(db),
      UpdateStartScenarioTool(db),
      DeleteStartScenarioTool(db),
      CreateCharacterBookTool(db),
      UpdateCharacterBookTool(db),
      DeleteCharacterBookTool(db),
    ];
    for (final tool in tools) {
      _tools[tool.name] = tool;
    }
  }

  List<Map<String, dynamic>> get toolSchemas =>
      _tools.values.map((t) => t.toSchema()).toList();

  ParsedResponse parseResponse(String text) {
    final toolCalls = <ToolCall>[];
    final conversationParts = <String>[];

    final pattern = RegExp(r'```tool_call\s*\n([\s\S]*?)```', multiLine: true);
    int lastEnd = 0;

    for (final match in pattern.allMatches(text)) {
      // Collect conversation text before this tool call
      final before = text.substring(lastEnd, match.start).trim();
      if (before.isNotEmpty) conversationParts.add(before);
      lastEnd = match.end;

      final jsonStr = match.group(1)!.trim();
      try {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        final toolName = json['tool'] as String;
        final args = (json['args'] as Map<String, dynamic>?) ?? {};
        toolCalls.add(ToolCall(toolName: toolName, args: args));
      } catch (e) {
        debugPrint('Failed to parse tool call JSON: $e');
        conversationParts.add(jsonStr);
      }
    }

    // Collect remaining text after last tool call
    final remaining = text.substring(lastEnd).trim();
    if (remaining.isNotEmpty) conversationParts.add(remaining);

    return ParsedResponse(
      conversationText: conversationParts.join('\n\n'),
      toolCalls: toolCalls,
    );
  }

  Future<AgentToolResult> executeToolCall(ToolCall call) async {
    final tool = _tools[call.toolName];
    if (tool == null) {
      return AgentToolResult(
        success: false,
        message: '알 수 없는 도구: ${call.toolName}',
      );
    }

    try {
      return await tool.execute(call.args);
    } catch (e) {
      debugPrint('Tool execution error (${call.toolName}): $e');
      return AgentToolResult(
        success: false,
        message: '도구 실행 중 오류: $e',
      );
    }
  }
}
