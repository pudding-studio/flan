import 'package:flutter/material.dart';
import '../../../constants/ui_constants.dart';
import '../../../models/prompt/prompt_regex_rule.dart';
import '../../../widgets/common/common_dropdown_button.dart';
import '../../../widgets/common/common_editable_expandable_item.dart';
import '../../../widgets/common/common_edit_text.dart';
import '../../../widgets/common/common_empty_state.dart';
import '../../../widgets/common/common_title_medium.dart';

class PromptRegexTab extends StatefulWidget {
  final List<PromptRegexRule> rules;
  final Map<int, TextEditingController> patternControllers;
  final Map<int, TextEditingController> replacementControllers;
  final bool readOnly;
  final VoidCallback onUpdate;
  final void Function(PromptRegexRule) onDeleteRule;
  final VoidCallback onAddRule;

  const PromptRegexTab({
    super.key,
    required this.rules,
    required this.patternControllers,
    required this.replacementControllers,
    this.readOnly = false,
    required this.onUpdate,
    required this.onDeleteRule,
    required this.onAddRule,
  });

  @override
  State<PromptRegexTab> createState() => _PromptRegexTabState();
}

class _PromptRegexTabState extends State<PromptRegexTab> {
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
              text: '정규식 규칙',
              helpMessage: '정규식(RegExp)을 사용하여 텍스트를 변환합니다.\n\n'
                  '속성에 따라 적용 시점이 달라집니다:\n'
                  '• 입력문 수정: 사용자 입력 텍스트에 적용\n'
                  '• 출력문 수정: AI 응답 텍스트에 적용\n'
                  '• 전송데이터 수정: API 전송 데이터에 적용\n'
                  '• 출력화면 수정: 화면 표시 시에만 적용',
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: widget.rules.isEmpty
                ? _buildEmptyState()
                : _buildRuleList(),
          ),
          if (!widget.readOnly) _buildAddButton(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const CommonEmptyState(
      icon: Icons.find_replace_outlined,
      message: '정규식 규칙이 없습니다',
    );
  }

  Widget _buildRuleList() {
    return ListView.builder(
      itemCount: widget.rules.length,
      itemBuilder: (context, index) {
        final rule = widget.rules[index];
        return _buildRuleCard(rule, index);
      },
    );
  }

  Widget _buildRuleCard(PromptRegexRule rule, int index) {
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        );

    return CommonEditableExpandableItem(
      key: ValueKey(rule.id),
      icon: Icon(
        Icons.find_replace_outlined,
        size: UIConstants.iconSizeMedium,
        color: rule.target == RegexTarget.disabled
            ? Theme.of(context).colorScheme.onSurfaceVariant
            : Theme.of(context).colorScheme.secondary,
      ),
      name: rule.name.isEmpty ? '규칙 ${index + 1}' : rule.name,
      isExpanded: rule.isExpanded,
      onToggleExpanded: () {
        if (rule.isExpanded) {
          FocusScope.of(context).unfocus();
        }
        setState(() {
          rule.isExpanded = !rule.isExpanded;
        });
        widget.onUpdate();
      },
      onDelete: widget.readOnly ? () {} : () => widget.onDeleteRule(rule),
      showDeleteButton: !widget.readOnly,
      nameHint: '규칙 이름 (예: OOC 제거, 태그 변환)',
      onNameChanged: (value) {
        final idx = widget.rules.indexOf(rule);
        if (idx != -1) {
          widget.rules[idx] = rule.copyWith(name: value);
        }
        widget.onUpdate();
      },
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('속성', style: labelStyle),
          const SizedBox(height: 6),
          CommonDropdownButton<RegexTarget>(
            value: rule.target,
            items: RegexTarget.values,
            size: CommonDropdownButtonSize.xsmall,
            onChanged: widget.readOnly
                ? null
                : (value) {
                    if (value != null) {
                      setState(() {
                        final idx = widget.rules.indexOf(rule);
                        if (idx != -1) {
                          widget.rules[idx] = rule.copyWith(target: value);
                        }
                      });
                      widget.onUpdate();
                    }
                  },
            labelBuilder: (target) => target.displayName,
          ),
          const SizedBox(height: UIConstants.spacing12),
          Text('정규식 패턴', style: labelStyle),
          const SizedBox(height: 6),
          CommonEditText(
            controller: widget.patternControllers[rule.id],
            hintText: '예: \\(OOC:.*?\\)',
            size: CommonEditTextSize.small,
            maxLines: null,
            minLines: 1,
          ),
          const SizedBox(height: UIConstants.spacing12),
          Text('변환 형식', style: labelStyle),
          const SizedBox(height: 6),
          CommonEditText(
            controller: widget.replacementControllers[rule.id],
            hintText: '정규식에 매칭된 텍스트가 이 형식으로 변환됩니다\n\n캡처 그룹: \$1, \$2, ...',
            size: CommonEditTextSize.small,
            maxLines: null,
            minLines: 5,
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: widget.onAddRule,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('규칙 추가'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
            ),
          ),
        ),
      ),
    );
  }
}
