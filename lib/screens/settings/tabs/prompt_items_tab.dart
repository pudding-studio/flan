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
  final void Function(PromptItemFolder folder, int targetIndex) onReorderFolder;
  final bool readOnly;

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
              addItemLabel: '항목 추가',
              addFolderLabel: '폴더 추가',
              readOnly: widget.readOnly,
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
    final disabledColor = Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5);

    return Opacity(
      opacity: item.enabled ? 1.0 : 0.5,
      child: CommonEditableExpandableItem(
      key: ValueKey(item.id),
      icon: Stack(
        children: [
          Icon(
            _getRoleIcon(item.role),
            size: UIConstants.iconSizeMedium,
            color: item.enabled
                ? Theme.of(context).colorScheme.secondary
                : disabledColor,
          ),
          if (!item.enabled)
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
            '활성화',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          CommonSegmentedButton<bool>(
            values: const [true, false],
            selected: item.enabled,
            onSelectionChanged: widget.readOnly ? (_) {} : (selected) {
              _updateItem(item, folder, item.copyWith(enabled: selected));
            },
            labelBuilder: (value) => value ? '활성화' : '비활성화',
          ),
          const SizedBox(height: UIConstants.spacing12),
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
          if (item.role == PromptRole.chat)
            _buildChatSettings(item, folder)
          else ...[
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

  Widget _buildChatSettings(PromptItem item, PromptItemFolder? folder) {
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('설정', style: labelStyle),
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
            Text('최근 채팅 포함 개수', style: labelStyle),
            const SizedBox(height: 6),
            CommonEditText(
              hintText: '개수',
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
            Text('이전 채팅 시작 위치', style: labelStyle),
            const SizedBox(height: 6),
            CommonEditText(
              hintText: '시작 위치',
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
            Text('이전 채팅 마지막 위치', style: labelStyle),
            const SizedBox(height: 6),
            CommonEditText(
              hintText: '마지막 위치',
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
