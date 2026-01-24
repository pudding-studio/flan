import 'package:flutter/material.dart';

import '../../../constants/ui_constants.dart';
import '../../../models/character/persona.dart';
import '../../../utils/common_dialog.dart';
import '../../../widgets/common/common_editable_expandable_item.dart';
import '../../../widgets/common/common_title_medium.dart';

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
            child: CommonTitleMediumWithHelp(
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
    return CommonEditableExpandableItem(
      key: ValueKey(persona.id),
      icon: Icon(
        Icons.person_outline,
        size: UIConstants.iconSizeMedium,
        color: Theme.of(context).colorScheme.secondary,
      ),
      name: persona.name,
      isExpanded: persona.isExpanded,
      onToggleExpanded: () {
        setState(() {
          persona.isExpanded = !persona.isExpanded;
        });
      },
      onDelete: () => _deletePersona(persona),
      nameHint: '페르소나 이름',
      onNameChanged: (value) {
        persona.name = value;
        _notifyUpdate();
      },
      content: _buildPersonaContentField(persona),
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
