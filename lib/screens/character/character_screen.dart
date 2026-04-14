import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common/common_fab.dart';
import '../../providers/theme_provider.dart';
import '../../database/database_helper.dart';
import '../../models/character/character.dart';
import '../../models/character/cover_image.dart';
import '../../utils/common_dialog.dart';
import '../../utils/character_exporter.dart';
import '../../utils/character_importer.dart';
import 'character_edit_screen.dart';
import 'character_view_screen.dart';
import '../../widgets/character/character_card.dart';
import '../../widgets/character/character_list_item.dart';
import '../../widgets/common/common_appbar.dart';
import '../agent/agent_chat_screen.dart';
import '../tutorial/tutorial_screen.dart' show showAgentHighlightKey;

class CharacterScreen extends StatefulWidget {
  const CharacterScreen({super.key});

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

enum SortMethod {
  nameAsc,
  nameDesc,
  updatedAtAsc,
  updatedAtDesc,
  createdAtAsc,
  createdAtDesc,
  custom,
}

class _CharacterScreenState extends State<CharacterScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  bool _isGridView = true;
  SortMethod _sortMethod = SortMethod.createdAtDesc;
  List<Character> _characters = [];
  bool _isLoading = true;
  Map<int, Uint8List?> _characterCoverImages = {};
  bool _isEditMode = false;
  final Set<int> _selectedCharacterIds = {};
  bool _showAgentHighlight = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadCharacters();
    _checkAgentHighlight();
  }

  Future<void> _checkAgentHighlight() async {
    final prefs = await SharedPreferences.getInstance();
    final show = prefs.getBool(showAgentHighlightKey) ?? false;
    if (show && mounted) {
      setState(() => _showAgentHighlight = true);
      await prefs.remove(showAgentHighlightKey);
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isGridView = prefs.getBool('character_is_grid_view') ?? true;
      final sortMethodString = prefs.getString('character_sort_method') ?? 'createdAtDesc';
      _sortMethod = SortMethod.values.firstWhere(
        (e) => e.name == sortMethodString,
        orElse: () => SortMethod.createdAtDesc,
      );
    });
  }

  Future<void> _saveViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('character_is_grid_view', _isGridView);
  }

  Future<void> _saveSortPreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('character_sort_method', _sortMethod.name);
  }

  Future<void> _loadCharacters() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final characters = await _db.readAllCharacters();

      // 각 캐릭터의 표지 이미지 로드
      final coverImages = <int, Uint8List?>{};
      for (var character in characters) {
        final images = await _db.readCoverImages(character.id!);
        if (images.isNotEmpty) {
          CoverImage selectedImage;
          if (character.selectedCoverImageId != null) {
            selectedImage = images.firstWhere(
              (img) => img.id == character.selectedCoverImageId,
              orElse: () => images.first,
            );
          } else {
            selectedImage = images.first;
          }
          coverImages[character.id!] = await selectedImage.resolveImageData();
        }
      }

      if (!mounted) return;
      setState(() {
        _characters = characters;
        _characterCoverImages = coverImages;
        _sortCharacters();
      });
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: AppLocalizations.of(context).characterLoadFailed(e.toString()),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _sortCharacters() {
    switch (_sortMethod) {
      case SortMethod.nameAsc:
        _characters.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortMethod.nameDesc:
        _characters.sort((a, b) => b.name.compareTo(a.name));
        break;
      case SortMethod.updatedAtAsc:
        _characters.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        break;
      case SortMethod.updatedAtDesc:
        _characters.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case SortMethod.createdAtAsc:
        _characters.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortMethod.createdAtDesc:
        _characters.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortMethod.custom:
        _characters.sort((a, b) {
          if (a.sortOrder == null && b.sortOrder == null) return 0;
          if (a.sortOrder == null) return 1;
          if (b.sortOrder == null) return -1;
          return a.sortOrder!.compareTo(b.sortOrder!);
        });
        break;
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) {
        _selectedCharacterIds.clear();
      }
    });
  }

  void _toggleCharacterSelection(int id) {
    setState(() {
      if (_selectedCharacterIds.contains(id)) {
        _selectedCharacterIds.remove(id);
      } else {
        _selectedCharacterIds.add(id);
      }
    });
  }

  Future<void> _reorderCharacters(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    setState(() {
      final character = _characters.removeAt(oldIndex);
      _characters.insert(newIndex, character);
    });

    try {
      for (int i = 0; i < _characters.length; i++) {
        final updatedCharacter = _characters[i].copyWith(sortOrder: i);
        await _db.updateCharacter(updatedCharacter);
        _characters[i] = updatedCharacter;
      }
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: AppLocalizations.of(context).characterReorderFailed(e.toString()),
        );
      }
      await _loadCharacters();
    }
  }

  Future<void> _deleteSelectedCharacters() async {
    if (_selectedCharacterIds.isEmpty) return;

    final l10n = AppLocalizations.of(context);
    final confirm = await CommonDialog.showConfirmation(
      context: context,
      title: l10n.characterDeleteSelectedTitle,
      content:
          l10n.characterDeleteSelectedContent(_selectedCharacterIds.length),
      confirmText: l10n.commonDelete,
      isDestructive: true,
    );

    if (confirm == true) {
      try {
        for (final id in _selectedCharacterIds) {
          await _db.deleteCharacter(id);
        }
        setState(() {
          _selectedCharacterIds.clear();
          _isEditMode = false;
        });
        await _loadCharacters();
        if (mounted) {
          CommonDialog.showSnackBar(
            context: context,
            message: l10n.characterDeletedSelected,
          );
        }
      } catch (e) {
        if (mounted) {
          CommonDialog.showSnackBar(
            context: context,
            message: l10n.characterDeleteFailed(e.toString()),
          );
        }
      }
    }
  }

  Future<void> _duplicateCharacter(int characterId) async {
    final l10n = AppLocalizations.of(context);
    try {
      final character = await _db.readCharacter(characterId);
      if (character == null) throw Exception('Character not found');

      final personas = await _db.readPersonas(characterId);
      final startScenarios = await _db.readStartScenarios(characterId);
      final characterBookFolders = await _db.readCharacterBookFolders(characterId);
      final standaloneCharacterBooks = await _db.readCharacterBooks(characterId);
      final coverImages = await _db.readCoverImages(characterId);

      for (final folder in characterBookFolders) {
        folder.characterBooks.addAll(await _db.readCharacterBooksByFolder(folder.id!));
      }

      final newCharacterId = await _db.createCharacter(
        Character(
          name: l10n.characterCopyName(character.name),
          nickname: character.nickname,
          creatorNotes: character.creatorNotes,
          tags: List<String>.from(character.tags),
          description: character.description,
          isDraft: character.isDraft,
        ),
      );

      for (final persona in personas) {
        await _db.createPersona(persona.copyWith(id: null, characterId: newCharacterId));
      }

      for (final scenario in startScenarios) {
        await _db.createStartScenario(scenario.copyWith(id: null, characterId: newCharacterId));
      }

      for (final folder in characterBookFolders) {
        final newFolderId = await _db.createCharacterBookFolder(
          folder.copyWith(id: null, characterId: newCharacterId),
        );
        for (final book in folder.characterBooks) {
          await _db.createCharacterBook(
            book.copyWith(id: null, characterId: newCharacterId, folderId: newFolderId),
          );
        }
      }

      for (final book in standaloneCharacterBooks) {
        await _db.createCharacterBook(book.copyWith(id: null, characterId: newCharacterId));
      }

      for (final image in coverImages) {
        await _db.createCoverImage(image.copyWith(id: null, characterId: newCharacterId));
      }

      await _loadCharacters();
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: l10n.characterCopied,
        );
      }
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: l10n.characterCopyFailed(e.toString()),
        );
      }
    }
  }

  Future<void> _deleteCharacter(int id) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await CommonDialog.showConfirmation(
      context: context,
      title: l10n.characterDeleteSelectedTitle,
      content: l10n.characterDeleteOneContent,
      confirmText: l10n.commonDelete,
      isDestructive: true,
    );

    if (confirm == true) {
      try {
        await _db.deleteCharacter(id);
        await _loadCharacters();
        if (mounted) {
          CommonDialog.showSnackBar(
            context: context,
            message: l10n.characterDeleted,
          );
        }
      } catch (e) {
        if (mounted) {
          CommonDialog.showSnackBar(
            context: context,
            message: l10n.characterDeleteFailed(e.toString()),
          );
        }
      }
    }
  }

  // ─── Export: format selection dialog ───────────────────────────────────────

  Future<void> _exportCharacter(int characterId) async {
    await CharacterExporter.export(context, characterId, _db);
  }




  Future<void> _importCharacter() async {
    final success = await CharacterImporter.import(context, _db);
    if (success) _loadCharacters();
  }


  String _getSortMethodLabel(AppLocalizations l10n) {
    String body;
    switch (_sortMethod) {
      case SortMethod.nameAsc:
        body = l10n.characterSortNameAsc;
      case SortMethod.nameDesc:
        body = l10n.characterSortNameDesc;
      case SortMethod.updatedAtAsc:
        body = l10n.characterSortUpdatedAtAsc;
      case SortMethod.updatedAtDesc:
        body = l10n.characterSortUpdatedAtDesc;
      case SortMethod.createdAtAsc:
        body = l10n.characterSortCreatedAtAsc;
      case SortMethod.createdAtDesc:
        body = l10n.characterSortCreatedAtDesc;
      case SortMethod.custom:
        body = l10n.characterSortCustom;
    }
    return l10n.characterSortLabel(body);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: CommonAppBar(
        title: _isEditMode
          ? l10n.characterSelectedCount(_selectedCharacterIds.length)
          : l10n.characterTitle,
        showBackButton: false,
        showCloseButton: _isEditMode,
        onClosePressed: _toggleEditMode,
        actions: [
          if (!_isEditMode)
            _showAgentHighlight
                ? _AgentHighlightButton(
                    onPressed: () async {
                      setState(() => _showAgentHighlight = false);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AgentChatScreen(),
                        ),
                      );
                      _loadCharacters();
                    },
                  )
                : CommonAppBarIconButton(
                    icon: Icons.auto_awesome,
                    offsetX: 10.0,
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AgentChatScreen(),
                        ),
                      );
                      _loadCharacters();
                    },
                    tooltip: l10n.characterFlanAgentTooltip,
                  ),
          if (!_isEditMode)
            CommonAppBarIconButton(
              icon: Icons.edit_outlined,
              onPressed: _toggleEditMode,
              tooltip: l10n.commonEdit,
            ),
          if (_isEditMode)
            CommonAppBarIconButton(
              icon: Icons.delete_outline,
              onPressed: _selectedCharacterIds.isEmpty ? null : _deleteSelectedCharacters,
              tooltip: l10n.commonDelete,
            ),
          if (!_isEditMode)
            CommonAppBarPopupMenuButton<String>(
              tooltip: l10n.commonMore,
              onSelected: (value) {
                if (value == 'import') {
                  _importCharacter();
                }
              },
              itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'import',
                  child: Row(
                    children: [
                      const Icon(Icons.download_outlined, size: 20),
                      const SizedBox(width: 12),
                      Text(l10n.characterImport),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  enabled: false,
                  child: Text(
                    l10n.characterViewMode,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'view_grid',
                  onTap: () {
                    setState(() {
                      _isGridView = true;
                    });
                    _saveViewPreference();
                  },
                  child: Row(
                    children: [
                      if (_isGridView)
                        const Icon(Icons.check, size: 20)
                      else
                        const SizedBox(width: 20),
                      const SizedBox(width: 12),
                      Text(l10n.characterViewGrid),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'view_list',
                  onTap: () {
                    setState(() {
                      _isGridView = false;
                    });
                    _saveViewPreference();
                  },
                  child: Row(
                    children: [
                      if (!_isGridView)
                        const Icon(Icons.check, size: 20)
                      else
                        const SizedBox(width: 20),
                      const SizedBox(width: 12),
                      Text(l10n.characterViewList),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  enabled: false,
                  child: Text(
                    l10n.characterThemeSelect,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'theme_light',
                  child: Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return InkWell(
                        onTap: () {
                          themeProvider.setThemeMode(ThemeMode.light);
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Row(
                            children: [
                              if (themeProvider.themeMode == ThemeMode.light)
                                const Icon(Icons.check, size: 20)
                              else
                                const SizedBox(width: 20),
                              const SizedBox(width: 12),
                              Text(l10n.settingsThemeLight),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'theme_dark',
                  child: Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return InkWell(
                        onTap: () {
                          themeProvider.setThemeMode(ThemeMode.dark);
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Row(
                            children: [
                              if (themeProvider.themeMode == ThemeMode.dark)
                                const Icon(Icons.check, size: 20)
                              else
                                const SizedBox(width: 20),
                              const SizedBox(width: 12),
                              Text(l10n.settingsThemeDark),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'theme_system',
                  child: Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return InkWell(
                        onTap: () {
                          themeProvider.setThemeMode(ThemeMode.system);
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Row(
                            children: [
                              if (themeProvider.themeMode == ThemeMode.system)
                                const Icon(Icons.check, size: 20)
                              else
                                const SizedBox(width: 20),
                              const SizedBox(width: 12),
                              Text(l10n.settingsThemeSystem),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ];
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PopupMenuButton<SortMethod>(
                  offset: const Offset(0, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onSelected: (selectedMethod) {
                    if (selectedMethod != _sortMethod) {
                      setState(() {
                        _sortMethod = selectedMethod;
                        _sortCharacters();
                      });
                      _saveSortPreference();
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      PopupMenuItem<SortMethod>(
                        value: SortMethod.nameAsc,
                        child: Row(
                          children: [
                            if (_sortMethod == SortMethod.nameAsc)
                              const Icon(Icons.check, size: 20)
                            else
                              const SizedBox(width: 20),
                            const SizedBox(width: 12),
                            Text(l10n.characterSortNameAsc),
                          ],
                        ),
                      ),
                      PopupMenuItem<SortMethod>(
                        value: SortMethod.nameDesc,
                        child: Row(
                          children: [
                            if (_sortMethod == SortMethod.nameDesc)
                              const Icon(Icons.check, size: 20)
                            else
                              const SizedBox(width: 20),
                            const SizedBox(width: 12),
                            Text(l10n.characterSortNameDesc),
                          ],
                        ),
                      ),
                      PopupMenuItem<SortMethod>(
                        value: SortMethod.updatedAtAsc,
                        child: Row(
                          children: [
                            if (_sortMethod == SortMethod.updatedAtAsc)
                              const Icon(Icons.check, size: 20)
                            else
                              const SizedBox(width: 20),
                            const SizedBox(width: 12),
                            Text(l10n.characterSortUpdatedAtAsc),
                          ],
                        ),
                      ),
                      PopupMenuItem<SortMethod>(
                        value: SortMethod.updatedAtDesc,
                        child: Row(
                          children: [
                            if (_sortMethod == SortMethod.updatedAtDesc)
                              const Icon(Icons.check, size: 20)
                            else
                              const SizedBox(width: 20),
                            const SizedBox(width: 12),
                            Text(l10n.characterSortUpdatedAtDesc),
                          ],
                        ),
                      ),
                      PopupMenuItem<SortMethod>(
                        value: SortMethod.createdAtAsc,
                        child: Row(
                          children: [
                            if (_sortMethod == SortMethod.createdAtAsc)
                              const Icon(Icons.check, size: 20)
                            else
                              const SizedBox(width: 20),
                            const SizedBox(width: 12),
                            Text(l10n.characterSortCreatedAtAsc),
                          ],
                        ),
                      ),
                      PopupMenuItem<SortMethod>(
                        value: SortMethod.createdAtDesc,
                        child: Row(
                          children: [
                            if (_sortMethod == SortMethod.createdAtDesc)
                              const Icon(Icons.check, size: 20)
                            else
                              const SizedBox(width: 20),
                            const SizedBox(width: 12),
                            Text(l10n.characterSortCreatedAtDesc),
                          ],
                        ),
                      ),
                      PopupMenuItem<SortMethod>(
                        value: SortMethod.custom,
                        child: Row(
                          children: [
                            if (_sortMethod == SortMethod.custom)
                              const Icon(Icons.check, size: 20)
                            else
                              const SizedBox(width: 20),
                            const SizedBox(width: 12),
                            Text(l10n.characterSortCustom),
                          ],
                        ),
                      ),
                    ];
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _getSortMethodLabel(l10n),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 18,
                          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isGridView ? _buildGridView() : _buildListView(),
          ),
        ],
      ),
      floatingActionButton: _isEditMode ? null : CommonFab(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const CharacterEditScreen(),
            ),
          );
          if (result == true) {
            _loadCharacters();
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_add_outlined,
            size: 80,
            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).characterEmptyTitle,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).characterEmptySubtitle,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_characters.isEmpty) return _buildEmptyState();

    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.05;
    final spacing = screenWidth * 0.025;

    final gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      childAspectRatio: 0.592,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
    );

    final padding = EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0);

    Widget buildCharacterCard(int index) {
      return CharacterCard(
        key: ValueKey(_characters[index].id),
        title: _characters[index].name,
        description: _characters[index].creatorNotes ?? '',
        tags: _characters[index].tags,
        imageData: _characterCoverImages[_characters[index].id],
        isEditMode: _isEditMode,
        isSelected: _selectedCharacterIds.contains(_characters[index].id),
        onTap: () async {
          if (_isEditMode) {
            _toggleCharacterSelection(_characters[index].id!);
          } else {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => CharacterViewScreen(characterId: _characters[index].id!),
              ),
            );
            if (result == true) {
              _loadCharacters();
            }
          }
        },
        onEdit: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => CharacterEditScreen(characterId: _characters[index].id),
            ),
          );
          if (result == true) {
            _loadCharacters();
          }
        },
        onCopy: () => _duplicateCharacter(_characters[index].id!),
        onExport: () => _exportCharacter(_characters[index].id!),
        onDelete: () => _deleteCharacter(_characters[index].id!),
      );
    }

    if (_sortMethod == SortMethod.custom) {
      return ReorderableGridView.builder(
        padding: padding,
        itemCount: _characters.length,
        onReorder: _reorderCharacters,
        gridDelegate: gridDelegate,
        itemBuilder: (context, index) => buildCharacterCard(index),
      );
    }

    return GridView.builder(
      padding: padding,
      itemCount: _characters.length,
      gridDelegate: gridDelegate,
      itemBuilder: (context, index) => buildCharacterCard(index),
    );
  }

  Widget _buildListView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_characters.isEmpty) return _buildEmptyState();

    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.05;

    if (_sortMethod == SortMethod.custom) {
      return ReorderableListView.builder(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
        itemCount: _characters.length,
        onReorder: _reorderCharacters,
        itemBuilder: (context, index) {
          return Padding(
            key: ValueKey(_characters[index].id),
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            
            child: CharacterListItem(
              title: _characters[index].name,
              description: _characters[index].creatorNotes ?? '',
              tags: _characters[index].tags,
              imageData: _characterCoverImages[_characters[index].id],
              isEditMode: _isEditMode,
              isSelected: _selectedCharacterIds.contains(_characters[index].id),
              onTap: () async {
                if (_isEditMode) {
                  _toggleCharacterSelection(_characters[index].id!);
                } else {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CharacterViewScreen(characterId: _characters[index].id!),
                    ),
                  );
                  if (result == true) {
                    _loadCharacters();
                  }
                }
              },
              onEdit: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CharacterEditScreen(characterId: _characters[index].id),
                  ),
                );
                if (result == true) {
                  _loadCharacters();
                }
              },
              onExport: () => _exportCharacter(_characters[index].id!),
              onDelete: () => _deleteCharacter(_characters[index].id!),
            ),
          );
        },

      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
      itemCount: _characters.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: CharacterListItem(
            title: _characters[index].name,
            description: _characters[index].creatorNotes ?? '',
            tags: _characters[index].tags,
            imageData: _characterCoverImages[_characters[index].id],
            isEditMode: _isEditMode,
            isSelected: _selectedCharacterIds.contains(_characters[index].id),
            onTap: () async {
              if (_isEditMode) {
                _toggleCharacterSelection(_characters[index].id!);
              } else {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CharacterViewScreen(characterId: _characters[index].id!),
                  ),
                );
                if (result == true) {
                  _loadCharacters();
                }
              }
            },
            onEdit: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => CharacterEditScreen(characterId: _characters[index].id),
                ),
              );
              if (result == true) {
                _loadCharacters();
              }
            },
            onExport: () => _exportCharacter(_characters[index].id!),
            onDelete: () => _deleteCharacter(_characters[index].id!),
          ),
        );
      },
    );
  }
}

class _AgentHighlightButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _AgentHighlightButton({required this.onPressed});

  @override
  State<_AgentHighlightButton> createState() => _AgentHighlightButtonState();
}

class _AgentHighlightButtonState extends State<_AgentHighlightButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Transform.translate(
      offset: const Offset(10.0, 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing background circle
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Container(
                width: 36 * _scaleAnimation.value,
                height: 36 * _scaleAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary.withValues(
                    alpha: 0.2 * (2.0 - _scaleAnimation.value),
                  ),
                ),
              );
            },
          ),
          // Tooltip + button
          Tooltip(
            message: AppLocalizations.of(context).characterAgentHighlightTooltip,
            triggerMode: TooltipTriggerMode.manual,
            showDuration: const Duration(seconds: 5),
            child: IconButton(
              icon: Icon(Icons.auto_awesome, color: colorScheme.primary),
              onPressed: widget.onPressed,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }
}
