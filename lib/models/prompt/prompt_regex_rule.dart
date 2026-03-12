enum RegexTarget {
  disabled,
  inputModify,
  outputModify,
  sendDataModify,
  displayModify;

  String get displayName {
    switch (this) {
      case RegexTarget.disabled:
        return '비활성화';
      case RegexTarget.inputModify:
        return '입력문 수정';
      case RegexTarget.outputModify:
        return '출력문 수정';
      case RegexTarget.sendDataModify:
        return '전송데이터 수정';
      case RegexTarget.displayModify:
        return '출력화면 수정';
    }
  }

  String get dbValue => name;

  static RegexTarget fromDbValue(String value) {
    return RegexTarget.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RegexTarget.disabled,
    );
  }
}

class PromptRegexRule {
  final int? id;
  final int? chatPromptId;
  final String name;
  final RegexTarget target;
  final String pattern;
  final String replacement;
  final int order;
  bool isExpanded;

  PromptRegexRule({
    this.id,
    this.chatPromptId,
    this.name = '',
    this.target = RegexTarget.disabled,
    this.pattern = '',
    this.replacement = '',
    this.order = 0,
    this.isExpanded = false,
  });

  factory PromptRegexRule.fromMap(Map<String, dynamic> map) {
    return PromptRegexRule(
      id: map['id'] as int?,
      chatPromptId: map['chat_prompt_id'] as int?,
      name: map['name'] as String? ?? '',
      target: RegexTarget.fromDbValue(map['target'] as String? ?? 'disabled'),
      pattern: map['pattern'] as String? ?? '',
      replacement: map['replacement'] as String? ?? '',
      order: map['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chat_prompt_id': chatPromptId,
      'name': name,
      'target': target.dbValue,
      'pattern': pattern,
      'replacement': replacement,
      'order': order,
    };
  }

  factory PromptRegexRule.fromJson(Map<String, dynamic> json) {
    return PromptRegexRule(
      name: json['name'] as String? ?? '',
      target: RegexTarget.fromDbValue(json['target'] as String? ?? 'disabled'),
      pattern: json['pattern'] as String? ?? '',
      replacement: json['replacement'] as String? ?? '',
      order: json['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'target': target.dbValue,
      'pattern': pattern,
      'replacement': replacement,
      'order': order,
    };
  }

  PromptRegexRule copyWith({
    int? id,
    int? chatPromptId,
    String? name,
    RegexTarget? target,
    String? pattern,
    String? replacement,
    int? order,
    bool? isExpanded,
  }) {
    return PromptRegexRule(
      id: id ?? this.id,
      chatPromptId: chatPromptId ?? this.chatPromptId,
      name: name ?? this.name,
      target: target ?? this.target,
      pattern: pattern ?? this.pattern,
      replacement: replacement ?? this.replacement,
      order: order ?? this.order,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }
}
