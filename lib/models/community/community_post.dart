import 'community_comment.dart';

class CommunityPost {
  final int? id;
  final int chatRoomId;
  final String author;
  final String title;
  final DateTime time;
  final String content;
  final DateTime createdAt;
  List<CommunityComment> comments;

  CommunityPost({
    this.id,
    required this.chatRoomId,
    required this.author,
    required this.title,
    required this.time,
    required this.content,
    DateTime? createdAt,
    List<CommunityComment>? comments,
  })  : createdAt = createdAt ?? DateTime.now(),
        comments = comments ?? [];

  factory CommunityPost.fromMap(Map<String, dynamic> map) => CommunityPost(
        id: map['id'] as int?,
        chatRoomId: map['chat_room_id'] as int,
        author: map['author'] as String,
        title: map['title'] as String,
        time: DateTime.parse(map['time'] as String),
        content: map['content'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'chat_room_id': chatRoomId,
        'author': author,
        'title': title,
        'time': time.toIso8601String(),
        'content': content,
        'created_at': createdAt.toIso8601String(),
      };
}
