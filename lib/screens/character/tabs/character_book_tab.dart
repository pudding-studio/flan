import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  int _getNextMixedOrder() {
    int maxOrder = -1;
    for (final folder in widget.folders) {
      if (folder.order > maxOrder) maxOrder = folder.order;
    }
    for (final item in widget.standaloneCharacterBooks) {
      if (item.order > maxOrder) maxOrder = item.order;
    }
    return maxOrder + 1;
  }

  /// SillyTavern / RisuAI character_book JSON에서 가져오기
  Future<void> _importCharacterBooks() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString);

      if (jsonData is! Map<String, dynamic>) {
        if (mounted) {
          CommonDialog.showSnackBar(
            context: context,
            message: '올바른 설정집 형식이 아닙니다',
          );
        }
        return;
      }

      List<CharacterBook> parsed;
      if (jsonData.containsKey('entries')) {
        parsed = _parseSillyTavernEntries(jsonData['entries'] as List);
      } else if (jsonData.containsKey('data') && jsonData['data'] is List) {
        parsed = _parseRisuAIEntries(jsonData['data'] as List);
      } else {
        if (mounted) {
          CommonDialog.showSnackBar(
            context: context,
            message: '올바른 설정집 형식이 아닙니다',
          );
        }
        return;
      }

      if (parsed.isEmpty) {
        if (mounted) {
          CommonDialog.showSnackBar(
            context: context,
            message: '가져올 설정이 없습니다',
          );
        }
        return;
      }

      setState(() {
        widget.standaloneCharacterBooks.addAll(parsed);
      });
      _notifyUpdate();

      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: '${parsed.length}개 설정을 가져왔습니다',
        );
      }
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: '가져오기 실패: $e',
        );
      }
    }
  }

  List<CharacterBook> _parseSillyTavernEntries(List entries) {
    final result = <CharacterBook>[];
    for (final entry in entries) {
      final item = entry as Map<String, dynamic>;
      final keys = (item['keys'] as List?)
              ?.map((k) => k.toString())
              .where((k) => k.isNotEmpty)
              .toList() ??
          [];
      final secondaryKeys = (item['secondary_keys'] as List?)
              ?.map((k) => k.toString())
              .where((k) => k.isNotEmpty)
              .toList() ??
          [];
      final selective = item['selective'] as bool? ?? false;
      final enabled = item['enabled'] as bool? ?? false;
      final constant = item['constant'] as bool? ?? false;

      CharacterBookActivationCondition condition;
      if (constant) {
        condition = CharacterBookActivationCondition.enabled;
      } else if (enabled) {
        condition = CharacterBookActivationCondition.keyBased;
      } else {
        condition = CharacterBookActivationCondition.disabled;
      }

      result.add(CharacterBook(
        id: _getNextTempId(),
        characterId: -1,
        name: item['name'] as String? ??
            item['comment'] as String? ??
            '설정 ${widget.standaloneCharacterBooks.length + result.length + 1}',
        order: _getNextMixedOrder() + result.length,
        enabled: condition,
        keys: keys,
        secondaryKeyUsage: selective && secondaryKeys.isNotEmpty
            ? CharacterBookSecondaryKeyUsage.enabled
            : CharacterBookSecondaryKeyUsage.disabled,
        secondaryKeys: secondaryKeys,
        insertionOrder: item['insertion_order'] as int? ?? 0,
        content: item['content'] as String?,
      ));
    }
    return result;
  }

  List<CharacterBook> _parseRisuAIEntries(List entries) {
    // Collect folder names to filter from keys
    final folderNames = <String>{};
    for (final entry in entries) {
      final item = entry as Map<String, dynamic>;
      final type = item['type'] as String? ?? '';
      if (type == 'folder') {
        final name = item['name'] as String? ?? item['comment'] as String? ?? '';
        if (name.isNotEmpty) folderNames.add(name);
      }
    }

    final result = <CharacterBook>[];
    for (final entry in entries) {
      final item = entry as Map<String, dynamic>;
      final type = item['type'] as String? ?? '';
      if (type == 'folder') continue;

      final rawKeys = _splitCommaString(item['key'] as String? ?? '');
      final hasFolderKey = rawKeys.any((k) => folderNames.contains(k));
      final keys = rawKeys.where((k) => !folderNames.contains(k)).toList();
      final secondaryKeys = _splitCommaString(item['secondkey'] as String? ?? '');
      final selective = item['selective'] as bool? ?? false;
      final alwaysActive = item['alwaysActive'] as bool? ?? false;

      CharacterBookActivationCondition condition;
      if (alwaysActive || hasFolderKey) {
        condition = CharacterBookActivationCondition.enabled;
      } else if (keys.isNotEmpty) {
        condition = CharacterBookActivationCondition.keyBased;
      } else {
        condition = CharacterBookActivationCondition.disabled;
      }

      result.add(CharacterBook(
        id: _getNextTempId(),
        characterId: -1,
        name: item['comment'] as String? ??
            '설정 ${widget.standaloneCharacterBooks.length + result.length + 1}',
        order: _getNextMixedOrder() + result.length,
        enabled: condition,
        keys: keys,
        secondaryKeyUsage: selective && secondaryKeys.isNotEmpty
            ? CharacterBookSecondaryKeyUsage.enabled
            : CharacterBookSecondaryKeyUsage.disabled,
        secondaryKeys: secondaryKeys,
        insertionOrder: item['insertorder'] as int? ?? 0,
        content: item['content'] as String?,
      ));
    }
    return result;
  }

  List<String> _splitCommaString(String value) {
    return value
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// SillyTavern character_book JSON으로 내보내기
  Future<void> _exportCharacterBooks() async {
    try {
      final allBooks = <CharacterBook>[];
      for (final folder in widget.folders) {
        allBooks.addAll(folder.characterBooks);
      }
      allBooks.addAll(widget.standaloneCharacterBooks);

      if (allBooks.isEmpty) {
        if (mounted) {
          CommonDialog.showSnackBar(
            context: context,
            message: '내보낼 설정이 없습니다',
          );
        }
        return;
      }

      final entries = allBooks.map((cb) => {
            'keys': cb.keys,
            'secondary_keys': cb.secondaryKeys,
            'content': cb.content ?? '',
            'extensions': <String, dynamic>{},
            'enabled': cb.enabled != CharacterBookActivationCondition.disabled,
            'insertion_order': cb.insertionOrder,
            'case_sensitive': false,
            'name': cb.name,
            'priority': 10,
            'id': 0,
            'comment': '',
            'selective': cb.secondaryKeyUsage == CharacterBookSecondaryKeyUsage.enabled,
            'constant': cb.enabled == CharacterBookActivationCondition.enabled,
            'order': cb.order,
          }).toList();

      final jsonString = const JsonEncoder.withIndent('  ').convert({
        'entries': entries,
      });

      if (Platform.isAndroid) {
        const platform = MethodChannel('com.flanapp.flan/file_saver');
        final result = await platform.invokeMethod('saveToDownloads', {
          'fileName': 'character_book.json',
          'content': jsonString,
        });

        if (mounted) {
          CommonDialog.showSnackBar(
            context: context,
            message: result == true
                ? 'Download/character_book.json에 저장되었습니다'
                : '저장에 실패했습니다',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: '내보내기 실패: $e',
        );
      }
    }
  }

  void _addFolder() {
    setState(() {
      final newFolder = CharacterBookFolder(
        id: _getNextTempId(),
        characterId: -1,
        name: '새 폴더',
        order: _getNextMixedOrder(),
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
        name: '새 설정',
        order: folder != null ? folder.characterBooks.length : _getNextMixedOrder(),
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
      content: '${folder.name} 폴더를 삭제하시겠습니까?\n폴더 내 모든 설정도 함께 삭제됩니다.',
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
      characterBook.order = _getNextMixedOrder();
      widget.standaloneCharacterBooks.add(characterBook);
    });
    _notifyUpdate();
  }

  void _reorderCharacterBook(CharacterBook draggedCharacterBook, int targetIndex, CharacterBookFolder? folder) {
    setState(() {
      if (folder != null) {
        final characterBooks = folder.characterBooks;
        final draggedIndex = characterBooks.indexOf(draggedCharacterBook);
        if (draggedIndex == -1) return;
        characterBooks.removeAt(draggedIndex);
        final insertIndex = targetIndex > draggedIndex ? targetIndex - 1 : targetIndex;
        characterBooks.insert(insertIndex.clamp(0, characterBooks.length), draggedCharacterBook);
        for (var i = 0; i < characterBooks.length; i++) {
          characterBooks[i].order = i;
        }
      } else {
        _reassignMixedOrder(movedItem: draggedCharacterBook, targetMixedIndex: targetIndex);
      }
    });
    _notifyUpdate();
  }

  void _reorderFolder(CharacterBookFolder folder, int targetMixedIndex) {
    setState(() {
      _reassignMixedOrder(movedFolder: folder, targetMixedIndex: targetMixedIndex);
    });
    _notifyUpdate();
  }

  void _reassignMixedOrder({CharacterBook? movedItem, CharacterBookFolder? movedFolder, required int targetMixedIndex}) {
    final entries = <Object>[];
    for (final f in widget.folders) entries.add(f);
    for (final i in widget.standaloneCharacterBooks) entries.add(i);
    entries.sort((a, b) {
      final orderA = a is CharacterBookFolder ? a.order : (a as CharacterBook).order;
      final orderB = b is CharacterBookFolder ? b.order : (b as CharacterBook).order;
      return orderA.compareTo(orderB);
    });

    final moved = movedItem ?? movedFolder!;
    final fromIndex = entries.indexOf(moved);
    if (fromIndex != -1) {
      entries.removeAt(fromIndex);
      final insertIndex = fromIndex < targetMixedIndex ? targetMixedIndex - 1 : targetMixedIndex;
      entries.insert(insertIndex.clamp(0, entries.length), moved);
    }

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      if (entry is CharacterBookFolder) {
        entry.order = i;
      } else if (entry is CharacterBook) {
        entry.order = i;
      }
    }
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
              text: '설정집',
              helpMessage: '캐릭터의 세계관과 관련된 정보를 설정집에 추가할 수 있습니다.\n\n'
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
              getFolderOrder: (folder) => folder.order,
              getItemId: (item) => item.id,
              getItemOrder: (item) => item.order,
              itemContentBuilder: _buildCharacterBookCard,
              getItemIcon: (item) => Icons.description_outlined,
              getItemName: (item) => item.name,
              onReorderItem: _reorderCharacterBook,
              onMoveItemToFolder: _moveCharacterBookToFolder,
              onMoveItemOutOfFolder: _moveCharacterBookOutOfFolder,
              onReorderFolder: _reorderFolder,
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
              extraActions: [
                _buildSquareIconButton(
                  icon: Icons.download_outlined,
                  onPressed: _importCharacterBooks,
                ),
                _buildSquareIconButton(
                  icon: Icons.upload_outlined,
                  onPressed: _exportCharacterBooks,
                ),
              ],
              itemTypeKey: 'characterBook',
              addItemLabel: '설정 추가',
              addFolderLabel: '폴더 추가',
              emptyWidget: const CommonEmptyState(
                message: '설정집 항목이 없습니다',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquareIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 48,
      width: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Icon(icon, size: 20),
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
      nameHint: '설정 이름',
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
            _buildSecondaryKeyUsageField(characterBook),
            if (characterBook.secondaryKeyUsage == CharacterBookSecondaryKeyUsage.enabled)
              _buildSecondaryKeysField(characterBook),
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

  Widget _buildSecondaryKeyUsageField(CharacterBook characterBook) {
    return CommonFieldSection(
      label: '두번째 키',
      child: CommonSegmentedButton<CharacterBookSecondaryKeyUsage>(
        values: CharacterBookSecondaryKeyUsage.values,
        selected: characterBook.secondaryKeyUsage,
        onSelectionChanged: (selected) {
          setState(() {
            characterBook.secondaryKeyUsage = selected;
          });
          _notifyUpdate();
        },
        labelBuilder: (usage) => usage.displayName,
      ),
    );
  }

  Widget _buildSecondaryKeysField(CharacterBook characterBook) {
    final key = 'characterBook_${characterBook.id}_secondaryKeys';
    final controller = _getFieldController(key, characterBook.secondaryKeys.join(', '));

    return CommonFieldSection(
      label: '두번째 키',
      child: CommonEditText(
        controller: controller,
        hintText: '쉼표로 구분하여 입력 (예: 마법, 전투)',
        size: CommonEditTextSize.small,
        onFocusLost: (value) {
          characterBook.secondaryKeys = value
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
          _notifyUpdate(rebuildUI: false);
        },
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
        hintText: '설정 내용을 입력해주세요',
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
