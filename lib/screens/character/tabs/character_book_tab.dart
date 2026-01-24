import 'package:flutter/material.dart';

import '../../../constants/ui_constants.dart';
import '../../../models/character/character_book_folder.dart';
import '../../../utils/common_dialog.dart';
import '../../../widgets/common/common_editable_expandable_item.dart';
import '../../../widgets/common/common_title_medium.dart';

class CharacterBookTab extends StatefulWidget {
  final List<CharacterBookFolder> folders;
  final List<CharacterBook> standaloneCharacterBooks;
  final VoidCallback onUpdate;

  const CharacterBookTab({
    super.key,
    required this.folders,
    required this.standaloneCharacterBooks,
    required this.onUpdate,
  });

  @override
  State<CharacterBookTab> createState() => _CharacterBookTabState();
}

class _CharacterBookTabState extends State<CharacterBookTab> {
  static const double _characterBookItemHorizontalPadding = 10.0;
  static const double _characterBookItemVerticalPadding = 10.0;
  static const double _segmentedButtonBorderRadius = 8.0;

  int? _editingFolderId;
  final Map<int, TextEditingController> _editControllers = {};
  final Map<String, TextEditingController> _fieldControllers = {};

  int _nextTempId = -1;
  int _getNextTempId() => _nextTempId--;

