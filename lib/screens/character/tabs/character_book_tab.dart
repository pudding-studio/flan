import 'package:flutter/material.dart';

import '../../../constants/ui_constants.dart';
import '../../../models/character/character_book_folder.dart';
import '../../../utils/common_dialog.dart';
import '../../../widgets/common/common_draggable_folder_list.dart';
import '../../../widgets/common/common_editable_expandable_item.dart';
import '../../../widgets/common/common_edit_text.dart';
import '../../../widgets/common/common_empty_state.dart';
import '../../../widgets/common/common_field_section.dart';
import '../../../widgets/common/common_segmented_button.dart';
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
  final Map<String, TextEditingController> _fieldControllers = {};

  int _nextTempId = -1;
  int _getNextTempId() => _nextTempId--;

  @override
  void dispose() {
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

  void _notifyUpdate({bool rebuildUI = true}) {
    widget.onUpdate();
    if (rebuildUI) {
      setState(() {});
    }
  }

  void _addFolder() {
    setState(() {
      final newFolder = CharacterBookFolder(
        id: _getNextTempId(),
        characterId: -1,
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
        characterId: -1,
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

  void _reorderCharacterBook(CharacterBook draggedCharacterBook, int targetIndex, CharacterBookFolder? folder) {
    setState(() {
      final characterBooks = folder != null ? folder.characterBooks : widget.standaloneCharacterBooks;
      final draggedIndex = characterBooks.indexOf(draggedCharacterBook);

      if (draggedIndex == -1) return;

      characterBooks.removeAt(draggedIndex);

      final insertIndex = targetIndex > draggedIndex ? targetIndex - 1 : targetIndex;
      characterBooks.insert(insertIndex.clamp(0, characterBooks.length), draggedCharacterBook);

      for (var i = 0; i < characterBooks.length; i++) {
        characterBooks[i].order = i;
      }
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
            child: CommonTitleMedium(
              text: '캐릭터북',
              helpMessage: '캐릭터의 세계관과 관련된 정보를 캐릭터북에 추가할 수 있습니다.\n\n'
                  '길게 눌러 순서를 변경할 수 있습니다.',
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: CommonDraggableFolderList<CharacterBookFolder, CharacterBook>(
              folders: widget.folders,
              standaloneItems: widget.standaloneCharacterBooks,
              getFolderId: (folder) => folder.id,
              getFolderName: (folder) => folder.name,
              getFolderExpanded: (folder) => folder.isExpanded,
              getFolderItems: (folder) => folder.characterBooks,
              getItemId: (item) => item.id,
              itemContentBuilder: _buildCharacterBookCard,
              getItemIcon: (item) => Icons.description_outlined,
              getItemName: (item) => item.name,
              onReorderItem: _reorderCharacterBook,
              onMoveItemToFolder: _moveCharacterBookToFolder,
              onMoveItemOutOfFolder: _moveCharacterBookOutOfFolder,
              onFolderNameChanged: (folder, newName) {
                folder.name = newName;
                _notifyUpdate();
              },
              onFolderExpandedChanged: (folder, isExpanded) {
                setState(() {
                  folder.isExpanded = isExpanded;
                });
              },
              onDeleteFolder: _deleteFolder,
              onAddItem: _addCharacterBook,
              onAddFolder: _addFolder,
              itemTypeKey: 'characterBook',
              addItemLabel: '캐릭터북 추가',
              addFolderLabel: '폴더 추가',
              emptyWidget: const CommonEmptyState(
                message: '캐릭터북 항목이 없습니다',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterBookCard(BuildContext context, CharacterBook characterBook, CharacterBookFolder? folder) {
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
        if (characterBook.isExpanded) {
          FocusScope.of(context).unfocus();
        }
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
    return CommonFieldSection(
      label: '활성화 조건',
      child: CommonSegmentedButton<CharacterBookActivationCondition>(
        values: CharacterBookActivationCondition.values,
        selected: characterBook.enabled,
        onSelectionChanged: (selected) {
          setState(() {
            characterBook.enabled = selected;
          });
          _notifyUpdate();
        },
        labelBuilder: (condition) => condition.displayName,
      ),
    );
  }

  Widget _buildActivationKeysField(CharacterBook characterBook) {
    final key = 'characterBook_${characterBook.id}_keys';
    final controller = _getFieldController(key, characterBook.keys.join(', '));

    return CommonFieldSection(
      label: '활성화 키',
      child: CommonEditText(
        controller: controller,
        hintText: '쉼표로 구분하여 입력 (예: 마법, 전투)',
        size: CommonEditTextSize.small,
        onFocusLost: (value) {
          characterBook.keys = value
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
          _notifyUpdate(rebuildUI: false);
        },
      ),
    );
  }

  Widget _buildKeyConditionField(CharacterBook characterBook) {
    return CommonFieldSection(
      label: '키 사용 조건',
      child: CommonSegmentedButton<CharacterBookKeyCondition>(
        values: CharacterBookKeyCondition.values,
        selected: characterBook.keyCondition,
        onSelectionChanged: (selected) {
          setState(() {
            characterBook.keyCondition = selected;
          });
          _notifyUpdate();
        },
        labelBuilder: (condition) => condition.displayName,
      ),
    );
  }

  Widget _buildDeploymentOrderField(CharacterBook characterBook) {
    final key = 'characterBook_${characterBook.id}_insertionOrder';
    final controller = _getFieldController(key, characterBook.insertionOrder.toString());

    return CommonFieldSection(
      label: '배치 순서',
      child: CommonEditText(
        controller: controller,
        hintText: '0',
        size: CommonEditTextSize.small,
        keyboardType: TextInputType.number,
        onFocusLost: (value) {
          final intValue = int.tryParse(value);
          if (intValue != null) {
            characterBook.insertionOrder = intValue;
            _notifyUpdate(rebuildUI: false);
          }
        },
      ),
    );
  }

  Widget _buildContentField(CharacterBook characterBook) {
    final key = 'characterBook_${characterBook.id}_content';
    final controller = _getFieldController(key, characterBook.content ?? '');

    return CommonFieldSection(
      label: '내용',
      bottomSpacing: 0,
      child: CommonEditText(
        controller: controller,
        hintText: '캐릭터북 내용을 입력해주세요',
        size: CommonEditTextSize.small,
        maxLines: null,
        minLines: 5,
        onFocusLost: (value) {
          characterBook.content = value;
          _notifyUpdate(rebuildUI: false);
        },
      ),
    );
  }
}
