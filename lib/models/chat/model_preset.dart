import 'chat_model.dart';
import 'custom_provider.dart';

enum ModelPreset {
  primary('주 모델'),
  secondary('보조 모델'),
  custom('기타');

  final String displayName;
  const ModelPreset(this.displayName);

  static ModelPreset fromString(String? value) {
    return ModelPreset.values.firstWhere(
      (p) => p.name == value,
      orElse: () => ModelPreset.primary,
    );
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
