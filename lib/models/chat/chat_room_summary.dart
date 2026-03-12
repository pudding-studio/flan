import '../character/character.dart';
import '../character/cover_image.dart';
import 'chat_message.dart';
import 'chat_room.dart';

class ChatRoomSummary {
  final ChatRoom chatRoom;
  final Character? character;
  final CoverImage? coverImage;
  final ChatMessage? lastMessage;
  final int messageCount;
  final int tokenCount;

  ChatRoomSummary({
    required this.chatRoom,
    this.character,
    this.coverImage,
    this.lastMessage,
    required this.messageCount,
    required this.tokenCount,
  });
}
