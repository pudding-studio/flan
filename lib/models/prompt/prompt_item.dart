enum PromptRole {
  system,
  user,
  assistant;

  String get displayName {
    switch (this) {
      case PromptRole.system:
        return '시스템';
      case PromptRole.user:
        return '사용자';
      case PromptRole.assistant:
        return '캐릭터';
    }
  }
}

class PromptItem {
  final int? id;
  final int? chatPromptId;
  final PromptRole role;
  final String content;
  final int order;
  bool isExpanded;

  PromptItem({
    this.id,
    this.chatPromptId,
    required this.role,
    required this.content,
    this.order = 0,
    this.isExpanded = false,
  });

  factory PromptItem.fromMap(Map<String, dynamic> map) {
    return PromptItem(
      id: map['id'] as int?,
      chatPromptId: map['chat_prompt_id'] as int?,
      role: PromptRole.values.firstWhere(
        (r) => r.name == (map['role'] as String? ?? 'system'),
        orElse: () => PromptRole.system,
      ),
      content: map['content'] as String,
      order: map['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chat_prompt_id': chatPromptId,
      'role': role.name,
      'content': content,
      'order': order,
    };
  }

  PromptItem copyWith({
    int? id,
    int? chatPromptId,
    PromptRole? role,
    String? content,
    int? order,
    bool? isExpanded,
  }) {
    return PromptItem(
      id: id ?? this.id,
      chatPromptId: chatPromptId ?? this.chatPromptId,
      role: role ?? this.role,
      content: content ?? this.content,
      order: order ?? this.order,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }
}
