import 'chat_model.dart';
import 'custom_model.dart';

class UnifiedModel {
  final String id;
  final String displayName;
  final String modelId;
  final ApiFormat apiFormat;
  final ChatModelProvider provider;
  final ModelPricing pricing;
  final String? baseUrl;
  final String apiKeyType;
  final bool isCustom;

  const UnifiedModel({
    required this.id,
    required this.displayName,
    required this.modelId,
    required this.apiFormat,
    required this.provider,
    required this.pricing,
    this.baseUrl,
    required this.apiKeyType,
    this.isCustom = false,
  });

  factory UnifiedModel.fromChatModel(ChatModel model) => UnifiedModel(
        id: model.name,
        displayName: model.displayName,
        modelId: model.modelId,
        apiFormat: model.apiFormat,
        provider: model.provider,
        pricing: model.pricing,
        apiKeyType: _apiKeyTypeForProvider(model.provider),
      );

  factory UnifiedModel.fromCustomModel(CustomModel model) => UnifiedModel(
        id: 'custom:${model.id}',
        displayName: model.displayName,
        modelId: model.modelId,
        apiFormat: model.apiFormat,
        provider: ChatModelProvider.custom,
        pricing: model.pricing,
        baseUrl: model.baseUrl,
        apiKeyType: model.apiKeyType,
        isCustom: true,
      );

  static String _apiKeyTypeForProvider(ChatModelProvider provider) {
    switch (provider) {
      case ChatModelProvider.googleAIStudio:
        return 'google';
      case ChatModelProvider.vertexAi:
        return 'vertex_ai';
      case ChatModelProvider.openai:
        return 'openai';
      case ChatModelProvider.anthropic:
        return 'anthropic';
      default:
        return 'openai';
    }
  }

  static List<UnifiedModel> allBuiltIn() =>
      ChatModel.values.map((m) => UnifiedModel.fromChatModel(m)).toList();

  static List<UnifiedModel> getByProvider(
    ChatModelProvider provider,
    List<CustomModel> customModels,
  ) {
    final builtIn = ChatModel.getModelsByProvider(provider)
        .map((m) => UnifiedModel.fromChatModel(m))
        .toList();

    if (provider == ChatModelProvider.all) {
      return [
        ...builtIn,
        ...customModels.map((m) => UnifiedModel.fromCustomModel(m)),
      ];
    }

    if (provider == ChatModelProvider.custom) {
      return customModels.map((m) => UnifiedModel.fromCustomModel(m)).toList();
    }

    return builtIn;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnifiedModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
