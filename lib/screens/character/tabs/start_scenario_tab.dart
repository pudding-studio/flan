import 'package:flutter/material.dart';

import '../../../constants/ui_constants.dart';
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

  void _notifyUpdate() {
    widget.onUpdate();
    setState(() {});
  }

  void _addStartScenario() {
    setState(() {
      final newScenario = StartScenario(
        id: _getNextTempId(),
        characterId: -1, // Will be set when saving
        name: '새 시작설정',
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
    return Padding(
      padding: const EdgeInsets.all(UIConstants.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 5),
            child: CommonTitleMedium(
              text: '시작설정',
              helpMessage: '대화의 시작 설정 정보를 추가할 수 있습니다.',
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: widget.startScenarios.isEmpty
                ? const Center(
                    child: Text('시작설정 항목이 없습니다'),
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
              label: '시작설정 추가',
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
        setState(() {
          scenario.isExpanded = !scenario.isExpanded;
        });
      },
      onDelete: () => _deleteStartScenario(scenario),
      nameHint: '시작설정 이름',
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
    final key = 'scenario_${scenario.id}_start_setting';
    final controller = _getFieldController(key, scenario.startSetting ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '시작 설정',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    content: const Text('해당 내용은 요약 이전에 삽입되고 삭제되지 않습니다.'),
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
                size: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        CommonEditText(
          controller: controller,
          hintText: '시작 설정 내용을 입력해주세요',
          size: CommonEditTextSize.small,
          maxLines: null,
          minLines: 5,
          onChanged: (value) {
            scenario.startSetting = value;
            _notifyUpdate();
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildStartMessageField(StartScenario scenario) {
    final key = 'scenario_${scenario.id}_start_message';
    final controller = _getFieldController(key, scenario.startMessage ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '시작 메시지',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 2),
        CommonEditText(
          controller: controller,
          hintText: '시작 메시지를 입력해주세요',
          size: CommonEditTextSize.small,
          maxLines: null,
          minLines: 5,
          onChanged: (value) {
            scenario.startMessage = value;
            _notifyUpdate();
          },
        ),
      ],
    );
  }
}
