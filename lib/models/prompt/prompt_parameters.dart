class PromptParameters {
  final double temperature;
  final int maxTokens;
  final double topP;
  final int topK;
  final double frequencyPenalty;
  final double presencePenalty;

  const PromptParameters({
    this.temperature = 1.0,
    this.maxTokens = 2048,
    this.topP = 0.95,
    this.topK = 40,
    this.frequencyPenalty = 0.0,
    this.presencePenalty = 0.0,
  });

  factory PromptParameters.fromJson(Map<String, dynamic> json) {
    return PromptParameters(
      temperature: (json['temperature'] as num?)?.toDouble() ?? 1.0,
      maxTokens: json['maxTokens'] as int? ?? 2048,
      topP: (json['topP'] as num?)?.toDouble() ?? 0.95,
      topK: json['topK'] as int? ?? 40,
      frequencyPenalty: (json['frequencyPenalty'] as num?)?.toDouble() ?? 0.0,
      presencePenalty: (json['presencePenalty'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'maxTokens': maxTokens,
      'topP': topP,
      'topK': topK,
      'frequencyPenalty': frequencyPenalty,
      'presencePenalty': presencePenalty,
    };
  }

  PromptParameters copyWith({
    double? temperature,
    int? maxTokens,
    double? topP,
    int? topK,
    double? frequencyPenalty,
    double? presencePenalty,
  }) {
    return PromptParameters(
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      topP: topP ?? this.topP,
      topK: topK ?? this.topK,
      frequencyPenalty: frequencyPenalty ?? this.frequencyPenalty,
      presencePenalty: presencePenalty ?? this.presencePenalty,
    );
  }
}
