class Character {
  final int? id; // autoincrement primary key
  final String name;
  final String? summary;
  final String? keywords;
  final String? worldSetting;
  final int? selectedCoverImageId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDraft; // 임시저장 여부

  Character({
    this.id,
    required this.name,
    this.summary,
    this.keywords,
    this.worldSetting,
    this.selectedCoverImageId,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isDraft = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // DB에서 읽어올 때 사용
  factory Character.fromMap(Map<String, dynamic> map) {
    return Character(
      id: map['id'] as int?,
      name: map['name'] as String,
      summary: map['summary'] as String?,
      keywords: map['keywords'] as String?,
      worldSetting: map['world_setting'] as String?,
      selectedCoverImageId: map['selected_cover_image_id'] != null
          ? int.tryParse(map['selected_cover_image_id'].toString())
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isDraft: (map['is_draft'] as int) == 1,
    );
  }

  // DB에 저장할 때 사용
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'summary': summary,
      'keywords': keywords,
      'world_setting': worldSetting,
      'selected_cover_image_id': selectedCoverImageId?.toString(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_draft': isDraft ? 1 : 0,
    };
  }

  // 업데이트용 copyWith
  Character copyWith({
    int? id,
    String? name,
    String? summary,
    String? keywords,
    String? worldSetting,
    int? selectedCoverImageId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDraft,
  }) {
    return Character(
      id: id ?? this.id,
      name: name ?? this.name,
      summary: summary ?? this.summary,
      keywords: keywords ?? this.keywords,
      worldSetting: worldSetting ?? this.worldSetting,
      selectedCoverImageId: selectedCoverImageId ?? this.selectedCoverImageId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDraft: isDraft ?? this.isDraft,
    );
  }
}
