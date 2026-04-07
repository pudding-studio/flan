import 'package:flutter/material.dart';
import '../models/chat/chat_room_summary.dart';
import '../database/database_helper.dart';

mixin ChatRoomPaginationMixin<T extends StatefulWidget> on State<T> {
  static const int pageSize = 15;

  final DatabaseHelper paginationDb = DatabaseHelper.instance;
  final ScrollController chatScrollController = ScrollController();
  List<ChatRoomSummary> chatRooms = [];
  bool isLoadingMoreChats = false;
  bool hasMoreChats = true;
  int chatDbOffset = 0;

  int? get paginationCharacterId => null;

  void initPagination() {
    chatScrollController.addListener(_onChatScroll);
    loadChatRooms();
  }

  void disposePagination() {
    chatScrollController.removeListener(_onChatScroll);
    chatScrollController.dispose();
  }

  void _onChatScroll() {
    if (chatScrollController.position.pixels >=
        chatScrollController.position.maxScrollExtent - 200) {
      loadMoreChatRooms();
    }
  }

  Future<void> loadChatRooms() async {
    try {
      final result = await paginationDb.readChatRoomSummaries(
        characterId: paginationCharacterId,
        limit: pageSize,
      );

      if (!mounted) return;
      setState(() {
        chatRooms = result.summaries;
        chatDbOffset = result.queriedCount;
        hasMoreChats = result.queriedCount >= pageSize;
        onChatRoomsLoaded();
      });
    } catch (e) {
      debugPrint('Error loading chat rooms: $e');
    }
  }

  Future<void> loadMoreChatRooms() async {
    if (isLoadingMoreChats || !hasMoreChats) return;
    isLoadingMoreChats = true;

    try {
      final result = await paginationDb.readChatRoomSummaries(
        characterId: paginationCharacterId,
        limit: pageSize,
        offset: chatDbOffset,
      );

      if (!mounted) return;
      setState(() {
        chatRooms.addAll(result.summaries);
        chatDbOffset += result.queriedCount;
        hasMoreChats = result.queriedCount >= pageSize;
        onChatRoomsLoaded();
      });
    } catch (e) {
      debugPrint('Error loading more chat rooms: $e');
    } finally {
      isLoadingMoreChats = false;
    }
  }

  void onChatRoomsLoaded() {}
}
