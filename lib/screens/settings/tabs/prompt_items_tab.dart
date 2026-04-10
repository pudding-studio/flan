import 'package:flutter/material.dart';
import '../../../constants/ui_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/prompt/prompt_condition.dart';
import '../../../models/prompt/prompt_condition_option.dart';
import '../../../models/prompt/prompt_item.dart';
import '../../../models/prompt/prompt_item_folder.dart';
import '../../../widgets/common/common_draggable_folder_list.dart';
import '../../../widgets/common/common_dropdown_button.dart';
import '../../../widgets/common/common_editable_expandable_item.dart';
import '../../../widgets/common/common_edit_text.dart';
import '../../../widgets/common/common_empty_state.dart';
import '../../../widgets/common/common_segmented_button.dart';
import '../../../widgets/common/common_title_medium.dart';
import 'prompt_conditions_section.dart';

class PromptItemsTab extends StatefulWidget {
  final List<PromptItemFolder> folders;
  final List<PromptItem> standaloneItems;
  final Map<int, TextEditingController> contentControllers;
  final VoidCallback onUpdate;
  final void Function(PromptItem) onDeleteItem;
  final void Function(PromptItemFolder) onDeleteFolder;
  final void Function(PromptItemFolder? folder) onAddItem;
  final VoidCallback onAddFolder;
  final void Function(PromptItem item, PromptItemFolder? fromFolder, PromptItemFolder toFolder) onMoveItemToFolder;
  final void Function(PromptItem item, PromptItemFolder fromFolder) onMoveItemOutOfFolder;
  final void Function(PromptItem item, int targetIndex, PromptItemFolder? folder) onReorderItem;
  final void Function(PromptItemFolder folder, int targetIndex) onReorderFolder;
  final bool readOnly;

  // Condition props
  final List<PromptCondition> conditions;
  final bool conditionsSectionExpanded;
  final VoidCallback onConditionsSectionToggle;
  final VoidCallback onAddCondition;
  final void Function(PromptCondition) onDeleteCondition;
  final VoidCallback onUpdateConditions;
  final int Function() getNextConditionOptionTempId;

  const PromptItemsTab({
    super.key,
    required this.folders,
    required this.standaloneItems,
    required this.contentControllers,
    this.readOnly = false,
    required this.onUpdate,
    required this.onDeleteItem,
    required this.onDeleteFolder,
    required this.onAddItem,
    required this.onAddFolder,
    required this.onMoveItemToFolder,
    required this.onMoveItemOutOfFolder,
    required this.onReorderItem,
    required this.onReorderFolder,
    required this.conditions,
    required this.conditionsSectionExpanded,
    required this.onConditionsSectionToggle,
    required this.onAddCondition,
    required this.onDeleteCondition,
    required this.onUpdateConditions,
    required this.getNextConditionOptionTempId,
  });

  @override
  State<PromptItemsTab> createState() => _PromptItemsTabState();
}

