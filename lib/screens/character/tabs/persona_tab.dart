import 'package:flutter/material.dart';

import '../../../constants/ui_constants.dart';
import '../../../models/character/persona.dart';
import '../../../utils/common_dialog.dart';
import '../../../widgets/label_with_help.dart';

class PersonaTab extends StatefulWidget {
  final List<Persona> personas;
  final VoidCallback onUpdate;

  const PersonaTab({
    super.key,
    required this.personas,
    required this.onUpdate,
  });

  @override
  State<PersonaTab> createState() => _PersonaTabState();
}

class _PersonaTabState extends State<PersonaTab> {
  static const double _lorebookItemHorizontalPadding = 10.0;
  static const double _lorebookItemVerticalPadding = 10.0;

  final Map<String, TextEditingController> _fieldControllers = {};

  int _nextTempId = -1;
  int _getNextTempId() => _nextTempId--;

  @override
  void dispose() {
    for (var controller in _fieldControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _getFieldController(String key, String initialValue) {
    if (!_fieldControllers.containsKey(key)) {
      _fieldControllers[key] = TextEditingController(text: initialValue);
    }
    return _fieldControllers[key]!;
  }

  void _notifyUpdate() {
    widget.onUpdate();
    setState(() {});
  }

  void _addPersona() {
    setState(() {
      final newPersona = Persona(
        id: _getNextTempId(),
        characterId: -1, // Will be set when saving
        name: '새 페르소나',
        order: widget.personas.length,
        isExpanded: true,
      );
      widget.personas.add(newPersona);
    });
    _notifyUpdate();
  }

  Future<void> _deletePersona(Persona persona) async {
    final confirmed = await CommonDialog.showDeleteConfirmation(
      context: context,
      itemName: persona.name,
    );

    if (confirmed) {
      setState(() {
        widget.personas.remove(persona);
      });
      _notifyUpdate();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(UIConstants.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 5),
            child: LabelWithHelp(
              label: '페르소나',
              helpMessage: '캐릭터의 페르소나 정보를 추가할 수 있습니다.',
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: widget.personas.isEmpty
                ? const Center(
                    child: Text('페르소나 항목이 없습니다'),
                  )
                : ListView.builder(
                    itemCount: widget.personas.length,
                    itemBuilder: (context, index) {
                      return _buildPersonaItem(widget.personas[index]);
                    },
                  ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _addPersona,
              icon: const Icon(Icons.add),
              label: const Text('페르소나 추가'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonaItem(Persona persona) {
    return Container(
      key: ValueKey(persona.id),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                persona.isExpanded = !persona.isExpanded;
              });
            },
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: _lorebookItemHorizontalPadding,
                vertical: _lorebookItemVerticalPadding,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      persona.name,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _deletePersona(persona),
                    child: const Icon(Icons.delete_outline, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    persona.isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (persona.isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '이름',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    initialValue: persona.name,
                    decoration: InputDecoration(
                      hintText: '페르소나 이름',
                      hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      isDense: true,
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                    onChanged: (value) {
                      if (value.trim().isNotEmpty) {
                        persona.name = value.trim();
                        _notifyUpdate();
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildPersonaContentField(persona),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonaContentField(Persona persona) {
    final key = 'persona_${persona.id}_content';
    final controller = _getFieldController(key, persona.content ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '내용',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 2),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: '페르소나 내용을 입력해주세요',
            hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
          ),
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: null,
          minLines: 5,
          onChanged: (value) {
            persona.content = value;
            _notifyUpdate();
          },
        ),
      ],
    );
  }
}
