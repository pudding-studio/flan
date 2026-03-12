import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/ui_constants.dart';
import 'common_button.dart';

/// 통합 리스트 엔트리 (폴더 또는 standalone 아이템)
class _MixedEntry<TFolder, TItem> {
  final TFolder? folder;
  final TItem? item;
  final int order;

  bool get isFolder => folder != null;

  _MixedEntry.folder(this.folder, this.order) : item = null;
  _MixedEntry.item(this.item, this.order) : folder = null;
}

/// 드래그 가능한 폴더+아이템 리스트 위젯
///
/// 폴더와 단독 아이템을 order 기준으로 혼합 배치하고,
/// 슬롯 기반 드래그로 재정렬할 수 있습니다.
class CommonDraggableFolderList<TFolder, TItem> extends StatefulWidget {
  final List<TFolder> folders;
  final List<TItem> standaloneItems;

  final int? Function(TFolder folder) getFolderId;
  final String Function(TFolder folder) getFolderName;
  final bool Function(TFolder folder) getFolderExpanded;
  final List<TItem> Function(TFolder folder) getFolderItems;
  final int Function(TFolder folder) getFolderOrder;
  final int? Function(TItem item) getItemId;
  final int Function(TItem item) getItemOrder;

  final Widget Function(BuildContext context, TItem item, TFolder? folder) itemContentBuilder;
  final IconData Function(TItem item)? getItemIcon;
  final String Function(TItem item)? getItemName;
  final Widget Function(BuildContext context, TItem item)? dragFeedbackBuilder;

  final void Function(TItem item, int targetIndex, TFolder? folder) onReorderItem;
  final void Function(TItem item, TFolder? fromFolder, TFolder toFolder) onMoveItemToFolder;
  final void Function(TItem item, TFolder fromFolder) onMoveItemOutOfFolder;
  final void Function(TFolder folder, int targetIndex) onReorderFolder;
  final void Function(TFolder folder, String newName) onFolderNameChanged;
  final void Function(TFolder folder, bool isExpanded) onFolderExpandedChanged;
  final void Function(TFolder folder) onDeleteFolder;
  final void Function(TFolder? folder) onAddItem;
  final VoidCallback onAddFolder;

  final String itemTypeKey;
  final String addItemLabel;
  final String addFolderLabel;
  final List<Widget>? extraActions;
  final Widget? emptyWidget;
  final bool readOnly;
  final bool shrinkWrap;
  final ScrollController? scrollController;

  const CommonDraggableFolderList({
    super.key,
    required this.folders,
    required this.standaloneItems,
    required this.getFolderId,
    required this.getFolderName,
    required this.getFolderExpanded,
    required this.getFolderItems,
    required this.getFolderOrder,
    required this.getItemId,
    required this.getItemOrder,
    required this.itemContentBuilder,
    this.getItemIcon,
    this.getItemName,
    this.dragFeedbackBuilder,
    required this.onReorderItem,
    required this.onMoveItemToFolder,
    required this.onMoveItemOutOfFolder,
    required this.onReorderFolder,
    required this.onFolderNameChanged,
    required this.onFolderExpandedChanged,
    required this.onDeleteFolder,
    required this.onAddItem,
    required this.onAddFolder,
    required this.itemTypeKey,
    this.addItemLabel = '항목 추가',
    this.addFolderLabel = '폴더 추가',
    this.extraActions,
    this.emptyWidget,
    this.readOnly = false,
    this.shrinkWrap = false,
    this.scrollController,
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

  List<_MixedEntry<TFolder, TItem>> _buildMixedEntries() {
    final entries = <_MixedEntry<TFolder, TItem>>[];
    for (final folder in widget.folders) {
      entries.add(_MixedEntry.folder(folder, widget.getFolderOrder(folder)));
    }
    for (final item in widget.standaloneItems) {
      entries.add(_MixedEntry.item(item, widget.getItemOrder(item)));
    }
    entries.sort((a, b) => a.order.compareTo(b.order));
    return entries;
  }

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
    final entries = _buildMixedEntries();

    final listWidget = isEmpty
        ? (widget.emptyWidget ?? const Center(child: Text('항목이 없습니다')))
        : ListView.builder(
            key: _listKey,
            controller: widget.shrinkWrap ? null : (widget.scrollController ?? _scrollController),
            shrinkWrap: widget.shrinkWrap,
            physics: widget.shrinkWrap ? const NeverScrollableScrollPhysics() : null,
            itemCount: entries.length + 1,
            itemBuilder: (context, index) {
              if (index < entries.length) {
                final entry = entries[index];
                if (entry.isFolder) {
                  return _buildDraggableFolderItem(entry.folder as TFolder, index);
                } else {
                  return _buildTopLevelItemWidget(entry.item as TItem, index);
                }
              } else {
                return _buildTopLevelDropSlot(entries.length);
              }
            },
          );

    final actionButtons = !widget.readOnly
        ? Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              spacing: 6,
              children: [
                if (widget.extraActions != null)
                  ...widget.extraActions!,
                Expanded(
                  child: CommonButton.outlined(
                    onPressed: widget.onAddFolder,
                    icon: Icons.folder_outlined,
                    label: widget.addFolderLabel,
                  ),
                ),
                Expanded(
                  child: CommonButton.filled(
                    onPressed: () => widget.onAddItem(null),
                    icon: Icons.add,
                    label: widget.addItemLabel,
                  ),
                ),
              ],
            ),
          )
        : null;

