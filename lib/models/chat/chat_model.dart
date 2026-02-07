enum ChatModelProvider {
  all('ALL'),
  googleAIStudio('Google AIstudio');

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
}

enum ChatModel {
  geminiPro3Preview(
    'Gemini 3 Pro Preview',
    ChatModelProvider.googleAIStudio,
    'gemini-3-pro-preview',
    ModelPricing(inputPrice: 2.00, cachedInputPrice: 0.20, outputPrice: 12.00),
  ),
  geminiFlash3Preview(
    'Gemini 3 Flash Preview',
    ChatModelProvider.googleAIStudio,
    'gemini-3-flash-preview',
    ModelPricing(inputPrice: 0.50, cachedInputPrice: 0.05, outputPrice: 3.00),
  ),
  geminiPro25(
    'Gemini 2.5 Pro',
    ChatModelProvider.googleAIStudio,
    'gemini-2.5-pro',
    ModelPricing(inputPrice: 1.25, cachedInputPrice: 0.125, outputPrice: 10.00),
  ),
  geminiFlash25(
    'Gemini 2.5 Flash',
    ChatModelProvider.googleAIStudio,
    'gemini-2.5-flash',
    ModelPricing(inputPrice: 0.15, cachedInputPrice: 0.015, outputPrice: 0.60, thinkingOutputPrice: 3.50),
  ),
  geminiFlashLite25(
    'Gemini 2.5 Flash Lite',
    ChatModelProvider.googleAIStudio,
    'gemini-2.5-flash-lite',
    ModelPricing(inputPrice: 0.10, cachedInputPrice: 0.010, outputPrice: 0.40),
  );

  final String displayName;
  final ChatModelProvider provider;
  final String modelId;
  final ModelPricing pricing;

  const ChatModel(this.displayName, this.provider, this.modelId, this.pricing);

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
}
