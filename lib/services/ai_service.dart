import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat/chat_log.dart';
import '../models/chat/chat_message.dart';
import '../models/chat/chat_model.dart';
import '../models/chat/unified_model.dart';
import '../models/prompt/prompt_parameters.dart';
import '../database/database_helper.dart';
import 'format_converter.dart';

class AiResponse {
  final String text;
  final UsageMetadata? usageMetadata;
  final String? modelId;

  const AiResponse({
    required this.text,
    this.usageMetadata,
    this.modelId,
  });
}

class AiService {
  static const String _geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const String _openaiBaseUrl = 'https://api.openai.com';
  static const String _claudeBaseUrl = 'https://api.anthropic.com';

  final DatabaseHelper _db = DatabaseHelper.instance;

  static const List<Map<String, String>> _geminiSafetySettings = [
    {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
    {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_NONE'},
    {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_NONE'},
    {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_NONE'},
    {'category': 'HARM_CATEGORY_CIVIC_INTEGRITY', 'threshold': 'BLOCK_NONE'},
  ];

  Future<String> getApiKey(String apiKeyType) async {
    final prefs = await SharedPreferences.getInstance();

    // Migration: old single 'api_key' → 'api_key_google'
    final legacyKey = prefs.getString('api_key');
    if (legacyKey != null && legacyKey.isNotEmpty) {
      final googleKey = prefs.getString('api_key_google');
      if (googleKey == null || googleKey.isEmpty) {
        await prefs.setString('api_key_google', legacyKey);
      }
    }

    // Try multi-key storage first
    final multiKeys = prefs.getString('api_keys_$apiKeyType');
    if (multiKeys != null) {
      final List<dynamic> keys = jsonDecode(multiKeys);
      if (keys.isNotEmpty) {
        final activeIndex =
            (prefs.getInt('api_key_active_$apiKeyType') ?? 0)
                .clamp(0, keys.length - 1);
        return keys[activeIndex] as String;
      }
    }

    // Fallback to single key storage
    final key = prefs.getString('api_key_$apiKeyType');
    if (key == null || key.isEmpty) {
      throw Exception('API 키가 설정되지 않았습니다 ($apiKeyType)');
    }
    return key;
  }

  Future<AiResponse> sendMessage({
    required String systemPrompt,
    required List<Map<String, dynamic>> contents,
    required UnifiedModel model,
    PromptParameters? promptParameters,
    int? chatRoomId,
    int? characterId,
    String logType = 'ai',
  }) async {
    final apiKey = await getApiKey(model.apiKeyType);

    switch (model.apiFormat) {
      case ApiFormat.gemini:
        return _sendGemini(
          systemPrompt: systemPrompt,
          contents: contents,
          modelId: model.modelId,
          apiKey: apiKey,
          promptParameters: promptParameters,
          chatRoomId: chatRoomId,
          characterId: characterId,
          logType: logType,
        );
      case ApiFormat.openai:
        return _sendOpenAI(
          systemPrompt: systemPrompt,
          contents: contents,
          modelId: model.modelId,
          apiKey: apiKey,
          baseUrl: model.baseUrl ?? _openaiBaseUrl,
          promptParameters: promptParameters,
          chatRoomId: chatRoomId,
          characterId: characterId,
          logType: logType,
        );
      case ApiFormat.claude:
        return _sendClaude(
          systemPrompt: systemPrompt,
          contents: contents,
          modelId: model.modelId,
          apiKey: apiKey,
          baseUrl: model.baseUrl ?? _claudeBaseUrl,
          promptParameters: promptParameters,
          chatRoomId: chatRoomId,
          characterId: characterId,
          logType: logType,
        );
    }
  }

  // ── Gemini ──

  Future<AiResponse> _sendGemini({
    required String systemPrompt,
    required List<Map<String, dynamic>> contents,
    required String modelId,
    required String apiKey,
    PromptParameters? promptParameters,
    int? chatRoomId,
    int? characterId,
    String logType = 'gemini',
  }) async {
    final generationConfig = _buildGeminiGenerationConfig(promptParameters);

    final requestBody = {
      'model': modelId,
      if (systemPrompt.isNotEmpty)
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt}
          ]
        },
      if (generationConfig != null) 'generationConfig': generationConfig,
      'safetySettings': _geminiSafetySettings,
      'contents': contents,
    };

    final requestJson = jsonEncode(requestBody);
    final startTime = DateTime.now();

    try {
      final url = Uri.parse(
          '$_geminiBaseUrl/$modelId:generateContent?key=$apiKey');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: requestJson,
      );

      if (response.statusCode != 200) {
        throw Exception(
            'API 요청 실패: ${response.statusCode} - ${response.body}');
      }

      final responseData = jsonDecode(response.body);
      final text = _extractGeminiText(responseData);
      final usageMetadata = _extractGeminiUsageMetadata(responseData);

      if (text.isEmpty) {
        debugPrint(
            'Empty AI response - status: ${response.statusCode}, body: ${response.body}');
        await _saveChatLog(
          request: requestJson,
          response: response.body,
          timestamp: startTime,
          chatRoomId: chatRoomId,
          characterId: characterId,
          type: logType,
        );
        final blockReason =
            responseData['promptFeedback']?['blockReason'] as String?;
        if (blockReason != null) {
          throw Exception('AI 응답이 차단되었습니다 (사유: $blockReason)');
        }
        throw Exception('AI 응답을 받지 못했습니다');
      }

      await _saveChatLog(
        request: requestJson,
        response: response.body,
        timestamp: startTime,
        chatRoomId: chatRoomId,
        characterId: characterId,
        type: logType,
      );

      return AiResponse(
          text: text, usageMetadata: usageMetadata, modelId: modelId);
    } catch (e) {
      await _saveChatLog(
        request: requestJson,
        response: 'Error: $e',
        timestamp: startTime,
        chatRoomId: chatRoomId,
        characterId: characterId,
        type: logType,
      );
      rethrow;
    }
  }

