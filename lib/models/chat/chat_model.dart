enum ApiFormat {
  gemini('Gemini'),
  openai('OpenAI'),
  claude('Claude');

  final String displayName;
  const ApiFormat(this.displayName);
}

enum ChatModelProvider {
  all('ALL'),
  googleAIStudio('Google AI Studio'),
  vertexAi('Vertex AI'),
  openai('OpenAI'),
  anthropic('Anthropic'),
  custom('커스텀');

  final String displayName;
  const ChatModelProvider(this.displayName);
}

/// 모델별 토큰 가격 (USD per 1M tokens)
class ModelPricing {
  final double inputPrice;
  final double cachedInputPrice;
  final double outputPrice;
  final double? thinkingOutputPrice;

  const ModelPricing({
    required this.inputPrice,
    required this.cachedInputPrice,
    required this.outputPrice,
    this.thinkingOutputPrice,
  });

  const ModelPricing.zero()
      : inputPrice = 0,
        cachedInputPrice = 0,
        outputPrice = 0,
        thinkingOutputPrice = null;

  double calculateCost({
    required int promptTokens,
    required int cachedTokens,
    required int outputTokens,
    int thinkingTokens = 0,
  }) {
    final nonCachedInputTokens = promptTokens - cachedTokens;
    final inputCost = nonCachedInputTokens * inputPrice / 1000000;
    final cachedCost = cachedTokens * cachedInputPrice / 1000000;
    final thinkingPrice = thinkingOutputPrice ?? outputPrice;
    final outputCost = outputTokens * outputPrice / 1000000;
    final thinkingCost = thinkingTokens * thinkingPrice / 1000000;
    return inputCost + cachedCost + outputCost + thinkingCost;
  }

  Map<String, dynamic> toJson() => {
        'inputPrice': inputPrice,
        'cachedInputPrice': cachedInputPrice,
        'outputPrice': outputPrice,
        if (thinkingOutputPrice != null)
          'thinkingOutputPrice': thinkingOutputPrice,
      };

  factory ModelPricing.fromJson(Map<String, dynamic> json) => ModelPricing(
        inputPrice: (json['inputPrice'] as num?)?.toDouble() ?? 0,
        cachedInputPrice: (json['cachedInputPrice'] as num?)?.toDouble() ?? 0,
        outputPrice: (json['outputPrice'] as num?)?.toDouble() ?? 0,
        thinkingOutputPrice:
            (json['thinkingOutputPrice'] as num?)?.toDouble(),
      );
}

enum ChatModel {
  // Gemini models
  geminiPro31Preview(
    'Gemini 3.1 Pro Preview',
    ChatModelProvider.googleAIStudio,
    'gemini-3.1-pro-preview',
    ApiFormat.gemini,
    ModelPricing(inputPrice: 2.00, cachedInputPrice: 0.20, outputPrice: 12.00),
  ),
  geminiFlash3Preview(
    'Gemini 3 Flash Preview',
    ChatModelProvider.googleAIStudio,
    'gemini-3-flash-preview',
    ApiFormat.gemini,
    ModelPricing(inputPrice: 0.50, cachedInputPrice: 0.05, outputPrice: 3.00),
  ),
  geminiPro25(
    'Gemini 2.5 Pro',
    ChatModelProvider.googleAIStudio,
    'gemini-2.5-pro',
    ApiFormat.gemini,
    ModelPricing(inputPrice: 1.25, cachedInputPrice: 0.125, outputPrice: 10.00),
  ),
  geminiFlash25(
    'Gemini 2.5 Flash',
    ChatModelProvider.googleAIStudio,
    'gemini-2.5-flash',
    ApiFormat.gemini,
    ModelPricing(inputPrice: 0.15, cachedInputPrice: 0.015, outputPrice: 0.60, thinkingOutputPrice: 3.50),
  ),
  geminiFlashLite25(
    'Gemini 2.5 Flash Lite',
    ChatModelProvider.googleAIStudio,
    'gemini-2.5-flash-lite',
    ApiFormat.gemini,
    ModelPricing(inputPrice: 0.10, cachedInputPrice: 0.010, outputPrice: 0.40),
  ),

