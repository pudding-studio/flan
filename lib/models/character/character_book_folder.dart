import 'dart:convert';

import 'cover_image.dart';

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

enum CharacterBookSecondaryKeyUsage {
  disabled,
  enabled;

  String get displayName {
    switch (this) {
      case CharacterBookSecondaryKeyUsage.disabled:
        return '불용';
      case CharacterBookSecondaryKeyUsage.enabled:
        return '사용';
    }
  }
}

/// 설정집 항목의 카테고리. 각 카테고리별로 노출되는 세부 필드가 달라진다.
/// - character: 등장인물 (외형·성별·나이·성격·과거·능력·대사스타일)
/// - location: 지역/장소 (설정)
/// - event: 역사/사건/업적 (일시·내용·결과)
/// - other: 기타 (설정). 폴더 구조와 배치순서는 기타에서만 사용.
enum CharacterBookCategory {
  character,
  location,
  event,
  other;

  String get displayName {
    switch (this) {
      case CharacterBookCategory.character:
        return '등장인물';
      case CharacterBookCategory.location:
        return '지역/장소';
      case CharacterBookCategory.event:
        return '역사/사건';
      case CharacterBookCategory.other:
        return '기타';
    }
  }

  /// {{character_book}} 프롬프트 묶음 헤더. displayName과 동일하지만
  /// 다국어화에 영향받지 않고 AI로 전달되어야 하는 고정 키.
  String get promptHeader {
    switch (this) {
      case CharacterBookCategory.character:
        return '등장인물';
      case CharacterBookCategory.location:
        return '지역/장소';
      case CharacterBookCategory.event:
        return '역사/사건';
      case CharacterBookCategory.other:
        return '기타';
    }
  }
}

/// 등장인물 성별 옵션. '기타'가 선택된 경우 자유 입력값(genderOther)이 사용된다.
enum CharacterBookGender {
  male,
  female,
  other;

