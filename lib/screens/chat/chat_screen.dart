import 'package:flutter/material.dart';
import 'widgets/chat_room_card.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String?>> demoChatRooms = [
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
          Transform.translate(
            offset: const Offset(8, 0),
            child: IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                // TODO: 새 채팅 시작
              },
              tooltip: '새 채팅',
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: 더보기 메뉴 표시
            },
            tooltip: '더보기',
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
        itemCount: demoChatRooms.length,
        separatorBuilder: (context, index) => const SizedBox(height: 20.0),
        itemBuilder: (context, index) {
          return ChatRoomCard(
            title: demoChatRooms[index]['title']!,
            lastMessage: demoChatRooms[index]['lastMessage']!,
            date: demoChatRooms[index]['date']!,
            imageUrl: demoChatRooms[index]['imageUrl'],
          );
        },
      ),
    );
  }
}
