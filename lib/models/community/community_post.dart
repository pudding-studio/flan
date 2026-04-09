import 'community_comment.dart';

class CommunityPost {
  final int? id;
  final int chatRoomId;
  final String author;
  final String title;
  final DateTime time;
  final String content;
  final DateTime createdAt;
  final bool isFavorited;
  final bool favoriteUsed;
  List<CommunityComment> comments;

  CommunityPost({
    this.id,
    required this.chatRoomId,
    required this.author,
    required this.title,
    required this.time,
    required this.content,
    DateTime? createdAt,
    this.isFavorited = false,
    this.favoriteUsed = false,
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
        isFavorited: (map['is_favorited'] as int?) == 1,
        favoriteUsed: (map['favorite_used'] as int?) == 1,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'chat_room_id': chatRoomId,
        'author': author,
        'title': title,
        'time': time.toIso8601String(),
        'content': content,
        'created_at': createdAt.toIso8601String(),
        'is_favorited': isFavorited ? 1 : 0,
        'favorite_used': favoriteUsed ? 1 : 0,
      };

  CommunityPost copyWith({
    int? id,
    int? chatRoomId,
    String? author,
    String? title,
    DateTime? time,
    String? content,
    DateTime? createdAt,
    bool? isFavorited,
    bool? favoriteUsed,
    List<CommunityComment>? comments,
  }) => CommunityPost(
        id: id ?? this.id,
        chatRoomId: chatRoomId ?? this.chatRoomId,
        author: author ?? this.author,
        title: title ?? this.title,
        time: time ?? this.time,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
        isFavorited: isFavorited ?? this.isFavorited,
        favoriteUsed: favoriteUsed ?? this.favoriteUsed,
        comments: comments ?? this.comments,
      );
}
