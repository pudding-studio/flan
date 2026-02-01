import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/ui_constants.dart';
import 'common_button.dart';

/// 드래그 가능한 폴더+아이템 리스트 위젯
///
/// 폴더와 단독 아이템을 슬롯 기반 드래그로 재정렬할 수 있습니다.
/// 드래그 중 가장자리에서 자동 스크롤됩니다.
class CommonDraggableFolderList<TFolder, TItem> extends StatefulWidget {
  /// 폴더 목록
  final List<TFolder> folders;

  /// 폴더에 속하지 않은 단독 아이템 목록
  final List<TItem> standaloneItems;

  /// 폴더의 ID 반환
  final int? Function(TFolder folder) getFolderId;

  /// 폴더의 이름 반환
  final String Function(TFolder folder) getFolderName;

  /// 폴더의 확장 여부 반환
  final bool Function(TFolder folder) getFolderExpanded;

  /// 폴더 내 아이템 목록 반환
  final List<TItem> Function(TFolder folder) getFolderItems;

  /// 아이템의 ID 반환
  final int? Function(TItem item) getItemId;

  /// 아이템 콘텐츠 빌더 (카드 내부)
  final Widget Function(BuildContext context, TItem item, TFolder? folder) itemContentBuilder;

  /// 아이템의 아이콘 반환 (기본 드래그 피드백용)
  final IconData Function(TItem item)? getItemIcon;

  /// 아이템의 이름 반환 (기본 드래그 피드백용)
  final String Function(TItem item)? getItemName;

  /// 드래그 중 피드백 위젯 빌더 (커스텀 피드백이 필요할 때 사용)
  final Widget Function(BuildContext context, TItem item)? dragFeedbackBuilder;

  /// 같은 폴더/영역 내 아이템 순서 변경
  final void Function(TItem item, int targetIndex, TFolder? folder) onReorderItem;

  /// 아이템을 폴더로 이동
  final void Function(TItem item, TFolder? fromFolder, TFolder toFolder) onMoveItemToFolder;

  /// 아이템을 폴더 밖으로 이동
  final void Function(TItem item, TFolder fromFolder) onMoveItemOutOfFolder;

  /// 폴더 이름 변경
  final void Function(TFolder folder, String newName) onFolderNameChanged;

  /// 폴더 확장/축소 변경
  final void Function(TFolder folder, bool isExpanded) onFolderExpandedChanged;

  /// 폴더 삭제
  final void Function(TFolder folder) onDeleteFolder;

  /// 아이템 추가
  final void Function(TFolder? folder) onAddItem;

  /// 폴더 추가
  final VoidCallback onAddFolder;

  /// 드래그 데이터 타입 키 (예: 'promptItem', 'characterBook')
  final String itemTypeKey;

  /// 아이템 추가 버튼 라벨
  final String addItemLabel;

  /// 폴더 추가 버튼 라벨
  final String addFolderLabel;

  /// 빈 상태 위젯
  final Widget? emptyWidget;

  const CommonDraggableFolderList({
    super.key,
    required this.folders,
    required this.standaloneItems,
    required this.getFolderId,
    required this.getFolderName,
    required this.getFolderExpanded,
    required this.getFolderItems,
    required this.getItemId,
    required this.itemContentBuilder,
    this.getItemIcon,
    this.getItemName,
    this.dragFeedbackBuilder,
    required this.onReorderItem,
    required this.onMoveItemToFolder,
    required this.onMoveItemOutOfFolder,
    required this.onFolderNameChanged,
    required this.onFolderExpandedChanged,
    required this.onDeleteFolder,
    required this.onAddItem,
    required this.onAddFolder,
    required this.itemTypeKey,
    this.addItemLabel = '항목 추가',
    this.addFolderLabel = '폴더 추가',
    this.emptyWidget,
  });

  @override
  State<CommonDraggableFolderList<TFolder, TItem>> createState() =>
      _CommonDraggableFolderListState<TFolder, TItem>();
}

