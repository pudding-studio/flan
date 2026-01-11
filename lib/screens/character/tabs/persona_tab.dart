import 'package:flutter/material.dart';

import '../../../constants/ui_constants.dart';
import '../../../models/character/persona.dart';

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

  int? _editingPersonaId;
  final Map<int, TextEditingController> _editControllers = {};
  final Map<String, TextEditingController> _fieldControllers = {};

  int _nextTempId = -1;
  int _getNextTempId() => _nextTempId--;

  @override
  void dispose() {
    for (var controller in _editControllers.values) {
      controller.dispose();
    }
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

  void _deletePersona(Persona persona) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('페르소나 삭제'),
        content: Text('${persona.name}을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                widget.personas.remove(persona);
              });
              _notifyUpdate();
              Navigator.pop(context);
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _togglePersonaEdit(Persona persona) {
    setState(() {
      if (_editingPersonaId == persona.id) {
        final controller = _editControllers[persona.id!];
        if (controller != null && controller.text.isNotEmpty) {
          persona.name = controller.text;
        }
        _editingPersonaId = null;
        _editControllers.remove(persona.id!)?.dispose();
        _notifyUpdate();
      } else {
        _editingPersonaId = persona.id;
        _editControllers[persona.id!] = TextEditingController(text: persona.name);
      }
    });
  }

  void _savePersonaName(Persona persona, String value) {
    setState(() {
      if (value.isNotEmpty) {
        persona.name = value;
      }
      _editingPersonaId = null;
      _editControllers.remove(persona.id!)?.dispose();
    });
    _notifyUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(UIConstants.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '페르소나',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        content: const Text('캐릭터의 페르소나 정보를 추가할 수 있습니다.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('확인'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Icon(
                    Icons.help_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
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
                    child: _editingPersonaId == persona.id
                        ? TextField(
                            controller: _editControllers[persona.id!],
                            style: Theme.of(context).textTheme.bodyMedium,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            autofocus: true,
                            onSubmitted: (value) => _savePersonaName(persona, value),
                          )
                        : Text(
                            persona.name,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                  ),
                  GestureDetector(
                    onTap: () => _togglePersonaEdit(persona),
                    child: Icon(
                      _editingPersonaId == persona.id ? Icons.check : Icons.edit_outlined,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
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
              padding: const EdgeInsets.all(6),
              child: _buildPersonaContentField(persona),
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
