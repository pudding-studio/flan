import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        actions: [
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
          '설정 화면',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
