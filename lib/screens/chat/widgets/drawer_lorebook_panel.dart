import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../database/database_helper.dart';
import '../../../models/character/character_book_folder.dart';
import '../../../utils/common_dialog.dart';
import '../../../widgets/character/character_book_category_fields.dart';
import '../../../widgets/common/common_edit_text.dart';
import '../../../widgets/common/common_editable_expandable_item.dart';
import '../../../widgets/common/common_field_section.dart';
import '../../../widgets/common/common_segmented_button.dart';

class DrawerLorebookPanel extends StatefulWidget {
  final List<CharacterBookFolder> folders;
  final List<CharacterBook> standaloneBooks;
  final DatabaseHelper db;
  final int characterId;

  const DrawerLorebookPanel({
    super.key,
    required this.folders,
    required this.standaloneBooks,
    required this.db,
    required this.characterId,
  });

  @override
  DrawerLorebookPanelState createState() => DrawerLorebookPanelState();
}

class DrawerLorebookPanelState extends State<DrawerLorebookPanel> {
  final Map<String, TextEditingController> _bookFieldControllers = {};

  // ==================== Public API ====================

  Future<void> save() async {
    _syncBookFieldsFromControllers();

    final characterId = widget.characterId;

    for (final folder in widget.folders) {
      if (folder.id != null && folder.id! > 0) {
        await widget.db.updateCharacterBookFolder(folder.copyWith(characterId: characterId));
      } else {
        final newId = await widget.db.createCharacterBookFolder(
          folder.copyWith(characterId: characterId),
        );
        for (final book in folder.characterBooks) {
          book.order = folder.characterBooks.indexOf(book);
        }
        for (final book in folder.characterBooks) {
          await _saveOrCreateBook(book, characterId, folderId: newId);
        }
        continue;
      }

      for (final book in folder.characterBooks) {
        await _saveOrCreateBook(book, characterId, folderId: folder.id);
      }
    }

    for (final book in widget.standaloneBooks) {
      await _saveOrCreateBook(book, characterId);
    }
  }

  // ==================== Helpers ====================

  String _structuredKeyPrefix(CharacterBook book) => 'book_${book.id}_field_';

  TextEditingController _getBookFieldController(String key, String initialValue) {
    if (!_bookFieldControllers.containsKey(key)) {
      _bookFieldControllers[key] = TextEditingController(text: initialValue);
    }
    return _bookFieldControllers[key]!;
  }

  void _syncBookFieldsFromControllers() {
    for (final folder in widget.folders) {
      for (final book in folder.characterBooks) {
        _syncBookFromController(book);
      }
    }
    for (final book in widget.standaloneBooks) {
      _syncBookFromController(book);
    }
  }

