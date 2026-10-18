enum ApiFormat {
  gemini('Gemini'),
  openai('OpenAI'),
  claude('Claude');

  final String displayName;
  const ApiFormat(this.displayName);
}

enum ChatModelProvider {
  googleAIStudio('Google AI Studio'),
  vertexAi('Gemini Enterprise'),
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
  geminiArgon4(
    'Gemini 4 Argon',
    ChatModelProvider.googleAIStudio,
    'gemini-4-argon',
    ApiFormat.gemini,
    ModelPricing(inputPrice: 2.00, cachedInputPrice: 0.10, outputPrice: 10.00),
  ),
  geminiFlash38(
    'Gemini 3.8 Flash',
    ChatModelProvider.googleAIStudio,
    'gemini-3.8-flash',
    ApiFormat.gemini,
    ModelPricing(inputPrice: 0.75, cachedInputPrice: 0.075, outputPrice: 3.75),
  ),
  geminiFlash37(
    'Gemini 3.7 Flash',
    ChatModelProvider.googleAIStudio,
    'gemini-3.7-flash',
    ApiFormat.gemini,
    ModelPricing(inputPrice: 0.75, cachedInputPrice: 0.075, outputPrice: 3.75),
  ),
  geminiFlash36(
    'Gemini 3.6 Flash',
    ChatModelProvider.googleAIStudio,
    'gemini-3.6-flash',
    ApiFormat.gemini,
    ModelPricing(inputPrice: 1.50, cachedInputPrice: 0.15, outputPrice: 7.50),
  ),
  geminiFlash35(
    'Gemini 3.5 Flash',
    ChatModelProvider.googleAIStudio,
    'gemini-3.5-flash',
    ApiFormat.gemini,
    ModelPricing(inputPrice: 1.50, cachedInputPrice: 0.15, outputPrice: 9.00),
  ),
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
  geminiFlashLite31(
    'Gemini 3.1 Flash Lite',
    ChatModelProvider.googleAIStudio,
    'gemini-3.1-flash-lite',
    ApiFormat.gemini,
    ModelPricing(inputPrice: 0.25, cachedInputPrice: 0.025, outputPrice: 1.50),
  ),
  geminiFlashLite25(
    'Gemini 2.5 Flash Lite',
    ChatModelProvider.googleAIStudio,
    'gemini-2.5-flash-lite',
    ApiFormat.gemini,
    ModelPricing(inputPrice: 0.10, cachedInputPrice: 0.010, outputPrice: 0.40),
  ),

  // Gemini Enterprise models (formerly Vertex AI; same Gemini models via the same endpoint)
  vertexGeminiArgon4(
    'Gemini 4 Argon',
    ChatModelProvider.vertexAi,
    'gemini-4-argon',
    ApiFormat.gemini,
    ModelPricing(inputPrice: 2.00, cachedInputPrice: 0.10, outputPrice: 10.00),
  ),
  vertexGeminiFlash38(
    'Gemini 3.8 Flash',
    ChatModelProvider.vertexAi,
    'gemini-3.8-flash',
    ApiFormat.gemini,
    ModelPricing(inputPrice: 0.75, cachedInputPrice: 0.075, outputPrice: 3.75),
  ),
  vertexGeminiFlash37(
    'Gemini 3.7 Flash',
    ChatModelProvider.vertexAi,
    'gemini-3.7-flash',
    ApiFormat.gemini,
    ModelPricing(inputPrice: 0.75, cachedInputPrice: 0.075, outputPrice: 3.75),
  ),
  vertexGeminiFlash36(
    'Gemini 3.6 Flash',
    ChatModelProvider.vertexAi,
    'gemini-3.6-flash',
    ApiFormat.gemini,
    ModelPricing(inputPrice: 1.50, cachedInputPrice: 0.15, outputPrice: 7.50),
  ),
  vertexGeminiFlash35(
    'Gemini 3.5 Flash',
    ChatModelProvider.vertexAi,
    'gemini-3.5-flash',
    ApiFormat.gemini,
    ModelPricing(inputPrice: 1.50, cachedInputPrice: 0.15, outputPrice: 9.00),
  ),
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
  vertexGeminiFlashLite31(
    'Gemini 3.1 Flash Lite',
    ChatModelProvider.vertexAi,
    'gemini-3.1-flash-lite',
    ApiFormat.gemini,
    ModelPricing(inputPrice: 0.25, cachedInputPrice: 0.025, outputPrice: 1.50),
  ),
  vertexGeminiFlashLite25(
    'Gemini 2.5 Flash Lite',
    ChatModelProvider.vertexAi,
    'gemini-2.5-flash-lite',
    ApiFormat.gemini,
    ModelPricing(inputPrice: 0.10, cachedInputPrice: 0.010, outputPrice: 0.40),
  ),

