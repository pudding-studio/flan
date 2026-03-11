import 'prompt_condition_option.dart';

enum ConditionType {
  toggle,
  singleSelect,
  variable;

  String get displayName {
    switch (this) {
      case ConditionType.toggle:
        return '토글';
      case ConditionType.singleSelect:
        return '하나만 선택';
      case ConditionType.variable:
        return '변수 치환';
    }
  }

  String get dbValue => name;

  static ConditionType fromDbValue(String value) =>
      ConditionType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => ConditionType.toggle,
      );
}

class PromptCondition {
  final int? id;
  final int? chatPromptId;
  final String name;
  final ConditionType type;
  final String? variableName;
  final int order;
  bool isExpanded;
  final List<PromptConditionOption> options;

  PromptCondition({
    this.id,
    this.chatPromptId,
    this.name = '',
    this.type = ConditionType.toggle,
    this.variableName,
    this.order = 0,
    this.isExpanded = false,
    List<PromptConditionOption>? options,
  }) : options = options ?? [];

  factory PromptCondition.fromMap(Map<String, dynamic> map) {
    return PromptCondition(
      id: map['id'] as int?,
      chatPromptId: map['chat_prompt_id'] as int?,
      name: map['name'] as String? ?? '',
      type: ConditionType.fromDbValue(map['type'] as String? ?? 'toggle'),
      variableName: map['variable_name'] as String?,
      order: map['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chat_prompt_id': chatPromptId,
      'name': name,
      'type': type.dbValue,
      'variable_name': variableName,
      'order': order,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatPromptId': chatPromptId,
      'name': name,
      'type': type.dbValue,
      'variableName': variableName,
      'order': order,
      'options': options.map((o) => o.toJson()).toList(),
    };
  }

  factory PromptCondition.fromJson(Map<String, dynamic> json) {
    return PromptCondition(
      id: json['id'] as int?,
      chatPromptId: json['chatPromptId'] as int?,
      name: json['name'] as String? ?? '',
      type: ConditionType.fromDbValue(json['type'] as String? ?? 'toggle'),
      variableName: json['variableName'] as String?,
      order: json['order'] as int? ?? 0,
      options: (json['options'] as List<dynamic>?)
              ?.map((o) => PromptConditionOption.fromJson(o as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  PromptCondition copyWith({
    int? id,
    int? chatPromptId,
    String? name,
    ConditionType? type,
    String? variableName,
    int? order,
    bool? isExpanded,
    List<PromptConditionOption>? options,
  }) {
    return PromptCondition(
      id: id ?? this.id,
      chatPromptId: chatPromptId ?? this.chatPromptId,
      name: name ?? this.name,
      type: type ?? this.type,
      variableName: variableName ?? this.variableName,
      order: order ?? this.order,
      isExpanded: isExpanded ?? this.isExpanded,
      options: options ?? List.from(this.options),
    );
  }
}
