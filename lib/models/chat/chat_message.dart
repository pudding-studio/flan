enum MessageRole {
  user,
  assistant;

  String get displayName {
    switch (this) {
      case MessageRole.user:
        return '사용자';
      case MessageRole.assistant:
        return '어시스턴트';
    }
  }
}

class ChatMessage {
  final int? id;
  final int chatRoomId;
  final MessageRole role;
  final String content;
  final int tokenCount;
  final DateTime createdAt;
  final DateTime? editedAt;

  ChatMessage({
    this.id,
    required this.chatRoomId,
    required this.role,
    required this.content,
    this.tokenCount = 0,
    DateTime? createdAt,
    this.editedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as int?,
      chatRoomId: map['chat_room_id'] as int,
      role: MessageRole.values.firstWhere(
        (e) => e.name == (map['role'] as String),
        orElse: () => MessageRole.user,
      ),
      content: map['content'] as String,
      tokenCount: map['token_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      editedAt: map['edited_at'] != null
          ? DateTime.parse(map['edited_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chat_room_id': chatRoomId,
      'role': role.name,
      'content': content,
      'token_count': tokenCount,
      'created_at': createdAt.toIso8601String(),
      'edited_at': editedAt?.toIso8601String(),
    };
  }

  ChatMessage copyWith({
    int? id,
    int? chatRoomId,
    MessageRole? role,
    String? content,
    int? tokenCount,
    DateTime? createdAt,
    DateTime? editedAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      role: role ?? this.role,
      content: content ?? this.content,
      tokenCount: tokenCount ?? this.tokenCount,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
    );
  }
}
