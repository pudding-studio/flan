import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_model.dart';

class CustomProvider {
  final String id;
  final String name;
  final String baseUrl;
  final String apiKey;
  final ApiFormat apiFormat;
  final int retryCount;

  const CustomProvider({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.apiKey,
    this.apiFormat = ApiFormat.openai,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'baseUrl': baseUrl,
        'apiKey': apiKey,
        'apiFormat': apiFormat.name,
        'retryCount': retryCount,
      };

  factory CustomProvider.fromJson(Map<String, dynamic> json) => CustomProvider(
        id: json['id'] as String,
        name: json['name'] as String,
        baseUrl: json['baseUrl'] as String? ?? '',
        apiKey: json['apiKey'] as String? ?? '',
        apiFormat: ApiFormat.values.firstWhere(
          (f) => f.name == json['apiFormat'],
          orElse: () => ApiFormat.openai,
        ),
        retryCount: json['retryCount'] as int? ?? 0,
      );

  CustomProvider copyWith({
    String? name,
    String? baseUrl,
    String? apiKey,
    ApiFormat? apiFormat,
    int? retryCount,
  }) =>
      CustomProvider(
        id: id,
        name: name ?? this.name,
        baseUrl: baseUrl ?? this.baseUrl,
        apiKey: apiKey ?? this.apiKey,
        apiFormat: apiFormat ?? this.apiFormat,
        retryCount: retryCount ?? this.retryCount,
      );
}

class CustomProviderRepository {
  static const String _key = 'custom_providers';

  static Future<List<CustomProvider>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null || jsonString.isEmpty) return [];

    final list = jsonDecode(jsonString) as List<dynamic>;
    return list
        .map((e) => CustomProvider.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveAll(List<CustomProvider> providers) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString =
        jsonEncode(providers.map((p) => p.toJson()).toList());
    await prefs.setString(_key, jsonString);
  }

  static Future<void> add(CustomProvider provider) async {
    final providers = await loadAll();
    providers.add(provider);
    await saveAll(providers);
  }

  static Future<void> update(CustomProvider provider) async {
    final providers = await loadAll();
    final index = providers.indexWhere((p) => p.id == provider.id);
    if (index != -1) {
      providers[index] = provider;
      await saveAll(providers);
    }
  }

  static Future<void> delete(String id) async {
    final providers = await loadAll();
    providers.removeWhere((p) => p.id == id);
    await saveAll(providers);
  }
}
