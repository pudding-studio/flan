import 'dart:convert';
import 'persona.dart';
import 'start_scenario.dart';
import 'character_book_folder.dart';
import 'cover_image.dart';

class Character {
  final int? id;
  final String name;
  final String? creatorNotes;
  final List<String> tags;
  final String? description;
  final int? selectedCoverImageId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDraft;
  final int? sortOrder;

  Character({
    this.id,
    required this.name,
    this.creatorNotes,
    List<String>? tags,
    this.description,
    this.selectedCoverImageId,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isDraft = false,
    this.sortOrder,
  })  : tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Character.fromMap(Map<String, dynamic> map) {
    List<String> parsedTags = [];
    if (map['tags'] != null) {
      final tagsData = map['tags'];
      if (tagsData is String && tagsData.isNotEmpty) {
        try {
          final decoded = json.decode(tagsData);
          if (decoded is List) {
            parsedTags = decoded.cast<String>();
          }
        } catch (e) {
          // JSON 파싱 실패 시 빈 배열 사용
          parsedTags = [];
        }
      }
    }

    return Character(
      id: map['id'] as int?,
      name: map['name'] as String,
      creatorNotes: map['creator_notes'] as String?,
      tags: parsedTags,
      description: map['description'] as String?,
      selectedCoverImageId: map['selected_cover_image_id'] != null
          ? int.tryParse(map['selected_cover_image_id'].toString())
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isDraft: (map['is_draft'] as int) == 1,
      sortOrder: map['sort_order'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'creator_notes': creatorNotes,
      'tags': json.encode(tags),
      'description': description,
      'selected_cover_image_id': selectedCoverImageId?.toString(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_draft': isDraft ? 1 : 0,
      'sort_order': sortOrder,
    };
  }

  Character copyWith({
    int? id,
    String? name,
    String? creatorNotes,
    List<String>? tags,
    String? description,
    int? selectedCoverImageId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDraft,
    int? sortOrder,
  }) {
    return Character(
      id: id ?? this.id,
      name: name ?? this.name,
      creatorNotes: creatorNotes ?? this.creatorNotes,
      tags: tags ?? this.tags,
      description: description ?? this.description,
      selectedCoverImageId: selectedCoverImageId ?? this.selectedCoverImageId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDraft: isDraft ?? this.isDraft,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson({
    List<Persona>? personas,
    List<StartScenario>? startScenarios,
    List<CharacterBookFolder>? characterBookFolders,
    List<CharacterBook>? standaloneCharacterBooks,
    List<CoverImage>? coverImages,
  }) {
    return {
      'format': 'flan_v1',
      'name': name,
      'creatorNotes': creatorNotes,
      'tags': tags,
      'description': description,
      'selectedCoverImageId': selectedCoverImageId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDraft': isDraft,
      'sortOrder': sortOrder,
      'personas': personas?.map((p) => p.toJson()).toList(),
      'startScenarios': startScenarios?.map((s) => s.toJson()).toList(),
      'characterBookFolders': characterBookFolders?.map((f) => f.toJson()).toList(),
      'standaloneCharacterBooks': standaloneCharacterBooks?.map((l) => l.toJson()).toList(),
      'coverImages': coverImages?.map((c) => c.toJson()).toList(),
    };
  }

  factory Character.fromJson(Map<String, dynamic> json) {
    List<String> parsedTags = [];
    if (json['tags'] != null) {
      parsedTags = (json['tags'] as List).cast<String>();
    }

    return Character(
      name: json['name'] as String,
      creatorNotes: json['creatorNotes'] as String?,
      tags: parsedTags,
      description: json['description'] as String?,
      selectedCoverImageId: json['selectedCoverImageId'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      isDraft: json['isDraft'] as bool? ?? false,
      sortOrder: json['sortOrder'] as int?,
    );
  }
}
