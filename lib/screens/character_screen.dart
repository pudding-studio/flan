import 'package:flutter/material.dart';

class CharacterScreen extends StatefulWidget {
  const CharacterScreen({super.key});

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen> {
  bool _isGridView = true;

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
      body: Container(
        
        child: Text(
          _isGridView ? '캐릭터 화면 (격자뷰)' : '캐릭터 화면 (리스트뷰)',
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
