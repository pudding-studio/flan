import '../database/database_helper.dart';
import '../models/chat/auto_summary_settings.dart';
import '../models/chat/chat_summary.dart';
import '../models/chat/chat_message.dart';
import '../models/chat/chat_message_metadata.dart';
import 'gemini_service.dart';

class AutoSummaryService {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final GeminiService _geminiService = GeminiService();

  Future<bool> shouldTriggerSummary({
    required int chatRoomId,
    required int currentTokenCount,
  }) async {
    final settings = await _db.getAutoSummarySettings(chatRoomId);

    if (settings == null || !settings.isEnabled) {
      return false;
    }

    return currentTokenCount >= settings.tokenThreshold;
  }

  Future<ChatSummary?> generateSummary({
    required int chatRoomId,
  }) async {
    try {
      final settings = await _db.getAutoSummarySettings(chatRoomId);

      if (settings == null || !settings.isEnabled) {
        return null;
      }

      final pinnedMessages = await _getPinnedMessages(chatRoomId);

      if (pinnedMessages.length < 2) {
        return null;
      }

      final endPinMessage = pinnedMessages[pinnedMessages.length - 1];
      final startPinMessage = pinnedMessages[pinnedMessages.length - 2];

      final messagesToSummarize = await _getMessagesBetweenPins(
        chatRoomId: chatRoomId,
        startPinMessageId: startPinMessage.id!,
        endPinMessageId: endPinMessage.id!,
      );

      if (messagesToSummarize.isEmpty) {
        return null;
      }

      final conversationText = _buildConversationText(messagesToSummarize);
      final summaryPrompt = '${settings.summaryPrompt}\n\n$conversationText';

      final response = await _geminiService.sendMessage(
        systemPrompt: '',
        contents: [
          {
            'role': 'user',
            'parts': [
              {'text': summaryPrompt}
            ]
          }
        ],
        chatRoomId: chatRoomId,
      );

      final summary = ChatSummary(
        chatRoomId: chatRoomId,
        startPinMessageId: startPinMessage.id!,
        endPinMessageId: endPinMessage.id!,
        summaryContent: response.text,
        tokenCount: response.usageMetadata?.totalTokens ?? 0,
      );

      final summaryId = await _db.createChatSummary(summary);

      return summary.copyWith(id: summaryId);
    } catch (e) {
      return null;
    }
  }

  Future<List<ChatMessage>> _getPinnedMessages(int chatRoomId) async {
    final allMetadata = await _db.getChatMessageMetadataList(chatRoomId);
    final pinnedMetadata = allMetadata.where((m) => m.isPinned).toList();
    pinnedMetadata.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final pinnedMessages = <ChatMessage>[];
    for (final metadata in pinnedMetadata) {
      final messages = await _db.readChatMessages(chatRoomId);
      final message = messages.firstWhere(
        (msg) => msg.id == metadata.chatMessageId,
        orElse: () => ChatMessage(
          chatRoomId: chatRoomId,
          role: MessageRole.user,
          content: '',
        ),
      );
      if (message.id != null) {
        pinnedMessages.add(message);
      }
    }

    return pinnedMessages;
  }

  Future<List<ChatMessage>> _getMessagesBetweenPins({
    required int chatRoomId,
    required int startPinMessageId,
    required int endPinMessageId,
  }) async {
    final allMessages = await _db.readChatMessages(chatRoomId);

    final startIndex = allMessages.indexWhere((m) => m.id == startPinMessageId);
    final endIndex = allMessages.indexWhere((m) => m.id == endPinMessageId);

    if (startIndex == -1 || endIndex == -1 || startIndex >= endIndex) {
      return [];
    }

    return allMessages.sublist(startIndex + 1, endIndex);
  }

  String _buildConversationText(List<ChatMessage> messages) {
    final buffer = StringBuffer();
    for (final message in messages) {
      final roleLabel = message.role == MessageRole.user ? 'User' : 'Assistant';
      buffer.writeln('$roleLabel: ${message.content}');
      buffer.writeln();
    }
    return buffer.toString().trim();
  }

  Future<List<ChatMessageMetadata>> getChatMessageMetadataList(
      int chatRoomId) async {
    return await _db.getChatMessageMetadataList(chatRoomId);
  }
}
