class ChatRoom {
  final int? id;
  final int characterId;
  final String name;
  final int? selectedChatPromptId;
  final int? selectedPersonaId;
  final int? selectedStartScenarioId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatRoom({
    this.id,
    required this.characterId,
    required this.name,
    this.selectedChatPromptId,
    this.selectedPersonaId,
    this.selectedStartScenarioId,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
