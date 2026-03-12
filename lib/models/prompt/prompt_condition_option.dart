class PromptConditionOption {
  final int? id;
  final int? conditionId;
  final String name;
  final int order;

  PromptConditionOption({
    this.id,
    this.conditionId,
    required this.name,
    this.order = 0,
  });

  factory PromptConditionOption.fromMap(Map<String, dynamic> map) {
    return PromptConditionOption(
      id: map['id'] as int?,
      conditionId: map['condition_id'] as int?,
      name: map['name'] as String? ?? '',
      order: map['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'condition_id': conditionId,
      'name': name,
      'order': order,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conditionId': conditionId,
      'name': name,
      'order': order,
    };
  }

  factory PromptConditionOption.fromJson(Map<String, dynamic> json) {
    return PromptConditionOption(
      id: json['id'] as int?,
      conditionId: json['conditionId'] as int?,
      name: json['name'] as String? ?? '',
      order: json['order'] as int? ?? 0,
    );
  }

  PromptConditionOption copyWith({
    int? id,
    int? conditionId,
    String? name,
    int? order,
  }) {
    return PromptConditionOption(
      id: id ?? this.id,
      conditionId: conditionId ?? this.conditionId,
      name: name ?? this.name,
      order: order ?? this.order,
    );
  }
}
