import 'dart:convert';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
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

  String _localizedToolName(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (widget.toolName) {
      case 'list_characters': return l10n.toolListCharacters;
      case 'get_character': return l10n.toolGetCharacter;
      case 'create_character': return l10n.toolCreateCharacter;
      case 'update_character': return l10n.toolUpdateCharacter;
      case 'create_persona': return l10n.toolCreatePersona;
      case 'update_persona': return l10n.toolUpdatePersona;
      case 'delete_persona': return l10n.toolDeletePersona;
      case 'create_start_scenario': return l10n.toolCreateStartScenario;
      case 'update_start_scenario': return l10n.toolUpdateStartScenario;
      case 'delete_start_scenario': return l10n.toolDeleteStartScenario;
      case 'create_character_book': return l10n.toolCreateCharacterBook;
      case 'update_character_book': return l10n.toolUpdateCharacterBook;
      case 'delete_character_book': return l10n.toolDeleteCharacterBook;
      default: return widget.toolName;
    }
  }

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
                      '${_localizedToolName(context)}: ${widget.result.message}',
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
