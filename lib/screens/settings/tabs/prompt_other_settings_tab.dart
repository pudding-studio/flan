import 'package:flutter/material.dart';
import '../../../constants/ui_constants.dart';
import '../../../models/prompt/prompt_condition.dart';
import '../../../models/prompt/prompt_condition_option.dart';
import '../../../models/prompt/prompt_condition_preset.dart';
import '../../../models/prompt/prompt_condition_preset_value.dart';
import '../../../widgets/common/common_dropdown_button.dart';
import '../../../widgets/common/common_editable_expandable_item.dart';
import '../../../widgets/common/common_edit_text.dart';
import '../../../widgets/common/common_title_medium.dart';

class PromptOtherSettingsTab extends StatefulWidget {
  final List<PromptConditionPreset> presets;
  final List<PromptCondition> conditions;
  final bool readOnly;
  final VoidCallback onUpdate;
  final void Function(PromptConditionPreset) onDeletePreset;
  final VoidCallback onAddPreset;
  final bool presetsSectionExpanded;
  final VoidCallback onPresetsSectionToggle;

  const PromptOtherSettingsTab({
    super.key,
    required this.presets,
    required this.conditions,
    this.readOnly = false,
    required this.onUpdate,
    required this.onDeletePreset,
    required this.onAddPreset,
    required this.presetsSectionExpanded,
    required this.onPresetsSectionToggle,
  });

  @override
  State<PromptOtherSettingsTab> createState() => _PromptOtherSettingsTabState();
}

class _PromptOtherSettingsTabState extends State<PromptOtherSettingsTab> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(UIConstants.spacing20),
      child: ListView(
        children: [
          _buildPresetsSection(),
        ],
      ),
    );
  }

  Widget _buildPresetsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context),
        if (widget.presetsSectionExpanded) ...[
          const SizedBox(height: 8),
          ...widget.presets.map(
            (preset) => _PresetCard(
              key: ValueKey(preset.id),
              preset: preset,
              presets: widget.presets,
              conditions: widget.conditions,
              onUpdate: () {
                setState(() {});
                widget.onUpdate();
              },
              onDelete: () => widget.onDeletePreset(preset),
              readOnly: widget.readOnly,
            ),
          ),
          if (!widget.readOnly) _buildAddButton(),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return InkWell(
      onTap: widget.onPresetsSectionToggle,
      borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        child: Row(
          children: [
            const CommonTitleMedium(
              text: '프롬프트 조건 프리셋',
              helpMessage: '프롬프트 조건의 값을 미리 설정해둔 프리셋입니다.\n\n'
                  '채팅 시 프리셋을 선택하면 조건 값이 일괄 적용됩니다.',
            ),
            const Spacer(),
            Icon(
              widget.presetsSectionExpanded
                  ? Icons.expand_less
                  : Icons.expand_more,
              size: UIConstants.iconSizeLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: widget.onAddPreset,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('프리셋 추가'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(UIConstants.borderRadiusMedium),
            ),
          ),
        ),
      ),
    );
  }
}

class _PresetCard extends StatefulWidget {
  final PromptConditionPreset preset;
  final List<PromptConditionPreset> presets;
  final List<PromptCondition> conditions;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;
  final bool readOnly;

  const _PresetCard({
    super.key,
    required this.preset,
    required this.presets,
    required this.conditions,
    required this.onUpdate,
    required this.onDelete,
    this.readOnly = false,
  });

  @override
  State<_PresetCard> createState() => _PresetCardState();
}

class _PresetCardState extends State<_PresetCard> {
  final Map<int, TextEditingController> _customValueControllers = {};

  @override
  void dispose() {
    for (var controller in _customValueControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  PromptConditionPresetValue? _getValueForCondition(int? conditionId) {
    if (conditionId == null) return null;
    try {
      return widget.preset.values.firstWhere(
        (v) => v.conditionId == conditionId,
      );
    } catch (_) {
      return null;
    }
  }

  void _setValueForCondition(PromptCondition condition, String value, {String? customValue}) {
    setState(() {
      final existingIndex = widget.preset.values.indexWhere(
        (v) => v.conditionId == condition.id,
      );

      final presetValue = PromptConditionPresetValue(
        conditionId: condition.id,
        value: value,
        customValue: customValue,
      );

      if (existingIndex != -1) {
        widget.preset.values[existingIndex] = presetValue;
      } else {
        widget.preset.values.add(presetValue);
      }
    });
    widget.onUpdate();
  }

  TextEditingController _getCustomValueController(int conditionId, String? initialValue) {
    if (!_customValueControllers.containsKey(conditionId)) {
      _customValueControllers[conditionId] = TextEditingController(text: initialValue ?? '');
    }
    return _customValueControllers[conditionId]!;
  }

  @override
  Widget build(BuildContext context) {
    final preset = widget.preset;

    return CommonEditableExpandableItem(
      key: ValueKey(preset.id),
      icon: Icon(
        Icons.playlist_play_outlined,
        size: UIConstants.iconSizeMedium,
        color: Theme.of(context).colorScheme.secondary,
      ),
      name: preset.name.isEmpty ? '새 프리셋' : preset.name,
      isExpanded: preset.isExpanded,
      onToggleExpanded: () {
        if (preset.isExpanded) {
          FocusScope.of(context).unfocus();
        }
        setState(() {
          preset.isExpanded = !preset.isExpanded;
        });
        widget.onUpdate();
      },
      onDelete: widget.readOnly || preset.isDefault ? () {} : widget.onDelete,
      showDeleteButton: !widget.readOnly && !preset.isDefault,
      showNameField: false,
      content: _buildContent(preset),
    );
  }

  Widget _buildContent(PromptConditionPreset preset) {
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('이름', style: labelStyle),
        const SizedBox(height: 6),
        CommonEditText(
          size: CommonEditTextSize.small,
          hintText: '프리셋 이름',
          initialValue: preset.name,
          enabled: !preset.isDefault && !widget.readOnly,
          onFocusLost: (value) {
            if (value.trim().isNotEmpty) {
              final idx = widget.presets.indexOf(widget.preset);
              if (idx != -1) {
                widget.presets[idx] = widget.preset.copyWith(name: value.trim());
              }
              widget.onUpdate();
            }
          },
        ),
        if (widget.conditions.isNotEmpty) ...[
          const SizedBox(height: UIConstants.spacing16),
          Text('조건 목록', style: labelStyle),
          const SizedBox(height: 8),
          ...widget.conditions.map((condition) => _buildConditionRow(condition)),
        ],
      ],
    );
  }