    if (widget.shrinkWrap) {
      return Column(
        children: [
          listWidget,
          if (actionButtons != null) actionButtons,
        ],
      );
    }

    return Column(
      children: [
        Expanded(child: listWidget),
        if (actionButtons != null) actionButtons,
      ],
    );
  }

  Widget _buildTopLevelDropSlot(int targetIndex) {
    if (!_isDragging) {
      return const SizedBox.shrink();
    }
    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        final entries = _buildMixedEntries();

        if (data['type'] == 'folder') {
          final draggedFolder = data['folder'] as TFolder;
          final draggedIndex = entries.indexWhere((e) => e.isFolder && e.folder == draggedFolder);
          if (draggedIndex == targetIndex || draggedIndex == targetIndex - 1) return false;
          return true;
        }

        if (data['type'] == widget.itemTypeKey) {
          if (data['fromFolder'] != null) return true;
          final draggedItem = data['item'] as TItem;
          final draggedIndex = entries.indexWhere((e) => !e.isFolder && e.item == draggedItem);
          if (draggedIndex == targetIndex || draggedIndex == targetIndex - 1) return false;
          return true;
        }

        return false;
      },
      onAcceptWithDetails: (details) {
        final data = details.data;
        if (data['type'] == 'folder') {
          widget.onReorderFolder(data['folder'] as TFolder, targetIndex);
        } else if (data['type'] == widget.itemTypeKey) {
          final item = data['item'] as TItem;
          final fromFolder = data['fromFolder'] as TFolder?;
          if (fromFolder != null) {
            widget.onMoveItemOutOfFolder(item, fromFolder);
          }
          widget.onReorderItem(item, targetIndex, null);
        }
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

  Widget _buildTopLevelItemWidget(TItem item, int mixedIndex) {
    return Column(
      children: [
        _buildTopLevelDropSlot(mixedIndex),
        LongPressDraggable<Map<String, dynamic>>(
          data: {
            'type': widget.itemTypeKey,
            'item': item,
            'fromFolder': null,
          },
          onDragStarted: _onDragStarted,
          onDragUpdate: _handleDragUpdate,
          onDragEnd: _onDragEnded,
          feedback: widget.dragFeedbackBuilder?.call(context, item) ??
              _buildDefaultDragFeedback(context, item),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: widget.itemContentBuilder(context, item, null),
          ),
          child: widget.itemContentBuilder(context, item, null),
        ),
      ],
    );
  }

  Widget _buildDraggableFolderItem(TFolder folder, int mixedIndex) {
    final folderId = widget.getFolderId(folder);
    final folderName = widget.getFolderName(folder);

    return Column(
      children: [
        _buildTopLevelDropSlot(mixedIndex),
        LongPressDraggable<Map<String, dynamic>>(
          data: {
            'type': 'folder',
            'folder': folder,
          },
          onDragStarted: _onDragStarted,
          onDragUpdate: _handleDragUpdate,
          onDragEnd: _onDragEnded,
          feedback: Material(
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
                  Icon(
                    Icons.folder_outlined,
                    size: UIConstants.iconSizeLarge,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: UIConstants.spacing12),
                  Expanded(
                    child: Text(
                      folderName,
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
            child: _buildFolderContent(folder),
          ),
          child: _buildFolderContent(folder),
        ),
      ],
    );
  }

  Widget _buildFolderContent(TFolder folder) {
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
                        _buildFolderItemWidget(folderItems[i], folder, i),
                      if (folderItems.isNotEmpty) _buildFolderDropSlot(folderItems.length, folder),
                    ],
                  ),
                ),
                if (!widget.readOnly)
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

  Widget _buildFolderDropSlot(int targetIndex, TFolder folder) {
    if (!_isDragging) {
      return const SizedBox.shrink();
    }
    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        if (data['type'] != widget.itemTypeKey) return false;
        if (data['fromFolder'] != folder) return false;

        final draggedItem = data['item'] as TItem;
        final list = widget.getFolderItems(folder);
        final draggedIndex = list.indexOf(draggedItem);

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

  Widget _buildFolderItemWidget(TItem item, TFolder folder, int index) {
    return Column(
      children: [
        _buildFolderDropSlot(index, folder),
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
