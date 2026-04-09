class NewsArticle {
  final int? id;
  final int chatRoomId;
  final String topic;
  final String tone;
  final String author;
  final String title;
  final DateTime time;
  final String content;
  final DateTime createdAt;
  final int? agentEntryId;

  NewsArticle({
    this.id,
    required this.chatRoomId,
    required this.topic,
    required this.tone,
    required this.author,
    required this.title,
    required this.time,
    required this.content,
    DateTime? createdAt,
    this.agentEntryId,
  }) : createdAt = createdAt ?? DateTime.now();

  factory NewsArticle.fromMap(Map<String, dynamic> map) => NewsArticle(
        id: map['id'] as int?,
        chatRoomId: map['chat_room_id'] as int,
        topic: map['topic'] as String,
        tone: map['tone'] as String,
        author: map['author'] as String,
        title: map['title'] as String,
        time: DateTime.parse(map['time'] as String),
        content: map['content'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        agentEntryId: map['agent_entry_id'] as int?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'chat_room_id': chatRoomId,
        'topic': topic,
        'tone': tone,
        'author': author,
        'title': title,
        'time': time.toIso8601String(),
        'content': content,
        'created_at': createdAt.toIso8601String(),
        'agent_entry_id': agentEntryId,
      };

  NewsArticle copyWith({
    int? id,
    int? chatRoomId,
    String? topic,
    String? tone,
    String? author,
    String? title,
    DateTime? time,
    String? content,
    DateTime? createdAt,
    int? agentEntryId,
  }) => NewsArticle(
        id: id ?? this.id,
        chatRoomId: chatRoomId ?? this.chatRoomId,
        topic: topic ?? this.topic,
        tone: tone ?? this.tone,
        author: author ?? this.author,
        title: title ?? this.title,
        time: time ?? this.time,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
        agentEntryId: agentEntryId ?? this.agentEntryId,
      );
}
