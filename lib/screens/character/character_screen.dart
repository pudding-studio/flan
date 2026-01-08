import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import 'character_edit_screen.dart';
import 'widgets/character_card.dart';
import 'widgets/character_list_item.dart';

class CharacterScreen extends StatefulWidget {
  const CharacterScreen({super.key});

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen> {
  bool _isGridView = true;
  String _sortMethod = 'date';

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
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CharacterEditScreen(),
            ),
          );
        },
        elevation: 0,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGridView() {
    final demoCharacters = [
      {
        'title': '홍길동',
        'description': '조선시대 의적으로 탐관오리를 응징하고 백성들을 도운 전설적인 인물',
        'tags': ['역사', '의적'],
        'imageUrl': null,
      },
      {
        'title': '아이언맨',
        'description': '천재 발명가이자 억만장자로 첨단 슈트를 입고 세계를 지키는 영웅',
        'tags': ['SF', '히어로'],
        'imageUrl': null,
      },
      {
        'title': '셜록 홈즈',
        'description': '뛰어난 추리력과 관찰력으로 어떤 사건이든 해결하는 명탐정',
        'tags': ['추리', '고전'],
        'imageUrl': null,
      },
      {
        'title': '해리 포터',
        'description': '마법 세계에서 어둠의 마법사와 싸우는 용감한 소년 마법사',
        'tags': ['판타지', '마법'],
        'imageUrl': null,
      },
    ];

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
            for (int i = 0; i < demoCharacters.length; i += 2)
              Padding(
                padding: EdgeInsets.only(bottom: i < demoCharacters.length - 2 ? 0 : 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: CharacterCard(
                        title: demoCharacters[i]['title'] as String,
                        description: demoCharacters[i]['description'] as String,
                        tags: demoCharacters[i]['tags'] as List<String>,
                        imageUrl: demoCharacters[i]['imageUrl'] as String?,
                      ),
                    ),
                    SizedBox(width: spacing),
                    if (i + 1 < demoCharacters.length)
                      SizedBox(
                        width: cardWidth,
                        child: CharacterCard(
                          title: demoCharacters[i + 1]['title'] as String,
                          description: demoCharacters[i + 1]['description'] as String,
                          tags: demoCharacters[i + 1]['tags'] as List<String>,
                          imageUrl: demoCharacters[i + 1]['imageUrl'] as String?,
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
    final demoCharacters = [
      {
        'title': '홍길동',
        'description': '조선시대 의적으로 탐관오리를 응징하고 백성들을 도운 전설적인 인물',
        'tags': ['역사', '의적'],
        'imageUrl': null,
      },
      {
        'title': '아이언맨',
        'description': '천재 발명가이자 억만장자로 첨단 슈트를 입고 세계를 지키는 영웅',
        'tags': ['SF', '히어로'],
        'imageUrl': null,
      },
      {
        'title': '셜록 홈즈',
        'description': '뛰어난 추리력과 관찰력으로 어떤 사건이든 해결하는 명탐정',
        'tags': ['추리', '고전'],
        'imageUrl': null,
      },
      {
        'title': '해리 포터',
        'description': '마법 세계에서 어둠의 마법사와 싸우는 용감한 소년 마법사',
        'tags': ['판타지', '마법'],
        'imageUrl': null,
      },
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.05;

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
      itemCount: demoCharacters.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: CharacterListItem(
            title: demoCharacters[index]['title'] as String,
            description: demoCharacters[index]['description'] as String,
            tags: demoCharacters[index]['tags'] as List<String>,
            imageUrl: demoCharacters[index]['imageUrl'] as String?,
          ),
        );
      },
    );
  }
}
