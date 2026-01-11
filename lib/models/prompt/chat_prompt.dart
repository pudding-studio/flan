class ChatPrompt {
  final int? id;
  final String name;
  final String content;
  final bool isSelected;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatPrompt({
    this.id,
    required this.name,
    required this.content,
    this.isSelected = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory ChatPrompt.fromMap(Map<String, dynamic> map) {
    return ChatPrompt(
      id: map['id'] as int?,
      name: map['name'] as String,
      content: map['content'] as String,
      isSelected: (map['is_selected'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'content': content,
      'is_selected': isSelected ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ChatPrompt copyWith({
    int? id,
    String? name,
    String? content,
    bool? isSelected,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatPrompt(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
      isSelected: isSelected ?? this.isSelected,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
