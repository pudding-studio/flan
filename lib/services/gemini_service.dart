import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat/chat_log.dart';
import '../models/chat/chat_message.dart';
import '../models/prompt/prompt_parameters.dart';
import '../database/database_helper.dart';

class GeminiResponse {
  final String text;
  final UsageMetadata? usageMetadata;
  final String? modelId;

  const GeminiResponse({
    required this.text,
    this.usageMetadata,
    this.modelId,
  });
}

class GeminiService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<String> _getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('api_key');

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API 키가 설정되지 않았습니다');
    }

    return apiKey;
  }

  Future<String> _getSelectedModelId() async {
    final prefs = await SharedPreferences.getInstance();
    final modelString = prefs.getString('chat_model');

    if (modelString == null) {
      return 'gemini-3-pro-preview';
    }

    switch (modelString) {
      case 'geminiPro3Preview':
        return 'gemini-3-pro-preview';
      case 'geminiFlash3Preview':
        return 'gemini-3-flash-preview';
      case 'geminiPro25':
        return 'gemini-2.5-pro';
      case 'geminiFlash25':
        return 'gemini-2.5-flash';
      case 'geminiFlashLite25':
        return 'gemini-2.5-flash-lite';
      default:
        return 'gemini-3-pro-preview';
    }
  }

  Map<String, dynamic>? _buildGenerationConfig(PromptParameters? parameters) {
    if (parameters == null) {
      return null;
    }

    final config = <String, dynamic>{};

    if (parameters.maxOutputTokens != null) {
      config['maxOutputTokens'] = parameters.maxOutputTokens;
    }

    if (parameters.temperature != null) {
      config['temperature'] = parameters.temperature;
    }

    if (parameters.topP != null) {
      config['topP'] = parameters.topP;
    }

    if (parameters.topK != null) {
      config['topK'] = parameters.topK;
    }

    if (parameters.presencePenalty != null && parameters.presencePenalty != 0.0) {
      config['presencePenalty'] = parameters.presencePenalty;
    }

    if (parameters.frequencyPenalty != null && parameters.frequencyPenalty != 0.0) {
      config['frequencyPenalty'] = parameters.frequencyPenalty;
    }

    if (parameters.includeThoughts != null) {
      config['includeThoughts'] = parameters.includeThoughts;
    }

    if (parameters.thinkingMaxTokens != null || parameters.thinkingLevel != null) {
      final thinkingConfig = <String, dynamic>{};

      if (parameters.thinkingMaxTokens != null) {
        thinkingConfig['thinkingMaxTokens'] = parameters.thinkingMaxTokens;
      }

      if (parameters.thinkingLevel != null) {
        thinkingConfig['thinkingLevel'] = parameters.thinkingLevel!.apiValue;
      }

      if (thinkingConfig.isNotEmpty) {
        config['thinkingConfig'] = thinkingConfig;
      }
    }

    return config.isEmpty ? null : config;
  }

  Future<GeminiResponse> sendMessage({
    required String systemPrompt,
    required List<Map<String, dynamic>> contents,
    PromptParameters? promptParameters,
    int? chatRoomId,
    int? characterId,
  }) async {
    final modelId = await _getSelectedModelId();
    final apiKey = await _getApiKey();
    final generationConfig = _buildGenerationConfig(promptParameters);

    final requestBody = {
      'model': modelId,
      if (systemPrompt.isNotEmpty)
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt}
          ]
        },
      if (generationConfig != null) 'generationConfig': generationConfig,
      'contents': contents,
    };

    final requestJson = jsonEncode(requestBody);
    final startTime = DateTime.now();

    try {
      final url = Uri.parse('$_baseUrl/$modelId:generateContent?key=$apiKey');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: requestJson,
      );

      if (response.statusCode != 200) {
        throw Exception('API 요청 실패: ${response.statusCode} - ${response.body}');
      }

      final responseData = jsonDecode(response.body);
      final text = _extractTextFromResponse(responseData);
      final usageMetadata = _extractUsageMetadata(responseData);

      if (text.isEmpty) {
        throw Exception('AI 응답을 받지 못했습니다');
      }

      await _saveChatLog(
        request: requestJson,
        response: response.body,
        timestamp: startTime,
        chatRoomId: chatRoomId,
        characterId: characterId,
      );

      return GeminiResponse(text: text, usageMetadata: usageMetadata, modelId: modelId);
    } catch (e) {
      await _saveChatLog(
        request: requestJson,
        response: 'Error: $e',
        timestamp: startTime,
        chatRoomId: chatRoomId,
        characterId: characterId,
      );
      rethrow;
    }
  }

  String _extractTextFromResponse(Map<String, dynamic> response) {
    try {
      final candidates = response['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        return '';
      }

      final content = candidates[0]['content'];
      final parts = content['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        return '';
      }

      return parts[0]['text'] as String? ?? '';
    } catch (e) {
      return '';
    }
  }

  UsageMetadata? _extractUsageMetadata(Map<String, dynamic> response) {
    try {
      final usageMetadata = response['usageMetadata'] as Map<String, dynamic>?;
      if (usageMetadata == null) {
        return null;
      }
      return UsageMetadata.fromJson(usageMetadata);
    } catch (e) {
      return null;
    }
  }

  Stream<String> sendMessageStream({
    required String systemPrompt,
    required List<Map<String, dynamic>> contents,
    PromptParameters? promptParameters,
  }) async* {
    final modelId = await _getSelectedModelId();
    final apiKey = await _getApiKey();
    final generationConfig = _buildGenerationConfig(promptParameters);

    final requestBody = {
      'model': modelId,
      if (systemPrompt.isNotEmpty)
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt}
          ]
        },
      if (generationConfig != null) 'generationConfig': generationConfig,
      'contents': contents,
    };

    final url = Uri.parse('$_baseUrl/$modelId:streamGenerateContent?alt=sse&key=$apiKey');
    final request = http.Request('POST', url);
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode(requestBody);

    final streamedResponse = await request.send();

    if (streamedResponse.statusCode != 200) {
      throw Exception('API 요청 실패: ${streamedResponse.statusCode}');
    }

    await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
      final lines = chunk.split('\n');
      for (final line in lines) {
        if (line.startsWith('data: ')) {
          final jsonStr = line.substring(6);
          if (jsonStr.trim().isEmpty) continue;

          try {
            final data = jsonDecode(jsonStr);
            final text = _extractTextFromResponse(data);
            if (text.isNotEmpty) {
              yield text;
            }
          } catch (e) {
            continue;
          }
        }
      }
    }
  }

  Future<void> _saveChatLog({
    required String request,
    required String response,
    required DateTime timestamp,
    int? chatRoomId,
    int? characterId,
  }) async {
    try {
      final log = ChatLog(
        timestamp: timestamp,
        type: 'gemini',
        request: request,
        response: response,
        chatRoomId: chatRoomId,
        characterId: characterId,
      );
      await _db.createChatLog(log);
    } catch (e) {
      // 로그 저장 실패는 무시
    }
  }
}