  @override
  void dispose() {
    for (var controller in _editControllers.values) {
      controller.dispose();
    }
    for (var controller in _fieldControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _getFieldController(String key, String initialValue) {
    if (!_fieldControllers.containsKey(key)) {
      _fieldControllers[key] = TextEditingController(text: initialValue);
    }
    return _fieldControllers[key]!;
  }

  void _notifyUpdate() {
    widget.onUpdate();
    setState(() {});
  }

  void _addFolder() {
    setState(() {
      final newFolder = CharacterBookFolder(
        id: _getNextTempId(),
        characterId: -1, // Will be set when saving
        name: '새 폴더',
        order: widget.folders.length,
      );
      widget.folders.add(newFolder);
    });
    _notifyUpdate();
  }

  void _addCharacterBook(CharacterBookFolder? folder) {
    setState(() {
      final newCharacterBook = CharacterBook(
        id: _getNextTempId(),
        characterId: -1, // Will be set when saving
        folderId: folder?.id,
        name: '새 캐릭터북',
        order: folder != null ? folder.characterBooks.length : widget.standaloneCharacterBooks.length,
        isExpanded: true,
      );

      if (folder != null) {
        folder.characterBooks.add(newCharacterBook);
      } else {
        widget.standaloneCharacterBooks.add(newCharacterBook);
      }
    });
    _notifyUpdate();
  }

  Future<void> _deleteFolder(CharacterBookFolder folder) async {
    final confirmed = await CommonDialog.showConfirmation(
      context: context,
      title: '폴더 삭제',
      content: '${folder.name} 폴더를 삭제하시겠습니까?\n폴더 내 모든 캐릭터북도 함께 삭제됩니다.',
      confirmText: '삭제',
      isDestructive: true,
    );

    if (confirmed == true) {
      setState(() {
        widget.folders.remove(folder);
      });
      _notifyUpdate();
    }
  }

  Future<void> _deleteCharacterBook(CharacterBook characterBook, CharacterBookFolder? folder) async {
    final confirmed = await CommonDialog.showDeleteConfirmation(
      context: context,
      itemName: characterBook.name,
    );

    if (confirmed) {
      setState(() {
        if (folder != null) {
          folder.characterBooks.remove(characterBook);
        } else {
          widget.standaloneCharacterBooks.remove(characterBook);
        }
      });
      _notifyUpdate();
    }
  }

  void _moveCharacterBookToFolder(CharacterBook characterBook, CharacterBookFolder? fromFolder, CharacterBookFolder toFolder) {
    setState(() {
      if (fromFolder != null) {
        fromFolder.characterBooks.remove(characterBook);
      } else {
        widget.standaloneCharacterBooks.remove(characterBook);
      }
      toFolder.characterBooks.add(characterBook);
      characterBook.order = toFolder.characterBooks.length - 1;
    });
    _notifyUpdate();
  }

  void _moveCharacterBookOutOfFolder(CharacterBook characterBook, CharacterBookFolder fromFolder) {
    setState(() {
      fromFolder.characterBooks.remove(characterBook);
      widget.standaloneCharacterBooks.add(characterBook);
      characterBook.order = widget.standaloneCharacterBooks.length - 1;
    });
    _notifyUpdate();
  }

  void _reorderCharacterBookInFolder(CharacterBook draggedCharacterBook, CharacterBook targetCharacterBook, CharacterBookFolder? folder) {
    setState(() {
      if (folder != null) {
        // 폴더 내에서 순서 변경
        final characterBooks = folder.characterBooks;
        final draggedIndex = characterBooks.indexOf(draggedCharacterBook);
        final targetIndex = characterBooks.indexOf(targetCharacterBook);

        if (draggedIndex != -1 && targetIndex != -1) {
          characterBooks.removeAt(draggedIndex);
          final newIndex = characterBooks.indexOf(targetCharacterBook);
          characterBooks.insert(newIndex, draggedCharacterBook);

          // order 업데이트
          for (var i = 0; i < characterBooks.length; i++) {
            characterBooks[i].order = i;
          }
        }
      } else {
        // standalone 캐릭터북 순서 변경
        final characterBooks = widget.standaloneCharacterBooks;
        final draggedIndex = characterBooks.indexOf(draggedCharacterBook);
        final targetIndex = characterBooks.indexOf(targetCharacterBook);

        if (draggedIndex != -1 && targetIndex != -1) {
          characterBooks.removeAt(draggedIndex);
          final newIndex = characterBooks.indexOf(targetCharacterBook);
          characterBooks.insert(newIndex, draggedCharacterBook);

          // order 업데이트
          for (var i = 0; i < characterBooks.length; i++) {
            characterBooks[i].order = i;
          }
        }
      }
    });
    _notifyUpdate();
  }

  void _toggleFolderEdit(CharacterBookFolder folder) {
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

  void _saveFolderName(CharacterBookFolder folder, String value) {
    setState(() {
      if (value.isNotEmpty) {
        folder.name = value;
      }
      _editingFolderId = null;
      _editControllers.remove(folder.id!)?.dispose();
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 5),
            child: CommonTitleMediumWithHelp(
              label: '캐릭터북',
              helpMessage: '캐릭터의 세계관과 관련된 정보를 캐릭터북에 추가할 수 있습니다.',
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: widget.folders.isEmpty && widget.standaloneCharacterBooks.isEmpty
                ? const Center(
                    child: Text('캐릭터북 항목이 없습니다'),
                  )
                : DragTarget<Map<String, dynamic>>(
                    onWillAcceptWithDetails: (details) {
                      final data = details.data;
                      return data['type'] == 'characterBook' && data['fromFolder'] != null;
                    },
                    onAcceptWithDetails: (details) {
                      final data = details.data;
                      final characterBook = data['characterBook'] as CharacterBook;
                      final fromFolder = data['fromFolder'] as CharacterBookFolder?;
                      if (fromFolder != null) {
                        _moveCharacterBookOutOfFolder(characterBook, fromFolder);
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
                          itemCount: widget.folders.length + widget.standaloneCharacterBooks.length,
                          itemBuilder: (context, index) {
                            if (index < widget.folders.length) {
                              return _buildFolderItem(widget.folders[index]);
                            } else {
                              return _buildCharacterBookItem(
                                widget.standaloneCharacterBooks[index - widget.folders.length],
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
                  onPressed: () => _addCharacterBook(null),
                  icon: const Icon(Icons.add),
                  label: const Text('캐릭터북 추가'),
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

  Widget _buildFolderItem(CharacterBookFolder folder) {
    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        return data['type'] == 'characterBook' && data['fromFolder'] != folder;
      },
      onAcceptWithDetails: (details) {
        final data = details.data;
        final characterBook = data['characterBook'] as CharacterBook;
        final fromFolder = data['fromFolder'] as CharacterBookFolder?;
        _moveCharacterBookToFolder(characterBook, fromFolder, folder);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          key: ValueKey(folder.id),
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
                  setState(() {
                    folder.isExpanded = !folder.isExpanded;
                  });
                },
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _characterBookItemHorizontalPadding,
                    vertical: _characterBookItemVerticalPadding,
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
                          size: UIConstants.iconSizeMedium,
                        ),
                      ),
                      const SizedBox(width: UIConstants.spacing12),
                      GestureDetector(
                        onTap: () => _deleteFolder(folder),
                        child: const Icon(Icons.delete_outline, size: UIConstants.iconSizeMedium),
                      ),
                      const SizedBox(width: UIConstants.spacing12),
                      Icon(
                        folder.isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: UIConstants.iconSizeLarge,
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
                    children: folder.characterBooks.map((characterBook) => _buildCharacterBookItem(characterBook, folder)).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _addCharacterBook(folder),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('캐릭터북 추가', style: TextStyle(fontSize: 13)),
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

  Widget _buildCharacterBookItem(CharacterBook characterBook, CharacterBookFolder? folder) {
    return LongPressDraggable<Map<String, dynamic>>(
      data: {
        'type': 'characterBook',
        'characterBook': characterBook,
        'fromFolder': folder,
      },
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 300,
          padding: const EdgeInsets.symmetric(
            horizontal: _characterBookItemHorizontalPadding,
            vertical: _characterBookItemVerticalPadding,
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
                  characterBook.name,
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
        child: _buildCharacterBookCard(characterBook, folder),
      ),
      child: DragTarget<Map<String, dynamic>>(
        onWillAcceptWithDetails: (details) {
          final data = details.data;
          // 같은 폴더 내에서만 순서 변경 허용
          return data['type'] == 'characterBook' &&
                 data['characterBook'] != characterBook &&
                 data['fromFolder'] == folder;
        },
        onAcceptWithDetails: (details) {
          final data = details.data;
          final draggedCharacterBook = data['characterBook'] as CharacterBook;
          _reorderCharacterBookInFolder(draggedCharacterBook, characterBook, folder);
        },
        builder: (context, candidateData, rejectedData) {
          return Container(
            decoration: candidateData.isNotEmpty
                ? BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
                  )
                : null,
            child: _buildCharacterBookCard(characterBook, folder),
          );
        },
      ),
    );
  }

  Widget _buildCharacterBookCard(CharacterBook characterBook, CharacterBookFolder? folder) {
    return CommonEditableExpandableItem(
      key: ValueKey(characterBook.id),
      icon: Icon(
        Icons.description_outlined,
        size: UIConstants.iconSizeMedium,
        color: Theme.of(context).colorScheme.secondary,
      ),
      name: characterBook.name,
      isExpanded: characterBook.isExpanded,
      onToggleExpanded: () {
        setState(() {
          characterBook.isExpanded = !characterBook.isExpanded;
        });
      },
      onDelete: () => _deleteCharacterBook(characterBook, folder),
      nameHint: '캐릭터북 이름',
      onNameChanged: (value) {
        characterBook.name = value;
        _notifyUpdate();
      },
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActivationConditionField(characterBook),
          if (characterBook.enabled == CharacterBookActivationCondition.keyBased) ...[
            _buildActivationKeysField(characterBook),
            _buildKeyConditionField(characterBook),
          ],
          _buildDeploymentOrderField(characterBook),
          _buildContentField(characterBook),
        ],
      ),
    );
  }

  Widget _buildActivationConditionField(CharacterBook characterBook) {
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
          child: SegmentedButton<CharacterBookActivationCondition>(
            showSelectedIcon: false,
            segments: CharacterBookActivationCondition.values
                .map((condition) => ButtonSegment(
                      value: condition,
                      label: Text(condition.displayName, style: const TextStyle(fontSize: 13)),
                    ))
                .toList(),
            selected: {characterBook.enabled},
            onSelectionChanged: (Set<CharacterBookActivationCondition> selected) {
              setState(() {
                characterBook.enabled = selected.first;
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

  Widget _buildActivationKeysField(CharacterBook characterBook) {
    final key = 'characterBook_${characterBook.id}_keys';
    final controller = _getFieldController(key, characterBook.keys.join(', '));

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
            characterBook.keys = value
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

  Widget _buildKeyConditionField(CharacterBook characterBook) {
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
          child: SegmentedButton<CharacterBookKeyCondition>(
            showSelectedIcon: false,
            segments: CharacterBookKeyCondition.values
                .map((condition) => ButtonSegment(
                      value: condition,
                      label: Text(condition.displayName, style: const TextStyle(fontSize: 13)),
                    ))
                .toList(),
            selected: {characterBook.keyCondition},
            onSelectionChanged: (Set<CharacterBookKeyCondition> selected) {
              setState(() {
                characterBook.keyCondition = selected.first;
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

  Widget _buildDeploymentOrderField(CharacterBook characterBook) {
    final key = 'characterBook_${characterBook.id}_insertionOrder';
    final controller = _getFieldController(key, characterBook.insertionOrder.toString());

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
              characterBook.insertionOrder = intValue;
              _notifyUpdate();
            }
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildContentField(CharacterBook characterBook) {
    final key = 'characterBook_${characterBook.id}_content';
    final controller = _getFieldController(key, characterBook.content ?? '');

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
            hintText: '캐릭터북 내용을 입력해주세요',
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
            characterBook.content = value;
            _notifyUpdate();
          },
        ),
      ],
    );
  }
}