  String get displayName {
    switch (this) {
      case CharacterBookGender.male:
        return '남성';
      case CharacterBookGender.female:
        return '여성';
      case CharacterBookGender.other:
        return '기타';
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
  CharacterBookSecondaryKeyUsage secondaryKeyUsage;
  List<String> secondaryKeys;
  int insertionOrder;
  String? content;

  /// 설정집 카테고리. 기본값은 `other`로, 기존 항목 마이그레이션 시에도 기타로 분류된다.
  CharacterBookCategory category;

  /// 한줄 설명. 값이 비어있지 않으면 `{{character_book}}`에 항상 포함된다.
  String oneLineDescription;

  /// true면 채팅 최초 메시지 진행 시 AgentEntry로 복사된다.
  bool autoSummaryInsert;

  /// 런타임 전용 필드: category == character 일 때만 의미 있음.
  /// DB에는 `cover_images` 테이블에 별도 행으로 저장되고, 편집 화면이
  /// 로드할 때 채워 넣는다. `toMap()`에는 포함되지 않는다.
  List<CoverImage> images;

  CharacterBook({
    this.id,
    required this.characterId,
    this.folderId,
    required this.name,
    required this.order,
    this.isExpanded = false,
    this.enabled = CharacterBookActivationCondition.disabled,
    List<String>? keys,
    this.secondaryKeyUsage = CharacterBookSecondaryKeyUsage.disabled,
    List<String>? secondaryKeys,
    this.insertionOrder = 0,
    this.content,
    this.category = CharacterBookCategory.other,
    this.oneLineDescription = '',
    this.autoSummaryInsert = true,
    List<CoverImage>? images,
  }) : keys = keys ?? [],
       secondaryKeys = secondaryKeys ?? [],
       images = images ?? [];

  // ==================== 구조화된 데이터 (content JSON) ====================

  /// content 필드를 JSON Map으로 파싱. 레거시 문자열이거나 파싱 실패 시
  /// 빈 Map을 반환한다. (레거시 평문은 [legacyPlainContent]로 별도 노출)
  Map<String, dynamic> get structuredData {
    final raw = content;
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (_) {
      return {};
    }
  }

  /// content가 유효한 JSON이 아닐 때(레거시 평문) 원문을 반환. 그 외에는 null.
  /// 마이그레이션 전 기존 기타 항목을 읽기 위한 호환성 호출.
  String? get legacyPlainContent {
    final raw = content;
    if (raw == null || raw.isEmpty) return null;
    try {
      jsonDecode(raw);
      return null;
    } catch (_) {
      return raw;
    }
  }

  /// [structuredData]의 특정 키 값을 안전하게 문자열로 추출.
  /// 레거시 평문 content가 other.setting으로 해석되어야 하는 경우도 처리.
  String getStructuredString(String key) {
    final data = structuredData;
    if (data.containsKey(key)) {
      final v = data[key];
      return v?.toString() ?? '';
    }
    // Fallback: legacy raw content maps to other-category 'setting' field.
    if (category == CharacterBookCategory.other && key == 'setting') {
      return legacyPlainContent ?? '';
    }
    return '';
  }

  /// 주어진 key-value 쌍을 [structuredData]에 저장하고 content를 재직렬화.
  /// 빈 문자열은 키 자체를 제거한다.
  void setStructuredString(String key, String value) {
    final data = Map<String, dynamic>.from(structuredData);
    // First migration of legacy plain text: preserve it as 'setting' so it
    // doesn't silently disappear when the user edits another field first.
    if (data.isEmpty && category == CharacterBookCategory.other) {
      final legacy = legacyPlainContent;
      if (legacy != null && legacy.isNotEmpty) {
        data['setting'] = legacy;
      }
    }
    if (value.isEmpty) {
      data.remove(key);
    } else {
      data[key] = value;
    }
    content = data.isEmpty ? null : jsonEncode(data);
  }

  // ---------- 등장인물 필드 접근자 ----------
  /// 이미지 태그 매칭에 사용되는 별칭 목록. 쉼표로 구분된 원문을 그대로
  /// 저장한다 (예: "Alice, alice, 앨리스"). `<img="{alias}_{imgName}">`
  /// 렌더링 시 name과 subNameList를 모두 후보 키로 사용한다.
  String get subNames => getStructuredString('sub_names');
  set subNames(String v) => setStructuredString('sub_names', v);

  /// [subNames]를 쉼표로 분리해 공백 제거한 리스트. 빈 항목은 제외.
  List<String> get subNameList => subNames
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  String get appearance => getStructuredString('appearance');
  set appearance(String v) => setStructuredString('appearance', v);

  /// 성별 enum. 저장되지 않았거나 유효하지 않으면 null.
  CharacterBookGender? get gender {
    final raw = getStructuredString('gender');
    if (raw.isEmpty) return null;
    return CharacterBookGender.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => CharacterBookGender.other,
    );
  }

  set gender(CharacterBookGender? v) =>
      setStructuredString('gender', v?.name ?? '');

  /// gender == other 일 때 사용되는 자유 입력값
  String get genderOther => getStructuredString('gender_other');
  set genderOther(String v) => setStructuredString('gender_other', v);

  String get age => getStructuredString('age');
  set age(String v) => setStructuredString('age', v);

  String get personality => getStructuredString('personality');
  set personality(String v) => setStructuredString('personality', v);

  String get past => getStructuredString('past');
  set past(String v) => setStructuredString('past', v);

  String get abilities => getStructuredString('abilities');
  set abilities(String v) => setStructuredString('abilities', v);

  String get dialogueStyle => getStructuredString('dialogue_style');
  set dialogueStyle(String v) => setStructuredString('dialogue_style', v);

  // ---------- 지역/장소 & 기타 ----------
  String get setting => getStructuredString('setting');
  set setting(String v) => setStructuredString('setting', v);

  // ---------- 사건/업적 ----------
  String get eventDatetime => getStructuredString('datetime');
  set eventDatetime(String v) => setStructuredString('datetime', v);

  String get eventContent => getStructuredString('event_content');
  set eventContent(String v) => setStructuredString('event_content', v);

  String get eventResult => getStructuredString('result');
  set eventResult(String v) => setStructuredString('result', v);

  // ==================== 직렬화 ====================

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
      keys: (map['keys'] as String?)?.split(',').where((e) => e.isNotEmpty).toList() ?? [],
      secondaryKeyUsage: CharacterBookSecondaryKeyUsage.values.firstWhere(
        (e) => e.name == (map['key_condition'] as String? ?? 'disabled'),
        orElse: () => CharacterBookSecondaryKeyUsage.disabled,
      ),
      secondaryKeys: (map['secondary_keys'] as String?)?.split(',').where((e) => e.isNotEmpty).toList() ?? [],
      insertionOrder: map['insertion_order'] as int? ?? 0,
      content: map['content'] as String?,
      category: CharacterBookCategory.values.firstWhere(
        (e) => e.name == (map['category'] as String? ?? 'other'),
        orElse: () => CharacterBookCategory.other,
      ),
      oneLineDescription: (map['one_line_description'] as String?) ?? '',
      autoSummaryInsert: (map['auto_summary_insert'] as int? ?? 1) == 1,
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
      'key_condition': secondaryKeyUsage.name,
      'secondary_keys': secondaryKeys.join(','),
      'insertion_order': insertionOrder,
      'content': content,
      'category': category.name,
      'one_line_description': oneLineDescription,
      'auto_summary_insert': autoSummaryInsert ? 1 : 0,
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
    CharacterBookSecondaryKeyUsage? secondaryKeyUsage,
    List<String>? secondaryKeys,
    int? insertionOrder,
    String? content,
    CharacterBookCategory? category,
    String? oneLineDescription,
    bool? autoSummaryInsert,
    List<CoverImage>? images,
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
      secondaryKeyUsage: secondaryKeyUsage ?? this.secondaryKeyUsage,
      secondaryKeys: secondaryKeys ?? this.secondaryKeys,
      insertionOrder: insertionOrder ?? this.insertionOrder,
      content: content ?? this.content,
      category: category ?? this.category,
      oneLineDescription: oneLineDescription ?? this.oneLineDescription,
      autoSummaryInsert: autoSummaryInsert ?? this.autoSummaryInsert,
      images: images ?? this.images,
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
      'secondaryKeyUsage': secondaryKeyUsage.name,
      'secondaryKeys': secondaryKeys,
      'insertionOrder': insertionOrder,
      'content': content,
      'category': category.name,
      'oneLineDescription': oneLineDescription,
      'autoSummaryInsert': autoSummaryInsert,
      'images': images.map((e) => e.toJson()).toList(),
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
      secondaryKeyUsage: CharacterBookSecondaryKeyUsage.values.firstWhere(
        (e) => e.name == (json['secondaryKeyUsage'] ?? json['keyCondition'] ?? 'disabled'),
        orElse: () => CharacterBookSecondaryKeyUsage.disabled,
      ),
      secondaryKeys: (json['secondaryKeys'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      insertionOrder: json['insertionOrder'] as int? ?? 0,
      content: json['content'] as String?,
      category: CharacterBookCategory.values.firstWhere(
        (e) => e.name == (json['category'] as String? ?? 'other'),
        orElse: () => CharacterBookCategory.other,
      ),
      oneLineDescription: (json['oneLineDescription'] as String?) ?? '',
      autoSummaryInsert: json['autoSummaryInsert'] as bool? ?? true,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => CoverImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
