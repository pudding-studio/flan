enum ThinkingLevel {
  unspecified,
  minimal,
  low,
  medium,
  high;

  String get displayName {
    switch (this) {
      case ThinkingLevel.unspecified:
        return '기본값';
      case ThinkingLevel.minimal:
        return '최소';
      case ThinkingLevel.low:
        return '낮음';
      case ThinkingLevel.medium:
        return '중간';
      case ThinkingLevel.high:
        return '높음';
    }
  }

  String get apiValue {
    switch (this) {
      case ThinkingLevel.unspecified:
        return 'THINKING_LEVEL_UNSPECIFIED';
      case ThinkingLevel.minimal:
        return 'MINIMAL';
      case ThinkingLevel.low:
        return 'LOW';
      case ThinkingLevel.medium:
        return 'MEDIUM';
      case ThinkingLevel.high:
        return 'HIGH';
    }
  }

  static ThinkingLevel fromString(String value) {
    switch (value) {
      case 'THINKING_LEVEL_UNSPECIFIED':
        return ThinkingLevel.unspecified;
      case 'MINIMAL':
        return ThinkingLevel.minimal;
      case 'LOW':
        return ThinkingLevel.low;
      case 'MEDIUM':
        return ThinkingLevel.medium;
      case 'HIGH':
        return ThinkingLevel.high;
      default:
        return ThinkingLevel.unspecified;
    }
  }
}

class PromptParameters {
  final int? maxInputTokens;
  final int? maxOutputTokens;
  final int? thinkingTokens;
  final double? temperature;
  final double? topP;
  final int? topK;
  final double? presencePenalty;
  final double? frequencyPenalty;
  final bool? includeThoughts;
  final int? thinkingMaxTokens;
  final ThinkingLevel? thinkingLevel;
  final List<String>? stopSequences;

  // Template behavior (RisuAI preset settings).

  /// Places the new user message right after the last chat history item,
  /// as RisuAI does, instead of after every prompt item.
  final bool? userMessageInChatHistory;

  /// RisuAI `sendChatAsSystem`: history turns are sent as instructions,
  /// prefixed with their role.
  final bool? sendChatAsSystem;

  /// RisuAI `sendName`: history turns are wrapped with the speaker's name.
  final bool? sendName;

  /// RisuAI `templateDefaultVariables`: `key=value` lines that chat
  /// variables read as long as they are unset.
  final String? defaultVariables;

  const PromptParameters({
    this.maxInputTokens,
    this.maxOutputTokens,
    this.thinkingTokens,
    this.temperature,
    this.topP,
    this.topK,
    this.presencePenalty,
    this.frequencyPenalty,
    this.includeThoughts,
    this.thinkingMaxTokens,
    this.thinkingLevel,
    this.stopSequences,
    this.userMessageInChatHistory,
    this.sendChatAsSystem,
    this.sendName,
    this.defaultVariables,
  });