  // Vertex AI models (same Gemini models via Vertex AI endpoint)
  vertexGeminiPro31Preview(
    'Gemini 3.1 Pro Preview',
    ChatModelProvider.vertexAi,
    'gemini-3.1-pro-preview',
    ApiFormat.gemini,
    ModelPricing(inputPrice: 2.00, cachedInputPrice: 0.20, outputPrice: 12.00),
  ),
  vertexGeminiPro31(
    'Gemini 3.1 Pro',
    ChatModelProvider.vertexAi,
    'gemini-3.1-pro',
    ApiFormat.gemini,
    ModelPricing(inputPrice: 2.00, cachedInputPrice: 0.20, outputPrice: 12.00),
  ),
  vertexGeminiFlash3Preview(
    'Gemini 3 Flash Preview',
    ChatModelProvider.vertexAi,
    'gemini-3-flash-preview',
    ApiFormat.gemini,
    ModelPricing(inputPrice: 0.50, cachedInputPrice: 0.05, outputPrice: 3.00),
  ),
  vertexGeminiPro25(
    'Gemini 2.5 Pro',
    ChatModelProvider.vertexAi,
    'gemini-2.5-pro',
    ApiFormat.gemini,
    ModelPricing(inputPrice: 1.25, cachedInputPrice: 0.125, outputPrice: 10.00),
  ),
  vertexGeminiFlash25(
    'Gemini 2.5 Flash',
    ChatModelProvider.vertexAi,
    'gemini-2.5-flash',
    ApiFormat.gemini,
    ModelPricing(inputPrice: 0.15, cachedInputPrice: 0.015, outputPrice: 0.60, thinkingOutputPrice: 3.50),
  ),
  vertexGeminiFlashLite25(
    'Gemini 2.5 Flash Lite',
    ChatModelProvider.vertexAi,
    'gemini-2.5-flash-lite',
    ApiFormat.gemini,
    ModelPricing(inputPrice: 0.10, cachedInputPrice: 0.010, outputPrice: 0.40),
  ),

  // OpenAI models
  o3(
    'o3',
    ChatModelProvider.openai,
    'o3',
    ApiFormat.openai,
    ModelPricing(inputPrice: 2.00, cachedInputPrice: 0.50, outputPrice: 8.00),
  ),
  o4Mini(
    'o4-mini',
    ChatModelProvider.openai,
    'o4-mini',
    ApiFormat.openai,
    ModelPricing(inputPrice: 1.10, cachedInputPrice: 0.275, outputPrice: 4.40),
  ),
  gpt41(
    'GPT-4.1',
    ChatModelProvider.openai,
    'gpt-4.1',
    ApiFormat.openai,
    ModelPricing(inputPrice: 2.00, cachedInputPrice: 0.50, outputPrice: 8.00),
  ),
  gpt41Mini(
    'GPT-4.1 Mini',
    ChatModelProvider.openai,
    'gpt-4.1-mini',
    ApiFormat.openai,
    ModelPricing(inputPrice: 0.40, cachedInputPrice: 0.10, outputPrice: 1.60),
  ),
  gpt41Nano(
    'GPT-4.1 Nano',
    ChatModelProvider.openai,
    'gpt-4.1-nano',
    ApiFormat.openai,
    ModelPricing(inputPrice: 0.10, cachedInputPrice: 0.025, outputPrice: 0.40),
  ),
  gpt4o(
    'GPT-4o',
    ChatModelProvider.openai,
    'gpt-4o',
    ApiFormat.openai,
    ModelPricing(inputPrice: 2.50, cachedInputPrice: 1.25, outputPrice: 10.00),
  ),
  gpt4oMini(
    'GPT-4o Mini',
    ChatModelProvider.openai,
    'gpt-4o-mini',
    ApiFormat.openai,
    ModelPricing(inputPrice: 0.15, cachedInputPrice: 0.075, outputPrice: 0.60),
  ),
  o3Mini(
    'o3-mini',
    ChatModelProvider.openai,
    'o3-mini',
    ApiFormat.openai,
    ModelPricing(inputPrice: 1.10, cachedInputPrice: 0.55, outputPrice: 4.40),
  ),
  o1(
    'o1',
    ChatModelProvider.openai,
    'o1',
    ApiFormat.openai,
    ModelPricing(inputPrice: 15.00, cachedInputPrice: 7.50, outputPrice: 60.00),
  ),

