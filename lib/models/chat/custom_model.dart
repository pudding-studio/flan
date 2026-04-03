import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_model.dart';

class CustomModel {
  final String id;
  final String displayName;
  final String modelId;
  final ApiFormat apiFormat;
  final String baseUrl;
  final String apiKey;
  final ModelPricing pricing;
  final String? providerId;

  const CustomModel({
    required this.id,
    required this.displayName,
    required this.modelId,
    this.apiFormat = ApiFormat.openai,
    this.baseUrl = '',
    this.apiKey = '',
    this.pricing = const ModelPricing.zero(),
    this.providerId,
  });

  /// Backward-compatible apiKeyType for UnifiedModel
  String get apiKeyType => 'custom';

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'modelId': modelId,
        'apiFormat': apiFormat.name,
        'baseUrl': baseUrl,
        'apiKey': apiKey,
        'pricing': pricing.toJson(),
        if (providerId != null) 'providerId': providerId,
      };

  factory CustomModel.fromJson(Map<String, dynamic> json) => CustomModel(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        modelId: json['modelId'] as String,
        apiFormat: ApiFormat.values.firstWhere(
          (f) => f.name == json['apiFormat'],
          orElse: () => ApiFormat.openai,
        ),
        baseUrl: json['baseUrl'] as String? ?? '',
        apiKey: json['apiKey'] as String? ?? '',
        pricing: json['pricing'] != null
            ? ModelPricing.fromJson(json['pricing'] as Map<String, dynamic>)
            : const ModelPricing.zero(),
        providerId: json['providerId'] as String?,
      );

  CustomModel copyWith({
    String? displayName,
    String? modelId,
    ApiFormat? apiFormat,
    String? baseUrl,
    String? apiKey,
    ModelPricing? pricing,
    String? providerId,
  }) =>
      CustomModel(
        id: id,
        displayName: displayName ?? this.displayName,
        modelId: modelId ?? this.modelId,
        apiFormat: apiFormat ?? this.apiFormat,
        baseUrl: baseUrl ?? this.baseUrl,
        apiKey: apiKey ?? this.apiKey,
        pricing: pricing ?? this.pricing,
        providerId: providerId ?? this.providerId,
      );
}

class CustomModelRepository {
  static const String _key = 'custom_models';

  static Future<List<CustomModel>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null || jsonString.isEmpty) return [];

    final list = jsonDecode(jsonString) as List<dynamic>;
    return list
        .map((e) => CustomModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveAll(List<CustomModel> models) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(models.map((m) => m.toJson()).toList());
    await prefs.setString(_key, jsonString);
  }

  static Future<void> add(CustomModel model) async {
    final models = await loadAll();
    models.add(model);
    await saveAll(models);
  }

  static Future<void> update(CustomModel model) async {
    final models = await loadAll();
    final index = models.indexWhere((m) => m.id == model.id);
    if (index != -1) {
      models[index] = model;
      await saveAll(models);
    }
  }

  static Future<void> delete(String id) async {
    final models = await loadAll();
    models.removeWhere((m) => m.id == id);
    await saveAll(models);
  }
}
