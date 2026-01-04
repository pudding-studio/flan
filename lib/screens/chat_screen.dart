import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final demoChatRooms = [
      {
        'title': '홍길동',
        'lastMessage': '안녕하세요! 오늘 날씨가 정말 좋네요.',
        'date': '오늘',
        'imageUrl': null,
      },
      {
        'title': '아이언맨',
        'lastMessage': '새로운 슈트 디자인을 완성했어요.',
        'date': '어제',
        'imageUrl': null,
      },
      {
        'title': '셜록 홈즈',
        'lastMessage': '이 사건에는 흥미로운 단서가 있습니다. 정말이지 흥미로운 일이아닐수가 없군요',
        'date': '2일 전',
        'imageUrl': null,
      },
      {
        'title': '해리 포터',
        'lastMessage': '호그와트에서 재미있는 일이 있었어요.',
        'date': '3일 전',
        'imageUrl': null,
      },
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.05;

    return Scaffold(
      appBar: AppBar(
        title: const Text('채팅'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              // TODO: 새 채팅 시작
            },
            tooltip: '새 채팅',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: 더보기 메뉴 표시
            },
            tooltip: '더보기',
          ),
        ],
      ),
      body: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
        itemCount: demoChatRooms.length,
        separatorBuilder: (context, index) => const SizedBox(height: 20.0),
        itemBuilder: (context, index) {
          return _ChatRoomCard(
            title: demoChatRooms[index]['title'] as String,
            lastMessage: demoChatRooms[index]['lastMessage'] as String,
            date: demoChatRooms[index]['date'] as String,
            imageUrl: demoChatRooms[index]['imageUrl'] as String?,
          );
        },
      ),
    );
  }
}

class _ChatRoomCard extends StatelessWidget {
  final String title;
  final String lastMessage;
  final String date;
  final String? imageUrl;

  const _ChatRoomCard({
    required this.title,
    required this.lastMessage,
    required this.date,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = (screenWidth * 0.17);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
              padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        date,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
