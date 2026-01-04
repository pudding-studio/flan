import 'package:flutter/material.dart';

class CharacterScreen extends StatelessWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('캐릭터'),
      ),
      body: const Center(
        child: Text(
          '캐릭터 화면',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
