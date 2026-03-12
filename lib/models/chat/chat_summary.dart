class ChatSummary {
  final int? id;
  final int chatRoomId;
  final int startPinMessageId;
  final int endPinMessageId;
  final String summaryContent;
  final int tokenCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatSummary({
    this.id,
    required this.chatRoomId,
    required this.startPinMessageId,
    required this.endPinMessageId,
    required this.summaryContent,
    this.tokenCount = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory ChatSummary.fromMap(Map<String, dynamic> map) {
    return ChatSummary(
      id: map['id'] as int?,
      chatRoomId: map['chat_room_id'] as int,
      startPinMessageId: map['start_pin_message_id'] as int,
      endPinMessageId: map['end_pin_message_id'] as int,
      summaryContent: map['summary_content'] as String,
      tokenCount: map['token_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chat_room_id': chatRoomId,
      'start_pin_message_id': startPinMessageId,
      'end_pin_message_id': endPinMessageId,
      'summary_content': summaryContent,
      'token_count': tokenCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ChatSummary copyWith({
    int? id,
    int? chatRoomId,
    int? startPinMessageId,
    int? endPinMessageId,
    String? summaryContent,
    int? tokenCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatSummary(
      id: id ?? this.id,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      startPinMessageId: startPinMessageId ?? this.startPinMessageId,
      endPinMessageId: endPinMessageId ?? this.endPinMessageId,
      summaryContent: summaryContent ?? this.summaryContent,
      tokenCount: tokenCount ?? this.tokenCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
