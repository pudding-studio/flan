import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
      body: const Center(
        child: Text(
          '채팅 화면',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
