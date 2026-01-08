class LorebookFolder {
  final int? id; // autoincrement primary key
  final int characterId; // foreign key to character
  String name;
  int order;
  bool isExpanded;
  List<Lorebook> lorebooks;

  LorebookFolder({
    this.id,
    required this.characterId,
    required this.name,
    required this.order,
    this.isExpanded = true,
    List<Lorebook>? lorebooks,
  }) : lorebooks = lorebooks ?? [];

  // DB에서 읽어올 때 사용
  factory LorebookFolder.fromMap(Map<String, dynamic> map) {
    return LorebookFolder(
      id: map['id'] as int?,
      characterId: map['character_id'] as int,
      name: map['name'] as String,
      order: map['order'] as int,
      isExpanded: (map['is_expanded'] as int?) == 1,
    );
  }

  // DB에 저장할 때 사용
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'character_id': characterId,
      'name': name,
      'order': order,
      'is_expanded': isExpanded ? 1 : 0,
    };
  }

  LorebookFolder copyWith({
    int? id,
    int? characterId,
    String? name,
    int? order,
    bool? isExpanded,
    List<Lorebook>? lorebooks,
  }) {
    return LorebookFolder(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      name: name ?? this.name,
      order: order ?? this.order,
      isExpanded: isExpanded ?? this.isExpanded,
      lorebooks: lorebooks ?? this.lorebooks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'characterId': characterId,
      'name': name,
      'order': order,
      'isExpanded': isExpanded,
      'lorebooks': lorebooks.map((e) => e.toJson()).toList(),
    };
  }

  factory LorebookFolder.fromJson(Map<String, dynamic> json) {
    return LorebookFolder(
      id: json['id'] as int?,
      characterId: json['characterId'] as int,
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
  final int? id; // autoincrement primary key
  final int characterId; // foreign key to character
  final int? folderId; // foreign key to folder (nullable - standalone lorebooks)
  String name;
  int order;
  bool isExpanded;
  LorebookActivationCondition activationCondition;
  List<String> activationKeys;
  LorebookKeyCondition keyCondition;
  int deploymentOrder;
  String? content;

  Lorebook({
    this.id,
    required this.characterId,
    this.folderId,
    required this.name,
    required this.order,
    this.isExpanded = false,
    this.activationCondition = LorebookActivationCondition.disabled,
    List<String>? activationKeys,
    this.keyCondition = LorebookKeyCondition.and,
    this.deploymentOrder = 0,
    this.content,
  }) : activationKeys = activationKeys ?? [];

  // DB에서 읽어올 때 사용
  factory Lorebook.fromMap(Map<String, dynamic> map) {
    return Lorebook(
      id: map['id'] as int?,
      characterId: map['character_id'] as int,
      folderId: map['folder_id'] as int?,
      name: map['name'] as String,
      order: map['order'] as int,
      isExpanded: (map['is_expanded'] as int?) == 1,
      activationCondition: LorebookActivationCondition.values.firstWhere(
        (e) => e.name == (map['activation_condition'] as String),
        orElse: () => LorebookActivationCondition.disabled,
      ),
      activationKeys: (map['activation_keys'] as String?)?.split(',') ?? [],
      keyCondition: LorebookKeyCondition.values.firstWhere(
        (e) => e.name == (map['key_condition'] as String),
        orElse: () => LorebookKeyCondition.and,
      ),
      deploymentOrder: map['deployment_order'] as int? ?? 0,
      content: map['content'] as String?,
    );
  }

  // DB에 저장할 때 사용
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'character_id': characterId,
      'folder_id': folderId,
      'name': name,
      'order': order,
      'is_expanded': isExpanded ? 1 : 0,
      'activation_condition': activationCondition.name,
      'activation_keys': activationKeys.join(','),
      'key_condition': keyCondition.name,
      'deployment_order': deploymentOrder,
      'content': content,
    };
  }

  Lorebook copyWith({
    int? id,
    int? characterId,
    int? folderId,
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
      characterId: characterId ?? this.characterId,
      folderId: folderId ?? this.folderId,
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
      'characterId': characterId,
      'folderId': folderId,
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
      id: json['id'] as int?,
      characterId: json['characterId'] as int,
      folderId: json['folderId'] as int?,
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
