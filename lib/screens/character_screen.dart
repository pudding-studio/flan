import 'package:flutter/material.dart';

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
          IconButton(
            icon: Icon(_isGridView ? Icons.grid_view : Icons.view_list),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            tooltip: _isGridView ? '리스트뷰로 전환' : '격자뷰로 전환',
          ),
          IconButton(
            icon: const Icon(Icons.dark_mode_outlined),
            onPressed: () {
              // TODO: 다크모드 전환 기능 구현
            },
            tooltip: '다크모드 전환',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const CircleAvatar(
                radius: 16,
                child: Icon(Icons.person, size: 20),
              ),
              onPressed: () {
                // TODO: 프로필 페이지로 이동
              },
              tooltip: '프로필',
            ),
          ),
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
    final spacing = screenWidth * 0.05;
    final imageSize = screenWidth * 0.45;
    final cardWidth = imageSize;
    final cardHeight = imageSize + 120;

    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: spacing,
        mainAxisSpacing: 16.0,
        childAspectRatio: cardWidth / cardHeight,
      ),
      itemCount: demoCharacters.length,
      itemBuilder: (context, index) {
        return _CharacterCard(
          title: demoCharacters[index]['title'] as String,
          description: demoCharacters[index]['description'] as String,
          tags: demoCharacters[index]['tags'] as List<String>,
          imageUrl: demoCharacters[index]['imageUrl'] as String?,
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
          child: _CharacterListItem(
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

class _CharacterCard extends StatelessWidget {
  final String title;
  final String description;
  final List<String> tags;
  final String? imageUrl;

  const _CharacterCard({
    required this.title,
    required this.description,
    required this.tags,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth * 0.45;

    return SizedBox(
      width: imageSize,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20.0),
            child: Container(
              width: imageSize,
              height: imageSize,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: imageUrl != null
                  ? Image.network(imageUrl!, fit: BoxFit.cover)
                  : Icon(
                      Icons.person,
                      size: imageSize * 0.4,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 32,
                  child: Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: tags.map((tag) => _TagChip(label: tag)).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CharacterListItem extends StatelessWidget {
  final String title;
  final String description;
  final List<String> tags;
  final String? imageUrl;

  const _CharacterListItem({
    required this.title,
    required this.description,
    required this.tags,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = (screenWidth * 0.45) * 0.6;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20.0),
          child: Container(
            width: imageSize,
            height: imageSize,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: imageUrl != null
                ? Image.network(imageUrl!, fit: BoxFit.cover)
                : Icon(
                    Icons.person,
                    size: imageSize * 0.4,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: tags.map((tag) => _TagChip(label: tag)).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
      ),
    );
  }
}
