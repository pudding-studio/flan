import 'chat_model.dart';
import 'custom_provider.dart';
import 'unified_model.dart';
import '../../providers/chat_model_provider.dart';

enum ModelPreset {
  primary('Primary Model'),
  secondary('Secondary Model'),
  custom('Custom');

  final String displayName;
  const ModelPreset(this.displayName);

  static ModelPreset fromString(String? value) {
    return ModelPreset.values.firstWhere(
      (p) => p.name == value,
      orElse: () => ModelPreset.primary,
    );
  }

  /// Resolves the active model based on a feature-specific provider's preset
  /// and the global chat model settings.
  static Future<UnifiedModel> resolveModel({
    required Future<void> featureInitialized,
    required ModelPreset preset,
    required UnifiedModel customModel,
    required ChatModelSettingsProvider chatProvider,
  }) async {
    await featureInitialized;
    await chatProvider.initialized;
    switch (preset) {
      case ModelPreset.primary:
        return chatProvider.selectedModel;
      case ModelPreset.secondary:
        return chatProvider.subModel;
      case ModelPreset.custom:
        return customModel;
    }
  }
}

/// Unified dropdown item for built-in providers and custom providers.
class ProviderOption {
  final ChatModelProvider? builtInProvider;
  final String? customProviderId;
  final String displayName;

  const ProviderOption._({
    this.builtInProvider,
    this.customProviderId,
    required this.displayName,
  });

  factory ProviderOption.builtIn(ChatModelProvider provider) =>
      ProviderOption._(
          builtInProvider: provider, displayName: provider.displayName);

  factory ProviderOption.customProvider(CustomProvider cp) =>
      ProviderOption._(customProviderId: cp.id, displayName: cp.name);

  bool get isCustom => customProviderId != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProviderOption &&
          builtInProvider == other.builtInProvider &&
          customProviderId == other.customProviderId;

  @override
  int get hashCode => Object.hash(builtInProvider, customProviderId);

  /// Build provider options list: built-in providers (excluding 'custom')
  /// plus individual custom providers by name.
  static List<ProviderOption> buildOptions(
      List<CustomProvider> customProviders) {
    return [
      ...ChatModelProvider.values
          .where((p) => p != ChatModelProvider.custom)
          .map((p) => ProviderOption.builtIn(p)),
      ...customProviders.map((cp) => ProviderOption.customProvider(cp)),
    ];
  }
}
