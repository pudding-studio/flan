class StartScenario {
  final int? id; // autoincrement primary key
  final int characterId; // foreign key to character
  String name;
  int order;
  bool isExpanded;
  String? startSetting;
  String? startMessage;

  StartScenario({
    this.id,
    required this.characterId,
    required this.name,
    required this.order,
    this.isExpanded = false,
    this.startSetting,
    this.startMessage,
  });

  // DB에서 읽어올 때 사용
  factory StartScenario.fromMap(Map<String, dynamic> map) {
    return StartScenario(
      id: map['id'] as int?,
      characterId: map['character_id'] as int,
      name: map['name'] as String,
      order: map['order'] as int,
      isExpanded: (map['is_expanded'] as int?) == 1,
      startSetting: map['start_setting'] as String?,
      startMessage: map['start_message'] as String?,
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
      'start_setting': startSetting,
      'start_message': startMessage,
    };
  }

  StartScenario copyWith({
    int? id,
    int? characterId,
    String? name,
    int? order,
    bool? isExpanded,
    String? startSetting,
    String? startMessage,
  }) {
    return StartScenario(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      name: name ?? this.name,
      order: order ?? this.order,
      isExpanded: isExpanded ?? this.isExpanded,
      startSetting: startSetting ?? this.startSetting,
      startMessage: startMessage ?? this.startMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'characterId': characterId,
      'name': name,
      'order': order,
      'isExpanded': isExpanded,
      'startSetting': startSetting,
      'startMessage': startMessage,
    };
  }

  factory StartScenario.fromJson(Map<String, dynamic> json) {
    return StartScenario(
      id: json['id'] as int?,
      characterId: json['characterId'] as int,
      name: json['name'] as String,
      order: json['order'] as int,
      isExpanded: json['isExpanded'] as bool? ?? false,
      startSetting: json['startSetting'] as String?,
      startMessage: json['startMessage'] as String?,
    );
  }
}
