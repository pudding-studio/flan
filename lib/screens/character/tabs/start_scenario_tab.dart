import 'package:flutter/material.dart';

import '../../../constants/ui_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/character/start_scenario.dart';
import '../../../utils/common_dialog.dart';
import '../../../widgets/common/common_button.dart';
import '../../../widgets/common/common_editable_expandable_item.dart';
import '../../../widgets/common/common_edit_text.dart';
import '../../../widgets/common/common_title_medium.dart';

class StartScenarioTab extends StatefulWidget {
  final List<StartScenario> startScenarios;
  final VoidCallback onUpdate;

  const StartScenarioTab({
    super.key,
    required this.startScenarios,
    required this.onUpdate,
  });

  @override
  State<StartScenarioTab> createState() => _StartScenarioTabState();
}

class _StartScenarioTabState extends State<StartScenarioTab> {
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

  void _addStartScenario() {
    final l10n = AppLocalizations.of(context);
    setState(() {
      final newScenario = StartScenario(
        id: _getNextTempId(),
        characterId: -1, // Will be set when saving
        name: l10n.startScenarioNewName,
        order: widget.startScenarios.length,
        isExpanded: true,
      );
      widget.startScenarios.add(newScenario);
    });
    _notifyUpdate();
  }

  Future<void> _deleteStartScenario(StartScenario scenario) async {
    final confirmed = await CommonDialog.showDeleteConfirmation(
      context: context,
      itemName: scenario.name,
    );

    if (confirmed) {
      setState(() {
        widget.startScenarios.remove(scenario);
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
              text: l10n.startScenarioTitle,
              helpMessage: l10n.startScenarioTitleHelp,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: widget.startScenarios.isEmpty
                ? Center(
                    child: Text(l10n.startScenarioEmpty),
                  )
                : ListView.builder(
                    itemCount: widget.startScenarios.length,
                    itemBuilder: (context, index) {
                      return _buildStartScenarioItem(widget.startScenarios[index]);
                    },
                  ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CommonButton.filled(
              onPressed: _addStartScenario,
              icon: Icons.add,
              label: l10n.startScenarioAddButton,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartScenarioItem(StartScenario scenario) {
    return CommonEditableExpandableItem(
      key: ValueKey(scenario.id),
      icon: Icon(
        Icons.play_circle_outline,
        size: UIConstants.iconSizeMedium,
        color: Theme.of(context).colorScheme.secondary,
      ),
      name: scenario.name,
      isExpanded: scenario.isExpanded,
      onToggleExpanded: () {
        if (scenario.isExpanded) {
          FocusScope.of(context).unfocus();
        }
        setState(() {
          scenario.isExpanded = !scenario.isExpanded;
        });
      },
      onDelete: () => _deleteStartScenario(scenario),
      nameHint: AppLocalizations.of(context).startScenarioNameHint,
      onNameChanged: (value) {
        scenario.name = value;
        _notifyUpdate();
      },
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStartSettingField(scenario),
          _buildStartMessageField(scenario),
        ],
      ),
    );
  }

  Widget _buildStartSettingField(StartScenario scenario) {
    final l10n = AppLocalizations.of(context);
    final key = 'scenario_${scenario.id}_start_setting';
    final controller = _getFieldController(key, scenario.startSetting ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.startScenarioStartSettingLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    final dialogL10n = AppLocalizations.of(context);
                    return AlertDialog(
                      content: Text(dialogL10n.startScenarioStartSettingInfo),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(dialogL10n.commonConfirm),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Icon(
                Icons.help_outline,
                size: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        CommonEditText(
          controller: controller,
          hintText: l10n.startScenarioStartSettingHint,
          size: CommonEditTextSize.small,
          maxLines: null,
          minLines: 5,
          onFocusLost: (value) {
            scenario.startSetting = value;
            _notifyUpdate(rebuildUI: false);
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildStartMessageField(StartScenario scenario) {
    final l10n = AppLocalizations.of(context);
    final key = 'scenario_${scenario.id}_start_message';
    final controller = _getFieldController(key, scenario.startMessage ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.startScenarioStartMessageLabel,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 2),
        CommonEditText(
          controller: controller,
          hintText: l10n.startScenarioStartMessageHint,
          size: CommonEditTextSize.small,
          maxLines: null,
          minLines: 5,
          onFocusLost: (value) {
            scenario.startMessage = value;
            _notifyUpdate(rebuildUI: false);
          },
        ),
      ],
    );
  }
}
