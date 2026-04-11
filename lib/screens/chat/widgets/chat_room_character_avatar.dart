import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../models/character/cover_image.dart';

/// Small circular avatar shown next to the character name in the chat room
/// app bar.
///
/// Asynchronously resolves the first available cover image and falls back
/// to a neutral person icon when no image is set or the bytes fail to load.
class ChatRoomCharacterAvatar extends StatelessWidget {
  final List<CoverImage> coverImages;

  const ChatRoomCharacterAvatar({super.key, required this.coverImages});

  @override
  Widget build(BuildContext context) {
    const fallback = CircleAvatar(
      radius: 16,
      backgroundColor: Color(0xFFE0E0E0),
      child: Icon(
        Icons.person_outline,
        size: 16,
        color: Color(0xFF757575),
      ),
    );

    final selectedCover = coverImages.isNotEmpty ? coverImages.first : null;
    if (selectedCover == null) return fallback;

    return FutureBuilder<Uint8List?>(
      future: selectedCover.resolveImageData(),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) return fallback;
        return CircleAvatar(
          radius: 16,
          backgroundImage: MemoryImage(bytes),
        );
      },
    );
  }
}
