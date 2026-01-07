class StartScenario {
  final String id;
  String name;
  int order;
  bool isExpanded;
  String? startSetting;
  String? startMessage;

  StartScenario({
    required this.id,
    required this.name,
    required this.order,
    this.isExpanded = false,
    this.startSetting,
    this.startMessage,
  });

  StartScenario copyWith({
    String? id,
    String? name,
    int? order,
    bool? isExpanded,
    String? startSetting,
    String? startMessage,
  }) {
    return StartScenario(
      id: id ?? this.id,
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
      'name': name,
      'order': order,
      'isExpanded': isExpanded,
      'startSetting': startSetting,
      'startMessage': startMessage,
    };
  }

  factory StartScenario.fromJson(Map<String, dynamic> json) {
    return StartScenario(
      id: json['id'] as String,
      name: json['name'] as String,
      order: json['order'] as int,
      isExpanded: json['isExpanded'] as bool? ?? false,
      startSetting: json['startSetting'] as String?,
      startMessage: json['startMessage'] as String?,
    );
  }
}
