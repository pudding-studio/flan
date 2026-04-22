enum PromptRole {
  system,
  user,
  assistant,
  chat;

  String get displayName {
    switch (this) {
      case PromptRole.system:
        return '시스템';
      case PromptRole.user:
        return '사용자';
      case PromptRole.assistant:
        return '캐릭터';
      case PromptRole.chat:
        return '채팅';
    }
  }
}

enum ChatSettingMode {
  basic,
  advanced;

  String get displayName {
    switch (this) {
      case ChatSettingMode.basic:
        return '기본';
      case ChatSettingMode.advanced:
        return '고급';
    }
  }
}

enum EnableMode {
  enabled,
  conditional,
  disabled;

  String get displayName {
    switch (this) {
      case EnableMode.enabled:
        return '활성화';
      case EnableMode.conditional:
        return '조건';
      case EnableMode.disabled:
        return '비활성화';
    }
  }
}

enum ChatRangeType {
  recent,
  middle,
  old;

  String get displayName {
    switch (this) {
      case ChatRangeType.recent:
        return '최근';
      case ChatRangeType.middle:
        return '중간';
      case ChatRangeType.old:
        return '오래된';
    }
  }
}

class PromptItem {
  final int? id;
  final int? chatPromptId;
  final int? folderId;
  final PromptRole role;
  final String content;
  final String? contentEnglish;
  final String? name;
  final int order;
  final bool enabled;
  bool isExpanded;

  // chat role settings
  final ChatSettingMode chatSettingMode;
  final int? includeStartPosition;
  final ChatRangeType chatRangeType;
  final int? recentChatCount;
  final int? chatStartPosition;
  final int? chatEndPosition;

  // Condition-based activation
  final EnableMode enableMode;
  final int? conditionId;
  final String? conditionValue;

