import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../database/database_helper.dart';
import '../../models/character/character.dart';
import 'character_edit_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _loadCharacters();
  }

  Future<void> _loadCharacters() async {
    setState(() => _isLoading = true);
    try {
      final characters = await _db.readAllCharacters();
      setState(() {
        _characters = characters;
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
          Transform.translate(
            offset: const Offset(14, 0),
            child: IconButton(
              icon: Icon(_isGridView ? Icons.grid_view : Icons.view_list),
              onPressed: () {
                setState(() {
                  _isGridView = !_isGridView;
                });
              },
              tooltip: _isGridView ? '리스트뷰로 전환' : '격자뷰로 전환',
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(),
            ),
          ),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              IconData iconData;
              String tooltipText;
              ThemeMode nextMode;

              switch (themeProvider.themeMode) {
                case ThemeMode.light:
                  iconData = Icons.light_mode_outlined;
                  tooltipText = '다크 모드로 전환';
                  nextMode = ThemeMode.dark;
                  break;
                case ThemeMode.dark:
                  iconData = Icons.dark_mode_outlined;
                  tooltipText = '시스템 설정으로 전환';
                  nextMode = ThemeMode.system;
                  break;
                case ThemeMode.system:
                  iconData = Icons.brightness_auto_outlined;
                  tooltipText = '라이트 모드로 전환';
                  nextMode = ThemeMode.light;
                  break;
              }

              return Transform.translate(
                offset: const Offset(4, 0),
                child: IconButton(
                  icon: Icon(iconData),
                  onPressed: () {
                    themeProvider.setThemeMode(nextMode);
                  },
                  tooltip: tooltipText,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(),
                ),
              );
            },
          ),
          IconButton(
            icon: const CircleAvatar(
              radius: 16,
              child: Icon(Icons.person, size: 20),
            ),
            onPressed: () {
              // TODO: 프로필 페이지로 이동
            },
            tooltip: '프로필',
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(),
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
                PopupMenuButton<String>(
                  onSelected: (String value) {
                    setState(() {
                      _sortMethod = value;
                      _sortCharacters();
                    });
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem(
                      value: 'date',
                      child: Text('날짜순'),
                    ),
                    const PopupMenuItem(
                      value: 'name',
                      child: Text('이름(오름차순)'),
                    ),
                    const PopupMenuItem(
                      value: 'custom',
                      child: Text('사용자 지정'),
                    ),
                  ],
                  child: Text(
                    _getSortMethodLabel(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
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
        elevation: 0,
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
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '캐릭터가 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '+ 버튼을 눌러 새 캐릭터를 추가해보세요',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.4),
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
                        imageUrl: null, // TODO: 표지 이미지 처리
                        onTap: () async {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CharacterEditScreen(characterId: _characters[i].id),
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
                          imageUrl: null, // TODO: 표지 이미지 처리
                          onTap: () async {
                            final result = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CharacterEditScreen(characterId: _characters[i + 1].id),
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
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '캐릭터가 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '+ 버튼을 눌러 새 캐릭터를 추가해보세요',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.4),
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
            imageUrl: null, // TODO: 표지 이미지 처리
            onTap: () async {
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
            onDelete: () => _deleteCharacter(_characters[index].id!),
          ),
        );
      },
    );
  }
}
