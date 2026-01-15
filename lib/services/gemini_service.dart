import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat/chat_message.dart';
import '../models/chat/chat_log.dart';
import '../database/database_helper.dart';

class GeminiService {
  static const String _defaultModel = 'gemini-2.0-flash-exp';

  GenerativeModel? _model;
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<void> _initializeModel() async {
    if (_model != null) return;

    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('api_key');

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API 키가 설정되지 않았습니다');
    }

    _model = GenerativeModel(
      model: _defaultModel,
      apiKey: apiKey,
    );
  }

  Future<String> sendMessage({
    required String systemPrompt,
    required List<ChatMessage> chatHistory,
    required String userMessage,
    int? chatRoomId,
    int? characterId,
  }) async {
    await _initializeModel();

    final contents = _buildContents(
      systemPrompt: systemPrompt,
      chatHistory: chatHistory,
      userMessage: userMessage,
    );

    final requestJson = _buildRequestJson(contents);
    final startTime = DateTime.now();

    try {
      final response = await _model!.generateContent(contents);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('AI 응답을 받지 못했습니다');
      }

      await _saveChatLog(
        request: requestJson,
        response: response.text!,
        timestamp: startTime,
        chatRoomId: chatRoomId,
        characterId: characterId,
      );

      return response.text!;
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

  Stream<String> sendMessageStream({
    required String systemPrompt,
    required List<ChatMessage> chatHistory,
    required String userMessage,
  }) async* {
    await _initializeModel();

    final contents = _buildContents(
      systemPrompt: systemPrompt,
      chatHistory: chatHistory,
      userMessage: userMessage,
    );

    final response = _model!.generateContentStream(contents);

    await for (final chunk in response) {
      if (chunk.text != null && chunk.text!.isNotEmpty) {
        yield chunk.text!;
      }
    }
  }

  List<Content> _buildContents({
    required String systemPrompt,
    required List<ChatMessage> chatHistory,
    required String userMessage,
  }) {
    final contents = <Content>[];

    if (systemPrompt.isNotEmpty) {
      contents.add(Content.text(systemPrompt));
      contents.add(Content.model([TextPart('알겠습니다. 지정된 캐릭터로 대화하겠습니다.')]));
    }

    for (final message in chatHistory) {
      if (message.role == MessageRole.user) {
        contents.add(Content.text(message.content));
      } else if (message.role == MessageRole.assistant) {
        contents.add(Content.model([TextPart(message.content)]));
      }
    }

    contents.add(Content.text(userMessage));

    return contents;
  }

  String _buildRequestJson(List<Content> contents) {
    final request = {
      'model': _defaultModel,
      'contents': contents.map((content) {
        return {
          'role': content.role,
          'parts': content.parts.map((part) {
            if (part is TextPart) {
              return {'text': part.text};
            }
            return {};
          }).toList(),
        };
      }).toList(),
    };
    return jsonEncode(request);
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
