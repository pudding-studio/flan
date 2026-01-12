import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../../providers/theme_provider.dart';
import '../../database/database_helper.dart';
import '../../models/character/character.dart';
import '../../models/character/cover_image.dart';
import 'character_edit_screen.dart';
import 'character_view_screen.dart';
import 'widgets/character_card.dart';
import 'widgets/character_list_item.dart';

class CharacterScreen extends StatefulWidget {
  const CharacterScreen({super.key});

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  bool _isGridView = true;
  String _sortMethod = 'date';
  List<Character> _characters = [];
  bool _isLoading = true;
  Map<int, String?> _characterCoverImages = {};
  bool _isEditMode = false;
  final Set<int> _selectedCharacterIds = {};

  @override
  void initState() {
    super.initState();
    _loadCharacters();
  }

  Future<void> _loadCharacters() async {
    setState(() => _isLoading = true);
    try {
      final characters = await _db.readAllCharacters();

      // 각 캐릭터의 표지 이미지 로드
      final coverImages = <int, String?>{};
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
          coverImages[character.id!] = selectedImage.imagePath;
        }
      }

      setState(() {
        _characters = characters;
        _characterCoverImages = coverImages;
        _sortCharacters();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('캐릭터 목록을 불러오는데 실패했습니다: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _sortCharacters() {
    switch (_sortMethod) {
      case 'date':
        _characters.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'name':
        _characters.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'custom':
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('순서 변경에 실패했습니다: $e')),
        );
      }
      await _loadCharacters();
    }
  }

  Future<void> _deleteSelectedCharacters() async {
    if (_selectedCharacterIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('캐릭터 삭제'),
        content: Text('선택한 ${_selectedCharacterIds.length}개의 캐릭터를 삭제하시겠습니까? 관련된 모든 데이터가 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('선택한 캐릭터가 삭제되었습니다')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('캐릭터 삭제에 실패했습니다: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteCharacter(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('캐릭터 삭제'),
        content: const Text('이 캐릭터를 삭제하시겠습니까? 관련된 모든 데이터가 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _db.deleteCharacter(id);
        await _loadCharacters();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('캐릭터가 삭제되었습니다')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('캐릭터 삭제에 실패했습니다: $e')),
          );
        }
      }
    }
  }

  String _getSortMethodLabel() {
    switch (_sortMethod) {
      case 'date':
        return '정렬방식: 날짜순';
      case 'name':
        return '정렬방식: 이름(오름차순)';
      case 'custom':
        return '정렬방식: 사용자 지정';
      default:
        return '정렬방식';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isEditMode
          ? Text('${_selectedCharacterIds.length}개 선택됨')
          : const Text('캐릭터'),
        leading: _isEditMode
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleEditMode,
            )
          : null,
        actions: [
          if (!_isEditMode)
            Transform.translate(
              offset: const Offset(8, 0),
              child: IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: _toggleEditMode,
                tooltip: '편집',
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(),
              ),
            ),
          if (_isEditMode)
            Transform.translate(
              offset: const Offset(8, 0),
              child: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: _selectedCharacterIds.isEmpty ? null : _deleteSelectedCharacters,
                tooltip: '삭제',
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(),
              ),
            ),
          if (!_isEditMode)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: '더보기',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (String value) {
              if (value == 'date' || value == 'name' || value == 'custom') {
                setState(() {
                  _sortMethod = value;
                  _sortCharacters();
                });
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  enabled: false,
                  child: Text(
                    '보기 방식',
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
                  },
                  child: Row(
                    children: [
                      if (_isGridView)
                        const Icon(Icons.check, size: 20)
                      else
                        const SizedBox(width: 20),
                      const SizedBox(width: 12),
                      const Text('격자뷰'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'view_list',
                  onTap: () {
                    setState(() {
                      _isGridView = false;
                    });
                  },
                  child: Row(
                    children: [
                      if (!_isGridView)
                        const Icon(Icons.check, size: 20)
                      else
                        const SizedBox(width: 20),
                      const SizedBox(width: 12),
                      const Text('리스트뷰'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  enabled: false,
                  child: Text(
                    '정렬방식',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'date',
                  child: Row(
                    children: [
                      if (_sortMethod == 'date')
                        const Icon(Icons.check, size: 20)
                      else
                        const SizedBox(width: 20),
                      const SizedBox(width: 12),
                      const Text('날짜순'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'name',
                  child: Row(
                    children: [
                      if (_sortMethod == 'name')
                        const Icon(Icons.check, size: 20)
                      else
                        const SizedBox(width: 20),
                      const SizedBox(width: 12),
                      const Text('이름(오름차순)'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'custom',
                  child: Row(
                    children: [
                      if (_sortMethod == 'custom')
                        const Icon(Icons.check, size: 20)
                      else
                        const SizedBox(width: 20),
                      const SizedBox(width: 12),
                      const Text('사용자 지정'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  enabled: false,
                  child: Text(
                    '테마 선택',
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
                              const Text('라이트 모드'),
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
                              const Text('다크 모드'),
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
                              const Text('시스템 설정'),
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
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  _getSortMethodLabel(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
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
      floatingActionButton: _isEditMode ? null : FloatingActionButton(
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
        elevation: 4,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGridView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_characters.isEmpty) {
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
              '캐릭터가 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '+ 버튼을 눌러 새 캐릭터를 추가해보세요',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.05;
    final spacing = screenWidth * 0.025;

    final gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      childAspectRatio: 0.55,
      crossAxisSpacing: spacing,
      mainAxisSpacing: 0,
    );

    final padding = EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0);

    Widget buildCharacterCard(int index) {
      return CharacterCard(
        key: ValueKey(_characters[index].id),
        title: _characters[index].name,
        description: _characters[index].summary ?? '',
        tags: _characters[index].keywords?.split(',').map((e) => e.trim()).toList() ?? [],
        imageUrl: _characterCoverImages[_characters[index].id],
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
        onDelete: () => _deleteCharacter(_characters[index].id!),
      );
    }

    if (_sortMethod == 'custom') {
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

    if (_characters.isEmpty) {
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
              '캐릭터가 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '+ 버튼을 눌러 새 캐릭터를 추가해보세요',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.05;

    if (_sortMethod == 'custom') {
      return ReorderableListView.builder(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
        itemCount: _characters.length,
        onReorder: _reorderCharacters,
        itemBuilder: (context, index) {
          return Padding(
            key: ValueKey(_characters[index].id),
            padding: const EdgeInsets.only(bottom: 16.0),
            child: CharacterListItem(
              title: _characters[index].name,
              description: _characters[index].summary ?? '',
              tags: _characters[index].keywords?.split(',').map((e) => e.trim()).toList() ?? [],
              imageUrl: _characterCoverImages[_characters[index].id],
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
            description: _characters[index].summary ?? '',
            tags: _characters[index].keywords?.split(',').map((e) => e.trim()).toList() ?? [],
            imageUrl: _characterCoverImages[_characters[index].id],
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
            onDelete: () => _deleteCharacter(_characters[index].id!),
          ),
        );
      },
    );
  }
}