  // Claude models
  claudeOpus46(
    'Claude Opus 4.6',
    ChatModelProvider.anthropic,
    'claude-opus-4-6',
    ApiFormat.claude,
    ModelPricing(inputPrice: 5.00, cachedInputPrice: 0.50, outputPrice: 25.00),
  ),
  claudeOpus45(
    'Claude Opus 4.5',
    ChatModelProvider.anthropic,
    'claude-opus-4-5',
    ApiFormat.claude,
    ModelPricing(inputPrice: 5.00, cachedInputPrice: 0.50, outputPrice: 25.00),
  ),
  claudeSonnet45(
    'Claude Sonnet 4.5',
    ChatModelProvider.anthropic,
    'claude-sonnet-4-5',
    ApiFormat.claude,
    ModelPricing(inputPrice: 3.00, cachedInputPrice: 0.30, outputPrice: 15.00),
  ),
  claudeHaiku45(
    'Claude Haiku 4.5',
    ChatModelProvider.anthropic,
    'claude-haiku-4-5',
    ApiFormat.claude,
    ModelPricing(inputPrice: 1.00, cachedInputPrice: 0.10, outputPrice: 5.00),
  ),
  claudeOpus4(
    'Claude Opus 4',
    ChatModelProvider.anthropic,
    'claude-opus-4-20250514',
    ApiFormat.claude,
    ModelPricing(inputPrice: 15.00, cachedInputPrice: 1.50, outputPrice: 75.00),
  ),
  claudeSonnet4(
    'Claude Sonnet 4',
    ChatModelProvider.anthropic,
    'claude-sonnet-4-20250514',
    ApiFormat.claude,
    ModelPricing(inputPrice: 3.00, cachedInputPrice: 0.30, outputPrice: 15.00),
  ),
  claudeHaiku35(
    'Claude Haiku 3.5',
    ChatModelProvider.anthropic,
    'claude-3-5-haiku-20241022',
    ApiFormat.claude,
    ModelPricing(inputPrice: 0.80, cachedInputPrice: 0.08, outputPrice: 4.00),
  );

  final String displayName;
  final ChatModelProvider provider;
  final String modelId;
  final ApiFormat apiFormat;
  final ModelPricing pricing;

  const ChatModel(this.displayName, this.provider, this.modelId, this.apiFormat, this.pricing);

  static List<ChatModel> getModelsByProvider(ChatModelProvider provider) {
    if (provider == ChatModelProvider.all) {
      return ChatModel.values;
    }
    return ChatModel.values
        .where((model) => model.provider == provider)
        .toList();
  }

  static ChatModel? fromModelId(String modelId) {
    for (final model in ChatModel.values) {
      if (model.modelId == modelId) return model;
    }
    return null;
  }

  /// Resolve a ChatModel from a stored value (enum name or legacy modelId).
  static ChatModel resolveFromStoredValue(String storedValue) {
    // Try enum name first
    for (final model in ChatModel.values) {
      if (model.name == storedValue) return model;
    }
    // Fallback: legacy modelId lookup (returns first match)
    for (final model in ChatModel.values) {
      if (model.modelId == storedValue) return model;
    }
    // Legacy: geminiPro3Preview → redirect to 3.1 Pro Preview
    if (storedValue == 'geminiPro3Preview' || storedValue == 'gemini-3-pro-preview') {
      return ChatModel.geminiPro31Preview;
    }
    if (storedValue == 'vertexGeminiPro3Preview') {
      return ChatModel.vertexGeminiPro31Preview;
    }
    return ChatModel.geminiFlash3Preview;
  }
}
