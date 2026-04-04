class CommunityComment {
  final int? id;
  final int postId;
  final String author;
  final DateTime time;
  final String content;

  CommunityComment({
    this.id,
    required this.postId,
    required this.author,
    required this.time,
    required this.content,
  });

  factory CommunityComment.fromMap(Map<String, dynamic> map) => CommunityComment(
        id: map['id'] as int?,
        postId: map['post_id'] as int,
        author: map['author'] as String,
        time: DateTime.parse(map['time'] as String),
        content: map['content'] as String,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'post_id': postId,
        'author': author,
        'time': time.toIso8601String(),
        'content': content,
      };
}
