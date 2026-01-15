import 'package:flutter/material.dart';
import '../../../constants/ui_constants.dart';
import '../../../models/prompt/prompt_item.dart';
import '../../../widgets/label_with_help.dart';

class PromptItemsTab extends StatefulWidget {
  final List<PromptItem> items;
  final Map<int, TextEditingController> contentControllers;
  final VoidCallback onUpdate;
  final void Function(PromptItem) onDelete;
  final void Function(PromptItem dragged, PromptItem target) onMove;
  final VoidCallback onAdd;

  const PromptItemsTab({
    super.key,
    required this.items,
    required this.contentControllers,
    required this.onUpdate,
    required this.onDelete,
    required this.onMove,
    required this.onAdd,
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
            child: LabelWithHelp(
              label: '프롬프트 항목',
              helpMessage: 'AI에게 전달될 프롬프트 항목들을 추가하세요. '
                  '순서대로 전달됩니다.\n\n'
                  '길게 눌러 순서를 변경할 수 있습니다.',
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: widget.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color
                              ?.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '프롬프트 항목이 없습니다',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color
                                    ?.withValues(alpha: 0.5),
                              ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: widget.items.length,
                    itemBuilder: (context, index) {
                      return _buildItemCard(widget.items[index], index);
                    },
                  ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: widget.onAdd,
              icon: const Icon(Icons.add),
              label: const Text('항목 추가'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(PromptItem item, int index) {
    return LongPressDraggable<PromptItem>(
      data: item,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 300,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                _getRoleIcon(item.role),
                size: 18,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.name ?? item.role.displayName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildItemContent(item),
      ),
      child: _buildItemContent(item),
    );
  }

  Widget _buildItemContent(PromptItem item) {
    return DragTarget<PromptItem>(
      onWillAcceptWithDetails: (details) => details.data != item,
      onAcceptWithDetails: (details) => widget.onMove(details.data, item),
      builder: (context, candidateData, rejectedData) {
        return Container(
          key: ValueKey(item.id),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: candidateData.isNotEmpty
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              width: candidateData.isNotEmpty ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    item.isExpanded = !item.isExpanded;
                  });
                  widget.onUpdate();
                },
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        _getRoleIcon(item.role),
                        size: 18,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.name ?? item.role.displayName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => widget.onDelete(item),
                        child: const Icon(Icons.delete_outline, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        item.isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              if (item.isExpanded) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '이름',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        initialValue: item.name ?? '',
                        decoration: InputDecoration(
                          hintText: '항목 이름 (예: 시스템 설정, 캐릭터 성격)',
                          hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          isDense: true,
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                        onChanged: (value) {
                          final updatedItem = item.copyWith(name: value.trim().isEmpty ? null : value.trim());
                          final index = widget.items.indexOf(item);
                          widget.items[index] = updatedItem;
                          widget.onUpdate();
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '역할',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<PromptRole>(
                          showSelectedIcon: false,
                          segments: PromptRole.values
                              .map(
                                (role) => ButtonSegment(
                                  value: role,
                                  label: Text(
                                    role.displayName,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              )
                              .toList(),
                          selected: {item.role},
                          onSelectionChanged: (Set<PromptRole> selected) {
                            setState(() {
                              final updatedItem = item.copyWith(role: selected.first);
                              final index = widget.items.indexOf(item);
                              widget.items[index] = updatedItem;
                            });
                            widget.onUpdate();
                          },
                          style: ButtonStyle(
                            overlayColor: WidgetStateProperty.all(Colors.transparent),
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '프롬프트',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: widget.contentControllers[item.id],
                        decoration: InputDecoration(
                          hintText: 'AI의 역할과 응답 방식을 정의하세요',
                          hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          isDense: true,
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: null,
                        minLines: 5,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
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
    }
  }
}