  factory PromptParameters.fromJson(Map<String, dynamic> json) {
    return PromptParameters(
      maxInputTokens: json['maxInputTokens'] as int?,
      maxOutputTokens: json['maxOutputTokens'] as int?,
      thinkingTokens: json['thinkingTokens'] as int?,
      temperature: (json['temperature'] as num?)?.toDouble(),
      topP: (json['topP'] as num?)?.toDouble(),
      topK: json['topK'] as int?,
      presencePenalty: (json['presencePenalty'] as num?)?.toDouble(),
      frequencyPenalty: (json['frequencyPenalty'] as num?)?.toDouble(),
      includeThoughts: json['includeThoughts'] as bool?,
      thinkingMaxTokens: json['thinkingMaxTokens'] as int?,
      thinkingLevel: json['thinkingLevel'] != null
          ? ThinkingLevel.fromString(json['thinkingLevel'] as String)
          : null,
      stopSequences: (json['stopSequences'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      userMessageInChatHistory: json['userMessageInChatHistory'] as bool?,
      sendChatAsSystem: json['sendChatAsSystem'] as bool?,
      sendName: json['sendName'] as bool?,
      defaultVariables: json['defaultVariables'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (maxInputTokens != null) 'maxInputTokens': maxInputTokens,
      if (maxOutputTokens != null) 'maxOutputTokens': maxOutputTokens,
      if (thinkingTokens != null) 'thinkingTokens': thinkingTokens,
      if (temperature != null) 'temperature': temperature,
      if (topP != null) 'topP': topP,
      if (topK != null) 'topK': topK,
      if (presencePenalty != null) 'presencePenalty': presencePenalty,
      if (frequencyPenalty != null) 'frequencyPenalty': frequencyPenalty,
      if (includeThoughts != null) 'includeThoughts': includeThoughts,
      if (thinkingMaxTokens != null) 'thinkingMaxTokens': thinkingMaxTokens,
      if (thinkingLevel != null) 'thinkingLevel': thinkingLevel!.apiValue,
      if (stopSequences != null && stopSequences!.isNotEmpty) 'stopSequences': stopSequences,
      if (userMessageInChatHistory == true) 'userMessageInChatHistory': true,
      if (sendChatAsSystem == true) 'sendChatAsSystem': true,
      if (sendName == true) 'sendName': true,
      if (defaultVariables != null && defaultVariables!.isNotEmpty)
        'defaultVariables': defaultVariables,
    };
  }

  PromptParameters copyWith({
    Object? maxInputTokens = _undefined,
    Object? maxOutputTokens = _undefined,
    Object? thinkingTokens = _undefined,
    Object? temperature = _undefined,
    Object? topP = _undefined,
    Object? topK = _undefined,
    Object? presencePenalty = _undefined,
    Object? frequencyPenalty = _undefined,
    Object? includeThoughts = _undefined,
    Object? thinkingMaxTokens = _undefined,
    Object? thinkingLevel = _undefined,
    Object? stopSequences = _undefined,
    Object? userMessageInChatHistory = _undefined,
    Object? sendChatAsSystem = _undefined,
    Object? sendName = _undefined,
    Object? defaultVariables = _undefined,
  }) {
    return PromptParameters(
      maxInputTokens: maxInputTokens == _undefined ? this.maxInputTokens : maxInputTokens as int?,
      maxOutputTokens: maxOutputTokens == _undefined ? this.maxOutputTokens : maxOutputTokens as int?,
      thinkingTokens: thinkingTokens == _undefined ? this.thinkingTokens : thinkingTokens as int?,
      temperature: temperature == _undefined ? this.temperature : temperature as double?,
      topP: topP == _undefined ? this.topP : topP as double?,
      topK: topK == _undefined ? this.topK : topK as int?,
      presencePenalty: presencePenalty == _undefined ? this.presencePenalty : presencePenalty as double?,
      frequencyPenalty: frequencyPenalty == _undefined ? this.frequencyPenalty : frequencyPenalty as double?,
      includeThoughts: includeThoughts == _undefined ? this.includeThoughts : includeThoughts as bool?,
      thinkingMaxTokens: thinkingMaxTokens == _undefined ? this.thinkingMaxTokens : thinkingMaxTokens as int?,
      thinkingLevel: thinkingLevel == _undefined ? this.thinkingLevel : thinkingLevel as ThinkingLevel?,
      stopSequences: stopSequences == _undefined ? this.stopSequences : stopSequences as List<String>?,
      userMessageInChatHistory: userMessageInChatHistory == _undefined ? this.userMessageInChatHistory : userMessageInChatHistory as bool?,
      sendChatAsSystem: sendChatAsSystem == _undefined ? this.sendChatAsSystem : sendChatAsSystem as bool?,
      sendName: sendName == _undefined ? this.sendName : sendName as bool?,
      defaultVariables: defaultVariables == _undefined ? this.defaultVariables : defaultVariables as String?,
    );
  }
}

const _undefined = Object();
