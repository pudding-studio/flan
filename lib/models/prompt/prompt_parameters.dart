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
    );
  }
}

const _undefined = Object();
