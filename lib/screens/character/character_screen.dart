import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  Map<int, String?> _characterCoverImages = {}; // characterId -> imagePath

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
        if (character.selectedCoverImageId != null) {
          final images = await _db.readCoverImages(character.id!);
          final selectedImage = images.firstWhere(
            (img) => img.id == character.selectedCoverImageId,
            orElse: () => images.isNotEmpty ? images.first : CoverImage(
              characterId: character.id!,
              name: '',
              order: 0,
            ),
          );
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
        // TODO: 사용자 지정 정렬 구현
        break;
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
        title: const Text('캐릭터'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              // TODO: 편집 모드로 전환
            },
            tooltip: '편집',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: '더보기',
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
          const SizedBox(width: 8),
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
      floatingActionButton: FloatingActionButton(
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - (horizontalPadding * 2) - spacing;
        final cardWidth = availableWidth / 2;

        return ListView(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
          children: [
            for (int i = 0; i < _characters.length; i += 2)
              Padding(
                padding: EdgeInsets.only(bottom: i < _characters.length - 2 ? 0 : 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: CharacterCard(
                        title: _characters[i].name,
                        description: _characters[i].summary ?? '',
                        tags: _characters[i].keywords?.split(',').map((e) => e.trim()).toList() ?? [],
                        imageUrl: _characterCoverImages[_characters[i].id],
                        onTap: () async {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CharacterViewScreen(characterId: _characters[i].id!),
                            ),
                          );
                          if (result == true) {
                            _loadCharacters();
                          }
                        },
                        onDelete: () => _deleteCharacter(_characters[i].id!),
                      ),
                    ),
                    SizedBox(width: spacing),
                    if (i + 1 < _characters.length)
                      SizedBox(
                        width: cardWidth,
                        child: CharacterCard(
                          title: _characters[i + 1].name,
                          description: _characters[i + 1].summary ?? '',
                          tags: _characters[i + 1].keywords?.split(',').map((e) => e.trim()).toList() ?? [],
                          imageUrl: _characterCoverImages[_characters[i + 1].id],
                          onTap: () async {
                            final result = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CharacterViewScreen(characterId: _characters[i + 1].id!),
                              ),
                            );
                            if (result == true) {
                              _loadCharacters();
                            }
                          },
                          onDelete: () => _deleteCharacter(_characters[i + 1].id!),
                        ),
                      )
                    else
                      SizedBox(width: cardWidth),
                  ],
                ),
              ),
          ],
        );
      },
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
            onTap: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => CharacterViewScreen(characterId: _characters[index].id!),
                ),
              );
              if (result == true) {
                _loadCharacters();
              }
            },
            onDelete: () => _deleteCharacter(_characters[index].id!),
          ),
        );
      },
    );
  }
}
