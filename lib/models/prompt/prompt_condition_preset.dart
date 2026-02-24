import 'prompt_condition_preset_value.dart';

class PromptConditionPreset {
  final int? id;
  final int? chatPromptId;
  final String name;
  final bool isDefault;
  final int order;
  bool isExpanded;
  final List<PromptConditionPresetValue> values;

  PromptConditionPreset({
    this.id,
    this.chatPromptId,
    this.name = '기본',
    this.isDefault = false,
    this.order = 0,
    this.isExpanded = false,
    List<PromptConditionPresetValue>? values,
  }) : values = values ?? [];

  factory PromptConditionPreset.fromMap(Map<String, dynamic> map) {
    return PromptConditionPreset(
      id: map['id'] as int?,
      chatPromptId: map['chat_prompt_id'] as int?,
      name: map['name'] as String? ?? '기본',
      isDefault: (map['is_default'] as int?) == 1,
      order: map['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chat_prompt_id': chatPromptId,
      'name': name,
      'is_default': isDefault ? 1 : 0,
      'order': order,
    };
  }

  PromptConditionPreset copyWith({
    int? id,
    int? chatPromptId,
    String? name,
    bool? isDefault,
    int? order,
    bool? isExpanded,
    List<PromptConditionPresetValue>? values,
  }) {
    return PromptConditionPreset(
      id: id ?? this.id,
      chatPromptId: chatPromptId ?? this.chatPromptId,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      order: order ?? this.order,
      isExpanded: isExpanded ?? this.isExpanded,
      values: values ?? List.from(this.values),
    );
  }
}
