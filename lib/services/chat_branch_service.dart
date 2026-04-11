import '../database/database_helper.dart';
import '../models/chat/chat_message.dart';
import '../models/chat/chat_message_metadata.dart';
import '../models/chat/chat_room.dart';
import '../models/chat/chat_summary.dart';
import '../models/community/community_comment.dart';
import '../models/news/news_article.dart';

/// Cascading copy of a chat room up to a specific message index.
///
/// Used by the chat room screen's "branch" action: clones the chat room
/// settings, then copies messages, metadata, summaries, auto-summary
/// config, agent entries, community posts/comments, diary entries, and
/// news articles into the new room — preserving the message-id and
/// agent-entry-id mappings where downstream rows reference them.
///
/// Pure DB I/O, no [BuildContext]. Returns the new chat room id so the
/// host can navigate.
class ChatBranchService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  static final ChatBranchService instance = ChatBranchService._();
  ChatBranchService._();

  /// Generate a `"Base(N)"` style branch name unique within the source
  /// chat room's character. If the source name already matches that
  /// pattern its base is reused.
  Future<String> generateBranchName(ChatRoom source) async {
    final currentName = source.name;
    final branchPattern = RegExp(r'^(.+)\((\d+)\)$');
    final match = branchPattern.firstMatch(currentName);
    final baseName = match != null ? match.group(1)! : currentName;

    final allChatRooms = await _db.readChatRoomsByCharacter(source.characterId);

    int maxNumber = 0;
    final namePattern = RegExp('^${RegExp.escape(baseName)}\\((\\d+)\\)\$');
    for (final room in allChatRooms) {
      final roomMatch = namePattern.firstMatch(room.name);
      if (roomMatch != null) {
        final number = int.parse(roomMatch.group(1)!);
        if (number > maxNumber) maxNumber = number;
      }
    }
    return '$baseName(${maxNumber + 1})';
  }

  /// Branch [source] up to and including [messages][branchAtIndex].
  ///
  /// [metadataMap] is the host's cached mapping from message id to
  /// metadata so we don't have to re-read it from the database.
  ///
  /// Returns the id of the newly-created chat room.
  Future<int> createBranch({
    required ChatRoom source,
    required List<ChatMessage> messages,
    required Map<int, ChatMessageMetadata> metadataMap,
    required int branchAtIndex,
  }) async {
    final branchName = await generateBranchName(source);
    final newChatRoom = ChatRoom(
      characterId: source.characterId,
      name: branchName,
      selectedChatPromptId: source.selectedChatPromptId,
      selectedPersonaId: source.selectedPersonaId,
      selectedStartScenarioId: source.selectedStartScenarioId,
      selectedConditionPresetId: source.selectedConditionPresetId,
      memo: source.memo,
      summary: source.summary,
      autoPinByMessageCount: source.autoPinByMessageCount,
      selectedModelId: source.selectedModelId,
      modelPreset: source.modelPreset,
    );

    final newChatRoomId = await _db.createChatRoom(newChatRoom);

    // Messages + per-message metadata, building old→new id map.
    final messageIdMap = <int, int>{};
    for (int i = 0; i <= branchAtIndex; i++) {
      final msg = messages[i];
      final newMessage = ChatMessage(
        chatRoomId: newChatRoomId,
        role: msg.role,
        content: msg.content,
        tokenCount: msg.tokenCount,
        createdAt: msg.createdAt,
        editedAt: msg.editedAt,
        usageMetadata: msg.usageMetadata,
        modelId: msg.modelId,
      );
      final newMessageId = await _db.createChatMessage(newMessage);

      if (msg.id != null) {
        messageIdMap[msg.id!] = newMessageId;
        final metadata = metadataMap[msg.id!];
        if (metadata != null) {
          await _db.createChatMessageMetadata(ChatMessageMetadata(
            chatMessageId: newMessageId,
            chatRoomId: newChatRoomId,
            location: metadata.location,
            date: metadata.date,
            time: metadata.time,
            isPinned: metadata.isPinned,
            createdAt: metadata.createdAt,
          ));
        }
      }
    }

    // Summaries (skip ones whose pin endpoints didn't make the branch).
    final summaries = await _db.getChatSummaries(source.id!);
    for (final summary in summaries) {
      final newEndId = messageIdMap[summary.endPinMessageId];
      if (newEndId == null) continue;
      final newStartId =
          summary.startPinMessageId == 0 ? 0 : messageIdMap[summary.startPinMessageId];
      if (newStartId == null) continue;

      await _db.createChatSummary(ChatSummary(
        chatRoomId: newChatRoomId,
        startPinMessageId: newStartId,
        endPinMessageId: newEndId,
        summaryContent: summary.summaryContent,
        tokenCount: summary.tokenCount,
        createdAt: summary.createdAt,
        updatedAt: summary.updatedAt,
      ));
    }

    // Auto-summary settings.
    final autoSummarySettings = await _db.getAutoSummarySettings(source.id!);
    if (autoSummarySettings != null) {
      await _db.createAutoSummarySettings(autoSummarySettings.copyWith(
        id: null,
        chatRoomId: newChatRoomId,
      ));
    }

    // Agent entries — keep an old→new id map for news articles below.
    final agentIdMap = <int, int>{};
    final agentEntries = await _db.getAgentEntries(source.id!);
    for (final entry in agentEntries) {
      final newId = await _db.createAgentEntry(entry.copyWith(
        id: null,
        chatRoomId: newChatRoomId,
      ));
      if (entry.id != null) agentIdMap[entry.id!] = newId;
    }

    // Community posts and their comments.
    final communityPosts = await _db.readCommunityPosts(source.id!);
    for (final post in communityPosts) {
      final newPostId = await _db.createCommunityPost(post.copyWith(
        id: null,
        chatRoomId: newChatRoomId,
      ));
      for (final comment in post.comments) {
        await _db.createCommunityComment(CommunityComment(
          postId: newPostId,
          author: comment.author,
          time: comment.time,
          content: comment.content,
        ));
      }
    }

    // Diary entries.
    final diaryEntries = await _db.readDiaryEntries(source.id!);
    for (final diary in diaryEntries) {
      await _db.createDiaryEntry(diary.copyWith(
        id: null,
        chatRoomId: newChatRoomId,
      ));
    }

    // News articles (rewire optional agent entry id through the map).
    final newsArticles = await _db.readNewsArticles(source.id!);
    for (final article in newsArticles) {
      final newAgentEntryId =
          article.agentEntryId != null ? agentIdMap[article.agentEntryId!] : null;
      await _db.createNewsArticle(NewsArticle(
        chatRoomId: newChatRoomId,
        topic: article.topic,
        tone: article.tone,
        author: article.author,
        title: article.title,
        time: article.time,
        content: article.content,
        createdAt: article.createdAt,
        agentEntryId: newAgentEntryId,
      ));
    }

    await _db.updateChatRoomTotalTokenCount(newChatRoomId);
    return newChatRoomId;
  }
}
