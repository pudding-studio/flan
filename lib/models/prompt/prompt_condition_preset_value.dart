class PromptConditionPresetValue {
  final int? id;
  final int? presetId;
  final int? conditionId;
  final String value;
  final String? customValue;

  static const String customOptionKey = '__custom__';

  PromptConditionPresetValue({
    this.id,
    this.presetId,
    this.conditionId,
    this.value = '',
    this.customValue,
  });

  factory PromptConditionPresetValue.fromMap(Map<String, dynamic> map) {
    return PromptConditionPresetValue(
      id: map['id'] as int?,
      presetId: map['preset_id'] as int?,
      conditionId: map['condition_id'] as int?,
      value: map['value'] as String? ?? '',
      customValue: map['custom_value'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'preset_id': presetId,
      'condition_id': conditionId,
      'value': value,
      'custom_value': customValue,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'presetId': presetId,
      'conditionId': conditionId,
      'value': value,
      'customValue': customValue,
    };
  }

  factory PromptConditionPresetValue.fromJson(Map<String, dynamic> json) {
    return PromptConditionPresetValue(
      id: json['id'] as int?,
      presetId: json['presetId'] as int?,
      conditionId: json['conditionId'] as int?,
      value: json['value'] as String? ?? '',
      customValue: json['customValue'] as String?,
    );
  }

  PromptConditionPresetValue copyWith({
    int? id,
    int? presetId,
    int? conditionId,
    String? value,
    String? customValue,
  }) {
    return PromptConditionPresetValue(
      id: id ?? this.id,
      presetId: presetId ?? this.presetId,
      conditionId: conditionId ?? this.conditionId,
      value: value ?? this.value,
      customValue: customValue ?? this.customValue,
    );
  }

  PromptConditionPresetValue copyWithNullableCustomValue({
    int? id,
    int? presetId,
    int? conditionId,
    String? value,
    required String? customValue,
  }) {
    return PromptConditionPresetValue(
      id: id ?? this.id,
      presetId: presetId ?? this.presetId,
      conditionId: conditionId ?? this.conditionId,
      value: value ?? this.value,
      customValue: customValue,
    );
  }
}