class _PromptItemsTabState extends State<PromptItemsTab> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(UIConstants.spacing20),
      child: ListView(
        children: [
          PromptConditionsSection(
            conditions: widget.conditions,
            isExpanded: widget.conditionsSectionExpanded,
            onToggle: widget.onConditionsSectionToggle,
            onAddCondition: widget.onAddCondition,
            onDeleteCondition: widget.onDeleteCondition,
            onUpdate: widget.onUpdateConditions,
            getNextOptionTempId: widget.getNextConditionOptionTempId,
            readOnly: widget.readOnly,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: CommonTitleMedium(
              text: l10n.promptItemsTitle,
              helpMessage: l10n.promptItemsTitleHelp,
            ),
          ),
          const SizedBox(height: 8),
          CommonDraggableFolderList<PromptItemFolder, PromptItem>(
            folders: widget.folders,
            standaloneItems: widget.standaloneItems,
            getFolderId: (folder) => folder.id,
            getFolderName: (folder) => folder.name,
            getFolderExpanded: (folder) => folder.isExpanded,
            getFolderItems: (folder) => folder.items,
            getFolderOrder: (folder) => folder.order,
            getItemId: (item) => item.id,
            getItemOrder: (item) => item.order,
            itemContentBuilder: _buildItemCard,
            getItemIcon: (item) => _getRoleIcon(item.role),
            getItemName: (item) => item.name ?? item.role.displayName,
            onReorderItem: widget.readOnly ? (_, __, ___) {} : widget.onReorderItem,
            onMoveItemToFolder: widget.readOnly ? (_, __, ___) {} : widget.onMoveItemToFolder,
            onMoveItemOutOfFolder: widget.readOnly ? (_, __) {} : widget.onMoveItemOutOfFolder,
            onReorderFolder: widget.readOnly ? (_, __) {} : widget.onReorderFolder,
            onFolderNameChanged: widget.readOnly ? (_, __) {} : (folder, newName) {
              folder.name = newName;
              widget.onUpdate();
            },
            onFolderExpandedChanged: (folder, isExpanded) {
              setState(() {
                folder.isExpanded = isExpanded;
              });
            },
            onDeleteFolder: widget.readOnly ? (_) {} : widget.onDeleteFolder,
            onAddItem: widget.readOnly ? (_) {} : widget.onAddItem,
            onAddFolder: widget.readOnly ? () {} : widget.onAddFolder,
            itemTypeKey: 'promptItem',
            addItemLabel: l10n.promptItemsAddItem,
            addFolderLabel: l10n.promptItemsAddFolder,
            readOnly: widget.readOnly,
            shrinkWrap: true,
            emptyWidget: CommonEmptyState(
              icon: Icons.chat_bubble_outline,
              message: l10n.promptItemsEmpty,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, PromptItem item, PromptItemFolder? folder) {
    final l10n = AppLocalizations.of(context);
    final disabledColor = Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5);

    final isVisuallyEnabled = item.enableMode != EnableMode.disabled;

    return Opacity(
      opacity: isVisuallyEnabled ? 1.0 : 0.5,
      child: CommonEditableExpandableItem(
      key: ValueKey(item.id),
      icon: Stack(
        children: [
          Icon(
            _getRoleIcon(item.role),
            size: UIConstants.iconSizeMedium,
            color: isVisuallyEnabled
                ? Theme.of(context).colorScheme.secondary
                : disabledColor,
          ),
          if (!isVisuallyEnabled)
            Positioned.fill(
              child: CustomPaint(
                painter: _DisabledSlashPainter(
                  color: disabledColor,
                ),
              ),
            ),
        ],
      ),
      name: item.name ?? item.role.displayName,
      isExpanded: item.isExpanded,
      onToggleExpanded: () {
        if (item.isExpanded) {
          FocusScope.of(context).unfocus();
        }
        setState(() {
          item.isExpanded = !item.isExpanded;
        });
        widget.onUpdate();
      },
      onDelete: widget.readOnly ? () {} : () => widget.onDeleteItem(item),
      showDeleteButton: !widget.readOnly,
      nameHint: l10n.promptItemsNameHint,
      onNameChanged: (value) {
        if (folder != null) {
          final index = folder.items.indexOf(item);
          if (index != -1) {
            folder.items[index] = item.copyWith(name: value.isEmpty ? null : value);
          }
        } else {
          final index = widget.standaloneItems.indexOf(item);
          if (index != -1) {
            widget.standaloneItems[index] = item.copyWith(name: value.isEmpty ? null : value);
          }
        }
        widget.onUpdate();
      },
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.promptItemsLabelEnable,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          CommonSegmentedButton<EnableMode>(
            values: EnableMode.values,
            selected: item.enableMode,
            onSelectionChanged: widget.readOnly ? (_) {} : (selected) {
              if (selected == EnableMode.enabled) {
                _updateItem(item, folder, item.copyWithNullableCondition(
                  enableMode: EnableMode.enabled,
                  conditionId: null,
                  conditionValue: null,
                ).copyWith(enabled: true));
              } else if (selected == EnableMode.disabled) {
                _updateItem(item, folder, item.copyWithNullableCondition(
                  enableMode: EnableMode.disabled,
                  conditionId: null,
                  conditionValue: null,
                ).copyWith(enabled: false));
              } else {
                _updateItem(item, folder, item.copyWith(
                  enableMode: EnableMode.conditional,
                ));
              }
            },
            labelBuilder: (mode) => mode.displayName,
          ),
          if (item.enableMode == EnableMode.conditional) ...[
            const SizedBox(height: UIConstants.spacing12),
            _buildConditionSelector(item, folder),
          ],
          const SizedBox(height: UIConstants.spacing12),
          Text(
            l10n.promptItemsLabelRole,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          CommonSegmentedButton<PromptRole>(
            values: PromptRole.values,
            selected: item.role,
            onSelectionChanged: (selected) {
              setState(() {
                if (folder != null) {
                  final index = folder.items.indexOf(item);
                  if (index != -1) {
                    folder.items[index] = item.copyWith(role: selected);
                  }
                } else {
                  final index = widget.standaloneItems.indexOf(item);
                  if (index != -1) {
                    widget.standaloneItems[index] = item.copyWith(role: selected);
                  }
                }
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                widget.onUpdate();
              });
            },
            labelBuilder: (role) => role.displayName,
          ),
          const SizedBox(height: UIConstants.spacing12),
          if (item.role == PromptRole.chat)
            _buildChatSettings(item, folder)
          else ...[
            Text(
              l10n.promptItemsLabelPrompt,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            CommonEditText(
              controller: widget.contentControllers[item.id],
              hintText: l10n.promptItemsPromptHint,
              size: CommonEditTextSize.small,
              maxLines: null,
              minLines: 5,
            ),
          ],
        ],
      ),
    ),
    );
  }

  void _updateItem(PromptItem item, PromptItemFolder? folder, PromptItem updated) {
    setState(() {
      if (folder != null) {
        final index = folder.items.indexOf(item);
        if (index != -1) folder.items[index] = updated;
      } else {
        final index = widget.standaloneItems.indexOf(item);
        if (index != -1) widget.standaloneItems[index] = updated;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onUpdate();
    });
  }

  Widget _buildConditionSelector(PromptItem item, PromptItemFolder? folder) {
    final l10n = AppLocalizations.of(context);
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        );

    // Exclude variable type conditions from the selectable list
    final selectableConditions = widget.conditions
        .where((c) => c.type != ConditionType.variable)
        .toList();

    // Find the currently selected condition
    final selectedCondition = selectableConditions.cast<PromptCondition?>().firstWhere(
      (c) => c!.id == item.conditionId,
      orElse: () => null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.promptItemsConditionSelect, style: labelStyle),
        const SizedBox(height: 6),
        CommonDropdownButton<PromptCondition>(
          value: selectedCondition,
          items: selectableConditions,
          size: CommonDropdownButtonSize.xsmall,
          hintText: l10n.promptItemsConditionSelectHint,
          onChanged: widget.readOnly
              ? null
              : (value) {
                  if (value != null) {
                    // Set default conditionValue based on type
                    String? defaultValue;
                    if (value.type == ConditionType.toggle) {
                      defaultValue = 'true';
                    } else if (value.type == ConditionType.singleSelect &&
                        value.options.isNotEmpty) {
                      defaultValue = value.options.first.name;
                    }
                    _updateItem(
                      item,
                      folder,
                      item.copyWithNullableCondition(
                        enableMode: EnableMode.conditional,
                        conditionId: value.id,
                        conditionValue: defaultValue,
                      ),
                    );
                  }
                },
          labelBuilder: (c) => c.name.isEmpty ? l10n.promptItemsConditionNoName : c.name,
        ),
        if (selectedCondition != null) ...[
          const SizedBox(height: UIConstants.spacing12),
          if (selectedCondition.type == ConditionType.toggle) ...[
            Text(l10n.promptItemsConditionValue, style: labelStyle),
            const SizedBox(height: 6),
            CommonSegmentedButton<String>(
              values: const ['true', 'false'],
              selected: item.conditionValue ?? 'true',
              onSelectionChanged: widget.readOnly
                  ? (_) {}
                  : (selected) {
                      _updateItem(
                        item,
                        folder,
                        item.copyWith(conditionValue: selected),
                      );
                    },
              labelBuilder: (v) => v == 'true' ? l10n.promptItemsConditionEnabled : l10n.promptItemsConditionDisabled,
            ),
          ],
          if (selectedCondition.type == ConditionType.singleSelect &&
              selectedCondition.options.isNotEmpty) ...[
            Text(l10n.promptItemsSingleSelectItems, style: labelStyle),
            const SizedBox(height: 6),
            CommonDropdownButton<PromptConditionOption>(
              value: selectedCondition.options.cast<PromptConditionOption?>().firstWhere(
                (o) => o!.name == item.conditionValue,
                orElse: () => null,
              ),
              items: selectedCondition.options,
              size: CommonDropdownButtonSize.xsmall,
              hintText: l10n.promptItemsSingleSelectHint,
              onChanged: widget.readOnly
                  ? null
                  : (value) {
                      if (value != null) {
                        _updateItem(
                          item,
                          folder,
                          item.copyWith(conditionValue: value.name),
                        );
                      }
                    },
              labelBuilder: (o) => o.name,
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildChatSettings(PromptItem item, PromptItemFolder? folder) {
    final l10n = AppLocalizations.of(context);
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.promptItemsChatSettings, style: labelStyle),
        const SizedBox(height: 6),
        CommonSegmentedButton<ChatSettingMode>(
          values: ChatSettingMode.values,
          selected: item.chatSettingMode,
          onSelectionChanged: (selected) {
            _updateItem(item, folder, item.copyWith(chatSettingMode: selected));
          },
          labelBuilder: (mode) => mode.displayName,
        ),
        if (item.chatSettingMode == ChatSettingMode.advanced) ...[
          const SizedBox(height: UIConstants.spacing12),
          CommonSegmentedButton<ChatRangeType>(
            values: ChatRangeType.values,
            selected: item.chatRangeType,
            onSelectionChanged: (selected) {
              _updateItem(item, folder, item.copyWith(chatRangeType: selected));
            },
            labelBuilder: (type) => type.displayName,
          ),
          const SizedBox(height: UIConstants.spacing12),
          if (item.chatRangeType == ChatRangeType.recent) ...[
            Text(l10n.promptItemsRecentChatCount, style: labelStyle),
            const SizedBox(height: 6),
            CommonEditText(
              hintText: l10n.promptItemsRecentChatCountHint,
              size: CommonEditTextSize.small,
              initialValue: item.recentChatCount?.toString(),
              keyboardType: TextInputType.number,
              onFocusLost: (value) {
                _updateItem(item, folder, item.copyWith(
                  recentChatCount: int.tryParse(value),
                ));
              },
            ),
          ],
          if (item.chatRangeType == ChatRangeType.middle || item.chatRangeType == ChatRangeType.old) ...[
            Text(l10n.promptItemsChatStartPos, style: labelStyle),
            const SizedBox(height: 6),
            CommonEditText(
              hintText: l10n.promptItemsChatStartPosHint,
              size: CommonEditTextSize.small,
              initialValue: item.chatStartPosition?.toString(),
              keyboardType: TextInputType.number,
              onFocusLost: (value) {
                _updateItem(item, folder, item.copyWith(
                  chatStartPosition: int.tryParse(value),
                ));
              },
            ),
          ],
          if (item.chatRangeType == ChatRangeType.middle) ...[
            const SizedBox(height: UIConstants.spacing12),
            Text(l10n.promptItemsChatEndPos, style: labelStyle),
            const SizedBox(height: 6),
            CommonEditText(
              hintText: l10n.promptItemsChatEndPosHint,
              size: CommonEditTextSize.small,
              initialValue: item.chatEndPosition?.toString(),
              keyboardType: TextInputType.number,
              onFocusLost: (value) {
                _updateItem(item, folder, item.copyWith(
                  chatEndPosition: int.tryParse(value),
                ));
              },
            ),
          ],
        ],
      ],
    );
  }

  IconData _getRoleIcon(PromptRole role) {
    switch (role) {
      case PromptRole.system:
        return Icons.settings_outlined;
      case PromptRole.user:
        return Icons.person_outline;
      case PromptRole.assistant:
        return Icons.smart_toy_outlined;
      case PromptRole.chat:
        return Icons.chat_outlined;
    }
  }
}

class _DisabledSlashPainter extends CustomPainter {
  final Color color;

  _DisabledSlashPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width * 0.85, size.height * 0.15),
      Offset(size.width * 0.15, size.height * 0.85),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
