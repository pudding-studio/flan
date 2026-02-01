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
  final int? folderId;
  final PromptRole role;
  final String content;
  final String? name;
  final int order;
  bool isExpanded;

  PromptItem({
    this.id,
    this.chatPromptId,
    this.folderId,
    required this.role,
    required this.content,
    this.name,
    this.order = 0,
    this.isExpanded = false,
  });

  factory PromptItem.fromMap(Map<String, dynamic> map) {
    return PromptItem(
      id: map['id'] as int?,
      chatPromptId: map['chat_prompt_id'] as int?,
      folderId: map['folder_id'] as int?,
      role: PromptRole.values.firstWhere(
        (r) => r.name == (map['role'] as String? ?? 'system'),
        orElse: () => PromptRole.system,
      ),
      content: map['content'] as String? ?? '',
      name: map['name'] as String?,
      order: map['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chat_prompt_id': chatPromptId,
      'folder_id': folderId,
      'role': role.name,
      'content': content,
      'name': name,
      'order': order,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatPromptId': chatPromptId,
      'folderId': folderId,
      'role': role.name,
      'content': content,
      'name': name,
      'order': order,
      'isExpanded': isExpanded,
    };
  }

  factory PromptItem.fromJson(Map<String, dynamic> json) {
    return PromptItem(
      id: json['id'] as int?,
      chatPromptId: json['chatPromptId'] as int?,
      folderId: json['folderId'] as int?,
      role: PromptRole.values.firstWhere(
        (r) => r.name == (json['role'] as String? ?? 'system'),
        orElse: () => PromptRole.system,
      ),
      content: json['content'] as String? ?? '',
      name: json['name'] as String?,
      order: json['order'] as int? ?? 0,
      isExpanded: json['isExpanded'] as bool? ?? false,
    );
  }

  PromptItem copyWith({
    int? id,
    int? chatPromptId,
    int? folderId,
    PromptRole? role,
    String? content,
    String? name,
    int? order,
    bool? isExpanded,
  }) {
    return PromptItem(
      id: id ?? this.id,
      chatPromptId: chatPromptId ?? this.chatPromptId,
      folderId: folderId ?? this.folderId,
      role: role ?? this.role,
      content: content ?? this.content,
      name: name ?? this.name,
      order: order ?? this.order,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }

  PromptItem copyWithNullableFolderId({
    int? id,
    int? chatPromptId,
    required int? folderId,
    PromptRole? role,
    String? content,
    String? name,
    int? order,
    bool? isExpanded,
  }) {
    return PromptItem(
      id: id ?? this.id,
      chatPromptId: chatPromptId ?? this.chatPromptId,
      folderId: folderId,
      role: role ?? this.role,
      content: content ?? this.content,
      name: name ?? this.name,
      order: order ?? this.order,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }
}
