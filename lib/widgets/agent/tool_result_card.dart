import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/agent/agent_tool.dart';

class ToolResultCard extends StatefulWidget {
  final String toolName;
  final AgentToolResult result;

  const ToolResultCard({
    super.key,
    required this.toolName,
    required this.result,
  });

  @override
  State<ToolResultCard> createState() => _ToolResultCardState();
}

class _ToolResultCardState extends State<ToolResultCard> {
  bool _isExpanded = false;

  static const _toolNames = {
    'list_characters': '캐릭터 목록 조회',
    'get_character': '캐릭터 상세 조회',
    'create_character': '캐릭터 생성',
    'update_character': '캐릭터 수정',
    'create_persona': '페르소나 생성',
    'update_persona': '페르소나 수정',
    'delete_persona': '페르소나 삭제',
    'create_start_scenario': '시작 시나리오 생성',
    'update_start_scenario': '시작 시나리오 수정',
    'delete_start_scenario': '시작 시나리오 삭제',
    'create_character_book': '캐릭터북 생성',
    'update_character_book': '캐릭터북 수정',
    'delete_character_book': '캐릭터북 삭제',
  };

  static const _toolIcons = {
    'list_characters': Icons.list,
    'get_character': Icons.person_search,
    'create_character': Icons.person_add,
    'update_character': Icons.edit,
    'create_persona': Icons.add_circle_outline,
    'update_persona': Icons.edit_note,
    'delete_persona': Icons.delete_outline,
    'create_start_scenario': Icons.play_circle_outline,
    'update_start_scenario': Icons.play_circle,
    'delete_start_scenario': Icons.delete_outline,
    'create_character_book': Icons.menu_book,
    'update_character_book': Icons.auto_stories,
    'delete_character_book': Icons.delete_outline,
  };

  String get _toolDisplayName =>
      _toolNames[widget.toolName] ?? widget.toolName;

  IconData get _toolIcon {
    if (!widget.result.success) return Icons.error_outline;
    return _toolIcons[widget.toolName] ?? Icons.build;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final success = widget.result.success;
    final color = success
        ? theme.colorScheme.primary
        : theme.colorScheme.error;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        onTap: widget.result.data != null
            ? () => setState(() => _isExpanded = !_isExpanded)
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(_toolIcon, size: 16, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$_toolDisplayName: ${widget.result.message}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (widget.result.data != null)
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 16,
                      color: color.withValues(alpha: 0.6),
                    ),
                ],
              ),
            ),
            if (_isExpanded && widget.result.data != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Text(
                  const JsonEncoder.withIndent('  ').convert(widget.result.data),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
