import 'package:flutter/material.dart';

import '../../../constants/ui_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/character/persona.dart';
import '../../../utils/common_dialog.dart';
import '../../../widgets/common/common_button.dart';
import '../../../widgets/common/common_editable_expandable_item.dart';
import '../../../widgets/common/common_edit_text.dart';
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

  void _notifyUpdate({bool rebuildUI = true}) {
    widget.onUpdate();
    if (rebuildUI) {
      setState(() {});
    }
  }

  void _addPersona() {
    final l10n = AppLocalizations.of(context);
    setState(() {
      final newPersona = Persona(
        id: _getNextTempId(),
        characterId: -1, // Will be set when saving
        name: l10n.personaNewName,
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
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(UIConstants.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: CommonTitleMedium(
              text: l10n.personaTitle,
              helpMessage: l10n.personaTitleHelp,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: widget.personas.isEmpty
                ? Center(
                    child: Text(l10n.personaEmpty),
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
            child: CommonButton.filled(
              onPressed: _addPersona,
              icon: Icons.add,
              label: l10n.personaAddButton,
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
        if (persona.isExpanded) {
          FocusScope.of(context).unfocus();
        }
        setState(() {
          persona.isExpanded = !persona.isExpanded;
        });
      },
      onDelete: () => _deletePersona(persona),
      nameHint: AppLocalizations.of(context).personaNameHint,
      onNameChanged: (value) {
        persona.name = value;
        _notifyUpdate();
      },
      content: _buildPersonaContentField(persona),
    );
  }

  Widget _buildPersonaContentField(Persona persona) {
    final l10n = AppLocalizations.of(context);
    final key = 'persona_${persona.id}_content';
    final controller = _getFieldController(key, persona.content ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.personaContentLabel,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 2),
        CommonEditText(
          controller: controller,
          hintText: l10n.personaContentHint,
          size: CommonEditTextSize.small,
          maxLines: null,
          minLines: 5,
          onFocusLost: (value) {
            persona.content = value;
            _notifyUpdate(rebuildUI: false);
          },
        ),
      ],
    );
  }
}
