import 'package:flutter/material.dart';

import '../../../constants/ui_constants.dart';
import '../../../models/character/start_scenario.dart';

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
  static const double _lorebookItemHorizontalPadding = 10.0;
  static const double _lorebookItemVerticalPadding = 10.0;

  int? _editingStartScenarioId;
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

  void _deleteStartScenario(StartScenario scenario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('시작설정 삭제'),
        content: Text('${scenario.name}을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                widget.startScenarios.remove(scenario);
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

  void _toggleStartScenarioEdit(StartScenario scenario) {
    setState(() {
      if (_editingStartScenarioId == scenario.id) {
        final controller = _editControllers[scenario.id!];
        if (controller != null && controller.text.isNotEmpty) {
          scenario.name = controller.text;
        }
        _editingStartScenarioId = null;
        _editControllers.remove(scenario.id!)?.dispose();
        _notifyUpdate();
      } else {
        _editingStartScenarioId = scenario.id;
        _editControllers[scenario.id!] = TextEditingController(text: scenario.name);
      }
    });
  }

  void _saveStartScenarioName(StartScenario scenario, String value) {
    setState(() {
      if (value.isNotEmpty) {
        scenario.name = value;
      }
      _editingStartScenarioId = null;
      _editControllers.remove(scenario.id!)?.dispose();
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
                  '시작설정',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        content: const Text('대화의 시작 설정 정보를 추가할 수 있습니다.'),
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
            child: FilledButton.icon(
              onPressed: _addStartScenario,
              icon: const Icon(Icons.add),
              label: const Text('시작설정 추가'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartScenarioItem(StartScenario scenario) {
    return Container(
      key: ValueKey(scenario.id),
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
                scenario.isExpanded = !scenario.isExpanded;
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
                    Icons.play_circle_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _editingStartScenarioId == scenario.id
                        ? TextField(
                            controller: _editControllers[scenario.id!],
                            style: Theme.of(context).textTheme.bodyMedium,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            autofocus: true,
                            onSubmitted: (value) => _saveStartScenarioName(scenario, value),
                          )
                        : Text(
                            scenario.name,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                  ),
                  GestureDetector(
                    onTap: () => _toggleStartScenarioEdit(scenario),
                    child: Icon(
                      _editingStartScenarioId == scenario.id ? Icons.check : Icons.edit_outlined,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _deleteStartScenario(scenario),
                    child: const Icon(Icons.delete_outline, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    scenario.isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (scenario.isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStartSettingField(scenario),
                  _buildStartMessageField(scenario),
                ],
              ),
            ),
          ],
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
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: '시작 설정 내용을 입력해주세요',
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
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: '시작 메시지를 입력해주세요',
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
            scenario.startMessage = value;
            _notifyUpdate();
          },
        ),
      ],
    );
  }
}