  void _syncBookFromController(CharacterBook book) {
    final structuredPrefix = _structuredKeyPrefix(book);
    for (final entry in _bookFieldControllers.entries) {
      if (entry.key.startsWith(structuredPrefix)) {
        book.setStructuredString(
            entry.key.substring(structuredPrefix.length), entry.value.text);
      }
    }
    final subNamesKey = 'book_${book.id}_subNames';
    if (_bookFieldControllers.containsKey(subNamesKey)) {
      book.subNames = _bookFieldControllers[subNamesKey]!.text;
    }
    final oneLineKey = 'book_${book.id}_oneLineDescription';
    if (_bookFieldControllers.containsKey(oneLineKey)) {
      book.oneLineDescription = _bookFieldControllers[oneLineKey]!.text;
    }
    final keysKey = 'book_${book.id}_keys';
    if (_bookFieldControllers.containsKey(keysKey)) {
      book.keys = _bookFieldControllers[keysKey]!.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    final secondaryKeysKey = 'book_${book.id}_secondaryKeys';
    if (_bookFieldControllers.containsKey(secondaryKeysKey)) {
      book.secondaryKeys = _bookFieldControllers[secondaryKeysKey]!.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    final orderKey = 'book_${book.id}_insertionOrder';
    if (_bookFieldControllers.containsKey(orderKey)) {
      final intValue = int.tryParse(_bookFieldControllers[orderKey]!.text);
      if (intValue != null) book.insertionOrder = intValue;
    }
  }

  Future<void> _saveOrCreateBook(CharacterBook book, int characterId, {int? folderId}) async {
    if (book.id != null && book.id! > 0) {
      await widget.db.updateCharacterBook(book.copyWith(characterId: characterId, folderId: folderId));
    } else {
      await widget.db.createCharacterBook(book.copyWith(characterId: characterId, folderId: folderId));
    }
  }

  // ==================== Logic ====================

  Future<void> _deleteBook(CharacterBook book, CharacterBookFolder? folder) async {
    final confirmed = await CommonDialog.showDeleteConfirmation(
      context: context,
      itemName: book.name,
    );
    if (!confirmed) return;

    if (book.id != null && book.id! > 0) {
      await widget.db.deleteCharacterBook(book.id!);
    }

    setState(() {
      if (folder != null) {
        folder.characterBooks.remove(book);
      } else {
        widget.standaloneBooks.remove(book);
      }
    });
  }

  // ==================== Build ====================

  @override
  Widget build(BuildContext context) {
    final allItems = <Widget>[];

    for (final folder in widget.folders) {
      allItems.add(_buildFolderSection(folder));
    }

    for (final category in CharacterBookCategory.values) {
      final books = widget.standaloneBooks
          .where((b) => b.category == category)
          .toList();
      if (books.isEmpty) continue;
      allItems.add(_buildCategoryHeader(category));
      for (final book in books) {
        allItems.add(_buildBookCard(book, null));
      }
    }

    return Column(
      children: [
        Expanded(
          child: allItems.isEmpty
              ? Center(
                  child: Text(
                    AppLocalizations.of(context).drawerLorebookEmpty,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
                  children: allItems,
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryHeader(CharacterBookCategory category) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
      child: Row(
        children: [
          Icon(characterBookCategoryIcon(category),
              size: 16, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            category.displayName,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderSection(CharacterBookFolder folder) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          folder.name,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 16),
        ),
        leading: const Icon(Icons.folder_outlined, size: 20),
        initiallyExpanded: folder.isExpanded,
        onExpansionChanged: (expanded) => folder.isExpanded = expanded,
        children: [
          for (final book in folder.characterBooks)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _buildBookCard(book, folder),
            ),
        ],
      ),
    );
  }

  Widget _buildBookCard(CharacterBook book, CharacterBookFolder? folder) {
    final l10n = AppLocalizations.of(context);
    return CommonEditableExpandableItem(
      key: ValueKey('book_${book.id}'),
      icon: Icon(
        characterBookCategoryIcon(book.category),
        size: 20,
        color: Theme.of(context).colorScheme.secondary,
      ),
      name: book.name,
      isExpanded: book.isExpanded,
      onToggleExpanded: () {
        setState(() => book.isExpanded = !book.isExpanded);
      },
      onDelete: () => _deleteBook(book, folder),
      nameHint: l10n.drawerBookNameHint,
      onNameChanged: (value) => book.name = value,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (book.category == CharacterBookCategory.character)
            _buildBookSubNamesField(book),
          CommonFieldSection(
            label: l10n.drawerBookActivationCondition,
            child: CommonSegmentedButton<CharacterBookActivationCondition>(
              values: CharacterBookActivationCondition.values,
              selected: book.enabled,
              onSelectionChanged: (selected) {
                setState(() => book.enabled = selected);
              },
              labelBuilder: (c) => c.displayName,
            ),
          ),
          if (book.enabled == CharacterBookActivationCondition.keyBased) ...[
            _buildBookKeysField(book),
            CommonFieldSection(
              label: l10n.drawerBookSecondaryKey,
              child: CommonSegmentedButton<CharacterBookSecondaryKeyUsage>(
                values: CharacterBookSecondaryKeyUsage.values,
                selected: book.secondaryKeyUsage,
                onSelectionChanged: (selected) {
                  setState(() => book.secondaryKeyUsage = selected);
                },
                labelBuilder: (c) => c.displayName,
              ),
            ),
            if (book.secondaryKeyUsage == CharacterBookSecondaryKeyUsage.enabled)
              _buildBookSecondaryKeysField(book),
          ],
          if (book.category == CharacterBookCategory.other)
            _buildBookInsertionOrderField(book),
          _buildBookOneLineDescriptionField(book),
          CharacterBookCategoryFields(
            book: book,
            controllerFor: (fieldKey, initialValue) => _getBookFieldController(
                '${_structuredKeyPrefix(book)}$fieldKey', initialValue),
            onChanged: ({required bool rebuildUI}) {
              if (rebuildUI) setState(() {});
            },
            // Image editing needs the character's asset folder, so the
            // drawer only shows existing images.
            imagesReadOnly: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBookSubNamesField(CharacterBook book) {
    final l10n = AppLocalizations.of(context);
    final controller =
        _getBookFieldController('book_${book.id}_subNames', book.subNames);
    return CommonFieldSection(
      label: l10n.characterBookFieldSubNames,
      child: CommonEditText(
        controller: controller,
        hintText: l10n.characterBookFieldSubNamesHint,
        size: CommonEditTextSize.small,
        onFocusLost: (value) => book.subNames = value,
      ),
    );
  }

  Widget _buildBookOneLineDescriptionField(CharacterBook book) {
    final l10n = AppLocalizations.of(context);
    final key = 'book_${book.id}_oneLineDescription';
    final controller = _getBookFieldController(key, book.oneLineDescription);
    return CommonFieldSection(
      label: l10n.characterBookOneLineDescription,
      child: CommonEditText(
        controller: controller,
        size: CommonEditTextSize.small,
        onFocusLost: (value) => book.oneLineDescription = value,
      ),
    );
  }

  Widget _buildBookKeysField(CharacterBook book) {
    final l10n = AppLocalizations.of(context);
    final key = 'book_${book.id}_keys';
    final controller = _getBookFieldController(key, book.keys.join(', '));
    return CommonFieldSection(
      label: l10n.drawerBookActivationKey,
      child: CommonEditText(
        controller: controller,
        hintText: l10n.drawerBookKeysHint,
        size: CommonEditTextSize.small,
        onFocusLost: (value) {
          book.keys = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        },
      ),
    );
  }

  Widget _buildBookSecondaryKeysField(CharacterBook book) {
    final l10n = AppLocalizations.of(context);
    final key = 'book_${book.id}_secondaryKeys';
    final controller = _getBookFieldController(key, book.secondaryKeys.join(', '));
    return CommonFieldSection(
      label: l10n.drawerBookSecondaryKey,
      child: CommonEditText(
        controller: controller,
        hintText: l10n.drawerBookSecondaryKeysHint,
        size: CommonEditTextSize.small,
        onFocusLost: (value) {
          book.secondaryKeys = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        },
      ),
    );
  }

  Widget _buildBookInsertionOrderField(CharacterBook book) {
    final key = 'book_${book.id}_insertionOrder';
    final controller = _getBookFieldController(key, book.insertionOrder.toString());
    return CommonFieldSection(
      label: AppLocalizations.of(context).drawerBookInsertionOrder,
      child: CommonEditText(
        controller: controller,
        hintText: '0',
        size: CommonEditTextSize.small,
        keyboardType: TextInputType.number,
        onFocusLost: (value) {
          final intValue = int.tryParse(value);
          if (intValue != null) book.insertionOrder = intValue;
        },
      ),
    );
  }

  // ==================== Dispose ====================

  @override
  void dispose() {
    for (final controller in _bookFieldControllers.values) {
      controller.dispose();
    }
    _bookFieldControllers.clear();
    super.dispose();
  }
}
