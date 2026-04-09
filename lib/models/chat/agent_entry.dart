import 'dart:convert';

enum AgentEntryType {
  episode,
  character,
  location,
  item,
  event;

  String get displayName {
    switch (this) {
      case AgentEntryType.episode:
        return '요약';
      case AgentEntryType.character:
        return '등장인물';
      case AgentEntryType.location:
        return '지역/장소';
      case AgentEntryType.item:
        return '물품';
      case AgentEntryType.event:
        return '업적/사건';
    }
  }
}

class AgentEntry {
  final int? id;
  final int chatRoomId;
  final AgentEntryType entryType;
  final String name;
  final Map<String, dynamic> data;
  final bool isActive;
  final List<String> relatedNames;
  final DateTime createdAt;
  final DateTime updatedAt;

  AgentEntry({
    this.id,
    required this.chatRoomId,
    required this.entryType,
    required this.name,
    required this.data,
    this.isActive = true,
    this.relatedNames = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory AgentEntry.fromMap(Map<String, dynamic> map) {
    return AgentEntry(
      id: map['id'] as int?,
      chatRoomId: map['chat_room_id'] as int,
      entryType: AgentEntryType.values.firstWhere(
        (e) => e.name == (map['entry_type'] as String),
        orElse: () => AgentEntryType.episode,
      ),
      name: map['name'] as String,
      data: map['data'] != null
          ? jsonDecode(map['data'] as String) as Map<String, dynamic>
          : {},
      isActive: (map['is_active'] as int? ?? 1) == 1,
      relatedNames: map['related_names'] != null
          ? (jsonDecode(map['related_names'] as String) as List)
              .cast<String>()
          : [],
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chat_room_id': chatRoomId,
      'entry_type': entryType.name,
      'name': name,
      'data': jsonEncode(data),
      'is_active': isActive ? 1 : 0,
      'related_names': jsonEncode(relatedNames),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  AgentEntry copyWith({
    int? id,
    int? chatRoomId,
    AgentEntryType? entryType,
    String? name,
    Map<String, dynamic>? data,
    bool? isActive,
    List<String>? relatedNames,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AgentEntry(
      id: id ?? this.id,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      entryType: entryType ?? this.entryType,
      name: name ?? this.name,
      data: data ?? this.data,
      isActive: isActive ?? this.isActive,
      relatedNames: relatedNames ?? this.relatedNames,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Formats entry data as readable text for prompt injection
  String toReadableText() {
    final buffer = StringBuffer();
    buffer.writeln('[$name]');

    switch (entryType) {
      case AgentEntryType.episode:
        if (data['date_range'] != null) buffer.writeln('날짜/시간: ${data['date_range']}');
        if (data['characters'] != null) buffer.writeln('등장인물: ${(data['characters'] as List).join(', ')}');
        if (data['locations'] != null) buffer.writeln('장소: ${(data['locations'] as List).join(', ')}');
        if (data['summary_text'] != null) buffer.writeln('요약: ${data['summary_text']}');
      case AgentEntryType.character:
        if (data['appearance'] != null) buffer.writeln('외형: ${data['appearance']}');
        if (data['personality'] != null) buffer.writeln('성격: ${data['personality']}');
        if (data['past'] != null) buffer.writeln('과거: ${data['past']}');
        if (data['abilities'] != null) buffer.writeln('능력: ${data['abilities']}');
        if (data['story_actions'] != null) buffer.writeln('작중행적: ${data['story_actions']}');
        if (data['dialogue_style'] != null) buffer.writeln('대사 스타일: ${data['dialogue_style']}');
        if (data['possessions'] != null) buffer.writeln('소지품: ${(data['possessions'] as List).join(', ')}');
      case AgentEntryType.location:
        if (data['parent_location'] != null) buffer.writeln('위치: ${data['parent_location']}');
        if (data['features'] != null) buffer.writeln('특징: ${data['features']}');
        if (data['ascii_map'] != null) buffer.writeln('맵:\n${data['ascii_map']}');
        if (data['related_episodes'] != null) buffer.writeln('관련 에피소드: ${(data['related_episodes'] as List).join(', ')}');
      case AgentEntryType.item:
        if (data['keywords'] != null) buffer.writeln('키워드: ${data['keywords']}');
        if (data['features'] != null) buffer.writeln('특징: ${data['features']}');
        if (data['related_episodes'] != null) buffer.writeln('관련 에피소드: ${(data['related_episodes'] as List).join(', ')}');
      case AgentEntryType.event:
        if (data['datetime'] != null) buffer.writeln('일시: ${data['datetime']}');
        if (data['overview'] != null) buffer.writeln('개요: ${data['overview']}');
        if (data['result'] != null) buffer.writeln('결과: ${data['result']}');
        if (data['related_episodes'] != null) buffer.writeln('관련 에피소드: ${(data['related_episodes'] as List).join(', ')}');
    }

    return buffer.toString();
  }
}
