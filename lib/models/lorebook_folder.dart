class LorebookFolder {
  final String id;
  String name;
  int order;
  bool isExpanded;
  List<Lorebook> lorebooks;

  LorebookFolder({
    required this.id,
    required this.name,
    required this.order,
    this.isExpanded = true,
    List<Lorebook>? lorebooks,
  }) : lorebooks = lorebooks ?? [];

  LorebookFolder copyWith({
    String? id,
    String? name,
    int? order,
    bool? isExpanded,
    List<Lorebook>? lorebooks,
  }) {
    return LorebookFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
      isExpanded: isExpanded ?? this.isExpanded,
      lorebooks: lorebooks ?? this.lorebooks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'order': order,
      'isExpanded': isExpanded,
      'lorebooks': lorebooks.map((e) => e.toJson()).toList(),
    };
  }

  factory LorebookFolder.fromJson(Map<String, dynamic> json) {
    return LorebookFolder(
      id: json['id'] as String,
      name: json['name'] as String,
      order: json['order'] as int,
      isExpanded: json['isExpanded'] as bool? ?? true,
      lorebooks: (json['lorebooks'] as List<dynamic>?)
              ?.map((e) => Lorebook.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

enum LorebookActivationCondition {
  disabled,
  keyBased,
  enabled;

  String get displayName {
    switch (this) {
      case LorebookActivationCondition.disabled:
        return '비활성화';
      case LorebookActivationCondition.keyBased:
        return '키 사용';
      case LorebookActivationCondition.enabled:
        return '활성화';
    }
  }
}

enum LorebookKeyCondition {
  and,
  or;

  String get displayName {
    switch (this) {
      case LorebookKeyCondition.and:
        return 'AND';
      case LorebookKeyCondition.or:
        return 'OR';
    }
  }
}

class Lorebook {
  final String id;
  String name;
  int order;
  bool isExpanded;
  LorebookActivationCondition activationCondition;
  List<String> activationKeys;
  LorebookKeyCondition keyCondition;
  int deploymentOrder;
  String? content;

  Lorebook({
    required this.id,
    required this.name,
    required this.order,
    this.isExpanded = false,
    this.activationCondition = LorebookActivationCondition.disabled,
    List<String>? activationKeys,
    this.keyCondition = LorebookKeyCondition.and,
    this.deploymentOrder = 0,
    this.content,
  }) : activationKeys = activationKeys ?? [];

  Lorebook copyWith({
    String? id,
    String? name,
    int? order,
    bool? isExpanded,
    LorebookActivationCondition? activationCondition,
    List<String>? activationKeys,
    LorebookKeyCondition? keyCondition,
    int? deploymentOrder,
    String? content,
  }) {
    return Lorebook(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
      isExpanded: isExpanded ?? this.isExpanded,
      activationCondition: activationCondition ?? this.activationCondition,
      activationKeys: activationKeys ?? this.activationKeys,
      keyCondition: keyCondition ?? this.keyCondition,
      deploymentOrder: deploymentOrder ?? this.deploymentOrder,
      content: content ?? this.content,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'order': order,
      'isExpanded': isExpanded,
      'activationCondition': activationCondition.name,
      'activationKeys': activationKeys,
      'keyCondition': keyCondition.name,
      'deploymentOrder': deploymentOrder,
      'content': content,
    };
  }

  factory Lorebook.fromJson(Map<String, dynamic> json) {
    return Lorebook(
      id: json['id'] as String,
      name: json['name'] as String,
      order: json['order'] as int,
      isExpanded: json['isExpanded'] as bool? ?? false,
      activationCondition: LorebookActivationCondition.values.firstWhere(
        (e) => e.name == json['activationCondition'],
        orElse: () => LorebookActivationCondition.disabled,
      ),
      activationKeys: (json['activationKeys'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      keyCondition: LorebookKeyCondition.values.firstWhere(
        (e) => e.name == json['keyCondition'],
        orElse: () => LorebookKeyCondition.and,
      ),
      deploymentOrder: json['deploymentOrder'] as int? ?? 0,
      content: json['content'] as String?,
    );
  }
}
