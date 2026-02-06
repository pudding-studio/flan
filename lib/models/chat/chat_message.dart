import 'dart:convert';

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

class UsageMetadata {
  final int promptTokenCount;
  final int candidatesTokenCount;
  final int totalTokenCount;
  final int? cachedContentTokenCount;
  final int? thoughtsTokenCount;

  const UsageMetadata({
    this.promptTokenCount = 0,
    this.candidatesTokenCount = 0,
    this.totalTokenCount = 0,
    this.cachedContentTokenCount,
    this.thoughtsTokenCount,
  });

  factory UsageMetadata.fromJson(Map<String, dynamic> json) {
    return UsageMetadata(
      promptTokenCount: json['promptTokenCount'] as int? ?? 0,
      candidatesTokenCount: json['candidatesTokenCount'] as int? ?? 0,
      totalTokenCount: json['totalTokenCount'] as int? ?? 0,
      cachedContentTokenCount: json['cachedContentTokenCount'] as int?,
      thoughtsTokenCount: json['thoughtsTokenCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'promptTokenCount': promptTokenCount,
      'candidatesTokenCount': candidatesTokenCount,
      'totalTokenCount': totalTokenCount,
      if (cachedContentTokenCount != null) 'cachedContentTokenCount': cachedContentTokenCount,
      if (thoughtsTokenCount != null) 'thoughtsTokenCount': thoughtsTokenCount,
    };
  }

  double get cacheRatio {
    if (promptTokenCount == 0) return 0;
    return (cachedContentTokenCount ?? 0) / promptTokenCount;
  }

  double get thoughtsRatio {
    if (candidatesTokenCount == 0) return 0;
    return (thoughtsTokenCount ?? 0) / candidatesTokenCount;
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
  final UsageMetadata? usageMetadata;

  ChatMessage({
    this.id,
    required this.chatRoomId,
    required this.role,
    required this.content,
    this.tokenCount = 0,
    DateTime? createdAt,
    this.editedAt,
    this.usageMetadata,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    UsageMetadata? usageMetadata;
    if (map['usage_metadata'] != null) {
      final usageJson = map['usage_metadata'] as String;
      usageMetadata = UsageMetadata.fromJson(jsonDecode(usageJson));
    }

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
      usageMetadata: usageMetadata,
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
      'usage_metadata': usageMetadata != null ? jsonEncode(usageMetadata!.toJson()) : null,
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
    UsageMetadata? usageMetadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      role: role ?? this.role,
      content: content ?? this.content,
      tokenCount: tokenCount ?? this.tokenCount,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      usageMetadata: usageMetadata ?? this.usageMetadata,
    );
  }
}
