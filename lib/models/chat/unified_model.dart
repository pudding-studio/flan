import 'chat_model.dart';
import 'custom_model.dart';
import 'custom_provider.dart';

class UnifiedModel {
  final String id;
  final String displayName;
  final String modelId;
  final ApiFormat apiFormat;
  final ChatModelProvider provider;
  final ModelPricing pricing;
  final String? baseUrl;
  final String apiKeyType;
  final String? apiKey;
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
    this.apiKey,
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

  factory UnifiedModel.fromCustomModel(
    CustomModel model, {
    CustomProvider? provider,
  }) =>
      UnifiedModel(
        id: 'custom:${model.id}',
        displayName: model.displayName,
        modelId: model.modelId,
        apiFormat: provider?.apiFormat ?? model.apiFormat,
        provider: ChatModelProvider.custom,
        pricing: model.pricing,
        baseUrl: provider?.baseUrl ?? model.baseUrl,
        apiKeyType: model.apiKeyType,
        apiKey: provider?.apiKey ?? model.apiKey,
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
    List<CustomModel> customModels, [
    List<CustomProvider> customProviders = const [],
  ]) {
    final builtIn = ChatModel.getModelsByProvider(provider)
        .map((m) => UnifiedModel.fromChatModel(m))
        .toList();

    UnifiedModel resolveCustom(CustomModel m) {
      final cp = m.providerId != null
          ? customProviders
              .where((p) => p.id == m.providerId)
              .firstOrNull
          : null;
      return UnifiedModel.fromCustomModel(m, provider: cp);
    }

    if (provider == ChatModelProvider.custom) {
      return customModels.map(resolveCustom).toList();
    }

    return builtIn;
  }

  static List<UnifiedModel> getByCustomProvider(
    String customProviderId,
    List<CustomModel> customModels,
    List<CustomProvider> customProviders,
  ) {
    final cp =
        customProviders.where((p) => p.id == customProviderId).firstOrNull;
    return customModels
        .where((m) => m.providerId == customProviderId)
        .map((m) => UnifiedModel.fromCustomModel(m, provider: cp))
        .toList();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnifiedModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
