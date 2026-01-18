import 'dart:typed_data';

class CoverImage {
  final int? id; // autoincrement primary key
  final int characterId; // foreign key to character
  String name;
  int order;
  bool isExpanded;
  Uint8List? imageData; // webp 512x512 바이너리 데이터

  CoverImage({
    this.id,
    required this.characterId,
    required this.name,
    required this.order,
    this.isExpanded = false,
    this.imageData,
  });

  // DB에서 읽어올 때 사용
  factory CoverImage.fromMap(Map<String, dynamic> map) {
    return CoverImage(
      id: map['id'] as int?,
      characterId: map['character_id'] as int,
      name: map['name'] as String,
      order: map['order'] as int,
      isExpanded: (map['is_expanded'] as int?) == 1,
      imageData: map['image_data'] as Uint8List?,
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
      'image_data': imageData,
    };
  }

  CoverImage copyWith({
    int? id,
    int? characterId,
    String? name,
    int? order,
    bool? isExpanded,
    Uint8List? imageData,
  }) {
    return CoverImage(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      name: name ?? this.name,
      order: order ?? this.order,
      isExpanded: isExpanded ?? this.isExpanded,
      imageData: imageData ?? this.imageData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'characterId': characterId,
      'name': name,
      'order': order,
      'isExpanded': isExpanded,
      'imageData': imageData?.toList(),
    };
  }

  factory CoverImage.fromJson(Map<String, dynamic> json) {
    final imageDataList = json['imageData'] as List<dynamic>?;
    return CoverImage(
      id: json['id'] as int?,
      characterId: json['characterId'] as int,
      name: json['name'] as String,
      order: json['order'] as int,
      isExpanded: json['isExpanded'] as bool? ?? false,
      imageData: imageDataList != null ? Uint8List.fromList(imageDataList.cast<int>()) : null,
    );
  }
}
