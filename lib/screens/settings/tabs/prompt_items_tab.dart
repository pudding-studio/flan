import 'dart:async';

import 'package:flutter/material.dart';
import '../../../constants/ui_constants.dart';
import '../../../models/prompt/prompt_item.dart';
import '../../../widgets/common/common_button.dart';
import '../../../widgets/common/common_editable_expandable_item.dart';
import '../../../widgets/common/common_edit_text.dart';
import '../../../widgets/common/common_segmented_button.dart';
import '../../../widgets/common/common_title_medium.dart';

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
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _listKey = GlobalKey();
  Timer? _autoScrollTimer;
  double _currentScrollDelta = 0;

  static const double _edgeThreshold = 80.0;
  static const double _scrollSpeed = 8.0;

  @override
  void dispose() {
    _scrollController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final listBox = _listKey.currentContext?.findRenderObject() as RenderBox?;
    if (listBox == null) return;

    final localPosition = listBox.globalToLocal(details.globalPosition);
    final listHeight = listBox.size.height;

    if (localPosition.dy < _edgeThreshold) {
      _currentScrollDelta = -_scrollSpeed;
      _startAutoScroll();
    } else if (localPosition.dy > listHeight - _edgeThreshold) {
      _currentScrollDelta = _scrollSpeed;
      _startAutoScroll();
    } else {
      _stopAutoScroll();
    }
  }

  void _startAutoScroll() {
    if (_autoScrollTimer != null) return;

    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_scrollController.hasClients) return;

      final currentOffset = _scrollController.offset;
      final maxScroll = _scrollController.position.maxScrollExtent;
      final minScroll = _scrollController.position.minScrollExtent;

      if ((_currentScrollDelta < 0 && currentOffset <= minScroll) ||
          (_currentScrollDelta > 0 && currentOffset >= maxScroll)) {
        return;
      }

      final newOffset = (currentOffset + _currentScrollDelta).clamp(minScroll, maxScroll);
      _scrollController.jumpTo(newOffset);
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    _currentScrollDelta = 0;
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
              text: '프롬프트 항목',
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
                    key: _listKey,
                    controller: _scrollController,
                    itemCount: widget.items.length,
                    itemBuilder: (context, index) {
                      return _buildItemCard(widget.items[index], index);
                    },
                  ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CommonButton.filled(
              onPressed: widget.onAdd,
              icon: Icons.add,
              label: '항목 추가',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(PromptItem item, int index) {
    return LongPressDraggable<PromptItem>(
      data: item,
      onDragUpdate: _handleDragUpdate,
      onDragEnd: (_) => _stopAutoScroll(),
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
                .withValues(alpha: UIConstants.opacityMedium),
            borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
            border: Border.all(
              color: candidateData.isNotEmpty
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withValues(alpha: UIConstants.opacityLow),
              width: candidateData.isNotEmpty ? 2 : 1,
            ),
          ),
          child: CommonEditableExpandableItem(
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
            onDelete: () => widget.onDelete(item),
            nameHint: '항목 이름 (예: 시스템 설정, 캐릭터 성격)',
            onNameChanged: (value) {
              final updatedItem = item.copyWith(name: value.isEmpty ? null : value);
              final index = widget.items.indexOf(item);
              widget.items[index] = updatedItem;
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
                      final updatedItem = item.copyWith(role: selected);
                      final index = widget.items.indexOf(item);
                      widget.items[index] = updatedItem;
                    });
                    widget.onUpdate();
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