  Widget _buildConditionRow(PromptCondition condition) {
    switch (condition.type) {
      case ConditionType.toggle:
        return _buildToggleRow(condition);
      case ConditionType.singleSelect:
        return _buildSingleSelectRow(condition);
      case ConditionType.variable:
        return _buildVariableRow(condition);
    }
  }

  Widget _buildToggleRow(PromptCondition condition) {
    final presetValue = _getValueForCondition(condition.id);
    final isOn = presetValue?.value == 'true';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              condition.name.isEmpty ? '이름 없음' : condition.name,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          SizedBox(
            height: 24,
            child: Transform.scale(
              scale: 0.75,
              child: Switch(
                value: isOn,
                onChanged: widget.readOnly
                    ? null
                    : (value) {
                        _setValueForCondition(
                          condition,
                          value ? 'true' : 'false',
                        );
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleSelectRow(PromptCondition condition) {
    final presetValue = _getValueForCondition(condition.id);

    final selectedOption = condition.options.cast<PromptConditionOption?>().firstWhere(
      (o) => o!.name == presetValue?.value,
      orElse: () => null,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            condition.name.isEmpty ? '이름 없음' : condition.name,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          CommonDropdownButton<PromptConditionOption>(
            value: selectedOption,
            items: condition.options,
            size: CommonDropdownButtonSize.xsmall,
            hintText: '항목을 선택하세요',
            onChanged: widget.readOnly
                ? null
                : (value) {
                    if (value != null) {
                      _setValueForCondition(condition, value.name);
                    }
                  },
            labelBuilder: (o) => o.name,
          ),
        ],
      ),
    );
  }

  Widget _buildVariableRow(PromptCondition condition) {
    final presetValue = _getValueForCondition(condition.id);
    final isCustom = presetValue?.value == PromptConditionPresetValue.customOptionKey;

    // Build items list with "기타" appended
    final optionsWithCustom = [
      ...condition.options,
      PromptConditionOption(id: -9999, name: '기타', order: condition.options.length),
    ];

    PromptConditionOption? selectedOption;
    if (isCustom) {
      selectedOption = optionsWithCustom.last;
    } else if (presetValue != null) {
      selectedOption = optionsWithCustom.cast<PromptConditionOption?>().firstWhere(
        (o) => o!.name == presetValue.value && o.id != -9999,
        orElse: () => null,
      );
    }

    final customController = _getCustomValueController(
      condition.id!,
      presetValue?.customValue,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            condition.name.isEmpty ? '이름 없음' : condition.name,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          CommonDropdownButton<PromptConditionOption>(
            value: selectedOption,
            items: optionsWithCustom,
            size: CommonDropdownButtonSize.xsmall,
            hintText: '항목을 선택하세요',
            onChanged: widget.readOnly
                ? null
                : (value) {
                    if (value != null) {
                      if (value.id == -9999) {
                        _setValueForCondition(
                          condition,
                          PromptConditionPresetValue.customOptionKey,
                          customValue: customController.text,
                        );
                      } else {
                        _setValueForCondition(condition, value.name);
                        // Clear custom controller when switching away
                        customController.clear();
                      }
                    }
                  },
            labelBuilder: (o) => o.name,
          ),
          if (isCustom) ...[
            const SizedBox(height: 6),
            Text(
              '직접입력',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            CommonEditText(
              controller: customController,
              size: CommonEditTextSize.small,
              hintText: '값을 입력하세요',
              enabled: !widget.readOnly,
              onFocusLost: (value) {
                _setValueForCondition(
                  condition,
                  PromptConditionPresetValue.customOptionKey,
                  customValue: value.trim(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
