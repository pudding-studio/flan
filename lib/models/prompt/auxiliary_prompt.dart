/// Identifies an auxiliary (non-chat) prompt stored in `auxiliary_prompts`.
/// Each key maps 1:1 to a default asset file and a specific feature that
/// previously loaded its system prompt directly from bundled text assets.
enum AuxiliaryPromptKey {
  flanAgentSystem,
  chatTranslation,
  agentSummary,
  snsGenerate,
  snsPostReplies,
  snsCommentReplies,
  diaryGenerate,
  newsGenerate,
  newsEventGenerate,
}

extension AuxiliaryPromptKeyX on AuxiliaryPromptKey {
  String get storageKey {
    switch (this) {
      case AuxiliaryPromptKey.flanAgentSystem:
        return 'flan_agent_system';
      case AuxiliaryPromptKey.chatTranslation:
        return 'chat_translation';
      case AuxiliaryPromptKey.agentSummary:
        return 'agent_summary';
      case AuxiliaryPromptKey.snsGenerate:
        return 'sns_generate';
      case AuxiliaryPromptKey.snsPostReplies:
        return 'sns_post_replies';
      case AuxiliaryPromptKey.snsCommentReplies:
        return 'sns_comment_replies';
      case AuxiliaryPromptKey.diaryGenerate:
        return 'diary_generate';
      case AuxiliaryPromptKey.newsGenerate:
        return 'news_generate';
      case AuxiliaryPromptKey.newsEventGenerate:
        return 'news_event_generate';
    }
  }

  static AuxiliaryPromptKey? fromStorageKey(String key) {
    for (final value in AuxiliaryPromptKey.values) {
      if (value.storageKey == key) return value;
    }
    return null;
  }
}

class AuxiliaryPrompt {
  final int? id;
  final AuxiliaryPromptKey key;
  final String contentNative;
  final String contentEnglish;
  final bool useEnglish;
  final DateTime updatedAt;

  AuxiliaryPrompt({
    this.id,
    required this.key,
    required this.contentNative,
    required this.contentEnglish,
    required this.useEnglish,
    required this.updatedAt,
  });

  String get effectiveContent =>
      useEnglish && contentEnglish.trim().isNotEmpty
          ? contentEnglish
          : contentNative;

  AuxiliaryPrompt copyWith({
    int? id,
    AuxiliaryPromptKey? key,
    String? contentNative,
    String? contentEnglish,
    bool? useEnglish,
    DateTime? updatedAt,
  }) {
    return AuxiliaryPrompt(
      id: id ?? this.id,
      key: key ?? this.key,
      contentNative: contentNative ?? this.contentNative,
      contentEnglish: contentEnglish ?? this.contentEnglish,
      useEnglish: useEnglish ?? this.useEnglish,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'prompt_key': key.storageKey,
      'content_native': contentNative,
      'content_english': contentEnglish,
      'use_english': useEnglish ? 1 : 0,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory AuxiliaryPrompt.fromMap(Map<String, dynamic> map) {
    final rawKey = map['prompt_key'] as String;
    final key = AuxiliaryPromptKeyX.fromStorageKey(rawKey);
    if (key == null) {
      throw ArgumentError('Unknown auxiliary prompt key: $rawKey');
    }
    return AuxiliaryPrompt(
      id: map['id'] as int?,
      key: key,
      contentNative: (map['content_native'] as String?) ?? '',
      contentEnglish: (map['content_english'] as String?) ?? '',
      useEnglish: (map['use_english'] as int? ?? 0) == 1,
      updatedAt:
          DateTime.tryParse(map['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
