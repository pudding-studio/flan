class ChatLog {
  final int? id;
  final DateTime timestamp;
  final String type;
  final String request;
  final String response;
  final int? chatRoomId;
  final int? characterId;

  const ChatLog({
    this.id,
    required this.timestamp,
    required this.type,
    required this.request,
    required this.response,
    this.chatRoomId,
    this.characterId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'request': request,
      'response': response,
      'chat_room_id': chatRoomId,
      'character_id': characterId,
    };
  }

  factory ChatLog.fromMap(Map<String, dynamic> map) {
    return ChatLog(
      id: map['id'] as int?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      type: map['type'] as String,
      request: map['request'] as String,
      response: map['response'] as String,
      chatRoomId: map['chat_room_id'] as int?,
      characterId: map['character_id'] as int?,
    );
  }

  ChatLog copyWith({
    int? id,
    DateTime? timestamp,
    String? type,
    String? request,
    String? response,
    int? chatRoomId,
    int? characterId,
  }) {
    return ChatLog(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      request: request ?? this.request,
      response: response ?? this.response,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      characterId: characterId ?? this.characterId,
    );
  }
}
