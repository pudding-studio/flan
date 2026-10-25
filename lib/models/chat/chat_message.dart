import 'dart:convert';

enum MessageRole {
  user,
  assistant;

  String get displayName {
    switch (this) {
      case MessageRole.user:
        return '사용자';
      case MessageRole.assistant:
        return '어시스턴트';
    }
  }
}

class UsageMetadata {
  final int promptTokenCount;
  final int candidatesTokenCount;
  final int totalTokenCount;
  final int? cachedContentTokenCount;
  final int? thoughtsTokenCount;

  const UsageMetadata({
    this.promptTokenCount = 0,
    this.candidatesTokenCount = 0,
    this.totalTokenCount = 0,
    this.cachedContentTokenCount,
    this.thoughtsTokenCount,
  });

  factory UsageMetadata.fromJson(Map<String, dynamic> json) {
    return UsageMetadata(
      promptTokenCount: json['promptTokenCount'] as int? ?? 0,
      candidatesTokenCount: json['candidatesTokenCount'] as int? ?? 0,
      totalTokenCount: json['totalTokenCount'] as int? ?? 0,
      cachedContentTokenCount: json['cachedContentTokenCount'] as int?,
      thoughtsTokenCount: json['thoughtsTokenCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'promptTokenCount': promptTokenCount,
      'candidatesTokenCount': candidatesTokenCount,
      'totalTokenCount': totalTokenCount,
      if (cachedContentTokenCount != null) 'cachedContentTokenCount': cachedContentTokenCount,
      if (thoughtsTokenCount != null) 'thoughtsTokenCount': thoughtsTokenCount,
    };
  }

  double get cacheRatio {
    if (promptTokenCount == 0) return 0;
    return (cachedContentTokenCount ?? 0) / promptTokenCount;
  }

  double get thoughtsRatio {
    final thoughts = thoughtsTokenCount ?? 0;
    final total = candidatesTokenCount + thoughts;
    if (total == 0) return 0;
    return thoughts / total;
  }
}

/// One reply an AI message has had. Regenerating keeps the earlier ones so
/// the user can go back to them.
class ChatMessageVersion {
  final String content;
  final int tokenCount;
  final UsageMetadata? usageMetadata;
  final String? modelId;
  final String? emotion;
  final DateTime createdAt;

  const ChatMessageVersion({
    required this.content,
    required this.tokenCount,
    required this.createdAt,
    this.usageMetadata,
    this.modelId,
    this.emotion,
  });

  factory ChatMessageVersion.fromJson(Map<String, dynamic> json) =>
      ChatMessageVersion(
        content: json['content'] as String? ?? '',
        tokenCount: json['tokenCount'] as int? ?? 0,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        usageMetadata: json['usageMetadata'] is Map
            ? UsageMetadata.fromJson(
                (json['usageMetadata'] as Map).cast<String, dynamic>())
            : null,
        modelId: json['modelId'] as String?,
        emotion: json['emotion'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'content': content,
        'tokenCount': tokenCount,
        'createdAt': createdAt.toIso8601String(),
        if (usageMetadata != null) 'usageMetadata': usageMetadata!.toJson(),
        if (modelId != null) 'modelId': modelId,
        if (emotion != null) 'emotion': emotion,
      };
}

class ChatMessage {
  final int? id;
  final int chatRoomId;
  final MessageRole role;
  final String content;
  final int tokenCount;
  final DateTime createdAt;
  final DateTime? editedAt;
  final UsageMetadata? usageMetadata;
  final String? modelId;

  /// Emotion image name picked for this AI reply (classifier mode).
  final String? emotion;

  /// Every reply this message has had, oldest first; empty until it is
  /// first regenerated. The fields above always hold the selected one,
  /// so everything else reads the message as before.
  final List<ChatMessageVersion> versions;
  final int versionIndex;

