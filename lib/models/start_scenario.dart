class StartScenario {
  final String id;
  String name;
  int order;
  bool isExpanded;
  String? content;

  StartScenario({
    required this.id,
    required this.name,
    required this.order,
    this.isExpanded = false,
    this.content,
  });

  StartScenario copyWith({
    String? id,
    String? name,
    int? order,
    bool? isExpanded,
    String? content,
  }) {
    return StartScenario(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
      isExpanded: isExpanded ?? this.isExpanded,
      content: content ?? this.content,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'order': order,
      'isExpanded': isExpanded,
      'content': content,
    };
  }

  factory StartScenario.fromJson(Map<String, dynamic> json) {
    return StartScenario(
      id: json['id'] as String,
      name: json['name'] as String,
      order: json['order'] as int,
      isExpanded: json['isExpanded'] as bool? ?? false,
      content: json['content'] as String?,
    );
  }
}
