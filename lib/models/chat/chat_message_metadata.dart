class ChatMessageMetadata {
  final int? id;
  final int chatMessageId;
  final int chatRoomId;
  final String? location;
  final String? date;
  final String? time;
  final DateTime createdAt;

  ChatMessageMetadata({
    this.id,
    required this.chatMessageId,
    required this.chatRoomId,
    this.location,
    this.date,
    this.time,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ChatMessageMetadata.fromMap(Map<String, dynamic> map) {
    return ChatMessageMetadata(
      id: map['id'] as int?,
      chatMessageId: map['chat_message_id'] as int,
      chatRoomId: map['chat_room_id'] as int,
      location: map['location'] as String?,
      date: map['date'] as String?,
      time: map['time'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chat_message_id': chatMessageId,
      'chat_room_id': chatRoomId,
      'location': location,
      'date': date,
      'time': time,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ChatMessageMetadata copyWith({
    int? id,
    int? chatMessageId,
    int? chatRoomId,
    String? location,
    String? date,
    String? time,
    DateTime? createdAt,
  }) {
    return ChatMessageMetadata(
      id: id ?? this.id,
      chatMessageId: chatMessageId ?? this.chatMessageId,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      location: location ?? this.location,
      date: date ?? this.date,
      time: time ?? this.time,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
