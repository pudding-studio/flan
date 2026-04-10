import 'package:flutter/material.dart';
import '../../../constants/ui_constants.dart';
import '../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(UIConstants.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: CommonTitleMedium(
              text: l10n.promptRegexTitle,
              helpMessage: l10n.promptRegexTitleHelp,
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
    return CommonEmptyState(
      icon: Icons.find_replace_outlined,
      message: AppLocalizations.of(context).promptRegexEmpty,
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
    final l10n = AppLocalizations.of(context);
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
      name: rule.name.isEmpty ? l10n.promptRegexRuleDefaultName(index + 1) : rule.name,
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
      nameHint: l10n.promptRegexNameHint,
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
          Text(l10n.promptRegexLabelTarget, style: labelStyle),
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
          Text(l10n.promptRegexLabelPattern, style: labelStyle),
          const SizedBox(height: 6),
          CommonEditText(
            controller: widget.patternControllers[rule.id],
            hintText: l10n.promptRegexPatternHint,
            size: CommonEditTextSize.small,
            maxLines: null,
            minLines: 1,
          ),
          const SizedBox(height: UIConstants.spacing12),
          Text(l10n.promptRegexLabelReplacement, style: labelStyle),
          const SizedBox(height: 6),
          CommonEditText(
            controller: widget.replacementControllers[rule.id],
            hintText: l10n.promptRegexReplacementHint,
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
          label: Text(AppLocalizations.of(context).promptRegexAddButton),
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
