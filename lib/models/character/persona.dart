class Persona {
  final String id;
  String name;
  int order;
  bool isExpanded;
  String? content;

  Persona({
    required this.id,
    required this.name,
    required this.order,
    this.isExpanded = false,
    this.content,
  });

  Persona copyWith({
    String? id,
    String? name,
    int? order,
    bool? isExpanded,
    String? content,
  }) {
    return Persona(
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

  factory Persona.fromJson(Map<String, dynamic> json) {
    return Persona(
      id: json['id'] as String,
      name: json['name'] as String,
      order: json['order'] as int,
      isExpanded: json['isExpanded'] as bool? ?? false,
      content: json['content'] as String?,
    );
  }
}
