class CoverImage {
  final String id;
  String name;
  int order;
  bool isExpanded;
  String? imagePath;

  CoverImage({
    required this.id,
    required this.name,
    required this.order,
    this.isExpanded = false,
    this.imagePath,
  });

  CoverImage copyWith({
    String? id,
    String? name,
    int? order,
    bool? isExpanded,
    String? imagePath,
  }) {
    return CoverImage(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
      isExpanded: isExpanded ?? this.isExpanded,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'order': order,
      'isExpanded': isExpanded,
      'imagePath': imagePath,
    };
  }

  factory CoverImage.fromJson(Map<String, dynamic> json) {
    return CoverImage(
      id: json['id'] as String,
      name: json['name'] as String,
      order: json['order'] as int,
      isExpanded: json['isExpanded'] as bool? ?? false,
      imagePath: json['imagePath'] as String?,
    );
  }
}