  Map<String, dynamic>? _buildGeminiGenerationConfig(
      PromptParameters? parameters) {
    if (parameters == null) return null;

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
    if (parameters.presencePenalty != null &&
        parameters.presencePenalty != 0.0) {
      config['presencePenalty'] = parameters.presencePenalty;
    }
    if (parameters.frequencyPenalty != null &&
        parameters.frequencyPenalty != 0.0) {
      config['frequencyPenalty'] = parameters.frequencyPenalty;
    }
    if (parameters.includeThoughts != null) {
      config['includeThoughts'] = parameters.includeThoughts;
    }
    if (parameters.thinkingMaxTokens != null ||
        parameters.thinkingLevel != null) {
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

  String _extractGeminiText(Map<String, dynamic> response) {
    try {
      final candidates = response['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) return '';
      final content = candidates[0]['content'];
      final parts = content['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) return '';
      return parts[0]['text'] as String? ?? '';
    } catch (e) {
      return '';
    }
  }

  UsageMetadata? _extractGeminiUsageMetadata(Map<String, dynamic> response) {
    try {
      final usage = response['usageMetadata'] as Map<String, dynamic>?;
      if (usage == null) return null;
      return UsageMetadata.fromJson(usage);
    } catch (e) {
      return null;
    }
  }

  // ── OpenAI ──

  Future<AiResponse> _sendOpenAI({
    required String systemPrompt,
    required List<Map<String, dynamic>> contents,
    required String modelId,
    required String apiKey,
    required String baseUrl,
    PromptParameters? promptParameters,
    int? chatRoomId,
    int? characterId,
    String logType = 'openai',
  }) async {
    final messages =
        FormatConverter.toOpenAIMessages(systemPrompt, contents);

    final requestBody = <String, dynamic>{
      'model': modelId,
      'messages': messages,
    };

    if (promptParameters != null) {
      if (promptParameters.maxOutputTokens != null) {
        requestBody['max_tokens'] = promptParameters.maxOutputTokens;
      }
      if (promptParameters.temperature != null) {
        requestBody['temperature'] = promptParameters.temperature;
      }
      if (promptParameters.topP != null) {
        requestBody['top_p'] = promptParameters.topP;
      }
      if (promptParameters.presencePenalty != null &&
          promptParameters.presencePenalty != 0.0) {
        requestBody['presence_penalty'] = promptParameters.presencePenalty;
      }
      if (promptParameters.frequencyPenalty != null &&
          promptParameters.frequencyPenalty != 0.0) {
        requestBody['frequency_penalty'] = promptParameters.frequencyPenalty;
      }
    }

    final requestJson = jsonEncode(requestBody);
    final startTime = DateTime.now();

    try {
      final url = Uri.parse('$baseUrl/v1/chat/completions');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: requestJson,
      );

      if (response.statusCode != 200) {
        throw Exception(
            'API 요청 실패: ${response.statusCode} - ${response.body}');
      }

      final responseData = jsonDecode(response.body);
      final text = _extractOpenAIText(responseData);
      final usageMetadata = _extractOpenAIUsageMetadata(responseData);

      if (text.isEmpty) {
        debugPrint(
            'Empty AI response - status: ${response.statusCode}, body: ${response.body}');
        await _saveChatLog(
          request: requestJson,
          response: response.body,
          timestamp: startTime,
          chatRoomId: chatRoomId,
          characterId: characterId,
          type: logType,
        );
        throw Exception('AI 응답을 받지 못했습니다');
      }

      await _saveChatLog(
        request: requestJson,
        response: response.body,
        timestamp: startTime,
        chatRoomId: chatRoomId,
        characterId: characterId,
        type: logType,
      );

      return AiResponse(
          text: text, usageMetadata: usageMetadata, modelId: modelId);
    } catch (e) {
      await _saveChatLog(
        request: requestJson,
        response: 'Error: $e',
        timestamp: startTime,
        chatRoomId: chatRoomId,
        characterId: characterId,
        type: logType,
      );
      rethrow;
    }
  }

  String _extractOpenAIText(Map<String, dynamic> response) {
    try {
      final choices = response['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) return '';
      final message = choices[0]['message'] as Map<String, dynamic>?;
      return message?['content'] as String? ?? '';
    } catch (e) {
      return '';
    }
  }

  UsageMetadata? _extractOpenAIUsageMetadata(Map<String, dynamic> response) {
    try {
      final usage = response['usage'] as Map<String, dynamic>?;
      if (usage == null) return null;
      final promptTokens = usage['prompt_tokens'] as int? ?? 0;
      final completionTokens = usage['completion_tokens'] as int? ?? 0;
      final totalTokens = usage['total_tokens'] as int? ?? 0;
      return UsageMetadata(
        promptTokenCount: promptTokens,
        candidatesTokenCount: completionTokens,
        totalTokenCount: totalTokens,
      );
    } catch (e) {
      return null;
    }
  }

  // ── Claude ──

  Future<AiResponse> _sendClaude({
    required String systemPrompt,
    required List<Map<String, dynamic>> contents,
    required String modelId,
    required String apiKey,
    required String baseUrl,
    PromptParameters? promptParameters,
    int? chatRoomId,
    int? characterId,
    String logType = 'claude',
  }) async {
    final converted =
        FormatConverter.toClaudeMessages(systemPrompt, contents);

    final requestBody = <String, dynamic>{
      'model': modelId,
      'messages': converted.messages,
      'max_tokens': promptParameters?.maxOutputTokens ?? 4096,
    };

    if (converted.systemPrompt.isNotEmpty) {
      requestBody['system'] = converted.systemPrompt;
    }

    if (promptParameters != null) {
      if (promptParameters.temperature != null) {
        requestBody['temperature'] = promptParameters.temperature;
      }
      if (promptParameters.topP != null) {
        requestBody['top_p'] = promptParameters.topP;
      }
      if (promptParameters.topK != null) {
        requestBody['top_k'] = promptParameters.topK;
      }
    }

    final requestJson = jsonEncode(requestBody);
    final startTime = DateTime.now();

    try {
      final url = Uri.parse('$baseUrl/v1/messages');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: requestJson,
      );

      if (response.statusCode != 200) {
        throw Exception(
            'API 요청 실패: ${response.statusCode} - ${response.body}');
      }

      final responseData = jsonDecode(response.body);
      final text = _extractClaudeText(responseData);
      final usageMetadata = _extractClaudeUsageMetadata(responseData);

      if (text.isEmpty) {
        debugPrint(
            'Empty AI response - status: ${response.statusCode}, body: ${response.body}');
        await _saveChatLog(
          request: requestJson,
          response: response.body,
          timestamp: startTime,
          chatRoomId: chatRoomId,
          characterId: characterId,
          type: logType,
        );
        throw Exception('AI 응답을 받지 못했습니다');
      }

      await _saveChatLog(
        request: requestJson,
        response: response.body,
        timestamp: startTime,
        chatRoomId: chatRoomId,
        characterId: characterId,
        type: logType,
      );

      return AiResponse(
          text: text, usageMetadata: usageMetadata, modelId: modelId);
    } catch (e) {
      await _saveChatLog(
        request: requestJson,
        response: 'Error: $e',
        timestamp: startTime,
        chatRoomId: chatRoomId,
        characterId: characterId,
        type: logType,
      );
      rethrow;
    }
  }

  String _extractClaudeText(Map<String, dynamic> response) {
    try {
      final content = response['content'] as List<dynamic>?;
      if (content == null || content.isEmpty) return '';
      final buffer = StringBuffer();
      for (final block in content) {
        if (block is Map<String, dynamic> && block['type'] == 'text') {
          if (buffer.isNotEmpty) buffer.write('\n');
          buffer.write(block['text'] as String? ?? '');
        }
      }
      return buffer.toString();
    } catch (e) {
      return '';
    }
  }

  UsageMetadata? _extractClaudeUsageMetadata(Map<String, dynamic> response) {
    try {
      final usage = response['usage'] as Map<String, dynamic>?;
      if (usage == null) return null;
      final inputTokens = usage['input_tokens'] as int? ?? 0;
      final outputTokens = usage['output_tokens'] as int? ?? 0;
      return UsageMetadata(
        promptTokenCount: inputTokens,
        candidatesTokenCount: outputTokens,
        totalTokenCount: inputTokens + outputTokens,
      );
    } catch (e) {
      return null;
    }
  }

  // ── Chat log ──

  Future<void> _saveChatLog({
    required String request,
    required String response,
    required DateTime timestamp,
    int? chatRoomId,
    int? characterId,
    String type = 'ai',
  }) async {
    try {
      final log = ChatLog(
        timestamp: timestamp,
        type: type,
        request: request,
        response: response,
        chatRoomId: chatRoomId,
        characterId: characterId,
      );
      await _db.createChatLog(log);
    } catch (e) {
      // Log save failure is non-critical
    }
  }
}
