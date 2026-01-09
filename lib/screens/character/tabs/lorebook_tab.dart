import 'package:flutter/material.dart';

import '../../../constants/ui_constants.dart';
import '../../../models/character/lorebook_folder.dart';

class LorebookTab extends StatefulWidget {
  final List<LorebookFolder> folders;
  final List<Lorebook> standaloneLorebooks;
  final VoidCallback onUpdate;

  const LorebookTab({
    super.key,
    required this.folders,
    required this.standaloneLorebooks,
    required this.onUpdate,
  });

  @override
  State<LorebookTab> createState() => _LorebookTabState();
}

class _LorebookTabState extends State<LorebookTab> {
  static const double _lorebookItemHorizontalPadding = 10.0;
  static const double _lorebookItemVerticalPadding = 10.0;
  static const double _segmentedButtonBorderRadius = 8.0;

  int? _editingFolderId;
  int? _editingLorebookId;
  final Map<int, TextEditingController> _editControllers = {};

  int _nextTempId = -1;
  int _getNextTempId() => _nextTempId--;

  @override
  void dispose() {
    for (var controller in _editControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _notifyUpdate() {
    widget.onUpdate();
    setState(() {});
  }

  void _addFolder() {
    setState(() {
      final newFolder = LorebookFolder(
        id: _getNextTempId(),
        characterId: -1, // Will be set when saving
        name: '새 폴더',
        order: widget.folders.length,
      );
      widget.folders.add(newFolder);
    });
    _notifyUpdate();
  }

  void _addLorebook(LorebookFolder? folder) {
    setState(() {
      final newLorebook = Lorebook(
        id: _getNextTempId(),
        characterId: -1, // Will be set when saving
        folderId: folder?.id,
        name: '새 로어북',
        order: folder != null ? folder.lorebooks.length : widget.standaloneLorebooks.length,
        isExpanded: true,
      );

      if (folder != null) {
        folder.lorebooks.add(newLorebook);
      } else {
        widget.standaloneLorebooks.add(newLorebook);
      }
    });
    _notifyUpdate();
  }

  void _deleteFolder(LorebookFolder folder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('폴더 삭제'),
        content: Text('${folder.name} 폴더를 삭제하시겠습니까?\n폴더 내 모든 로어북도 함께 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                widget.folders.remove(folder);
              });
              _notifyUpdate();
              Navigator.pop(context);
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _deleteLorebook(Lorebook lorebook, LorebookFolder? folder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로어북 삭제'),
        content: Text('${lorebook.name}을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                if (folder != null) {
                  folder.lorebooks.remove(lorebook);
                } else {
                  widget.standaloneLorebooks.remove(lorebook);
                }
              });
              _notifyUpdate();
              Navigator.pop(context);
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _moveLorebookToFolder(Lorebook lorebook, LorebookFolder? fromFolder, LorebookFolder toFolder) {
    setState(() {
      if (fromFolder != null) {
        fromFolder.lorebooks.remove(lorebook);
      } else {
        widget.standaloneLorebooks.remove(lorebook);
      }
      toFolder.lorebooks.add(lorebook);
      lorebook.order = toFolder.lorebooks.length - 1;
    });
    _notifyUpdate();
  }

  void _moveLorebookOutOfFolder(Lorebook lorebook, LorebookFolder fromFolder) {
    setState(() {
      fromFolder.lorebooks.remove(lorebook);
      widget.standaloneLorebooks.add(lorebook);
      lorebook.order = widget.standaloneLorebooks.length - 1;
    });
    _notifyUpdate();
  }

  void _toggleFolderEdit(LorebookFolder folder) {
    setState(() {
      if (_editingFolderId == folder.id) {
        final controller = _editControllers[folder.id!];
        if (controller != null && controller.text.isNotEmpty) {
          folder.name = controller.text;
        }
        _editingFolderId = null;
        _editControllers.remove(folder.id!)?.dispose();
        _notifyUpdate();
      } else {
        _editingFolderId = folder.id;
        _editControllers[folder.id!] = TextEditingController(text: folder.name);
      }
    });
  }

  void _saveFolderName(LorebookFolder folder, String value) {
    setState(() {
      if (value.isNotEmpty) {
        folder.name = value;
      }
      _editingFolderId = null;
      _editControllers.remove(folder.id!)?.dispose();
    });
    _notifyUpdate();
  }

  void _toggleLorebookEdit(Lorebook lorebook) {
    setState(() {
      if (_editingLorebookId == lorebook.id) {
        final controller = _editControllers[lorebook.id!];
        if (controller != null && controller.text.isNotEmpty) {
          lorebook.name = controller.text;
        }
        _editingLorebookId = null;
        _editControllers.remove(lorebook.id!)?.dispose();
        _notifyUpdate();
      } else {
        _editingLorebookId = lorebook.id;
        _editControllers[lorebook.id!] = TextEditingController(text: lorebook.name);
      }
    });
  }

  void _saveLorebookName(Lorebook lorebook, String value) {
    setState(() {
      if (value.isNotEmpty) {
        lorebook.name = value;
      }
      _editingLorebookId = null;
      _editControllers.remove(lorebook.id!)?.dispose();
    });
    _notifyUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(UIConstants.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '로어북',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        content: const Text('캐릭터의 세계관과 관련된 정보를 로어북에 추가할 수 있습니다.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('확인'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Icon(
                    Icons.help_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: widget.folders.isEmpty && widget.standaloneLorebooks.isEmpty
                ? const Center(
                    child: Text('로어북 항목이 없습니다'),
                  )
                : DragTarget<Map<String, dynamic>>(
                    onWillAcceptWithDetails: (details) {
                      final data = details.data;
                      return data['type'] == 'lorebook' && data['fromFolder'] != null;
                    },
                    onAcceptWithDetails: (details) {
                      final data = details.data;
                      final lorebook = data['lorebook'] as Lorebook;
                      final fromFolder = data['fromFolder'] as LorebookFolder?;
                      if (fromFolder != null) {
                        _moveLorebookOutOfFolder(lorebook, fromFolder);
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
                          itemCount: widget.folders.length + widget.standaloneLorebooks.length,
                          itemBuilder: (context, index) {
                            if (index < widget.folders.length) {
                              return _buildFolderItem(widget.folders[index]);
                            } else {
                              return _buildLorebookItem(
                                widget.standaloneLorebooks[index - widget.folders.length],
                                null,
                              );
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
                child: OutlinedButton.icon(
                  onPressed: _addFolder,
                  icon: const Icon(Icons.folder_outlined),
                  label: const Text('폴더 추가'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _addLorebook(null),
                  icon: const Icon(Icons.add),
                  label: const Text('로어북 추가'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFolderItem(LorebookFolder folder) {
    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        return data['type'] == 'lorebook' && data['fromFolder'] != folder;
      },
      onAcceptWithDetails: (details) {
        final data = details.data;
        final lorebook = data['lorebook'] as Lorebook;
        final fromFolder = data['fromFolder'] as LorebookFolder?;
        _moveLorebookToFolder(lorebook, fromFolder, folder);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          key: ValueKey(folder.id),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: candidateData.isNotEmpty
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              width: candidateData.isNotEmpty ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    folder.isExpanded = !folder.isExpanded;
                  });
                },
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _lorebookItemHorizontalPadding,
                    vertical: _lorebookItemVerticalPadding,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.folder_outlined,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _editingFolderId == folder.id
                            ? TextField(
                                controller: _editControllers[folder.id!],
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
                                folder.name,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                      ),
                      GestureDetector(
                        onTap: () => _toggleFolderEdit(folder),
                        child: Icon(
                          _editingFolderId == folder.id ? Icons.check : Icons.edit_outlined,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _deleteFolder(folder),
                        child: const Icon(Icons.delete_outline, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        folder.isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              if (folder.isExpanded) ...[
                const Divider(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: folder.lorebooks.map((lorebook) => _buildLorebookItem(lorebook, folder)).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _addLorebook(folder),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('로어북 추가', style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        overlayColor: Colors.transparent,
                      ),
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

  Widget _buildLorebookItem(Lorebook lorebook, LorebookFolder? folder) {
    return LongPressDraggable<Map<String, dynamic>>(
      data: {
        'type': 'lorebook',
        'lorebook': lorebook,
        'fromFolder': folder,
      },
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 300,
          padding: const EdgeInsets.symmetric(
            horizontal: _lorebookItemHorizontalPadding,
            vertical: _lorebookItemVerticalPadding,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  lorebook.name,
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildLorebookCard(lorebook, folder),
      ),
      child: _buildLorebookCard(lorebook, folder),
    );
  }

  Widget _buildLorebookCard(Lorebook lorebook, LorebookFolder? folder) {
    return Container(
      key: ValueKey(lorebook.id),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                lorebook.isExpanded = !lorebook.isExpanded;
              });
            },
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: _lorebookItemHorizontalPadding,
                vertical: _lorebookItemVerticalPadding,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _editingLorebookId == lorebook.id
                        ? TextField(
                            controller: _editControllers[lorebook.id!],
                            style: Theme.of(context).textTheme.bodyMedium,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            autofocus: true,
                            onSubmitted: (value) => _saveLorebookName(lorebook, value),
                          )
                        : Text(
                            lorebook.name,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                  ),
                  GestureDetector(
                    onTap: () => _toggleLorebookEdit(lorebook),
                    child: Icon(
                      _editingLorebookId == lorebook.id ? Icons.check : Icons.edit_outlined,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _deleteLorebook(lorebook, folder),
                    child: const Icon(Icons.delete_outline, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    lorebook.isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (lorebook.isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildActivationConditionField(lorebook),
                  if (lorebook.activationCondition == LorebookActivationCondition.keyBased) ...[
                    _buildActivationKeysField(lorebook),
                    _buildKeyConditionField(lorebook),
                  ],
                  _buildDeploymentOrderField(lorebook),
                  _buildContentField(lorebook),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivationConditionField(Lorebook lorebook) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '활성화 조건',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<LorebookActivationCondition>(
            showSelectedIcon: false,
            segments: LorebookActivationCondition.values
                .map((condition) => ButtonSegment(
                      value: condition,
                      label: Text(condition.displayName, style: const TextStyle(fontSize: 13)),
                    ))
                .toList(),
            selected: {lorebook.activationCondition},
            onSelectionChanged: (Set<LorebookActivationCondition> selected) {
              setState(() {
                lorebook.activationCondition = selected.first;
              });
              _notifyUpdate();
            },
            style: ButtonStyle(
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_segmentedButtonBorderRadius),
                ),
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildActivationKeysField(Lorebook lorebook) {
    final controller = TextEditingController(text: lorebook.activationKeys.join(', '));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '활성화 키',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 2),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: '쉼표로 구분하여 입력 (예: 마법, 전투)',
            hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
          ),
          style: Theme.of(context).textTheme.bodySmall,
          onChanged: (value) {
            lorebook.activationKeys = value
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
            _notifyUpdate();
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildKeyConditionField(Lorebook lorebook) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '키 사용 조건',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<LorebookKeyCondition>(
            showSelectedIcon: false,
            segments: LorebookKeyCondition.values
                .map((condition) => ButtonSegment(
                      value: condition,
                      label: Text(condition.displayName, style: const TextStyle(fontSize: 13)),
                    ))
                .toList(),
            selected: {lorebook.keyCondition},
            onSelectionChanged: (Set<LorebookKeyCondition> selected) {
              setState(() {
                lorebook.keyCondition = selected.first;
              });
              _notifyUpdate();
            },
            style: ButtonStyle(
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_segmentedButtonBorderRadius),
                ),
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildDeploymentOrderField(Lorebook lorebook) {
    final controller = TextEditingController(text: lorebook.deploymentOrder.toString());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '배치 순서',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 2),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '0',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
          ),
          style: Theme.of(context).textTheme.bodySmall,
          onChanged: (value) {
            final intValue = int.tryParse(value);
            if (intValue != null) {
              lorebook.deploymentOrder = intValue;
              _notifyUpdate();
            }
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildContentField(Lorebook lorebook) {
    final controller = TextEditingController(text: lorebook.content);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '내용',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 2),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: '로어북 내용을 입력해주세요',
            hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
          ),
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: null,
          minLines: 5,
          onChanged: (value) {
            lorebook.content = value;
            _notifyUpdate();
          },
        ),
      ],
    );
  }
}