  ChatMessage({
    this.id,
    required this.chatRoomId,
    required this.role,
    required this.content,
    this.tokenCount = 0,
    DateTime? createdAt,
    this.editedAt,
    this.usageMetadata,
    this.modelId,
    this.emotion,
    this.versions = const [],
    this.versionIndex = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    UsageMetadata? usageMetadata;
    if (map['usage_metadata'] != null) {
      final usageJson = map['usage_metadata'] as String;
      usageMetadata = UsageMetadata.fromJson(jsonDecode(usageJson));
    }

    return ChatMessage(
      id: map['id'] as int?,
      chatRoomId: map['chat_room_id'] as int,
      role: MessageRole.values.firstWhere(
        (e) => e.name == (map['role'] as String),
        orElse: () => MessageRole.user,
      ),
      content: map['content'] as String,
      tokenCount: map['token_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      editedAt: map['edited_at'] != null
          ? DateTime.parse(map['edited_at'] as String)
          : null,
      usageMetadata: usageMetadata,
      modelId: map['model_id'] as String?,
      emotion: map['emotion'] as String?,
      versions: _decodeVersions(map['versions'] as String?),
      versionIndex: map['version_index'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chat_room_id': chatRoomId,
      'role': role.name,
      'content': content,
      'token_count': tokenCount,
      'created_at': createdAt.toIso8601String(),
      'edited_at': editedAt?.toIso8601String(),
      'usage_metadata': usageMetadata != null ? jsonEncode(usageMetadata!.toJson()) : null,
      'model_id': modelId,
      'emotion': emotion,
      'versions': versions.isEmpty
          ? null
          : jsonEncode(versions.map((v) => v.toJson()).toList()),
      'version_index': versionIndex,
    };
  }

  ChatMessage copyWith({
    int? id,
    int? chatRoomId,
    MessageRole? role,
    String? content,
    int? tokenCount,
    DateTime? createdAt,
    DateTime? editedAt,
    UsageMetadata? usageMetadata,
    String? modelId,
    Object? emotion = _sentinel,
    List<ChatMessageVersion>? versions,
    int? versionIndex,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      role: role ?? this.role,
      content: content ?? this.content,
      tokenCount: tokenCount ?? this.tokenCount,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      usageMetadata: usageMetadata ?? this.usageMetadata,
      modelId: modelId ?? this.modelId,
      emotion: emotion == _sentinel ? this.emotion : emotion as String?,
      versions: versions ?? this.versions,
      versionIndex: versionIndex ?? this.versionIndex,
    );
  }

  int get versionCount => versions.isEmpty ? 1 : versions.length;

  ChatMessageVersion get _selectedVersion => ChatMessageVersion(
        content: content,
        tokenCount: tokenCount,
        createdAt: editedAt ?? createdAt,
        usageMetadata: usageMetadata,
        modelId: modelId,
        emotion: emotion,
      );

  /// The stored versions with the selected one refreshed from the live
  /// fields, which may have been edited or given an emotion since.
  List<ChatMessageVersion> get _currentVersions => versions.isEmpty
      ? [_selectedVersion]
      : [
          for (var i = 0; i < versions.length; i++)
            i == versionIndex ? _selectedVersion : versions[i],
        ];

  /// Adds [version] as the newest reply and selects it.
  ChatMessage withNewVersion(ChatMessageVersion version) {
    final all = [..._currentVersions, version];
    return _showing(all, all.length - 1);
  }

  /// Shows the reply at [index] (clamped to the stored versions).
  ChatMessage withVersionSelected(int index) {
    final all = _currentVersions;
    return _showing(all, index.clamp(0, all.length - 1));
  }

  ChatMessage _showing(List<ChatMessageVersion> all, int index) {
    final version = all[index];
    return ChatMessage(
      id: id,
      chatRoomId: chatRoomId,
      role: role,
      content: version.content,
      tokenCount: version.tokenCount,
      createdAt: createdAt,
      editedAt: version.createdAt,
      usageMetadata: version.usageMetadata,
      modelId: version.modelId,
      emotion: version.emotion,
      versions: all,
      versionIndex: index,
    );
  }

  static List<ChatMessageVersion> _decodeVersions(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List)
          .map((v) => ChatMessageVersion.fromJson(
              (v as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static const _sentinel = Object();
}
