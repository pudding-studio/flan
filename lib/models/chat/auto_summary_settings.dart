class AutoSummarySettings {
  final int? id;
  final int chatRoomId;
  final bool isEnabled;
  final bool isAgentEnabled;
  final bool useSubModel;
  final String summaryModel;
  final int tokenThreshold;
  final String summaryPrompt;
  final String? parameters;
  final String? summaryPromptItems;
  final DateTime createdAt;
  final DateTime updatedAt;

  AutoSummarySettings({
    this.id,
    required this.chatRoomId,
    this.isEnabled = true,
    this.isAgentEnabled = false,
    this.useSubModel = false,
    this.summaryModel = 'geminiFlash3Preview',
    this.tokenThreshold = 5000,
    this.summaryPrompt = 'Please summarize the following conversation concisely.',
    this.parameters,
    this.summaryPromptItems,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory AutoSummarySettings.fromMap(Map<String, dynamic> map) {
    return AutoSummarySettings(
      id: map['id'] as int?,
      chatRoomId: map['chat_room_id'] as int,
      isEnabled: (map['is_enabled'] as int? ?? 1) == 1,
      isAgentEnabled: (map['is_agent_enabled'] as int? ?? 0) == 1,
      useSubModel: (map['use_sub_model'] as int? ?? 0) == 1,
      summaryModel: map['summary_model'] as String? ?? 'geminiFlash3Preview',
      tokenThreshold: map['token_threshold'] as int? ?? 5000,
      summaryPrompt: map['summary_prompt'] as String? ??
          'Please summarize the following conversation concisely.',
      parameters: map['parameters'] as String?,
      summaryPromptItems: map['summary_prompt_items'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chat_room_id': chatRoomId,
      'is_enabled': isEnabled ? 1 : 0,
      'is_agent_enabled': isAgentEnabled ? 1 : 0,
      'use_sub_model': useSubModel ? 1 : 0,
      'summary_model': summaryModel,
      'token_threshold': tokenThreshold,
      'summary_prompt': summaryPrompt,
      'parameters': parameters,
      'summary_prompt_items': summaryPromptItems,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  AutoSummarySettings copyWith({
    int? id,
    int? chatRoomId,
    bool? isEnabled,
    bool? isAgentEnabled,
    bool? useSubModel,
    String? summaryModel,
    int? tokenThreshold,
    String? summaryPrompt,
    String? parameters,
    String? summaryPromptItems,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AutoSummarySettings(
      id: id ?? this.id,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      isEnabled: isEnabled ?? this.isEnabled,
      isAgentEnabled: isAgentEnabled ?? this.isAgentEnabled,
      useSubModel: useSubModel ?? this.useSubModel,
      summaryModel: summaryModel ?? this.summaryModel,
      tokenThreshold: tokenThreshold ?? this.tokenThreshold,
      summaryPrompt: summaryPrompt ?? this.summaryPrompt,
      parameters: parameters ?? this.parameters,
      summaryPromptItems: summaryPromptItems ?? this.summaryPromptItems,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