  // OpenAI models
  gpt6Astra(
    'GPT-6 Astra',
    ChatModelProvider.openai,
    'gpt-6-astra',
    ApiFormat.openai,
    ModelPricing(inputPrice: 10.00, cachedInputPrice: 1.00, outputPrice: 50.00),
  ),
  gpt61Sol(
    'GPT-6.1 Sol',
    ChatModelProvider.openai,
    'gpt-6.1-sol',
    ApiFormat.openai,
    ModelPricing(inputPrice: 2.00, cachedInputPrice: 0.10, outputPrice: 10.00),
  ),
  gpt6Luna(
    'GPT-6 Luna',
    ChatModelProvider.openai,
    'gpt-6-luna',
    ApiFormat.openai,
    ModelPricing(inputPrice: 0.10, cachedInputPrice: 0.01, outputPrice: 0.50),
  ),
  gpt56Sol(
    'GPT-5.6 Sol',
    ChatModelProvider.openai,
    'gpt-5.6-sol',
    ApiFormat.openai,
    ModelPricing(inputPrice: 5.00, cachedInputPrice: 0.50, outputPrice: 30.00),
  ),
  gpt56Terra(
    'GPT-5.6 Terra',
    ChatModelProvider.openai,
    'gpt-5.6-terra',
    ApiFormat.openai,
    ModelPricing(inputPrice: 2.00, cachedInputPrice: 0.20, outputPrice: 12.00),
  ),
  gpt56Luna(
    'GPT-5.6 Luna',
    ChatModelProvider.openai,
    'gpt-5.6-luna',
    ApiFormat.openai,
    ModelPricing(inputPrice: 0.20, cachedInputPrice: 0.02, outputPrice: 1.20),
  ),
  gpt55(
    'GPT-5.5',
    ChatModelProvider.openai,
    'gpt-5.5',
    ApiFormat.openai,
    ModelPricing(inputPrice: 5.00, cachedInputPrice: 0.50, outputPrice: 30.00),
  ),
  gpt54(
    'GPT-5.4',
    ChatModelProvider.openai,
    'gpt-5.4',
    ApiFormat.openai,
    ModelPricing(inputPrice: 2.50, cachedInputPrice: 0.625, outputPrice: 15.00),
  ),
  gpt54Mini(
    'GPT-5.4 Mini',
    ChatModelProvider.openai,
    'gpt-5.4-mini',
    ApiFormat.openai,
    ModelPricing(inputPrice: 0.75, cachedInputPrice: 0.075, outputPrice: 4.50),
  ),
  gpt54Nano(
    'GPT-5.4 Nano',
    ChatModelProvider.openai,
    'gpt-5.4-nano',
    ApiFormat.openai,
    ModelPricing(inputPrice: 0.20, cachedInputPrice: 0.02, outputPrice: 1.25),
  ),
  o3(
    'o3',
    ChatModelProvider.openai,
    'o3',
    ApiFormat.openai,
    ModelPricing(inputPrice: 2.00, cachedInputPrice: 0.50, outputPrice: 8.00),
  ),
  o3Pro(
    'o3-pro',
    ChatModelProvider.openai,
    'o3-pro',
    ApiFormat.openai,
    ModelPricing(inputPrice: 20.00, cachedInputPrice: 5.00, outputPrice: 80.00),
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

  // Claude models
  claudeFable51(
    'Claude Fable 5.1',
    ChatModelProvider.anthropic,
    'claude-fable-5-1',
    ApiFormat.claude,
    ModelPricing(inputPrice: 10.00, cachedInputPrice: 0.25, outputPrice: 50.00),
  ),
  claudeOpus55(
    'Claude Opus 5.5',
    ChatModelProvider.anthropic,
    'claude-opus-5-5',
    ApiFormat.claude,
    ModelPricing(inputPrice: 4.00, cachedInputPrice: 0.20, outputPrice: 20.00),
  ),
  claudeSonnet55(
    'Claude Sonnet 5.5',
    ChatModelProvider.anthropic,
    'claude-sonnet-5-5',
    ApiFormat.claude,
    ModelPricing(inputPrice: 2.00, cachedInputPrice: 0.10, outputPrice: 10.00),
  ),
  claudeHaiku55(
    'Claude Haiku 5.5',
    ChatModelProvider.anthropic,
    'claude-haiku-5-5',
    ApiFormat.claude,
    ModelPricing(inputPrice: 0.10, cachedInputPrice: 0.01, outputPrice: 0.50),
  ),
  claudeOpus5(
    'Claude Opus 5',
    ChatModelProvider.anthropic,
    'claude-opus-5',
    ApiFormat.claude,
    ModelPricing(inputPrice: 5.00, cachedInputPrice: 0.50, outputPrice: 25.00),
  ),
  claudeSonnet5(
    'Claude Sonnet 5',
    ChatModelProvider.anthropic,
    'claude-sonnet-5',
    ApiFormat.claude,
    ModelPricing(inputPrice: 3.00, cachedInputPrice: 0.30, outputPrice: 15.00),
  ),
  claudeOpus48(
    'Claude Opus 4.8',
    ChatModelProvider.anthropic,
    'claude-opus-4-8',
    ApiFormat.claude,
    ModelPricing(inputPrice: 5.00, cachedInputPrice: 0.50, outputPrice: 25.00),
  ),
  claudeOpus47(
    'Claude Opus 4.7',
    ChatModelProvider.anthropic,
    'claude-opus-4-7',
    ApiFormat.claude,
    ModelPricing(inputPrice: 5.00, cachedInputPrice: 0.50, outputPrice: 25.00),
  ),
  claudeOpus46(
    'Claude Opus 4.6',
    ChatModelProvider.anthropic,
    'claude-opus-4-6',
    ApiFormat.claude,
    ModelPricing(inputPrice: 5.00, cachedInputPrice: 0.50, outputPrice: 25.00),
  ),
  claudeSonnet46(
    'Claude Sonnet 4.6',
    ChatModelProvider.anthropic,
    'claude-sonnet-4-6',
    ApiFormat.claude,
    ModelPricing(inputPrice: 3.00, cachedInputPrice: 0.30, outputPrice: 15.00),
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
  );

  final String displayName;
  final ChatModelProvider provider;
  final String modelId;
  final ApiFormat apiFormat;
  final ModelPricing pricing;

  const ChatModel(this.displayName, this.provider, this.modelId, this.apiFormat, this.pricing);

  static List<ChatModel> getModelsByProvider(ChatModelProvider provider) {
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
    final resolved = tryResolveStored(storedValue);
    if (resolved != null) return resolved;
    // Legacy: geminiPro3Preview → redirect to 3.1 Pro Preview
    if (storedValue == 'geminiPro3Preview' || storedValue == 'gemini-3-pro-preview') {
      return ChatModel.geminiPro31Preview;
    }
    if (storedValue == 'vertexGeminiPro3Preview') {
      return ChatModel.vertexGeminiPro31Preview;
    }
    return ChatModel.geminiFlash3Preview;
  }

  /// Exact match on a stored enum name or model ID. A retired model resolves
  /// to its [RetiredChatModel.successor]; anything else unknown is null.
  static ChatModel? tryResolveStored(String storedValue) {
    for (final model in ChatModel.values) {
      if (model.name == storedValue) return model;
    }
    final retired = RetiredChatModel.tryParse(storedValue);
    if (retired != null) return retired.successor;
    return fromModelId(storedValue);
  }

  /// Rewrites a saved UnifiedModel id so a retired model lands on its
  /// successor. Custom-model ids and current ids pass through unchanged.
  static String migrateStoredId(String storedId) =>
      RetiredChatModel.tryParse(storedId)?.successor.name ?? storedId;

  /// Pricing for a model ID found in message history. Also covers retired
  /// models, so past messages keep their real cost after removal.
  static ModelPricing? historicalPricing(String modelId) =>
      fromModelId(modelId)?.pricing ??
      RetiredChatModel.tryParse(modelId)?.pricing;

  static String? historicalDisplayName(String modelId) =>
      fromModelId(modelId)?.displayName ??
      RetiredChatModel.tryParse(modelId)?.displayName;
}

/// Built-in models removed after their provider shut them down. Each keeps
/// its old [ChatModel] name so saved selections still match, its price for
/// costing past messages, and the [successor] that saved choices move to.
enum RetiredChatModel {
  geminiFlashLite31Preview(
    'Gemini 3.1 Flash Lite Preview',
    'gemini-3.1-flash-lite-preview',
    ModelPricing(inputPrice: 0.25, cachedInputPrice: 0.025, outputPrice: 1.50),
    ChatModel.geminiFlashLite31,
  ),
  vertexGeminiFlashLite31Preview(
    'Gemini 3.1 Flash Lite Preview',
    'gemini-3.1-flash-lite-preview',
    ModelPricing(inputPrice: 0.25, cachedInputPrice: 0.025, outputPrice: 1.50),
    ChatModel.vertexGeminiFlashLite31,
  ),
  o1(
    'o1',
    'o1',
    ModelPricing(inputPrice: 15.00, cachedInputPrice: 7.50, outputPrice: 60.00),
    ChatModel.o3,
  ),
  o3Mini(
    'o3-mini',
    'o3-mini',
    ModelPricing(inputPrice: 1.10, cachedInputPrice: 0.55, outputPrice: 4.40),
    ChatModel.o3,
  ),
  // No later o-series mini exists; OpenAI's listed substitute is used.
  o4Mini(
    'o4-mini',
    'o4-mini',
    ModelPricing(inputPrice: 1.10, cachedInputPrice: 0.275, outputPrice: 4.40),
    ChatModel.gpt56Terra,
  ),
  claudeOpus4(
    'Claude Opus 4',
    'claude-opus-4-20250514',
    ModelPricing(inputPrice: 15.00, cachedInputPrice: 1.50, outputPrice: 75.00),
    ChatModel.claudeOpus48,
  ),
  claudeSonnet4(
    'Claude Sonnet 4',
    'claude-sonnet-4-20250514',
    ModelPricing(inputPrice: 3.00, cachedInputPrice: 0.30, outputPrice: 15.00),
    ChatModel.claudeSonnet55,
  ),
  claudeHaiku35(
    'Claude Haiku 3.5',
    'claude-3-5-haiku-20241022',
    ModelPricing(inputPrice: 0.80, cachedInputPrice: 0.08, outputPrice: 4.00),
    ChatModel.claudeHaiku45,
  );

  final String displayName;
  final String modelId;
  final ModelPricing pricing;
  final ChatModel successor;

  const RetiredChatModel(this.displayName, this.modelId, this.pricing, this.successor);

  /// Matches an old enum name first, then a model ID. The ID shared by the
  /// AI Studio and Gemini Enterprise previews resolves to the AI Studio
  /// entry, mirroring [ChatModel.fromModelId]'s first-match rule.
  static RetiredChatModel? tryParse(String value) {
    for (final model in RetiredChatModel.values) {
      if (model.name == value) return model;
    }
    for (final model in RetiredChatModel.values) {
      if (model.modelId == value) return model;
    }
    return null;
  }
}
