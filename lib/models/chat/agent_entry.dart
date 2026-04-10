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
        return 'Summary';
      case AgentEntryType.character:
        return 'Characters';
      case AgentEntryType.location:
        return 'Locations';
      case AgentEntryType.item:
        return 'Items';
      case AgentEntryType.event:
        return 'Events';
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
        if (data['date_range'] != null) buffer.writeln('Date/Time: ${data['date_range']}');
        if (data['characters'] != null) buffer.writeln('Characters: ${(data['characters'] as List).join(', ')}');
        if (data['locations'] != null) buffer.writeln('Locations: ${(data['locations'] as List).join(', ')}');
        if (data['summary_text'] != null) buffer.writeln('Summary: ${data['summary_text']}');
      case AgentEntryType.character:
        if (data['appearance'] != null) buffer.writeln('Appearance: ${data['appearance']}');
        if (data['personality'] != null) buffer.writeln('Personality: ${data['personality']}');
        if (data['past'] != null) buffer.writeln('Background: ${data['past']}');
        if (data['abilities'] != null) buffer.writeln('Abilities: ${data['abilities']}');
        if (data['story_actions'] != null) buffer.writeln('Story Actions: ${data['story_actions']}');
        if (data['dialogue_style'] != null) buffer.writeln('Dialogue Style: ${data['dialogue_style']}');
        if (data['possessions'] != null) buffer.writeln('Possessions: ${(data['possessions'] as List).join(', ')}');
      case AgentEntryType.location:
        if (data['parent_location'] != null) buffer.writeln('Parent Location: ${data['parent_location']}');
        if (data['features'] != null) buffer.writeln('Features: ${data['features']}');
        if (data['ascii_map'] != null) buffer.writeln('Map:\n${data['ascii_map']}');
        if (data['related_episodes'] != null) buffer.writeln('Related Episodes: ${(data['related_episodes'] as List).join(', ')}');
      case AgentEntryType.item:
        if (data['keywords'] != null) buffer.writeln('Keywords: ${data['keywords']}');
        if (data['features'] != null) buffer.writeln('Features: ${data['features']}');
        if (data['related_episodes'] != null) buffer.writeln('Related Episodes: ${(data['related_episodes'] as List).join(', ')}');
      case AgentEntryType.event:
        if (data['datetime'] != null) buffer.writeln('Date/Time: ${data['datetime']}');
        if (data['overview'] != null) buffer.writeln('Overview: ${data['overview']}');
        if (data['result'] != null) buffer.writeln('Result: ${data['result']}');
        if (data['related_episodes'] != null) buffer.writeln('Related Episodes: ${(data['related_episodes'] as List).join(', ')}');
    }

    return buffer.toString();
  }
}
