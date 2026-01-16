import 'persona.dart';
import 'start_scenario.dart';
import 'lorebook_folder.dart';
import 'cover_image.dart';

class Character {
  final int? id;
  final String name;
  final String? summary;
  final String? keywords;
  final String? worldSetting;
  final int? selectedCoverImageId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDraft;
  final int? sortOrder;

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
    this.sortOrder,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

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
      sortOrder: map['sort_order'] as int?,
    );
  }

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
      'sort_order': sortOrder,
    };
  }

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
    int? sortOrder,
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
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson({
    List<Persona>? personas,
    List<StartScenario>? startScenarios,
    List<LorebookFolder>? lorebookFolders,
    List<Lorebook>? standaloneLorebooks,
    List<CoverImage>? coverImages,
  }) {
    return {
      'format': 'flan_v1',
      'name': name,
      'summary': summary,
      'keywords': keywords,
      'worldSetting': worldSetting,
      'selectedCoverImageId': selectedCoverImageId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDraft': isDraft,
      'sortOrder': sortOrder,
      'personas': personas?.map((p) => p.toJson()).toList(),
      'startScenarios': startScenarios?.map((s) => s.toJson()).toList(),
      'lorebookFolders': lorebookFolders?.map((f) => f.toJson()).toList(),
      'standaloneLorebooks': standaloneLorebooks?.map((l) => l.toJson()).toList(),
      'coverImages': coverImages?.map((c) => c.toJson()).toList(),
    };
  }

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      name: json['name'] as String,
      summary: json['summary'] as String?,
      keywords: json['keywords'] as String?,
      worldSetting: json['worldSetting'] as String?,
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
