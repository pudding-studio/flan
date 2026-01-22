class CharacterBookFolder {
  final int? id; // autoincrement primary key
  final int characterId; // foreign key to character
  String name;
  int order;
  bool isExpanded;
  List<CharacterBook> characterBooks;

  CharacterBookFolder({
    this.id,
    required this.characterId,
    required this.name,
    required this.order,
    this.isExpanded = true,
    List<CharacterBook>? characterBooks,
  }) : characterBooks = characterBooks ?? [];

  // DB에서 읽어올 때 사용
  factory CharacterBookFolder.fromMap(Map<String, dynamic> map) {
    return CharacterBookFolder(
      id: map['id'] as int?,
      characterId: map['character_id'] as int,
      name: map['name'] as String,
      order: map['order'] as int,
      isExpanded: (map['is_expanded'] as int?) == 1,
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
    };
  }

  CharacterBookFolder copyWith({
    int? id,
    int? characterId,
    String? name,
    int? order,
    bool? isExpanded,
    List<CharacterBook>? characterBooks,
  }) {
    return CharacterBookFolder(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      name: name ?? this.name,
      order: order ?? this.order,
      isExpanded: isExpanded ?? this.isExpanded,
      characterBooks: characterBooks ?? this.characterBooks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'characterId': characterId,
      'name': name,
      'order': order,
      'isExpanded': isExpanded,
      'characterBooks': characterBooks.map((e) => e.toJson()).toList(),
    };
  }

  factory CharacterBookFolder.fromJson(Map<String, dynamic> json) {
    return CharacterBookFolder(
      id: json['id'] as int?,
      characterId: json['characterId'] as int,
      name: json['name'] as String,
      order: json['order'] as int,
      isExpanded: json['isExpanded'] as bool? ?? true,
      characterBooks: (json['characterBooks'] as List<dynamic>?)
              ?.map((e) => CharacterBook.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

enum CharacterBookActivationCondition {
  disabled,
  keyBased,
  enabled;

  String get displayName {
    switch (this) {
      case CharacterBookActivationCondition.disabled:
        return '비활성화';
      case CharacterBookActivationCondition.keyBased:
        return '키 사용';
      case CharacterBookActivationCondition.enabled:
        return '활성화';
    }
  }
}

enum CharacterBookKeyCondition {
  and,
  or;

  String get displayName {
    switch (this) {
      case CharacterBookKeyCondition.and:
        return 'AND';
      case CharacterBookKeyCondition.or:
        return 'OR';
    }
  }
}

class CharacterBook {
  final int? id; // autoincrement primary key
  final int characterId; // foreign key to character
  final int? folderId; // foreign key to folder (nullable - standalone characterBooks)
  String name;
  int order;
  bool isExpanded;
  CharacterBookActivationCondition enabled;
  List<String> keys;
  CharacterBookKeyCondition keyCondition;
  int insertionOrder;
  String? content;

  CharacterBook({
    this.id,
    required this.characterId,
    this.folderId,
    required this.name,
    required this.order,
    this.isExpanded = false,
    this.enabled = CharacterBookActivationCondition.disabled,
    List<String>? keys,
    this.keyCondition = CharacterBookKeyCondition.and,
    this.insertionOrder = 0,
    this.content,
  }) : keys = keys ?? [];

  // DB에서 읽어올 때 사용
  factory CharacterBook.fromMap(Map<String, dynamic> map) {
    return CharacterBook(
      id: map['id'] as int?,
      characterId: map['character_id'] as int,
      folderId: map['folder_id'] as int?,
      name: map['name'] as String,
      order: map['order'] as int,
      isExpanded: (map['is_expanded'] as int?) == 1,
      enabled: CharacterBookActivationCondition.values.firstWhere(
        (e) => e.name == (map['enabled'] as String),
        orElse: () => CharacterBookActivationCondition.disabled,
      ),
      keys: (map['keys'] as String?)?.split(',') ?? [],
      keyCondition: CharacterBookKeyCondition.values.firstWhere(
        (e) => e.name == (map['key_condition'] as String),
        orElse: () => CharacterBookKeyCondition.and,
      ),
      insertionOrder: map['insertionOrder'] as int? ?? 0,
      content: map['content'] as String?,
    );
  }

  // DB에 저장할 때 사용
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'character_id': characterId,
      'folder_id': folderId,
      'name': name,
      'order': order,
      'is_expanded': isExpanded ? 1 : 0,
      'enabled': enabled.name,
      'keys': keys.join(','),
      'key_condition': keyCondition.name,
      'insertionOrder': insertionOrder,
      'content': content,
    };
  }

  CharacterBook copyWith({
    int? id,
    int? characterId,
    int? folderId,
    String? name,
    int? order,
    bool? isExpanded,
    CharacterBookActivationCondition? enabled,
    List<String>? keys,
    CharacterBookKeyCondition? keyCondition,
    int? insertionOrder,
    String? content,
  }) {
    return CharacterBook(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      folderId: folderId ?? this.folderId,
      name: name ?? this.name,
      order: order ?? this.order,
      isExpanded: isExpanded ?? this.isExpanded,
      enabled: enabled ?? this.enabled,
      keys: keys ?? this.keys,
      keyCondition: keyCondition ?? this.keyCondition,
      insertionOrder: insertionOrder ?? this.insertionOrder,
      content: content ?? this.content,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'characterId': characterId,
      'folderId': folderId,
      'name': name,
      'order': order,
      'isExpanded': isExpanded,
      'enabled': enabled.name,
      'keys': keys,
      'keyCondition': keyCondition.name,
      'insertionOrder': insertionOrder,
      'content': content,
    };
  }

  factory CharacterBook.fromJson(Map<String, dynamic> json) {
    return CharacterBook(
      id: json['id'] as int?,
      characterId: json['characterId'] as int,
      folderId: json['folderId'] as int?,
      name: json['name'] as String,
      order: json['order'] as int,
      isExpanded: json['isExpanded'] as bool? ?? false,
      enabled: CharacterBookActivationCondition.values.firstWhere(
        (e) => e.name == json['enabled'],
        orElse: () => CharacterBookActivationCondition.disabled,
      ),
      keys: (json['keys'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      keyCondition: CharacterBookKeyCondition.values.firstWhere(
        (e) => e.name == json['keyCondition'],
        orElse: () => CharacterBookKeyCondition.and,
      ),
      insertionOrder: json['insertionOrder'] as int? ?? 0,
      content: json['content'] as String?,
    );
  }
}