  PromptItem({
    this.id,
    this.chatPromptId,
    this.folderId,
    required this.role,
    required this.content,
    this.contentEnglish,
    this.name,
    this.order = 0,
    this.enabled = true,
    this.isExpanded = false,
    this.chatSettingMode = ChatSettingMode.basic,
    this.includeStartPosition,
    this.chatRangeType = ChatRangeType.recent,
    this.recentChatCount,
    this.chatStartPosition,
    this.chatEndPosition,
    this.enableMode = EnableMode.enabled,
    this.conditionId,
    this.conditionValue,
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
      contentEnglish: map['content_english'] as String?,
      name: map['name'] as String?,
      order: map['order'] as int? ?? 0,
      enabled: (map['enabled'] as int? ?? 1) == 1,
      chatSettingMode: ChatSettingMode.values.firstWhere(
        (m) => m.name == (map['chat_setting_mode'] as String?),
        orElse: () => ChatSettingMode.basic,
      ),
      includeStartPosition: map['include_start_position'] as int?,
      chatRangeType: ChatRangeType.values.firstWhere(
        (t) => t.name == (map['chat_range_type'] as String?),
        orElse: () => ChatRangeType.recent,
      ),
      recentChatCount: map['recent_chat_count'] as int?,
      chatStartPosition: map['chat_start_position'] as int?,
      chatEndPosition: map['chat_end_position'] as int?,
      enableMode: EnableMode.values.firstWhere(
        (m) => m.name == (map['enable_mode'] as String?),
        orElse: () => (map['enabled'] as int? ?? 1) == 1
            ? EnableMode.enabled
            : EnableMode.disabled,
      ),
      conditionId: map['condition_id'] as int?,
      conditionValue: map['condition_value'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chat_prompt_id': chatPromptId,
      'folder_id': folderId,
      'role': role.name,
      'content': content,
      'content_english': contentEnglish,
      'name': name,
      'order': order,
      'enabled': enabled ? 1 : 0,
      'chat_setting_mode': chatSettingMode.name,
      'include_start_position': includeStartPosition,
      'chat_range_type': chatRangeType.name,
      'recent_chat_count': recentChatCount,
      'chat_start_position': chatStartPosition,
      'chat_end_position': chatEndPosition,
      'enable_mode': enableMode.name,
      'condition_id': conditionId,
      'condition_value': conditionValue,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatPromptId': chatPromptId,
      'folderId': folderId,
      'role': role.name,
      'content': content,
      'contentEnglish': contentEnglish,
      'name': name,
      'order': order,
      'enabled': enabled,
      'isExpanded': isExpanded,
      'chatSettingMode': chatSettingMode.name,
      'includeStartPosition': includeStartPosition,
      'chatRangeType': chatRangeType.name,
      'recentChatCount': recentChatCount,
      'chatStartPosition': chatStartPosition,
      'chatEndPosition': chatEndPosition,
      'enableMode': enableMode.name,
      'conditionId': conditionId,
      'conditionValue': conditionValue,
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
      contentEnglish: json['contentEnglish'] as String?,
      name: json['name'] as String?,
      order: json['order'] as int? ?? 0,
      enabled: json['enabled'] as bool? ?? true,
      isExpanded: json['isExpanded'] as bool? ?? false,
      chatSettingMode: ChatSettingMode.values.firstWhere(
        (m) => m.name == (json['chatSettingMode'] as String?),
        orElse: () => ChatSettingMode.basic,
      ),
      includeStartPosition: json['includeStartPosition'] as int?,
      chatRangeType: ChatRangeType.values.firstWhere(
        (t) => t.name == (json['chatRangeType'] as String?),
        orElse: () => ChatRangeType.recent,
      ),
      recentChatCount: json['recentChatCount'] as int?,
      chatStartPosition: json['chatStartPosition'] as int?,
      chatEndPosition: json['chatEndPosition'] as int?,
      enableMode: EnableMode.values.firstWhere(
        (m) => m.name == (json['enableMode'] as String?),
        orElse: () => (json['enabled'] as bool? ?? true)
            ? EnableMode.enabled
            : EnableMode.disabled,
      ),
      conditionId: json['conditionId'] as int?,
      conditionValue: json['conditionValue'] as String?,
    );
  }

  PromptItem copyWith({
    int? id,
    int? chatPromptId,
    int? folderId,
    PromptRole? role,
    String? content,
    String? contentEnglish,
    String? name,
    int? order,
    bool? enabled,
    bool? isExpanded,
    ChatSettingMode? chatSettingMode,
    int? includeStartPosition,
    ChatRangeType? chatRangeType,
    int? recentChatCount,
    int? chatStartPosition,
    int? chatEndPosition,
    EnableMode? enableMode,
    int? conditionId,
    String? conditionValue,
  }) {
    return PromptItem(
      id: id ?? this.id,
      chatPromptId: chatPromptId ?? this.chatPromptId,
      folderId: folderId ?? this.folderId,
      role: role ?? this.role,
      content: content ?? this.content,
      contentEnglish: contentEnglish ?? this.contentEnglish,
      name: name ?? this.name,
      order: order ?? this.order,
      enabled: enabled ?? this.enabled,
      isExpanded: isExpanded ?? this.isExpanded,
      chatSettingMode: chatSettingMode ?? this.chatSettingMode,
      includeStartPosition: includeStartPosition ?? this.includeStartPosition,
      chatRangeType: chatRangeType ?? this.chatRangeType,
      recentChatCount: recentChatCount ?? this.recentChatCount,
      chatStartPosition: chatStartPosition ?? this.chatStartPosition,
      chatEndPosition: chatEndPosition ?? this.chatEndPosition,
      enableMode: enableMode ?? this.enableMode,
      conditionId: conditionId ?? this.conditionId,
      conditionValue: conditionValue ?? this.conditionValue,
    );
  }

  PromptItem copyWithNullableCondition({
    EnableMode? enableMode,
    required int? conditionId,
    required String? conditionValue,
  }) {
    return PromptItem(
      id: id,
      chatPromptId: chatPromptId,
      folderId: folderId,
      role: role,
      content: content,
      contentEnglish: contentEnglish,
      name: name,
      order: order,
      enabled: enabled,
      isExpanded: isExpanded,
      chatSettingMode: chatSettingMode,
      includeStartPosition: includeStartPosition,
      chatRangeType: chatRangeType,
      recentChatCount: recentChatCount,
      chatStartPosition: chatStartPosition,
      chatEndPosition: chatEndPosition,
      enableMode: enableMode ?? this.enableMode,
      conditionId: conditionId,
      conditionValue: conditionValue,
    );
  }

  PromptItem copyWithNullableFolderId({
    int? id,
    int? chatPromptId,
    required int? folderId,
    PromptRole? role,
    String? content,
    String? contentEnglish,
    String? name,
    int? order,
    bool? enabled,
    bool? isExpanded,
    ChatSettingMode? chatSettingMode,
    int? includeStartPosition,
    ChatRangeType? chatRangeType,
    int? recentChatCount,
    int? chatStartPosition,
    int? chatEndPosition,
    EnableMode? enableMode,
    int? conditionId,
    String? conditionValue,
  }) {
    return PromptItem(
      id: id ?? this.id,
      chatPromptId: chatPromptId ?? this.chatPromptId,
      folderId: folderId,
      role: role ?? this.role,
      content: content ?? this.content,
      contentEnglish: contentEnglish ?? this.contentEnglish,
      name: name ?? this.name,
      order: order ?? this.order,
      enabled: enabled ?? this.enabled,
      isExpanded: isExpanded ?? this.isExpanded,
      chatSettingMode: chatSettingMode ?? this.chatSettingMode,
      includeStartPosition: includeStartPosition ?? this.includeStartPosition,
      chatRangeType: chatRangeType ?? this.chatRangeType,
      recentChatCount: recentChatCount ?? this.recentChatCount,
      chatStartPosition: chatStartPosition ?? this.chatStartPosition,
      chatEndPosition: chatEndPosition ?? this.chatEndPosition,
      enableMode: enableMode ?? this.enableMode,
      conditionId: conditionId ?? this.conditionId,
      conditionValue: conditionValue ?? this.conditionValue,
    );
  }
}
