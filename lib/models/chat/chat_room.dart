class ChatRoom {
  final int? id;
  final int characterId;
  final String name;
  final int? selectedChatPromptId;
  final int? selectedPersonaId;
  final int? selectedStartScenarioId;
  final int? selectedConditionPresetId;
  final int totalTokenCount;
  final String memo;
  final String summary;
  final int? autoPinByMessageCount;
  final String? selectedModelId;
  final String modelPreset; // 'primary', 'secondary', 'custom'
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatRoom({
    this.id,
    required this.characterId,
    required this.name,
    this.selectedChatPromptId,
    this.selectedPersonaId,
    this.selectedStartScenarioId,
    this.selectedConditionPresetId,
    this.totalTokenCount = 0,
    this.memo = '',
    this.summary = '',
    this.autoPinByMessageCount,
    this.selectedModelId,
    this.modelPreset = 'primary',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      id: map['id'] as int?,
      characterId: map['character_id'] as int,
      name: map['name'] as String,
      selectedChatPromptId: map['selected_chat_prompt_id'] as int?,
      selectedPersonaId: map['selected_persona_id'] as int?,
      selectedStartScenarioId: map['selected_start_scenario_id'] as int?,
      selectedConditionPresetId: map['selected_condition_preset_id'] as int?,
      totalTokenCount: map['total_token_count'] as int? ?? 0,
      memo: map['memo'] as String? ?? '',
      summary: map['summary'] as String? ?? '',
      autoPinByMessageCount: map['auto_pin_by_message_count'] as int?,
      selectedModelId: map['selected_model_id'] as String?,
      modelPreset: map['model_preset'] as String? ?? 'primary',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'character_id': characterId,
      'name': name,
      'selected_chat_prompt_id': selectedChatPromptId,
      'selected_persona_id': selectedPersonaId,
      'selected_start_scenario_id': selectedStartScenarioId,
      'selected_condition_preset_id': selectedConditionPresetId,
      'total_token_count': totalTokenCount,
      'memo': memo,
      'summary': summary,
      'auto_pin_by_message_count': autoPinByMessageCount,
      'selected_model_id': selectedModelId,
      'model_preset': modelPreset,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ChatRoom copyWith({
    int? id,
    int? characterId,
    String? name,
    int? selectedChatPromptId,
    int? selectedPersonaId,
    int? selectedStartScenarioId,
    Object? selectedConditionPresetId = _sentinel,
    int? totalTokenCount,
    String? memo,
    String? summary,
    Object? autoPinByMessageCount = _sentinel,
    Object? selectedModelId = _sentinel,
    String? modelPreset,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      name: name ?? this.name,
      selectedChatPromptId: selectedChatPromptId ?? this.selectedChatPromptId,
      selectedPersonaId: selectedPersonaId ?? this.selectedPersonaId,
      selectedStartScenarioId: selectedStartScenarioId ?? this.selectedStartScenarioId,
      selectedConditionPresetId: selectedConditionPresetId == _sentinel
          ? this.selectedConditionPresetId
          : selectedConditionPresetId as int?,
      totalTokenCount: totalTokenCount ?? this.totalTokenCount,
      memo: memo ?? this.memo,
      summary: summary ?? this.summary,
      autoPinByMessageCount: autoPinByMessageCount == _sentinel
          ? this.autoPinByMessageCount
          : autoPinByMessageCount as int?,
      selectedModelId: selectedModelId == _sentinel
          ? this.selectedModelId
          : selectedModelId as String?,
      modelPreset: modelPreset ?? this.modelPreset,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static const _sentinel = Object();
}
