import 'dart:convert';
import 'package:universal_io/io.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
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

/// 설정집 탭.
///
/// 상단 SelectChip으로 카테고리(등장인물·지역/장소·역사/사건·기타)를 필터링하고,
/// 각 카테고리별로 서로 다른 세부 필드를 편집할 수 있다. 폴더 구조는 '기타'
/// 카테고리에서만 활성화된다 — 등장인물·지역/장소·역사/사건은 플랫 리스트다.
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

  /// 현재 필터/작성 중인 카테고리. 신규 항목은 이 값으로 생성된다.
  CharacterBookCategory _selectedCategory = CharacterBookCategory.character;

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

  /// Flat standalone list filtered to the currently selected category.
  /// Non-other categories never use folders, so folder-contained items are
  /// excluded from non-other views.
  List<CharacterBook> _visibleStandalone() {
    return widget.standaloneCharacterBooks
        .where((b) => b.category == _selectedCategory)
        .toList();
  }

  /// Folders are only surfaced in the '기타' category view. Returns an empty
  /// list otherwise so the drag-drop widget hides the folder UI entirely.
  List<CharacterBookFolder> _visibleFolders() {
    if (_selectedCategory != CharacterBookCategory.other) return [];
    return widget.folders;
  }

  /// SillyTavern / RisuAI character_book JSON에서 가져오기
  Future<void> _importCharacterBooks() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString);

      if (jsonData is! Map<String, dynamic>) {
        if (mounted) {
          CommonDialog.showSnackBar(
            context: context,
            message: AppLocalizations.of(context).characterBookInvalidFormat,
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
            message: AppLocalizations.of(context).characterBookInvalidFormat,
          );
        }
        return;
      }

      if (parsed.isEmpty) {
        if (mounted) {
          CommonDialog.showSnackBar(
            context: context,
            message: AppLocalizations.of(context).characterBookNoImport,
          );
        }
        return;
      }

      setState(() {
        // Imported SillyTavern / RisuAI entries don't carry our category,
        // so they all land in '기타' which also makes them visible regardless
        // of which category chip the user currently has selected.
        _selectedCategory = CharacterBookCategory.other;
        widget.standaloneCharacterBooks.addAll(parsed);
      });
      _notifyUpdate();

      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: '${parsed.length} items imported',
        );
      }
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: AppLocalizations.of(context).characterBookImportFailed(e.toString()),
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
            'Item ${widget.standaloneCharacterBooks.length + result.length + 1}',
        order: _getNextMixedOrder() + result.length,
        enabled: condition,
        keys: keys,
        secondaryKeyUsage: selective && secondaryKeys.isNotEmpty
            ? CharacterBookSecondaryKeyUsage.enabled
            : CharacterBookSecondaryKeyUsage.disabled,
        secondaryKeys: secondaryKeys,
        insertionOrder: item['insertion_order'] as int? ?? 0,
        content: item['content'] as String?,
        category: CharacterBookCategory.other,
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
            'Item ${widget.standaloneCharacterBooks.length + result.length + 1}',
        order: _getNextMixedOrder() + result.length,
        enabled: condition,
        keys: keys,
        secondaryKeyUsage: selective && secondaryKeys.isNotEmpty
            ? CharacterBookSecondaryKeyUsage.enabled
            : CharacterBookSecondaryKeyUsage.disabled,
        secondaryKeys: secondaryKeys,
        insertionOrder: item['insertorder'] as int? ?? 0,
        content: item['content'] as String?,
        category: CharacterBookCategory.other,
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

  /// SillyTavern character_book JSON으로 내보내기.
  /// 카테고리·한줄설명 등 신규 필드는 'extensions'에 실어서 내보낸다.
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
            message: AppLocalizations.of(context).characterBookNoExport,
          );
        }
        return;
      }

      final entries = allBooks.map((cb) => {
            'keys': cb.keys,
            'secondary_keys': cb.secondaryKeys,
            'content': cb.content ?? '',
            'extensions': <String, dynamic>{
              'flan_category': cb.category.name,
              'flan_one_line_description': cb.oneLineDescription,
              'flan_auto_summary_insert': cb.autoSummaryInsert,
            },
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
          final l10n = AppLocalizations.of(context);
          CommonDialog.showSnackBar(
            context: context,
            message: result == true
                ? l10n.characterExportSuccessAndroid('character_book.json')
                : l10n.characterBookSaveFailed,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: AppLocalizations.of(context).characterBookExportFailed(e.toString()),
        );
      }
    }
  }

  void _addFolder() {
    final newFolderName = AppLocalizations.of(context).characterBookNewFolder;
    setState(() {
      final newFolder = CharacterBookFolder(
        id: _getNextTempId(),
        characterId: -1,
        name: newFolderName,
        order: _getNextMixedOrder(),
      );
      widget.folders.add(newFolder);
    });
    _notifyUpdate();
  }

  void _addCharacterBook(CharacterBookFolder? folder) {
    final newName = AppLocalizations.of(context).characterBookNewItem;
    setState(() {
      final newCharacterBook = CharacterBook(
        id: _getNextTempId(),
        characterId: -1,
        folderId: folder?.id,
        name: newName,
        order: folder != null ? folder.characterBooks.length : _getNextMixedOrder(),
        isExpanded: true,
        category: _selectedCategory,
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
    final l10n = AppLocalizations.of(context);
    final confirmed = await CommonDialog.showConfirmation(
      context: context,
      title: l10n.characterBookFolderDeleteTitle,
      content: folder.name,
      confirmText: l10n.commonDelete,
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
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(UIConstants.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: CommonTitleMedium(
              text: l10n.characterBookSection,
              helpMessage: l10n.characterBookSectionHelp,
            ),
          ),
          const SizedBox(height: 8),
          _buildCategoryChips(),
          const SizedBox(height: 8),
          Expanded(
            child: CommonDraggableFolderList<CharacterBookFolder, CharacterBook>(
              // ValueKey tied to category forces the drag/drop widget to fully
              // rebuild when the user switches categories — without this it
              // holds onto stale order/index state from the previous filter.
              key: ValueKey('characterBookList_${_selectedCategory.name}'),
              folders: _visibleFolders(),
              standaloneItems: _visibleStandalone(),
              getFolderId: (folder) => folder.id,
              getFolderName: (folder) => folder.name,
              getFolderExpanded: (folder) => folder.isExpanded,
              getFolderItems: (folder) => folder.characterBooks,
              getFolderOrder: (folder) => folder.order,
              getItemId: (item) => item.id,
              getItemOrder: (item) => item.order,
              itemContentBuilder: _buildCharacterBookCard,
              getItemIcon: (item) => _iconForCategory(item.category),
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
              addItemLabel: l10n.characterBookAddItem,
              // Folders only apply to the '기타' category; hide the add-folder
              // button label for other categories so the UI doesn't advertise
              // an option that wouldn't persist in context.
              addFolderLabel: _selectedCategory == CharacterBookCategory.other
                  ? l10n.characterBookAddFolder
                  : null,
              emptyWidget: CommonEmptyState(
                message: l10n.characterBookEmpty,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Row(
        children: [
          for (final category in CharacterBookCategory.values) ...[
            ChoiceChip(
              label: Text(category.displayName),
              selected: _selectedCategory == category,
              onSelected: (selected) {
                if (!selected) return;
                setState(() {
                  _selectedCategory = category;
                });
              },
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  IconData _iconForCategory(CharacterBookCategory category) {
    switch (category) {
      case CharacterBookCategory.character:
        return Icons.person_outline;
      case CharacterBookCategory.location:
        return Icons.place_outlined;
      case CharacterBookCategory.event:
        return Icons.event_note_outlined;
      case CharacterBookCategory.other:
        return Icons.description_outlined;
    }
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

  Widget _buildCharacterBookCard(BuildContext context, CharacterBook book, CharacterBookFolder? folder) {
    return CommonEditableExpandableItem(
      key: ValueKey(book.id),
      icon: Icon(
        _iconForCategory(book.category),
        size: UIConstants.iconSizeMedium,
        color: Theme.of(context).colorScheme.secondary,
      ),
      name: book.name,
      isExpanded: book.isExpanded,
      onToggleExpanded: () {
        if (book.isExpanded) {
          FocusScope.of(context).unfocus();
        }
        setState(() {
          book.isExpanded = !book.isExpanded;
        });
      },
      onDelete: () => _deleteCharacterBook(book, folder),
      nameHint: AppLocalizations.of(context).characterBookNameHint,
      onNameChanged: (value) {
        book.name = value;
        _notifyUpdate();
      },
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActivationConditionField(book),
          if (book.enabled == CharacterBookActivationCondition.keyBased) ...[
            _buildActivationKeysField(book),
            _buildSecondaryKeyUsageField(book),
            if (book.secondaryKeyUsage == CharacterBookSecondaryKeyUsage.enabled)
              _buildSecondaryKeysField(book),
          ],
          // 배치순서는 '기타' 카테고리에서만 사용
          if (book.category == CharacterBookCategory.other)
            _buildDeploymentOrderField(book),
          _buildAutoSummaryInsertField(book),
          _buildOneLineDescriptionField(book),
          ..._buildCategorySpecificFields(book),
        ],
      ),
    );
  }

  Widget _buildActivationConditionField(CharacterBook book) {
    return CommonFieldSection(
      label: AppLocalizations.of(context).characterBookActivationCondition,
      child: CommonSegmentedButton<CharacterBookActivationCondition>(
        values: CharacterBookActivationCondition.values,
        selected: book.enabled,
        onSelectionChanged: (selected) {
          setState(() {
            book.enabled = selected;
          });
          _notifyUpdate();
        },
        labelBuilder: (condition) => condition.displayName,
      ),
    );
  }

  Widget _buildActivationKeysField(CharacterBook book) {
    final l10n = AppLocalizations.of(context);
    final key = 'characterBook_${book.id}_keys';
    final controller = _getFieldController(key, book.keys.join(', '));

    return CommonFieldSection(
      label: l10n.characterBookActivationKey,
      child: CommonEditText(
        controller: controller,
        hintText: l10n.characterBookKeysHint,
        size: CommonEditTextSize.small,
        onFocusLost: (value) {
          book.keys = value
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
          _notifyUpdate(rebuildUI: false);
        },
      ),
    );
  }

  Widget _buildSecondaryKeyUsageField(CharacterBook book) {
    return CommonFieldSection(
      label: AppLocalizations.of(context).characterBookSecondaryKey,
      child: CommonSegmentedButton<CharacterBookSecondaryKeyUsage>(
        values: CharacterBookSecondaryKeyUsage.values,
        selected: book.secondaryKeyUsage,
        onSelectionChanged: (selected) {
          setState(() {
            book.secondaryKeyUsage = selected;
          });
          _notifyUpdate();
        },
        labelBuilder: (usage) => usage.displayName,
      ),
    );
  }

  Widget _buildSecondaryKeysField(CharacterBook book) {
    final l10n = AppLocalizations.of(context);
    final key = 'characterBook_${book.id}_secondaryKeys';
    final controller = _getFieldController(key, book.secondaryKeys.join(', '));

    return CommonFieldSection(
      label: l10n.characterBookSecondaryKey,
      child: CommonEditText(
        controller: controller,
        hintText: l10n.characterBookKeysHint,
        size: CommonEditTextSize.small,
        onFocusLost: (value) {
          book.secondaryKeys = value
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
          _notifyUpdate(rebuildUI: false);
        },
      ),
    );
  }

  Widget _buildDeploymentOrderField(CharacterBook book) {
    final key = 'characterBook_${book.id}_insertionOrder';
    final controller = _getFieldController(key, book.insertionOrder.toString());

    return CommonFieldSection(
      label: AppLocalizations.of(context).characterBookInsertionOrder,
      child: CommonEditText(
        controller: controller,
        hintText: '0',
        size: CommonEditTextSize.small,
        keyboardType: TextInputType.number,
        onFocusLost: (value) {
          final intValue = int.tryParse(value);
          if (intValue != null) {
            book.insertionOrder = intValue;
            _notifyUpdate(rebuildUI: false);
          }
        },
      ),
    );
  }

  Widget _buildAutoSummaryInsertField(CharacterBook book) {
    final l10n = AppLocalizations.of(context);
    return CommonFieldSection(
      label: l10n.characterBookAutoSummaryInsert,
      child: CommonSegmentedButton<bool>(
        values: const [true, false],
        selected: book.autoSummaryInsert,
        onSelectionChanged: (selected) {
          setState(() {
            book.autoSummaryInsert = selected;
          });
          _notifyUpdate();
        },
        labelBuilder: (v) =>
            v ? l10n.characterBookAutoSummaryInsertOn : l10n.characterBookAutoSummaryInsertOff,
      ),
    );
  }

  Widget _buildOneLineDescriptionField(CharacterBook book) {
    final l10n = AppLocalizations.of(context);
    final key = 'characterBook_${book.id}_oneLineDescription';
    final controller = _getFieldController(key, book.oneLineDescription);

    return CommonFieldSection(
      label: l10n.characterBookOneLineDescription,
      child: CommonEditText(
        controller: controller,
        hintText: _oneLineHintForCategory(book.category, l10n),
        size: CommonEditTextSize.small,
        onFocusLost: (value) {
          book.oneLineDescription = value;
          _notifyUpdate(rebuildUI: false);
        },
      ),
    );
  }

  String _oneLineHintForCategory(CharacterBookCategory category, AppLocalizations l10n) {
    switch (category) {
      case CharacterBookCategory.character:
        return l10n.characterBookOneLineHintCharacter;
      case CharacterBookCategory.location:
        return l10n.characterBookOneLineHintLocation;
      case CharacterBookCategory.event:
        return l10n.characterBookOneLineHintEvent;
      case CharacterBookCategory.other:
        return l10n.characterBookOneLineHintOther;
    }
  }

  // ==================== Category-specific fields ====================

  List<Widget> _buildCategorySpecificFields(CharacterBook book) {
    switch (book.category) {
      case CharacterBookCategory.character:
        return _buildCharacterFields(book);
      case CharacterBookCategory.location:
        return _buildLocationFields(book);
      case CharacterBookCategory.event:
        return _buildEventFields(book);
      case CharacterBookCategory.other:
        return _buildOtherFields(book);
    }
  }

  List<Widget> _buildCharacterFields(CharacterBook book) {
    final l10n = AppLocalizations.of(context);
    return [
      _buildStructuredTextField(
        book: book,
        fieldKey: 'appearance',
        label: l10n.characterBookFieldAppearance,
        minLines: 2,
        multiline: true,
      ),
      _buildGenderField(book),
      _buildStructuredTextField(
        book: book,
        fieldKey: 'age',
        label: l10n.characterBookFieldAge,
      ),
      _buildStructuredTextField(
        book: book,
        fieldKey: 'personality',
        label: l10n.characterBookFieldPersonality,
        minLines: 2,
        multiline: true,
      ),
      _buildStructuredTextField(
        book: book,
        fieldKey: 'past',
        label: l10n.characterBookFieldPast,
        minLines: 2,
        multiline: true,
      ),
      _buildStructuredTextField(
        book: book,
        fieldKey: 'abilities',
        label: l10n.characterBookFieldAbilities,
        minLines: 2,
        multiline: true,
      ),
      _buildStructuredTextField(
        book: book,
        fieldKey: 'dialogue_style',
        label: l10n.characterBookFieldDialogueStyle,
        minLines: 2,
        multiline: true,
        bottomSpacing: 0,
      ),
    ];
  }

  List<Widget> _buildLocationFields(CharacterBook book) {
    final l10n = AppLocalizations.of(context);
    return [
      _buildStructuredTextField(
        book: book,
        fieldKey: 'setting',
        label: l10n.characterBookFieldSetting,
        minLines: 5,
        multiline: true,
        bottomSpacing: 0,
      ),
    ];
  }

  List<Widget> _buildEventFields(CharacterBook book) {
    final l10n = AppLocalizations.of(context);
    return [
      _buildStructuredTextField(
        book: book,
        fieldKey: 'datetime',
        label: l10n.characterBookFieldDatetime,
      ),
      _buildStructuredTextField(
        book: book,
        fieldKey: 'event_content',
        label: l10n.characterBookFieldEventContent,
        minLines: 3,
        multiline: true,
      ),
      _buildStructuredTextField(
        book: book,
        fieldKey: 'result',
        label: l10n.characterBookFieldResult,
        minLines: 2,
        multiline: true,
        bottomSpacing: 0,
      ),
    ];
  }

  List<Widget> _buildOtherFields(CharacterBook book) {
    final l10n = AppLocalizations.of(context);
    return [
      _buildStructuredTextField(
        book: book,
        fieldKey: 'setting',
        label: l10n.characterBookFieldSetting,
        minLines: 5,
        multiline: true,
        bottomSpacing: 0,
      ),
    ];
  }

  /// Unified builder for a single structured-data text field. All edits flow
  /// through [CharacterBook.setStructuredString] so the underlying JSON stays
  /// consistent even for entries migrated from legacy plain-text content.
  Widget _buildStructuredTextField({
    required CharacterBook book,
    required String fieldKey,
    required String label,
    int minLines = 1,
    bool multiline = false,
    double bottomSpacing = 12.0,
  }) {
    final key = 'characterBook_${book.id}_$fieldKey';
    final initialValue = book.getStructuredString(fieldKey);
    final controller = _getFieldController(key, initialValue);

    return CommonFieldSection(
      label: label,
      bottomSpacing: bottomSpacing,
      child: CommonEditText(
        controller: controller,
        size: CommonEditTextSize.small,
        maxLines: multiline ? null : 1,
        minLines: multiline ? minLines : null,
        onFocusLost: (value) {
          book.setStructuredString(fieldKey, value);
          _notifyUpdate(rebuildUI: false);
        },
      ),
    );
  }

  Widget _buildGenderField(CharacterBook book) {
    final l10n = AppLocalizations.of(context);
    final selectedGender = book.gender;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonFieldSection(
          label: l10n.characterBookFieldGender,
          bottomSpacing: selectedGender == CharacterBookGender.other ? 8 : 12,
          child: CommonSegmentedButton<CharacterBookGender>(
            values: CharacterBookGender.values,
            selected: selectedGender ?? CharacterBookGender.male,
            onSelectionChanged: (selected) {
              setState(() {
                book.gender = selected;
              });
              _notifyUpdate();
            },
            labelBuilder: (g) => g.displayName,
          ),
        ),
        if (selectedGender == CharacterBookGender.other)
          _buildStructuredTextField(
            book: book,
            fieldKey: 'gender_other',
            label: l10n.characterBookFieldGenderOther,
          ),
      ],
    );
  }
}
