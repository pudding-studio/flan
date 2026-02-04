import 'package:flutter/material.dart';
import '../../../constants/ui_constants.dart';
import '../../../models/prompt/prompt_item.dart';
import '../../../models/prompt/prompt_item_folder.dart';
import '../../../widgets/common/common_draggable_folder_list.dart';
import '../../../widgets/common/common_editable_expandable_item.dart';
import '../../../widgets/common/common_edit_text.dart';
import '../../../widgets/common/common_empty_state.dart';
import '../../../widgets/common/common_segmented_button.dart';
import '../../../widgets/common/common_title_medium.dart';

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

  const PromptItemsTab({
    super.key,
    required this.folders,
    required this.standaloneItems,
    required this.contentControllers,
    required this.onUpdate,
    required this.onDeleteItem,
    required this.onDeleteFolder,
    required this.onAddItem,
    required this.onAddFolder,
    required this.onMoveItemToFolder,
    required this.onMoveItemOutOfFolder,
    required this.onReorderItem,
  });

  @override
  State<PromptItemsTab> createState() => _PromptItemsTabState();
}

class _PromptItemsTabState extends State<PromptItemsTab> {
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
              text: '프롬프트 항목',
              helpMessage: 'AI에게 전달될 프롬프트 항목들을 추가하세요. '
                  '순서대로 전달됩니다.\n\n'
                  '길게 눌러 순서를 변경할 수 있습니다.',
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: CommonDraggableFolderList<PromptItemFolder, PromptItem>(
              folders: widget.folders,
              standaloneItems: widget.standaloneItems,
              getFolderId: (folder) => folder.id,
              getFolderName: (folder) => folder.name,
              getFolderExpanded: (folder) => folder.isExpanded,
              getFolderItems: (folder) => folder.items,
              getItemId: (item) => item.id,
              itemContentBuilder: _buildItemCard,
              getItemIcon: (item) => _getRoleIcon(item.role),
              getItemName: (item) => item.name ?? item.role.displayName,
              onReorderItem: widget.onReorderItem,
              onMoveItemToFolder: widget.onMoveItemToFolder,
              onMoveItemOutOfFolder: widget.onMoveItemOutOfFolder,
              onFolderNameChanged: (folder, newName) {
                folder.name = newName;
                widget.onUpdate();
              },
              onFolderExpandedChanged: (folder, isExpanded) {
                setState(() {
                  folder.isExpanded = isExpanded;
                });
              },
              onDeleteFolder: widget.onDeleteFolder,
              onAddItem: widget.onAddItem,
              onAddFolder: widget.onAddFolder,
              itemTypeKey: 'promptItem',
              addItemLabel: '항목 추가',
              addFolderLabel: '폴더 추가',
              emptyWidget: const CommonEmptyState(
                icon: Icons.chat_bubble_outline,
                message: '프롬프트 항목이 없습니다',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, PromptItem item, PromptItemFolder? folder) {
    return CommonEditableExpandableItem(
      key: ValueKey(item.id),
      icon: Icon(
        _getRoleIcon(item.role),
        size: UIConstants.iconSizeMedium,
        color: Theme.of(context).colorScheme.secondary,
      ),
      name: item.name ?? item.role.displayName,
      isExpanded: item.isExpanded,
      onToggleExpanded: () {
        setState(() {
          item.isExpanded = !item.isExpanded;
        });
        widget.onUpdate();
      },
      onDelete: () => widget.onDeleteItem(item),
      nameHint: '항목 이름 (예: 시스템 설정, 캐릭터 성격)',
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
            '역할',
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
          Text(
            '프롬프트',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          CommonEditText(
            controller: widget.contentControllers[item.id],
            hintText: 'AI의 역할과 응답 방식을 정의하세요',
            size: CommonEditTextSize.small,
            maxLines: null,
            minLines: 5,
          ),
        ],
      ),
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
