import 'package:flutter/material.dart';
import '../../../constants/ui_constants.dart';
import '../../../models/prompt/prompt_condition.dart';
import '../../../models/prompt/prompt_condition_option.dart';
import '../../../widgets/common/common_dropdown_button.dart';
import '../../../widgets/common/common_editable_expandable_item.dart';
import '../../../widgets/common/common_edit_text.dart';
import '../../../widgets/common/common_title_medium.dart';

class PromptConditionsSection extends StatefulWidget {
  final List<PromptCondition> conditions;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onAddCondition;
  final void Function(PromptCondition) onDeleteCondition;
  final VoidCallback onUpdate;
  final int Function() getNextOptionTempId;
  final bool readOnly;

  const PromptConditionsSection({
    super.key,
    required this.conditions,
    required this.isExpanded,
    required this.onToggle,
    required this.onAddCondition,
    required this.onDeleteCondition,
    required this.onUpdate,
    required this.getNextOptionTempId,
    this.readOnly = false,
  });

  @override
  State<PromptConditionsSection> createState() =>
      _PromptConditionsSectionState();
}

class _PromptConditionsSectionState extends State<PromptConditionsSection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context),
        if (widget.isExpanded) ...[
          const SizedBox(height: 8),
          ...widget.conditions.map(
            (condition) => _ConditionCard(
              key: ValueKey(condition.id),
              condition: condition,
              conditions: widget.conditions,
              onUpdate: () {
                setState(() {});
                widget.onUpdate();
              },
              onDelete: () => widget.onDeleteCondition(condition),
              getNextOptionTempId: widget.getNextOptionTempId,
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
      onTap: widget.onToggle,
      borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        child: Row(
          children: [
            const CommonTitleMedium(
              text: '프롬프트 조건',
              helpMessage: '프롬프트에 적용할 조건을 설정합니다.\n\n'
                  '• 토글: ON/OFF 스위치\n'
                  '• 하나만 선택: 여러 항목 중 하나를 선택\n'
                  '• 변수 치환: 변수명을 선택한 항목으로 치환',
            ),
            const Spacer(),
            Icon(
              widget.isExpanded ? Icons.expand_less : Icons.expand_more,
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
          onPressed: widget.onAddCondition,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('조건 추가'),
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

class _ConditionCard extends StatefulWidget {
  final PromptCondition condition;
  final List<PromptCondition> conditions;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;
  final int Function() getNextOptionTempId;
  final bool readOnly;

  const _ConditionCard({
    super.key,
    required this.condition,
    required this.conditions,
    required this.onUpdate,
    required this.onDelete,
    required this.getNextOptionTempId,
    this.readOnly = false,
  });

  @override
  State<_ConditionCard> createState() => _ConditionCardState();
}

class _ConditionCardState extends State<_ConditionCard> {
  final TextEditingController _addOptionController = TextEditingController();
  final TextEditingController _optionEditController = TextEditingController();
  int? _editingOptionIndex;

  @override
  void dispose() {
    _addOptionController.dispose();
    _optionEditController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final condition = widget.condition;

    return CommonEditableExpandableItem(
      key: ValueKey(condition.id),
      icon: Icon(
        Icons.tune_outlined,
        size: UIConstants.iconSizeMedium,
        color: Theme.of(context).colorScheme.secondary,
      ),
      name: condition.name.isEmpty ? '새 조건' : condition.name,
      isExpanded: condition.isExpanded,
      onToggleExpanded: () {
        if (condition.isExpanded) {
          FocusScope.of(context).unfocus();
        }
        setState(() {
          condition.isExpanded = !condition.isExpanded;
        });
        widget.onUpdate();
      },
      onDelete: widget.readOnly ? () {} : widget.onDelete,
      showDeleteButton: !widget.readOnly,
      showNameField: true,
      nameHint: '조건 이름 (예: 말투, 분위기)',
      onNameChanged: (value) {
        final idx = widget.conditions.indexOf(condition);
        if (idx != -1) {
          widget.conditions[idx] = condition.copyWith(name: value);
        }
        widget.onUpdate();
      },
      content: _buildContent(condition),
    );
  }

  Widget _buildContent(PromptCondition condition) {
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('형태', style: labelStyle),
        const SizedBox(height: 6),
        CommonDropdownButton<ConditionType>(
          value: condition.type,
          items: ConditionType.values,
          size: CommonDropdownButtonSize.xsmall,
          onChanged: widget.readOnly
              ? null
              : (value) {
                  if (value != null) {
                    setState(() {
                      final idx = widget.conditions.indexOf(condition);
                      if (idx != -1) {
                        widget.conditions[idx] =
                            condition.copyWith(type: value);
                      }
                    });
                    widget.onUpdate();
                  }
                },
          labelBuilder: (type) => type.displayName,
        ),
        if (condition.type == ConditionType.variable) ...[
          const SizedBox(height: UIConstants.spacing12),
          Text('변수 이름', style: labelStyle),
          const SizedBox(height: 6),
          CommonEditText(
            size: CommonEditTextSize.small,
            hintText: '변수 이름',
            initialValue: condition.variableName ?? '',
            onFocusLost: (value) {
              final idx = widget.conditions.indexOf(condition);
              if (idx != -1) {
                widget.conditions[idx] = condition.copyWith(
                  variableName: value.trim().isEmpty ? null : value.trim(),
                );
              }
              widget.onUpdate();
            },
          ),
        ],
        if (condition.type == ConditionType.singleSelect ||
            condition.type == ConditionType.variable) ...[
          const SizedBox(height: UIConstants.spacing12),
          Text('항목 목록', style: labelStyle),
          const SizedBox(height: 6),
          _buildOptionList(condition),
          const SizedBox(height: 6),
          if (!widget.readOnly) _buildOptionAddInput(condition),
        ],
      ],
    );
  }

  Widget _buildOptionList(PromptCondition condition) {
    if (condition.options.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          '항목이 없습니다',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    return Column(
      children: condition.options.asMap().entries.map((entry) {
        final idx = entry.key;
        final option = entry.value;
        return _buildOptionRow(condition, idx, option);
      }).toList(),
    );
  }

  Widget _buildOptionRow(
      PromptCondition condition, int idx, PromptConditionOption option) {
    final isEditing = _editingOptionIndex == idx;
    final borderColor =
        Theme.of(context).colorScheme.outline.withValues(alpha: 0.3);

    if (isEditing) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: CommonEditText(
          controller: _optionEditController,
          size: CommonEditTextSize.small,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (value) {
            _saveOptionEdit(condition, idx, value);
          },
          suffixIcon: GestureDetector(
            onTap: () {
              _saveOptionEdit(condition, idx, _optionEditController.text);
            },
            child: Icon(
              Icons.check,
              size: UIConstants.iconSizeMedium,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          suffixIconConstraints: const BoxConstraints(
            minHeight: 0,
            minWidth: 0,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option.name,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            if (!widget.readOnly) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _editingOptionIndex = idx;
                    _optionEditController.text = option.name;
                  });
                },
                child: Icon(
                  Icons.edit_outlined,
                  size: UIConstants.iconSizeMedium,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  setState(() {
                    condition.options.removeAt(idx);
                    if (_editingOptionIndex == idx) {
                      _editingOptionIndex = null;
                    } else if (_editingOptionIndex != null &&
                        _editingOptionIndex! > idx) {
                      _editingOptionIndex = _editingOptionIndex! - 1;
                    }
                  });
                  widget.onUpdate();
                },
                child: Icon(
                  Icons.delete_outline,
                  size: UIConstants.iconSizeMedium,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _saveOptionEdit(PromptCondition condition, int idx, String value) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) {
      setState(() {
        condition.options[idx] = condition.options[idx].copyWith(name: trimmed);
        _editingOptionIndex = null;
      });
      widget.onUpdate();
    }
  }

  Widget _buildOptionAddInput(PromptCondition condition) {
    return CommonEditText(
      controller: _addOptionController,
      hintText: '항목 이름 입력',
      size: CommonEditTextSize.small,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _commitAddOption(condition),
      suffixIcon: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: GestureDetector(
          onTap: () => _commitAddOption(condition),
          child: const Icon(Icons.add, size: UIConstants.iconSizeMedium),
        ),
      ),
      suffixIconConstraints: const BoxConstraints(
        minHeight: 0,
        minWidth: 0,
      ),
    );
  }

  void _commitAddOption(PromptCondition condition) {
    final text = _addOptionController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      condition.options.add(PromptConditionOption(
        id: widget.getNextOptionTempId(),
        name: text,
        order: condition.options.length,
      ));
      _addOptionController.clear();
    });
    widget.onUpdate();
  }
}
