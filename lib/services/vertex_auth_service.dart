import 'dart:convert';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class VertexAuthService {
  static const String _regionKey = 'vertex_ai_region';
  static const String _defaultRegion = 'us-central1';

  static final VertexAuthService _instance = VertexAuthService._();
  factory VertexAuthService() => _instance;
  VertexAuthService._();

  AccessCredentials? _cachedCredentials;
  String? _cachedJsonKey;

  /// Get the stored region or default.
  static Future<String> getRegion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_regionKey) ?? _defaultRegion;
  }

  /// Save the selected region.
  static Future<void> setRegion(String region) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_regionKey, region);
  }

  /// Extract project_id from service account JSON.
  static String? extractProjectId(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return json['project_id'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Extract client_email from service account JSON.
  static String? extractClientEmail(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return json['client_email'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Get a valid OAuth2 access token from service account JSON.
  /// Caches the token and refreshes when expired.
  Future<String> getAccessToken(String serviceAccountJson) async {
    // Reuse cached credentials if still valid
    if (_cachedCredentials != null &&
        _cachedJsonKey == serviceAccountJson &&
        _cachedCredentials!.accessToken.expiry
            .isAfter(DateTime.now().add(const Duration(minutes: 1)))) {
      return _cachedCredentials!.accessToken.data;
    }

    final credentials =
        ServiceAccountCredentials.fromJson(jsonDecode(serviceAccountJson));

    final scopes = ['https://www.googleapis.com/auth/cloud-platform'];
    final client = http.Client();

    try {
      final accessCredentials =
          await obtainAccessCredentialsViaServiceAccount(
        credentials,
        scopes,
        client,
      );

      _cachedCredentials = accessCredentials;
      _cachedJsonKey = serviceAccountJson;

      return accessCredentials.accessToken.data;
    } finally {
      client.close();
    }
  }

  /// Build the Vertex AI endpoint URL.
  static String buildEndpoint({
    required String projectId,
    required String region,
    required String modelId,
  }) {
    return 'https://$region-aiplatform.googleapis.com/v1/projects/$projectId/locations/$region/publishers/google/models/$modelId:generateContent';
  }

  /// Validate a service account JSON by attempting token acquisition.
  /// Returns null on success, or an error message on failure.
  static Future<String?> validateServiceAccountJson(
      String serviceAccountJson) async {
    try {
      final json = jsonDecode(serviceAccountJson) as Map<String, dynamic>;

      if (json['type'] != 'service_account') {
        return '서비스 계정 JSON이 아닙니다 (type != service_account)';
      }
      if (json['project_id'] == null) {
        return 'project_id가 없습니다';
      }
      if (json['private_key'] == null) {
        return 'private_key가 없습니다';
      }
      if (json['client_email'] == null) {
        return 'client_email이 없습니다';
      }

      // Try to obtain an access token
      final service = VertexAuthService();
      await service.getAccessToken(serviceAccountJson);

      return null;
    } on FormatException {
      return '유효하지 않은 JSON 형식입니다';
    } catch (e) {
      return '서비스 계정 인증 실패: $e';
    }
  }

  /// Invalidate cached credentials.
  void clearCache() {
    _cachedCredentials = null;
    _cachedJsonKey = null;
  }

  static const List<String> availableRegions = [
    'us-central1',
    'us-east4',
    'us-west1',
    'europe-west1',
    'europe-west4',
    'asia-northeast1',
    'asia-southeast1',
  ];
}