class _CommonDraggableFolderListState<TFolder, TItem>
    extends State<CommonDraggableFolderList<TFolder, TItem>> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _listKey = GlobalKey();

  int? _editingFolderId;
  final Map<int, TextEditingController> _editControllers = {};

  bool _isDragging = false;
  Timer? _autoScrollTimer;
  double _currentScrollDelta = 0;

  static const double _edgeThreshold = 80.0;
  static const double _scrollSpeed = 8.0;
  static const double _itemPadding = 10.0;

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    for (var controller in _editControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onDragStarted() {
    setState(() {
      _isDragging = true;
    });
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

  void _onDragEnded([DraggableDetails? details]) {
    _stopAutoScroll();
    setState(() {
      _isDragging = false;
    });
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

  void _toggleFolderEdit(TFolder folder) {
    final folderId = widget.getFolderId(folder);
    if (folderId == null) return;

    setState(() {
      if (_editingFolderId == folderId) {
        final controller = _editControllers[folderId];
        if (controller != null && controller.text.isNotEmpty) {
          widget.onFolderNameChanged(folder, controller.text);
        }
        _editingFolderId = null;
        _editControllers.remove(folderId)?.dispose();
      } else {
        _editingFolderId = folderId;
        _editControllers[folderId] = TextEditingController(text: widget.getFolderName(folder));
      }
    });
  }

  void _saveFolderName(TFolder folder, String value) {
    final folderId = widget.getFolderId(folder);
    if (folderId == null) return;

    setState(() {
      if (value.isNotEmpty) {
        widget.onFolderNameChanged(folder, value);
      }
      _editingFolderId = null;
      _editControllers.remove(folderId)?.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = widget.folders.isEmpty && widget.standaloneItems.isEmpty;

    return Column(
      children: [
        Expanded(
          child: isEmpty
              ? (widget.emptyWidget ?? const Center(child: Text('항목이 없습니다')))
              : DragTarget<Map<String, dynamic>>(
                  onWillAcceptWithDetails: (details) {
                    final data = details.data;
                    return data['type'] == widget.itemTypeKey && data['fromFolder'] != null;
                  },
                  onAcceptWithDetails: (details) {
                    final data = details.data;
                    final item = data['item'] as TItem;
                    final fromFolder = data['fromFolder'] as TFolder?;
                    if (fromFolder != null) {
                      widget.onMoveItemOutOfFolder(item, fromFolder);
                    }
                  },
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      decoration: candidateData.isNotEmpty
                          ? BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            )
                          : null,
                      child: ListView.builder(
                        key: _listKey,
                        controller: _scrollController,
                        itemCount: widget.folders.length +
                            widget.standaloneItems.length +
                            (widget.standaloneItems.isNotEmpty ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index < widget.folders.length) {
                            return _buildFolderItem(widget.folders[index]);
                          } else {
                            final standaloneIndex = index - widget.folders.length;
                            if (standaloneIndex < widget.standaloneItems.length) {
                              return _buildItemWidget(
                                widget.standaloneItems[standaloneIndex],
                                null,
                                standaloneIndex,
                              );
                            } else {
                              // 마지막 드롭 슬롯
                              return _buildDropSlot(widget.standaloneItems.length, null);
                            }
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CommonButton.outlined(
                onPressed: widget.onAddFolder,
                icon: Icons.folder_outlined,
                label: widget.addFolderLabel,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CommonButton.filled(
                onPressed: () => widget.onAddItem(null),
                icon: Icons.add,
                label: widget.addItemLabel,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFolderItem(TFolder folder) {
    final folderId = widget.getFolderId(folder);
    final folderName = widget.getFolderName(folder);
    final isExpanded = widget.getFolderExpanded(folder);
    final folderItems = widget.getFolderItems(folder);

    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        return data['type'] == widget.itemTypeKey && data['fromFolder'] != folder;
      },
      onAcceptWithDetails: (details) {
        final data = details.data;
        final item = data['item'] as TItem;
        final fromFolder = data['fromFolder'] as TFolder?;
        widget.onMoveItemToFolder(item, fromFolder, folder);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          key: ValueKey('folder_$folderId'),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
            border: Border.all(
              color: candidateData.isNotEmpty
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withValues(alpha: UIConstants.opacityMedium),
              width: candidateData.isNotEmpty ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  widget.onFolderExpandedChanged(folder, !isExpanded);
                },
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _itemPadding,
                    vertical: _itemPadding,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.folder_outlined,
                        size: UIConstants.iconSizeLarge,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: UIConstants.spacing12),
                      Expanded(
                        child: _editingFolderId == folderId
                            ? TextField(
                                controller: _editControllers[folderId],
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                autofocus: true,
                                onSubmitted: (value) => _saveFolderName(folder, value),
                              )
                            : Text(
                                folderName,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                      ),
                      GestureDetector(
                        onTap: () => _toggleFolderEdit(folder),
                        child: Icon(
                          _editingFolderId == folderId ? Icons.check : Icons.edit_outlined,
                          size: UIConstants.iconSizeMedium,
                        ),
                      ),
                      const SizedBox(width: UIConstants.spacing12),
                      GestureDetector(
                        onTap: () => widget.onDeleteFolder(folder),
                        child: const Icon(Icons.delete_outline, size: UIConstants.iconSizeMedium),
                      ),
                      const SizedBox(width: UIConstants.spacing12),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: UIConstants.iconSizeLarge,
                      ),
                    ],
                  ),
                ),
              ),
              if (isExpanded) ...[
                const Divider(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      for (int i = 0; i < folderItems.length; i++)
                        _buildItemWidget(folderItems[i], folder, i),
                      if (folderItems.isNotEmpty) _buildDropSlot(folderItems.length, folder),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: CommonButton.outlined(
                      onPressed: () => widget.onAddItem(folder),
                      icon: Icons.add,
                      iconSize: 16,
                      label: widget.addItemLabel,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDropSlot(int targetIndex, TFolder? folder) {
    if (!_isDragging) {
      return const SizedBox.shrink();
    }
    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        if (data['type'] != widget.itemTypeKey) return false;
        if (data['fromFolder'] != folder) return false;

        final draggedItem = data['item'] as TItem;
        final list = folder != null ? widget.getFolderItems(folder) : widget.standaloneItems;
        final draggedIndex = list.indexOf(draggedItem);

        // 자기 바로 앞이나 뒤 슬롯은 무의미
        if (draggedIndex == targetIndex || draggedIndex == targetIndex - 1) {
          return false;
        }
        return true;
      },
      onAcceptWithDetails: (details) {
        final data = details.data;
        final draggedItem = data['item'] as TItem;
        widget.onReorderItem(draggedItem, targetIndex, folder);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return SizedBox(
          height: 16,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: isHovering ? 3 : 0,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDefaultDragFeedback(BuildContext context, TItem item) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
      child: Container(
        width: 300,
        padding: const EdgeInsets.symmetric(horizontal: _itemPadding, vertical: _itemPadding),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
        ),
        child: Row(
          children: [
            if (widget.getItemIcon != null) ...[
              Icon(
                widget.getItemIcon!(item),
                size: UIConstants.iconSizeMedium,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: UIConstants.spacing12),
            ],
            Expanded(
              child: Text(
                widget.getItemName?.call(item) ?? '',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemWidget(TItem item, TFolder? folder, int index) {
    return Column(
      children: [
        _buildDropSlot(index, folder),
        LongPressDraggable<Map<String, dynamic>>(
          data: {
            'type': widget.itemTypeKey,
            'item': item,
            'fromFolder': folder,
          },
          onDragStarted: _onDragStarted,
          onDragUpdate: _handleDragUpdate,
          onDragEnd: _onDragEnded,
          feedback: widget.dragFeedbackBuilder?.call(context, item) ??
              _buildDefaultDragFeedback(context, item),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: widget.itemContentBuilder(context, item, folder),
          ),
          child: widget.itemContentBuilder(context, item, folder),
        ),
      ],
    );
  }
}
