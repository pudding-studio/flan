class CoverImage {
  final int? id; // autoincrement primary key
  final int characterId; // foreign key to character
  String name;
  int order;
  bool isExpanded;
  String? imagePath;

  CoverImage({
    this.id,
    required this.characterId,
    required this.name,
    required this.order,
    this.isExpanded = false,
    this.imagePath,
  });

  // DB에서 읽어올 때 사용
  factory CoverImage.fromMap(Map<String, dynamic> map) {
    return CoverImage(
      id: map['id'] as int?,
      characterId: map['character_id'] as int,
      name: map['name'] as String,
      order: map['order'] as int,
      isExpanded: (map['is_expanded'] as int?) == 1,
      imagePath: map['image_path'] as String?,
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
      'image_path': imagePath,
    };
  }

  CoverImage copyWith({
    int? id,
    int? characterId,
    String? name,
    int? order,
    bool? isExpanded,
    String? imagePath,
  }) {
    return CoverImage(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      name: name ?? this.name,
      order: order ?? this.order,
      isExpanded: isExpanded ?? this.isExpanded,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'characterId': characterId,
      'name': name,
      'order': order,
      'isExpanded': isExpanded,
      'imagePath': imagePath,
    };
  }

  factory CoverImage.fromJson(Map<String, dynamic> json) {
    return CoverImage(
      id: json['id'] as int?,
      characterId: json['characterId'] as int,
      name: json['name'] as String,
      order: json['order'] as int,
      isExpanded: json['isExpanded'] as bool? ?? false,
      imagePath: json['imagePath'] as String?,
    );
  }
}
