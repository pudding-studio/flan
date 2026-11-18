import 'package:shared_preferences/shared_preferences.dart';

/// How many times a failed request to a built-in provider is re-sent,
/// stored per provider (keyed like its API key, e.g. 'google', 'anthropic').
/// Custom providers keep their own count on [CustomProvider.retryCount].
class ProviderRetrySettings {
  static const int maxRetries = 10;

  static String _storageKey(String apiKeyType) => 'retry_count_$apiKeyType';

  static Future<int> read(String apiKeyType) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_storageKey(apiKeyType)) ?? 0;
    return stored.clamp(0, maxRetries);
  }

  static Future<void> write(String apiKeyType, int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_storageKey(apiKeyType), count.clamp(0, maxRetries));
  }
}
