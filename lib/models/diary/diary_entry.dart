class DiaryEntry {
  final int? id;
  final int chatRoomId;
  final String author;
  final String title;
  final String content;
  final String date; // YYYY.MM.DD format (in-chat date)
  final DateTime createdAt;

  DiaryEntry({
    this.id,
    required this.chatRoomId,
    required this.author,
    required this.title,
    required this.content,
    required this.date,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory DiaryEntry.fromMap(Map<String, dynamic> map) => DiaryEntry(
        id: map['id'] as int?,
        chatRoomId: map['chat_room_id'] as int,
        author: map['author'] as String,
        title: map['title'] as String,
        content: map['content'] as String,
        date: map['date'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'chat_room_id': chatRoomId,
        'author': author,
        'title': title,
        'content': content,
        'date': date,
        'created_at': createdAt.toIso8601String(),
      };

  DiaryEntry copyWith({
    int? id,
    int? chatRoomId,
    String? author,
    String? title,
    String? content,
    String? date,
    DateTime? createdAt,
  }) => DiaryEntry(
        id: id ?? this.id,
        chatRoomId: chatRoomId ?? this.chatRoomId,
        author: author ?? this.author,
        title: title ?? this.title,
        content: content ?? this.content,
        date: date ?? this.date,
        createdAt: createdAt ?? this.createdAt,
      );
}
