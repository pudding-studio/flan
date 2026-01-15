import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat/chat_message.dart';
import '../models/chat/chat_log.dart';
import '../database/database_helper.dart';

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

  Future<String> sendMessage({
    required String systemPrompt,
    required List<ChatMessage> chatHistory,
    required String userMessage,
    int? chatRoomId,
    int? characterId,
  }) async {
    final modelId = await _getSelectedModelId();
    final apiKey = await _getApiKey();

    final contents = _buildContents(
      systemPrompt: systemPrompt,
      chatHistory: chatHistory,
      userMessage: userMessage,
    );

    final requestBody = {
      'model': modelId,
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

      if (text.isEmpty) {
        throw Exception('AI 응답을 받지 못했습니다');
      }

      await _saveChatLog(
        request: requestJson,
        response: text,
        timestamp: startTime,
        chatRoomId: chatRoomId,
        characterId: characterId,
      );

      return text;
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

  Stream<String> sendMessageStream({
    required String systemPrompt,
    required List<ChatMessage> chatHistory,
    required String userMessage,
  }) async* {
    final modelId = await _getSelectedModelId();
    final apiKey = await _getApiKey();

    final contents = _buildContents(
      systemPrompt: systemPrompt,
      chatHistory: chatHistory,
      userMessage: userMessage,
    );

    final requestBody = {
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

  List<Map<String, dynamic>> _buildContents({
    required String systemPrompt,
    required List<ChatMessage> chatHistory,
    required String userMessage,
  }) {
    final contents = <Map<String, dynamic>>[];

    if (systemPrompt.isNotEmpty) {
      contents.add({
        'role': 'user',
        'parts': [
          {'text': systemPrompt}
        ]
      });
      contents.add({
        'role': 'model',
        'parts': [
          {'text': '알겠습니다. 지정된 캐릭터로 대화하겠습니다.'}
        ]
      });
    }

    for (final message in chatHistory) {
      if (message.role == MessageRole.user) {
        contents.add({
          'role': 'user',
          'parts': [
            {'text': message.content}
          ]
        });
      } else if (message.role == MessageRole.assistant) {
        contents.add({
          'role': 'model',
          'parts': [
            {'text': message.content}
          ]
        });
      }
    }

    contents.add({
      'role': 'user',
      'parts': [
        {'text': userMessage}
      ]
    });

    return contents;
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
